-- =============================================================
-- FILE: schema/11_order_items.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Creates the order_items table
--              Line items within each order (one row per product per order)
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP TABLE IF EXISTS order_items;

-- =============================================================
-- TABLE: order_items
--
-- WHY THIS TABLE EXISTS:
--   An order can contain multiple products.
--   The orders table holds the overall order (totals, status).
--   This table holds the individual product lines within it.
--
--   Example:
--     Order #1001 (orders table — 1 row)
--       ├── iPhone 15 Pro  × 1  @ ₹134,900  (order_items — row 1)
--       ├── AirPods Pro    × 2  @ ₹24,900   (order_items — row 2)
--       └── MagSafe Case   × 1  @  ₹4,900   (order_items — row 3)
--
-- SNAPSHOT PATTERN (very important):
--   product_name, product_sku, and unit_price are COPIED from
--   the products table at the moment the order is placed.
--   They are stored directly in this row as a snapshot.
--
--   WHY:
--     If the product price changes tomorrow, the customer's
--     receipt from today must still show what they paid.
--     If the product is renamed, old invoices must stay correct.
--     Snapshots make order history tamper-proof and accurate.
--
-- RELATIONSHIPS:
--   order_items → orders    (many items belong to one order)
--   order_items → products  (each item references one product)
-- =============================================================
CREATE TABLE order_items (

    item_id         BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,

    -- Which order this line belongs to
    order_id        BIGINT UNSIGNED     NOT NULL,

    -- Which product was ordered (FK for joins and reports)
    product_id      BIGINT UNSIGNED     NOT NULL,

    -- ---------------------------------------------------------
    -- SNAPSHOTS — copied at purchase time, never updated
    -- Even if the product is later renamed, repriced, or deleted,
    -- these columns always show what was true at purchase time.
    -- ---------------------------------------------------------
    product_name    VARCHAR(255)        NOT NULL,
    product_sku     VARCHAR(100)        NOT NULL,

    -- How many units the customer ordered
    quantity        INT UNSIGNED        NOT NULL,

    -- Price per unit at purchase time (snapshot)
    unit_price      DECIMAL(10, 2)      NOT NULL,

    -- quantity × unit_price — stored for fast reporting
    -- (avoids recalculating on every query)
    total_price     DECIMAL(10, 2)      NOT NULL,

    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- ---------------------------------------------------------
    -- CONSTRAINTS
    -- ---------------------------------------------------------
    CONSTRAINT pk_order_items PRIMARY KEY (item_id),

    -- Quantity must be at least 1 — you can't order 0 of something
    CONSTRAINT chk_order_items_quantity
        CHECK (quantity > 0),

    -- Unit price must be positive
    CONSTRAINT chk_order_items_unit_price
        CHECK (unit_price > 0),

    -- total_price must equal quantity × unit_price
    CONSTRAINT chk_order_items_total
        CHECK (total_price = quantity * unit_price),

    -- FK to orders — cascade: if order deleted, delete its items
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- FK to products — RESTRICT: keep product referenced in history
    -- SET NULL not used here because product_name/sku are snapshots
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES products (product_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Line items within each order — prices snapshotted at purchase time';

-- =============================================================
-- INDEXES
-- =============================================================

-- All items in a specific order (order detail page)
CREATE INDEX idx_order_items_order_id
    ON order_items (order_id);

-- All orders containing a specific product (sales reports)
CREATE INDEX idx_order_items_product_id
    ON order_items (product_id);

-- =============================================================
-- VERIFICATION QUERY
-- =============================================================
DESCRIBE order_items;

-- =============================================================
-- SAMPLE DATA (mental model)
--
-- item_id | order_id | product_id | product_name   | qty | unit_price | total_price
-- --------+----------+------------+----------------+-----+------------+------------
--       1 |        1 |          1 | iPhone 15 Pro  |   1 |  134900.00 |  134900.00
--       2 |        1 |          5 | AirPods Pro    |   2 |   24900.00 |   49800.00
--       3 |        2 |          3 | MacBook Air M3 |   1 |  114900.00 |  114900.00
-- =============================================================
