-- =============================================================
-- FILE: schema/10_orders.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Creates the orders table
--              Order header — one row per customer order
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP TABLE IF EXISTS orders;

-- =============================================================
-- TABLE: orders
--
-- WHY THIS TABLE EXISTS:
--   When a customer completes checkout, one order row is created.
--   This is the "header" — it tracks who ordered, where to
--   deliver, what coupon was used, and the financial totals.
--   The actual products ordered live in order_items.
--
--   Think of it like a paper receipt:
--     orders      = the top half (customer, date, total)
--     order_items = the line items listed below
--
-- RELATIONSHIPS:
--   orders → users      (who placed the order)
--   orders → addresses  (where to deliver)
--   orders → coupons    (discount applied, if any)
--   orders ← order_items (products within this order)
--   orders ← payments   (payment records for this order)
--   orders ← shipments  (delivery records for this order)
--   orders ← reviews    (reviews tied to this order)
-- =============================================================
CREATE TABLE orders (

    order_id        BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    user_id         BIGINT UNSIGNED     NOT NULL,
    address_id      BIGINT UNSIGNED     NOT NULL,
    coupon_id       BIGINT UNSIGNED     NULL DEFAULT NULL,

    -- Human-readable order reference shown to customer
    -- e.g. ORD-000001, ORD-000002
    order_number    VARCHAR(50)         NOT NULL,

    -- Full order lifecycle
    status          ENUM(
                        'pending',      -- just placed, payment not confirmed
                        'confirmed',    -- payment confirmed
                        'processing',   -- being packed in warehouse
                        'shipped',      -- handed to courier
                        'delivered',    -- received by customer
                        'cancelled',    -- cancelled before delivery
                        'refunded'      -- money returned after delivery
                    )                   NOT NULL DEFAULT 'pending',

    -- Financial breakdown — all stored separately for transparency
    subtotal        DECIMAL(10, 2)      NOT NULL,
    discount_amount DECIMAL(10, 2)      NOT NULL DEFAULT 0.00,
    tax_amount      DECIMAL(10, 2)      NOT NULL DEFAULT 0.00,
    shipping_amount DECIMAL(10, 2)      NOT NULL DEFAULT 0.00,

    -- Final charge: subtotal - discount + tax + shipping
    total_amount    DECIMAL(10, 2)      NOT NULL,

    -- Customer delivery instructions
    notes           TEXT                NULL DEFAULT NULL,

    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP
                                        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_orders PRIMARY KEY (order_id),

    CONSTRAINT uq_orders_number UNIQUE (order_number),

    -- Total must be positive
    CONSTRAINT chk_orders_total
        CHECK (total_amount > 0),

    -- Discount cannot exceed the subtotal
    CONSTRAINT chk_orders_discount
        CHECK (discount_amount >= 0 AND discount_amount <= subtotal),

    CONSTRAINT fk_orders_user
        FOREIGN KEY (user_id)
        REFERENCES users (user_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_orders_address
        FOREIGN KEY (address_id)
        REFERENCES addresses (address_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_orders_coupon
        FOREIGN KEY (coupon_id)
        REFERENCES coupons (coupon_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Order header — one row per customer order';

-- Customer order history page
CREATE INDEX idx_orders_user_id
    ON orders (user_id);

-- Admin order management — filter by status
CREATE INDEX idx_orders_status
    ON orders (status);

-- Date-range reports — monthly sales etc.
CREATE INDEX idx_orders_created_at
    ON orders (created_at);

-- Lookup by order number (customer support)
CREATE INDEX idx_orders_order_number
    ON orders (order_number);

-- Combined — user's orders in a specific status
CREATE INDEX idx_orders_user_status
    ON orders (user_id, status);

DESCRIBE orders;
