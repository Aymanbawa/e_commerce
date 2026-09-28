-- =============================================================
-- FILE: routines/fn_calculate_discount.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Function that calculates the discount amount
--              for a given coupon code and order subtotal
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP FUNCTION IF EXISTS fn_calculate_discount;

DELIMITER $$

-- =============================================================
-- FUNCTION: fn_calculate_discount
--
-- WHAT IT DOES:
--   Validates a coupon and returns the exact discount amount.
--   Returns 0.00 if the coupon is invalid for any reason.
--
-- VALIDATION CHECKS (in order):
--   1. Coupon code exists in the database
--   2. Coupon is active (is_active = 1)
--   3. Coupon has not expired (expires_at > NOW() or NULL)
--   4. Coupon has started (starts_at <= NOW() or NULL)
--   5. Usage limit not exceeded (usage_count < usage_limit)
--   6. Order meets minimum amount requirement
--   7. Calculates discount based on type (percentage or fixed)
--   8. Applies max_discount_amount cap if set
--
-- PARAMETERS:
--   p_coupon_code  — the coupon code entered by the customer
--   p_subtotal     — order subtotal before discount
--
-- RETURNS:
--   DECIMAL(10,2)  — the discount amount to subtract
--                    Returns 0.00 if coupon is invalid
-- =============================================================
CREATE FUNCTION fn_calculate_discount(
    p_coupon_code   VARCHAR(50),
    p_subtotal      DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_discount_type     VARCHAR(20);
    DECLARE v_discount_value    DECIMAL(10,2);
    DECLARE v_min_order         DECIMAL(10,2);
    DECLARE v_max_discount      DECIMAL(10,2);
    DECLARE v_usage_limit       INT;
    DECLARE v_usage_count       INT;
    DECLARE v_is_active         TINYINT;
    DECLARE v_starts_at         DATETIME;
    DECLARE v_expires_at        DATETIME;
    DECLARE v_discount_amount   DECIMAL(10,2) DEFAULT 0.00;

    -- =========================================================
    -- Fetch coupon from database (normalize code to UPPERCASE)
    -- =========================================================
    SELECT
        discount_type,
        discount_value,
        min_order_amount,
        max_discount_amount,
        usage_limit,
        usage_count,
        is_active,
        starts_at,
        expires_at
    INTO
        v_discount_type,
        v_discount_value,
        v_min_order,
        v_max_discount,
        v_usage_limit,
        v_usage_count,
        v_is_active,
        v_starts_at,
        v_expires_at
    FROM coupons
    WHERE code = UPPER(p_coupon_code);

    -- Coupon not found
    IF v_discount_type IS NULL THEN
        RETURN 0.00;
    END IF;

    -- Coupon is disabled
    IF v_is_active = 0 THEN
        RETURN 0.00;
    END IF;

    -- Coupon has not started yet
    IF v_starts_at IS NOT NULL AND NOW() < v_starts_at THEN
        RETURN 0.00;
    END IF;

    -- Coupon has expired
    IF v_expires_at IS NOT NULL AND NOW() > v_expires_at THEN
        RETURN 0.00;
    END IF;

    -- Usage limit reached (NULL = unlimited)
    IF v_usage_limit IS NOT NULL AND v_usage_count >= v_usage_limit THEN
        RETURN 0.00;
    END IF;

    -- Order subtotal is below minimum required amount
    IF v_min_order IS NOT NULL AND p_subtotal < v_min_order THEN
        RETURN 0.00;
    END IF;

    -- =========================================================
    -- Calculate discount amount based on type
    -- =========================================================
    IF v_discount_type = 'percentage' THEN
        SET v_discount_amount = ROUND(p_subtotal * (v_discount_value / 100), 2);

    ELSEIF v_discount_type = 'fixed_amount' THEN
        SET v_discount_amount = v_discount_value;

    END IF;

    -- =========================================================
    -- Apply max_discount_amount cap (for percentage coupons)
    -- Example: 30% off but max ₹500 discount
    -- =========================================================
    IF v_max_discount IS NOT NULL AND v_discount_amount > v_max_discount THEN
        SET v_discount_amount = v_max_discount;
    END IF;

    -- Discount cannot exceed the order subtotal
    IF v_discount_amount > p_subtotal THEN
        SET v_discount_amount = p_subtotal;
    END IF;

    RETURN v_discount_amount;

END$$

DELIMITER ;

-- =============================================================
-- HOW TO USE THIS FUNCTION:
--
-- Direct call to check a coupon:
-- SELECT fn_calculate_discount('SAVE20', 5000.00) AS discount_amount;
-- -- Returns: 1000.00 (20% of 5000)
--
-- SELECT fn_calculate_discount('FLAT200', 5000.00) AS discount_amount;
-- -- Returns: 200.00 (fixed ₹200 off)
--
-- SELECT fn_calculate_discount('EXPIRED', 5000.00) AS discount_amount;
-- -- Returns: 0.00 (invalid coupon)
--
-- Used internally by sp_place_order automatically.
-- =============================================================
