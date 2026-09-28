-- =============================================================
-- FILE: schema/03_categories.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Creates the categories table
--              Self-referencing table for nested category tree
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP TABLE IF EXISTS categories;

-- =============================================================
-- TABLE: categories
--
-- WHY THIS TABLE EXISTS:
--   Products need to be organised so customers can browse.
--   Example tree:
--
--   Electronics                 ← top-level (parent_id = NULL)
--   ├── Mobile Phones           ← child of Electronics
--   │   ├── Smartphones         ← child of Mobile Phones
--   │   └── Feature Phones      ← child of Mobile Phones
--   └── Laptops                 ← child of Electronics
--   Clothing                    ← top-level (parent_id = NULL)
--   └── Men's Clothing          ← child of Clothing
--       └── T-Shirts            ← child of Men's Clothing
--
-- HOW THE SELF-REFERENCE WORKS:
--   parent_id points to another row in the SAME table.
--   Top-level categories have parent_id = NULL (no parent).
--   Child categories have parent_id = the category above them.
--
-- This lets you create infinite depth without ever changing
-- the table structure. Add 10 more levels? No schema change.
--
-- RELATIONSHIPS:
--   categories → categories  (self-reference: parent/child)
--   products   → categories  (many products per category)
-- =============================================================
CREATE TABLE categories (

    -- ---------------------------------------------------------
    -- PRIMARY KEY
    -- ---------------------------------------------------------
    category_id     BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,

    -- ---------------------------------------------------------
    -- SELF-REFERENCING FOREIGN KEY
    -- parent_id points to another category in this same table.
    -- NULL = this is a top-level category (no parent above it)
    -- 
    -- Example:
    --   category_id=1, name='Electronics',  parent_id=NULL
    --   category_id=2, name='Mobile Phones', parent_id=1
    --   category_id=3, name='Smartphones',   parent_id=2
    --
    -- ON DELETE SET NULL:
    --   If a parent category is deleted, child categories don't
    --   get deleted. Instead their parent_id becomes NULL and
    --   they become top-level categories.
    --   This is safer than CASCADE here — you don't want to
    --   accidentally delete hundreds of child categories by
    --   deleting one parent.
    -- ---------------------------------------------------------
    parent_id       BIGINT UNSIGNED     NULL DEFAULT NULL,

    -- ---------------------------------------------------------
    -- CATEGORY NAME
    -- The display name shown to customers on the storefront.
    -- ---------------------------------------------------------
    name            VARCHAR(100)        NOT NULL,

    -- ---------------------------------------------------------
    -- SLUG
    -- A URL-friendly version of the name.
    -- Used in web URLs: example.com/category/mobile-phones
    -- Rules: lowercase, hyphens instead of spaces, no special chars
    -- Must be unique — two categories cannot share a URL.
    --
    -- Example:
    --   name = "Mobile Phones"  →  slug = "mobile-phones"
    --   name = "Men's Clothing" →  slug = "mens-clothing"
    -- ---------------------------------------------------------
    slug            VARCHAR(120)        NOT NULL,

    -- ---------------------------------------------------------
    -- DESCRIPTION
    -- Optional longer text describing the category.
    -- Shown on the category browse page and used for SEO.
    -- ---------------------------------------------------------
    description     TEXT                NULL DEFAULT NULL,

    -- ---------------------------------------------------------
    -- DISPLAY ORDER
    -- Controls the order categories appear in menus.
    -- Lower number = shown first.
    -- Example: Electronics=1, Clothing=2, Books=3
    -- ---------------------------------------------------------
    sort_order      SMALLINT UNSIGNED   NOT NULL DEFAULT 0,

    -- ---------------------------------------------------------
    -- ACTIVE FLAG
    -- is_active = 0 hides the category from the storefront.
    -- Products in a hidden category also become unbrowsable.
    -- Used when a category is being prepared or retired.
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
    CONSTRAINT pk_categories PRIMARY KEY (category_id),

    -- slug must be unique — no two categories share a URL path
    CONSTRAINT uq_categories_slug UNIQUE (slug),

    -- Self-referencing foreign key
    -- parent_id references category_id in the SAME table
    CONSTRAINT fk_categories_parent
        FOREIGN KEY (parent_id)
        REFERENCES categories (category_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Product category tree — supports unlimited nesting via self-reference';

-- =============================================================
-- INDEXES
--
-- Query patterns:
--   1. "Show all top-level categories"     → WHERE parent_id IS NULL
--   2. "Show children of Electronics"      → WHERE parent_id = 1
--   3. "Find category by slug in URL"      → WHERE slug = 'electronics'
--   4. "Show all active categories"        → WHERE is_active = 1
-- =============================================================

-- Find all children of a given parent (tree traversal)
CREATE INDEX idx_categories_parent_id
    ON categories (parent_id);

-- URL routing — look up category by its slug
CREATE INDEX idx_categories_slug
    ON categories (slug);

-- Admin filtering — show only active categories
CREATE INDEX idx_categories_active
    ON categories (is_active);

-- Sort categories by display order in menus
CREATE INDEX idx_categories_sort_order
    ON categories (sort_order);

-- =============================================================
-- VERIFICATION QUERY
-- =============================================================
DESCRIBE categories;

-- =============================================================
-- VISUAL EXAMPLE — how the data looks in the table:
--
-- category_id | parent_id | name            | slug
-- ------------+-----------+-----------------+------------------
--           1 |      NULL | Electronics     | electronics
--           2 |         1 | Mobile Phones   | mobile-phones
--           3 |         2 | Smartphones     | smartphones
--           4 |         2 | Feature Phones  | feature-phones
--           5 |         1 | Laptops         | laptops
--           6 |      NULL | Clothing        | clothing
--           7 |         6 | Men's Clothing  | mens-clothing
--           8 |         7 | T-Shirts        | t-shirts
--
-- To get the full path "Electronics > Mobile Phones > Smartphones":
--   Start at category_id=3, follow parent_id up the chain.
--   This is done with a recursive CTE query (shown in queries/).
-- =============================================================
