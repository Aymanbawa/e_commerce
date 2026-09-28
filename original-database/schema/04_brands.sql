-- =============================================================
-- FILE: schema/04_brands.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Creates the brands table
--              Stores brand master data for all products
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP TABLE IF EXISTS brands;

-- =============================================================
-- TABLE: brands
--
-- WHY THIS TABLE EXISTS:
--   Many products share the same brand (Samsung, Apple, Nike).
--   Instead of typing "Samsung" into every product row, we store
--   the brand once here and reference it by brand_id.
--
--   Benefits:
--   1. If "Samsung" is misspelled, fix it in ONE place — not
--      across thousands of product rows.
--   2. You can attach extra info to a brand (logo, website)
--      without touching the products table at all.
--   3. Customers can filter products by brand easily.
--   4. This is 3NF — brand data depends only on brand_id,
--      not on any product-specific data.
--
-- RELATIONSHIPS:
--   products → brands  (many products belong to one brand)
-- =============================================================
CREATE TABLE brands (

    -- ---------------------------------------------------------
    -- PRIMARY KEY
    -- ---------------------------------------------------------
    brand_id        BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,

    -- ---------------------------------------------------------
    -- BRAND NAME
    -- Must be unique — you cannot have two "Samsung" brands.
    -- ---------------------------------------------------------
    name            VARCHAR(100)        NOT NULL,

    -- ---------------------------------------------------------
    -- SLUG
    -- URL-friendly brand name for filtering pages.
    -- Example: example.com/brand/apple
    -- ---------------------------------------------------------
    slug            VARCHAR(120)        NOT NULL,

    -- ---------------------------------------------------------
    -- LOGO URL
    -- Link to the brand's logo image stored in cloud storage
    -- (e.g. AWS S3, Cloudinary).
    -- NULL = brand has no logo uploaded yet.
    -- VARCHAR(500) handles long cloud storage URLs.
    -- ---------------------------------------------------------
    logo_url        VARCHAR(500)        NULL DEFAULT NULL,

    -- ---------------------------------------------------------
    -- WEBSITE URL
    -- Optional link to the brand's official website.
    -- Shown on the brand page for reference.
    -- ---------------------------------------------------------
    website_url     VARCHAR(500)        NULL DEFAULT NULL,

    -- ---------------------------------------------------------
    -- DESCRIPTION
    -- Short paragraph about the brand shown on its page.
    -- Also helps with SEO.
    -- ---------------------------------------------------------
    description     TEXT                NULL DEFAULT NULL,

    -- ---------------------------------------------------------
    -- ACTIVE FLAG
    -- is_active = 0 hides the brand from the storefront.
    -- Products linked to an inactive brand still exist but
    -- the brand filter won't show this brand to customers.
    -- ---------------------------------------------------------
    is_active       TINYINT(1)          NOT NULL DEFAULT 1,

    -- ---------------------------------------------------------
    -- TIMESTAMPS
    -- ---------------------------------------------------------
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP
                                        ON UPDATE CURRENT_TIMESTAMP,

    -- ---------------------------------------------------------
    -- CONSTRAINTS
    -- ---------------------------------------------------------
    CONSTRAINT pk_brands PRIMARY KEY (brand_id),

    CONSTRAINT uq_brands_name UNIQUE (name),

    CONSTRAINT uq_brands_slug UNIQUE (slug)

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Brand master data — one row per brand (Apple, Samsung, Nike etc.)';

-- =============================================================
-- INDEXES
--
-- Query patterns:
--   1. "Find brand by slug for URL routing"  → WHERE slug = 'apple'
--   2. "Show all active brands in filter"    → WHERE is_active = 1
--   3. "Admin: search brand by name"         → WHERE name LIKE 'Sam%'
-- =============================================================

-- URL routing and brand page lookup
CREATE INDEX idx_brands_slug
    ON brands (slug);

-- Storefront brand filter — only active brands shown
CREATE INDEX idx_brands_is_active
    ON brands (is_active);

-- =============================================================
-- VERIFICATION QUERY
-- =============================================================
DESCRIBE brands;

-- =============================================================
-- SAMPLE DATA (mental model — actual data comes in seeds/)
--
-- brand_id | name    | slug    | is_active
-- ---------+---------+---------+-----------
--        1 | Apple   | apple   |         1
--        2 | Samsung | samsung |         1
--        3 | Nike    | nike    |         1
--        4 | Adidas  | adidas  |         1
--        5 | Sony    | sony    |         1
--
-- Products table will reference these via brand_id.
-- Example: iPhone 15 → brand_id = 1 (Apple)
-- =============================================================
