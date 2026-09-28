-- =============================================================
-- FILE: routines/sp_place_order.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Stored procedure to place an order atomically
--              Validates stock, applies coupon, creates order + items
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

-- Drop procedure if it exists (for clean re-runs)
DROP PROCEDURE IF EXISTS sp_place_order;

-- Change delimiter so MySQL doesn't end the procedure early
-- at the first semicolon inside the body
DELIMITER $$

-- =============================================================
-- PROCEDURE: sp_place_order
--
-- WHAT IT DOES (in order):
--   1. Starts a transaction — all steps succeed or all roll back
--   2. Validates the user exists and is active
--   3. Validates the shipping address belongs to the user
--   4. Validates each product: active, in stock, enough quantity
--   5. Validates the coupon (if provided)
--   6. Calculates subtotal, discount, tax, shipping, total
--   7. Creates the order header row
--   8. Creates order_item rows for each product
--   9. Reserves stock (quantity_reserved += qty)
--  10. Updates coupon usage count
--  11. Commits the transaction
--
-- PARAMETERS:
--   p_user_id      — the customer placing the order
--   p_address_id   — shipping address to use
--   p_coupon_code  — discount code ('' or NULL = no coupon)
--   p_items        — JSON array of items:
--                    [{"product_id":1,"quantity":2}, ...]
--   p_notes        — delivery instructions (optional)
--
-- OUTPUT PARAMETER:
--   p_order_id     — returns the new order_id on success
--                    returns 0 on any validation failure
-- =============================================================
CREATE PROCEDURE sp_place_order(
    IN  p_user_id       BIGINT UNSIGNED,
    IN  p_address_id    BIGINT UNSIGNED,
    IN  p_coupon_code   VARCHAR(50),
    IN  p_items         JSON,
    IN  p_notes         TEXT,
    OUT p_order_id      BIGINT UNSIGNED
)
BEGIN
    -- ---------------------------------------------------------
    -- Local variables
    -- ---------------------------------------------------------
    DECLARE v_user_active       TINYINT DEFAULT 0;
    DECLARE v_address_valid     INT     DEFAULT 0;
    DECLARE v_coupon_id         BIGINT UNSIGNED DEFAULT NULL;
    DECLARE v_discount_amount   DECIMAL(10,2)   DEFAULT 0.00;
    DECLARE v_subtotal          DECIMAL(10,2)   DEFAULT 0.00;
    DECLARE v_tax_rate          DECIMAL(5,4)    DEFAULT 0.18; -- 18% GST
    DECLARE v_tax_amount        DECIMAL(10,2)   DEFAULT 0.00;
    DECLARE v_shipping_amount   DECIMAL(10,2)   DEFAULT 0.00;
    DECLARE v_total_amount      DECIMAL(10,2)   DEFAULT 0.00;
    DECLARE v_order_number      VARCHAR(50);
    DECLARE v_item_count        INT     DEFAULT 0;
    DECLARE v_i                 INT     DEFAULT 0;
    DECLARE v_product_id        BIGINT UNSIGNED;
    DECLARE v_quantity          INT UNSIGNED;
    DECLARE v_product_name      VARCHAR(255);
    DECLARE v_product_sku       VARCHAR(100);
    DECLARE v_unit_price        DECIMAL(10,2);
    DECLARE v_stock_available   INT;
    DECLARE v_product_status    VARCHAR(20);
    DECLARE v_item_total        DECIMAL(10,2);
    DECLARE v_error_msg         VARCHAR(500);

    -- Error handler — rolls back on any SQL error
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_order_id = 0;
        RESIGNAL;
    END;

    -- Default output
    SET p_order_id = 0;

    -- =========================================================
    -- STEP 1: Validate user
    -- =========================================================
    SELECT is_active INTO v_user_active
    FROM users
    WHERE user_id = p_user_id AND deleted_at IS NULL;

    IF v_user_active IS NULL OR v_user_active = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User account is inactive or does not exist.';
    END IF;

    -- =========================================================
    -- STEP 2: Validate address belongs to this user
    -- =========================================================
    SELECT COUNT(*) INTO v_address_valid
    FROM addresses
    WHERE address_id = p_address_id AND user_id = p_user_id;

    IF v_address_valid = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid shipping address for this user.';
    END IF;

    -- =========================================================
    -- STEP 3: Validate items JSON is not empty
    -- =========================================================
    SET v_item_count = JSON_LENGTH(p_items);

    IF v_item_count IS NULL OR v_item_count = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Order must contain at least one item.';
    END IF;

    -- =========================================================
    -- START TRANSACTION — everything below is atomic
    -- =========================================================
    START TRANSACTION;

    -- =========================================================
    -- STEP 4: Loop through each item — validate and calc subtotal
    -- =========================================================
    SET v_i = 0;
    WHILE v_i < v_item_count DO

        -- Extract product_id and quantity from JSON array
        SET v_product_id = JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[', v_i, '].product_id')));
        SET v_quantity   = JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[', v_i, '].quantity')));

        -- Validate quantity
        IF v_quantity IS NULL OR v_quantity < 1 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Item quantity must be at least 1.';
        END IF;

        -- Fetch product details
        SELECT
            p.name,
            p.sku,
            p.price,
            p.status,
            (i.quantity_in_stock - i.quantity_reserved) AS available_stock
        INTO
            v_product_name,
            v_product_sku,
            v_unit_price,
            v_product_status,
            v_stock_available
        FROM products p
        JOIN inventory i ON i.product_id = p.product_id
        WHERE p.product_id = v_product_id
          AND p.deleted_at IS NULL;

        -- Product must exist
        IF v_product_name IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'One or more products not found.';
        END IF;

        -- Product must be active
        IF v_product_status != 'active' THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'One or more products are not available for purchase.';
        END IF;

        -- Sufficient stock available
        IF v_stock_available < v_quantity THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Insufficient stock for one or more products.';
        END IF;

        -- Add to subtotal
        SET v_item_total = v_quantity * v_unit_price;
        SET v_subtotal   = v_subtotal + v_item_total;

        SET v_i = v_i + 1;
    END WHILE;

    -- =========================================================
    -- STEP 5: Validate and apply coupon
    -- =========================================================
    IF p_coupon_code IS NOT NULL AND p_coupon_code != '' THEN

        -- Call the discount function
        SET v_discount_amount = fn_calculate_discount(p_coupon_code, v_subtotal);

        -- Get coupon_id for the order record
        SELECT coupon_id INTO v_coupon_id
        FROM coupons
        WHERE code = UPPER(p_coupon_code) AND is_active = 1;

        -- Increment coupon usage count
        UPDATE coupons
        SET usage_count = usage_count + 1
        WHERE coupon_id = v_coupon_id;

    END IF;

    -- =========================================================
    -- STEP 6: Calculate final totals
    -- Shipping is free for orders over ₹999, else ₹99
    -- =========================================================
    SET v_shipping_amount = IF((v_subtotal - v_discount_amount) >= 999, 0.00, 99.00);
    SET v_tax_amount      = ROUND((v_subtotal - v_discount_amount) * v_tax_rate, 2);
    SET v_total_amount    = v_subtotal - v_discount_amount + v_tax_amount + v_shipping_amount;

    -- =========================================================
    -- STEP 7: Generate order number — format: ORD-YYYYMMDD-XXXXX
    -- =========================================================
    SET v_order_number = CONCAT(
        'ORD-',
        DATE_FORMAT(NOW(), '%Y%m%d'),
        '-',
        LPAD(FLOOR(RAND() * 99999), 5, '0')
    );

    -- =========================================================
    -- STEP 8: Insert the order header
    -- =========================================================
    INSERT INTO orders (
        user_id, address_id, coupon_id, order_number,
        status, subtotal, discount_amount, tax_amount,
        shipping_amount, total_amount, notes
    ) VALUES (
        p_user_id, p_address_id, v_coupon_id, v_order_number,
        'pending', v_subtotal, v_discount_amount, v_tax_amount,
        v_shipping_amount, v_total_amount, p_notes
    );

    -- Capture the new order_id
    SET p_order_id = LAST_INSERT_ID();

    -- =========================================================
    -- STEP 9: Insert order_items + reserve stock
    -- =========================================================
    SET v_i = 0;
    WHILE v_i < v_item_count DO

        SET v_product_id = JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[', v_i, '].product_id')));
        SET v_quantity   = JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[', v_i, '].quantity')));

        -- Re-fetch name, sku, price for the snapshot
        SELECT name, sku, price
        INTO v_product_name, v_product_sku, v_unit_price
        FROM products
        WHERE product_id = v_product_id;

        SET v_item_total = v_quantity * v_unit_price;

        -- Insert order item with snapshot values
        INSERT INTO order_items (
            order_id, product_id, product_name, product_sku,
            quantity, unit_price, total_price
        ) VALUES (
            p_order_id, v_product_id, v_product_name, v_product_sku,
            v_quantity, v_unit_price, v_item_total
        );

        -- Reserve stock — quantity_reserved increases
        UPDATE inventory
        SET quantity_reserved = quantity_reserved + v_quantity
        WHERE product_id = v_product_id;

        SET v_i = v_i + 1;
    END WHILE;

    -- =========================================================
    -- STEP 10: Commit everything
    -- =========================================================
    COMMIT;

END$$

DELIMITER ;

-- =============================================================
-- HOW TO CALL THIS PROCEDURE:
--
-- CALL sp_place_order(
--     1,                              -- user_id
--     1,                              -- address_id
--     'SAVE10',                       -- coupon_code (or NULL)
--     '[{"product_id":1,"quantity":1},{"product_id":5,"quantity":2}]',
--     'Please leave at door',         -- notes
--     @order_id                       -- output variable
-- );
-- SELECT @order_id;                   -- see the new order_id
-- =============================================================
