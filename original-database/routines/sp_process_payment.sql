-- =============================================================
-- FILE: routines/sp_process_payment.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Records a payment attempt and updates order status
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP PROCEDURE IF EXISTS sp_process_payment;

DELIMITER $$

-- =============================================================
-- PROCEDURE: sp_process_payment
--
-- WHAT IT DOES:
--   1. Validates the order exists and is in 'pending' status
--   2. Checks no completed payment already exists (prevent double pay)
--   3. Records the payment attempt (success or failure)
--   4. If payment succeeded → updates order status to 'confirmed'
--   5. All steps are atomic inside a transaction
--
-- PARAMETERS:
--   p_order_id        — which order is being paid
--   p_payment_method  — how the customer paid (upi, card etc.)
--   p_amount          — amount charged
--   p_transaction_id  — reference from payment gateway
--   p_status          — 'completed' or 'failed'
--   p_gateway_json    — raw JSON response from gateway
-- OUTPUT:
--   p_success         — 1 = recorded, 0 = failed
--   p_message         — human-readable result
-- =============================================================
CREATE PROCEDURE sp_process_payment(
    IN  p_order_id          BIGINT UNSIGNED,
    IN  p_payment_method    VARCHAR(20),
    IN  p_amount            DECIMAL(10,2),
    IN  p_transaction_id    VARCHAR(255),
    IN  p_status            VARCHAR(20),
    IN  p_gateway_json      JSON,
    OUT p_success           TINYINT,
    OUT p_message           VARCHAR(500)
)
BEGIN
    DECLARE v_order_status      VARCHAR(20);
    DECLARE v_order_total       DECIMAL(10,2);
    DECLARE v_existing_payment  INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_success = 0;
        SET p_message = 'Unexpected error during payment processing.';
    END;

    SET p_success = 0;

    -- =========================================================
    -- STEP 1: Fetch order
    -- =========================================================
    SELECT status, total_amount
    INTO v_order_status, v_order_total
    FROM orders
    WHERE order_id = p_order_id;

    IF v_order_status IS NULL THEN
        SET p_message = 'Order not found.';
        LEAVE sp_process_payment;
    END IF;

    -- =========================================================
    -- STEP 2: Order must be in pending state to accept payment
    -- =========================================================
    IF v_order_status != 'pending' THEN
        SET p_message = CONCAT('Order is in status: ', v_order_status, '. Cannot process payment.');
        LEAVE sp_process_payment;
    END IF;

    -- =========================================================
    -- STEP 3: Check for existing successful payment (no double pay)
    -- =========================================================
    SELECT COUNT(*) INTO v_existing_payment
    FROM payments
    WHERE order_id = p_order_id AND payment_status = 'completed';

    IF v_existing_payment > 0 THEN
        SET p_message = 'This order has already been paid successfully.';
        LEAVE sp_process_payment;
    END IF;

    -- =========================================================
    -- STEP 4: Amount must match order total
    -- =========================================================
    IF p_amount != v_order_total THEN
        SET p_message = CONCAT(
            'Payment amount (', p_amount,
            ') does not match order total (', v_order_total, ').'
        );
        LEAVE sp_process_payment;
    END IF;

    -- =========================================================
    -- START TRANSACTION
    -- =========================================================
    START TRANSACTION;

    -- =========================================================
    -- STEP 5: Record the payment attempt
    -- =========================================================
    INSERT INTO payments (
        order_id, payment_method, payment_status,
        amount, currency, transaction_id,
        gateway_response, paid_at
    ) VALUES (
        p_order_id,
        p_payment_method,
        p_status,
        p_amount,
        'INR',
        p_transaction_id,
        p_gateway_json,
        IF(p_status = 'completed', NOW(), NULL)
    );

    -- =========================================================
    -- STEP 6: If payment succeeded, confirm the order
    -- =========================================================
    IF p_status = 'completed' THEN
        UPDATE orders
        SET status = 'confirmed'
        WHERE order_id = p_order_id;
    END IF;
    -- If payment failed: order stays 'pending' for retry

    COMMIT;

    SET p_success = 1;
    SET p_message = IF(
        p_status = 'completed',
        CONCAT('Payment successful. Order #', p_order_id, ' confirmed.'),
        CONCAT('Payment failed. Order #', p_order_id, ' remains pending for retry.')
    );

END$$

DELIMITER ;

-- =============================================================
-- HOW TO CALL THIS PROCEDURE:
--
-- CALL sp_process_payment(
--     1,                   -- order_id
--     'upi',               -- payment_method
--     184700.00,           -- amount
--     'UPI123456789',      -- transaction_id
--     'completed',         -- status: 'completed' or 'failed'
--     '{"gateway":"razorpay","code":"SUCCESS"}',
--     @success,
--     @message
-- );
-- SELECT @success, @message;
-- =============================================================
