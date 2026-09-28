-- =============================================================
-- FILE: schema/12_payments.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Creates the payments table
--              Records every payment attempt per order
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP TABLE IF EXISTS payments;

-- =============================================================
-- TABLE: payments
--
-- WHY THIS TABLE EXISTS:
--   Payments are separate from orders because:
--   1. One order may have MULTIPLE payment attempts.
--      (First card declined → retry with second card)
--   2. We must record failed attempts for fraud detection
--      and customer support.
--   3. Refunds are also payments (negative flow) — keeping
--      them here gives a complete financial audit trail.
--
-- RELATIONSHIPS:
--   payments → orders  (many payment attempts per order)
-- =============================================================
CREATE TABLE payments (

    payment_id          BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,

    -- Which order this payment is for
    order_id            BIGINT UNSIGNED     NOT NULL,

    -- ---------------------------------------------------------
    -- PAYMENT METHOD
    -- How the customer chose to pay.
    -- ENUM restricts to known payment methods only.
    -- New methods (e.g. 'bnpl') can be added to ENUM later.
    -- ---------------------------------------------------------
    payment_method      ENUM(
                            'credit_card',
                            'debit_card',
                            'upi',
                            'net_banking',
                            'wallet',
                            'cod'               -- Cash on Delivery
                        )                   NOT NULL,

    -- ---------------------------------------------------------
    -- PAYMENT STATUS
    -- pending   = payment initiated, awaiting gateway response
    -- completed = payment successful, money received
    -- failed    = payment rejected by bank/gateway
    -- refunded  = money returned to customer
    -- ---------------------------------------------------------
    payment_status      ENUM(
                            'pending',
                            'completed',
                            'failed',
                            'refunded'
                        )                   NOT NULL DEFAULT 'pending',

    -- Amount charged in this transaction
    amount              DECIMAL(10, 2)      NOT NULL,

    -- ISO 4217 currency code — INR, USD, EUR, GBP etc.
    -- CHAR(3) = always exactly 3 characters
    currency            CHAR(3)             NOT NULL DEFAULT 'INR',

    -- ---------------------------------------------------------
    -- GATEWAY FIELDS
    -- transaction_id: the reference ID from the payment gateway
    --   (Razorpay, Stripe, PayU etc.)
    --   NULL = payment not yet processed or cash on delivery
    --
    -- gateway_response: raw JSON response from the gateway
    --   Stored for debugging payment failures and disputes.
    --   Example: {"status":"failed","code":"card_declined",
    --              "message":"Insufficient funds"}
    -- ---------------------------------------------------------
    transaction_id      VARCHAR(255)        NULL DEFAULT NULL,
    gateway_response    JSON                NULL DEFAULT NULL,

    -- When the payment was confirmed successful
    -- NULL = not yet paid (pending or failed)
    paid_at             DATETIME            NULL DEFAULT NULL,

    created_at          DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP
                                            ON UPDATE CURRENT_TIMESTAMP,

    -- ---------------------------------------------------------
    -- CONSTRAINTS
    -- ---------------------------------------------------------
    CONSTRAINT pk_payments PRIMARY KEY (payment_id),

    -- Amount must be positive
    CONSTRAINT chk_payments_amount
        CHECK (amount > 0),

    -- FK to orders
    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Payment records — one row per payment attempt per order';

-- =============================================================
-- INDEXES
-- =============================================================

-- All payments for a specific order
CREATE INDEX idx_payments_order_id
    ON payments (order_id);

-- Find payment by gateway transaction ID (for reconciliation)
CREATE INDEX idx_payments_transaction_id
    ON payments (transaction_id);

-- Filter by payment status (admin dashboard)
CREATE INDEX idx_payments_status
    ON payments (payment_status);

-- Revenue reports by date
CREATE INDEX idx_payments_paid_at
    ON payments (paid_at);

-- =============================================================
-- VERIFICATION QUERY
-- =============================================================
DESCRIBE payments;

-- =============================================================
-- SAMPLE DATA (mental model)
--
-- payment_id | order_id | method      | status    | amount     | transaction_id
-- -----------+----------+-------------+-----------+------------+---------------
--          1 |        1 | credit_card | failed    |  184700.00 | NULL
--          2 |        1 | upi         | completed |  184700.00 | UPI123456789
--          3 |        2 | credit_card | completed |  114900.00 | CC987654321
--
-- Order 1 had two attempts: first credit card failed, then UPI succeeded.
-- This complete history is preserved for customer support.
-- =============================================================
