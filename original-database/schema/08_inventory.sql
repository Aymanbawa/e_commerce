-- =============================================================
-- FILE: schema/08_inventory.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Creates the inventory table
--              Tracks stock levels per product
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP TABLE IF EXISTS inventory;

-- =============================================================
-- TABLE: inventory
--
-- WHY THIS TABLE EXISTS:
--   Stock levels change constantly — every sale, every restock,
--   every return affects the count. Keeping inventory separate
--   from products means stock updates never touch product data.
--
--   KEY CONCEPT — Two quantity columns:
--   quantity_in_stock: total physical units in the warehouse
--   quantity_reserved: units held for pending (unshipped) orders
--
--   Available to buy = quantity_in_stock - quantity_reserved
--
--   WHY RESERVED?
--   Without reservation, two customers could both buy the last
--   unit at the same time — one order would fail at shipping.
--   Reserving stock the moment an order is placed prevents this.
--
-- RELATIONSHIPS:
--   inventory → products  (one inventory row per product)
-- =============================================================
CREATE TABLE inventory (

    inventory_id        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    product_id          BIGINT UNSIGNED NOT NULL,

    -- Total physical units in warehouse
    quantity_in_stock   INT UNSIGNED    NOT NULL DEFAULT 0,

    -- Units held for pending/confirmed orders not yet shipped
    quantity_reserved   INT UNSIGNED    NOT NULL DEFAULT 0,

    -- Alert threshold — when stock drops below this, notify admin
    reorder_threshold   INT UNSIGNED    NOT NULL DEFAULT 10,

    updated_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP
                                        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_inventory PRIMARY KEY (inventory_id),

    -- One inventory row per product — enforced by UNIQUE
    CONSTRAINT uq_inventory_product UNIQUE (product_id),

    -- Stock can never go negative
    CONSTRAINT chk_inventory_stock
        CHECK (quantity_in_stock >= 0),

    CONSTRAINT chk_inventory_reserved
        CHECK (quantity_reserved >= 0),

    -- Reserved can never exceed total stock
    CONSTRAINT chk_inventory_reserved_lte_stock
        CHECK (quantity_reserved <= quantity_in_stock),

    CONSTRAINT fk_inventory_product
        FOREIGN KEY (product_id)
        REFERENCES products (product_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Stock levels per product with reservation support';

-- Index for low stock alert view
CREATE INDEX idx_inventory_product_id
    ON inventory (product_id);

CREATE INDEX idx_inventory_stock_level
    ON inventory (quantity_in_stock, reorder_threshold);

DESCRIBE inventory;
