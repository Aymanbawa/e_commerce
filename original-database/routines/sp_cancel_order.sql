-- =============================================================
-- FILE: routines/sp_cancel_order.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Stored procedure to cancel an order
--              Restores reserved stock and updates order status
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP PROCEDURE IF EXISTS sp_cancel_order;

DELIMITER $$

-- =============================================================
-- PROCEDURE: sp_cancel_order
--
-- WHAT IT DOES:
--   1. Validates the order exists and belongs to the user
--   2. Validates the order is in a cancellable state
--   3. Releases reserved stock back to available
--   4. Updates order status to 'cancelled'
--   All steps are atomic inside a transaction.
--
-- CANCELLABLE STATES:
--   pending, confirmed, processing
--   (Cannot cancel: shipped, delivered, already cancelled, refunded)
--
-- PARAMETERS:
--   p_user_id   — must be the order owner or an admin
--   p_order_id  — the order to cancel
--   p_reason    — optional reason for cancellation
-- OUTPUT:
--   p_success   — 1 = cancelled, 0 = failed
--   p_message   — human-readable result message
-- =============================================================
CREATE PROCEDURE sp_cancel_order(
    IN  p_user_id   BIGINT UNSIGNED,
    IN  p_order_id  BIGINT UNSIGNED,
    IN  p_reason    VARCHAR(500),
    OUT p_success   TINYINT,
    OUT p_message   VARCHAR(500)
)
BEGIN
    DECLARE v_order_user_id BIGINT UNSIGNED;
    DECLARE v_order_status  VARCHAR(20);
    DECLARE v_user_role     VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_success = 0;
        SET p_message = 'An unexpected error occurred during cancellation.';
    END;

    SET p_success = 0;

    -- =========================================================
    -- STEP 1: Fetch order details
    -- =========================================================
    SELECT user_id, status
    INTO v_order_user_id, v_order_status
    FROM orders
    WHERE order_id = p_order_id;

    IF v_order_user_id IS NULL THEN
        SET p_message = 'Order not found.';
        LEAVE sp_cancel_order;
    END IF;

    -- =========================================================
    -- STEP 2: Validate caller is owner or admin
    -- =========================================================
    SELECT role INTO v_user_role
    FROM users WHERE user_id = p_user_id;

    IF v_order_user_id != p_user_id AND v_user_role != 'admin' THEN
        SET p_message = 'You do not have permission to cancel this order.';
        LEAVE sp_cancel_order;
    END IF;

    -- =========================================================
    -- STEP 3: Validate cancellable status
    -- =========================================================
    IF v_order_status NOT IN ('pending', 'confirmed', 'processing') THEN
        SET p_message = CONCAT(
            'Cannot cancel order in status: ', v_order_status,
            '. Only pending, confirmed, or processing orders can be cancelled.'
        );
        LEAVE sp_cancel_order;
    END IF;

    -- =========================================================
    -- START TRANSACTION
    -- =========================================================
    START TRANSACTION;

    -- =========================================================
    -- STEP 4: Release reserved stock for each item in the order
    -- =========================================================
    UPDATE inventory i
    JOIN order_items oi ON oi.product_id = i.product_id
    SET i.quantity_reserved = GREATEST(0, i.quantity_reserved - oi.quantity)
    WHERE oi.order_id = p_order_id;

    -- =========================================================
    -- STEP 5: Update order status to cancelled
    -- The audit trigger will automatically log this change
    -- =========================================================
    UPDATE orders
    SET
        status  = 'cancelled',
        notes   = CONCAT(
                    IFNULL(notes, ''),
                    ' | Cancelled: ', IFNULL(p_reason, 'No reason given')
                  )
    WHERE order_id = p_order_id;

    -- =========================================================
    -- COMMIT
    -- =========================================================
    COMMIT;

    SET p_success = 1;
    SET p_message = CONCAT('Order #', p_order_id, ' successfully cancelled.');

END$$

DELIMITER ;

-- =============================================================
-- HOW TO CALL THIS PROCEDURE:
--
-- CALL sp_cancel_order(
--     1,                              -- user_id (order owner or admin)
--     42,                             -- order_id to cancel
--     'Customer requested cancellation',
--     @success,
--     @message
-- );
-- SELECT @success, @message;
-- =============================================================
