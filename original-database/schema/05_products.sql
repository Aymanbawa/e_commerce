-- =============================================================
-- FILE: schema/05_products.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Creates the products table
--              The core catalogue — every item available for sale
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP TABLE IF EXISTS products;

-- =============================================================
-- TABLE: products
--
-- WHY THIS TABLE EXISTS:
--   This is the heart of any e-commerce database.
--   Every item listed for sale gets one row here.
--   It connects to categories (what type of item) and brands
--   (who made it), and is referenced by orders, reviews,
--   wishlist, inventory, and product images.
--
-- WHAT THIS TABLE DOES NOT STORE:
--   - Stock quantity         → inventory table (separate concern)
--   - Product images         → product_images table
--   - Specs like color/size  → product_attributes table
--   These are kept separate to follow 3NF and allow
--   each concern to grow independently.
--
-- RELATIONSHIPS:
--   products → categories       (each product has one category)
--   products → brands           (each product has one brand)
--   products ← product_images   (one product, many images)
--   products ← product_attributes (one product, many specs)
--   products ← inventory        (one product, one stock row)
--   products ← order_items      (one product, many order lines)
--   products ← reviews          (one product, many reviews)
--   products ← wishlist         (one product, saved by many users)
-- =============================================================
CREATE TABLE products (

    -- ---------------------------------------------------------
    -- PRIMARY KEY
    -- ---------------------------------------------------------
    product_id      BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,

    -- ---------------------------------------------------------
    -- FOREIGN KEYS
    -- category_id: required — every product must have a category
    -- brand_id: optional — some products have no brand (generic)
    --
    -- ON DELETE RESTRICT on category:
    --   You cannot delete a category that still has products.
    --   Force the admin to move products first. This prevents
    --   orphaned products with no category.
    --
    -- ON DELETE SET NULL on brand:
    --   If a brand is deleted, products become unbranded (NULL).
    --   Products still exist and can be sold — just no brand shown.
    -- ---------------------------------------------------------
    category_id     BIGINT UNSIGNED     NOT NULL,
    brand_id        BIGINT UNSIGNED     NULL DEFAULT NULL,

    -- ---------------------------------------------------------
    -- PRODUCT IDENTITY
    -- name: displayed on the storefront and in orders
    -- slug: used in the URL — example.com/product/iphone-15-pro
    -- sku:  Stock Keeping Unit — internal code used in warehouses
    --       and on invoices. Must be unique across all products.
    -- ---------------------------------------------------------
    name            VARCHAR(255)        NOT NULL,
    slug            VARCHAR(300)        NOT NULL,
    sku             VARCHAR(100)        NOT NULL,

    -- ---------------------------------------------------------
    -- DESCRIPTIONS
    -- description: full product details — shown on product page
    -- short_desc:  one-liner — shown in search results / listings
    -- ---------------------------------------------------------
    description     TEXT                NULL DEFAULT NULL,
    short_desc      VARCHAR(500)        NULL DEFAULT NULL,

    -- ---------------------------------------------------------
    -- PRICING — all use DECIMAL(10,2)
    --
    -- WHY DECIMAL and not FLOAT?
    --   FLOAT stores approximate values. This causes errors:
    --   FLOAT: 19.99 + 0.01 might give 19.999999998
    --   DECIMAL: 19.99 + 0.01 = 20.00 (exact, always)
    --   Money MUST use DECIMAL. This is a hard rule.
    --
    -- DECIMAL(10, 2) means:
    --   Up to 10 digits total, with exactly 2 decimal places.
    --   Max value = 99,999,999.99 (about 99 million rupees/dollars)
    --
    -- price:         the current selling price (required)
    -- compare_price: the "original" price shown crossed out
    --                Example: ~~₹10,000~~ Now ₹7,999
    --                Must be > price when set (enforced by CHECK)
    -- cost_price:    what we paid the supplier — PRIVATE
    --                Used only for internal profit margin reports
    --                Never shown to customers
    -- ---------------------------------------------------------
    price           DECIMAL(10, 2)      NOT NULL,
    compare_price   DECIMAL(10, 2)      NULL DEFAULT NULL,
    cost_price      DECIMAL(10, 2)      NULL DEFAULT NULL,

    -- ---------------------------------------------------------
    -- PRODUCT STATUS
    -- Controls visibility and purchasability on the storefront.
    --
    -- draft     = being created, not visible to anyone
    -- active    = live on the storefront, can be purchased
    -- inactive  = hidden temporarily (out of season, low stock)
    -- archived  = permanently retired, kept for order history
    --
    -- Only 'active' products can be added to cart.
    -- (Enforced by stored procedure sp_place_order)
    -- ---------------------------------------------------------
    status          ENUM('draft', 'active', 'inactive', 'archived')
                                        NOT NULL DEFAULT 'draft',

    -- ---------------------------------------------------------
    -- FEATURED FLAG
    -- is_featured = 1: show this product on the homepage
    -- is_featured = 0: regular product (default)
    -- ---------------------------------------------------------
    is_featured     TINYINT(1)          NOT NULL DEFAULT 0,

    -- ---------------------------------------------------------
    -- PHYSICAL PROPERTIES
    -- weight_grams: used to calculate shipping cost
    -- NULL = digital product or weight not specified
    -- INT UNSIGNED = no negative weight possible
    -- ---------------------------------------------------------
    weight_grams    INT UNSIGNED        NULL DEFAULT NULL,

    -- ---------------------------------------------------------
    -- TIMESTAMPS + SOFT DELETE
    -- Same pattern as users table:
    --   deleted_at = NULL  → product is active
    --   deleted_at = date  → product is soft-deleted
    -- WHY soft delete:
    --   Past order_items reference this product_id.
    --   Hard deleting breaks that reference.
    --   The product name/price snapshot in order_items is safe,
    --   but the FK would fail without soft delete.
    -- ---------------------------------------------------------
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP
                                        ON UPDATE CURRENT_TIMESTAMP,
    deleted_at      DATETIME            NULL DEFAULT NULL,

    -- ---------------------------------------------------------
    -- CONSTRAINTS
    -- ---------------------------------------------------------
    CONSTRAINT pk_products PRIMARY KEY (product_id),

    CONSTRAINT uq_products_slug UNIQUE (slug),

    CONSTRAINT uq_products_sku  UNIQUE (sku),

    -- Price must always be positive — no free or negative prices
    CONSTRAINT chk_products_price
        CHECK (price > 0),

    -- compare_price (original/was price) must be higher than
    -- the actual selling price — otherwise the "sale" is fake
    CONSTRAINT chk_products_compare_price
        CHECK (compare_price IS NULL OR compare_price > price),

    -- cost_price must be positive when provided
    CONSTRAINT chk_products_cost_price
        CHECK (cost_price IS NULL OR cost_price > 0),

    -- FK to categories — RESTRICT prevents deleting a category
    -- that still has products assigned to it
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id)
        REFERENCES categories (category_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    -- FK to brands — SET NULL allows brand deletion
    -- products become unbranded but still exist
    CONSTRAINT fk_products_brand
        FOREIGN KEY (brand_id)
        REFERENCES brands (brand_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Product catalogue — every item available for sale';

-- =============================================================
-- INDEXES
--
-- Query patterns on this table:
--   1. Browse by category        → WHERE category_id = ?
--   2. Filter by brand           → WHERE brand_id = ?
--   3. Show only active products → WHERE status = 'active'
--   4. Homepage featured items   → WHERE is_featured = 1
--   5. Search by name            → WHERE name LIKE '%phone%'
--   6. URL routing               → WHERE slug = 'iphone-15-pro'
--   7. Exclude deleted products  → WHERE deleted_at IS NULL
--   8. Price range filter        → WHERE price BETWEEN ? AND ?
-- =============================================================

-- Browse products by category (very frequent)
CREATE INDEX idx_products_category_id
    ON products (category_id);

-- Filter products by brand
CREATE INDEX idx_products_brand_id
    ON products (brand_id);

-- Show only active, non-deleted products
-- Composite index covers both filters in one scan
CREATE INDEX idx_products_status_deleted
    ON products (status, deleted_at);

-- Homepage featured products query
CREATE INDEX idx_products_featured
    ON products (is_featured, status);

-- Price range filtering (shop by budget)
CREATE INDEX idx_products_price
    ON products (price);

-- URL slug lookup for product detail pages
CREATE INDEX idx_products_slug
    ON products (slug);

-- Full-text search on name and description
-- Allows: WHERE MATCH(name, short_desc) AGAINST ('wireless headphone')
CREATE FULLTEXT INDEX idx_products_fulltext
    ON products (name, short_desc);

-- =============================================================
-- VERIFICATION QUERY
-- =============================================================
DESCRIBE products;

-- =============================================================
-- SAMPLE DATA (mental model — actual data comes in seeds/)
--
-- product_id | category_id | brand_id | name           | sku        | price    | status
-- -----------+-------------+----------+----------------+------------+----------+--------
--          1 |           3 |        1 | iPhone 15 Pro  | APL-IP15P  | 134900.00| active
--          2 |           3 |        2 | Samsung S24    | SAM-S24    |  89999.00| active
--          3 |           5 |        1 | MacBook Air M3 | APL-MBA-M3 | 114900.00| active
--          4 |           8 |        3 | Nike Air Max   | NIK-AM-90  |   8995.00| active
--
-- Note:
--  - iPhone and MacBook share brand_id=1 (Apple) — one brand, many products
--  - category_id=3 is Smartphones, category_id=5 is Laptops
--  - All prices use DECIMAL — exact to the paisa/cent
-- =============================================================
