-- =============================================================
-- FILE: schema/06_product_images.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Creates the product_images table
--              Stores multiple images per product
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP TABLE IF EXISTS product_images;

-- =============================================================
-- TABLE: product_images
--
-- WHY THIS TABLE EXISTS:
--   Every product needs photos. Most products have MULTIPLE
--   photos — front view, back view, side view, lifestyle shot.
--
--   Bad approach — columns on products table:
--     products.image1, products.image2, products.image3
--     Problem: what if you need 10 images? Add 10 columns?
--     What if most products only have 2? 8 columns wasted.
--     This breaks 1NF (repeating groups).
--
--   Good approach — separate table (what we do here):
--     One row per image. Add unlimited images without any
--     schema change. Zero wasted space.
--
-- RELATIONSHIPS:
--   product_images → products  (many images belong to one product)
-- =============================================================
CREATE TABLE product_images (

    -- ---------------------------------------------------------
    -- PRIMARY KEY
    -- ---------------------------------------------------------
    image_id        BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,

    -- ---------------------------------------------------------
    -- FOREIGN KEY TO PRODUCTS
    -- Every image must belong to a real product.
    -- ON DELETE CASCADE: if product is deleted, delete its images.
    -- Images without a product are worthless orphan files.
    -- ---------------------------------------------------------
    product_id      BIGINT UNSIGNED     NOT NULL,

    -- ---------------------------------------------------------
    -- IMAGE URL
    -- Full URL to the image hosted on cloud storage.
    -- Examples:
    --   https://cdn.mystore.com/products/iphone15-front.jpg
    --   https://s3.amazonaws.com/mystore/iphone15-back.webp
    -- VARCHAR(500) handles long CDN URLs comfortably.
    -- ---------------------------------------------------------
    image_url       VARCHAR(500)        NOT NULL,

    -- ---------------------------------------------------------
    -- ALT TEXT
    -- Describes the image in words.
    -- Used by:
    --   - Screen readers (accessibility)
    --   - Search engines (SEO)
    -- Example: "iPhone 15 Pro in Natural Titanium, front view"
    -- NULL = no alt text provided yet
    -- ---------------------------------------------------------
    alt_text        VARCHAR(255)        NULL DEFAULT NULL,

    -- ---------------------------------------------------------
    -- SORT ORDER
    -- Controls which image appears first in the gallery.
    -- Lower number = shown earlier.
    -- sort_order=0 is typically the main gallery image.
    --
    -- Example for a product with 4 images:
    --   sort_order=0 → front view    (shown first)
    --   sort_order=1 → back view
    --   sort_order=2 → side view
    --   sort_order=3 → lifestyle photo (shown last)
    --
    -- TINYINT UNSIGNED: values 0–255, more than enough for
    -- image ordering. No product needs 255+ images.
    -- ---------------------------------------------------------
    sort_order      TINYINT UNSIGNED    NOT NULL DEFAULT 0,

    -- ---------------------------------------------------------
    -- PRIMARY IMAGE FLAG
    -- is_primary = 1: this image is the product thumbnail
    --   shown in search results, category pages, and cart.
    -- is_primary = 0: gallery image only (default)
    --
    -- Only ONE image per product should have is_primary = 1.
    -- Business rule BR-P7 — enforced at application layer.
    -- ---------------------------------------------------------
    is_primary      TINYINT(1)          NOT NULL DEFAULT 0,

    -- ---------------------------------------------------------
    -- TIMESTAMP
    -- When this image was uploaded / linked to the product.
    -- ---------------------------------------------------------
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- ---------------------------------------------------------
    -- CONSTRAINTS
    -- ---------------------------------------------------------
    CONSTRAINT pk_product_images PRIMARY KEY (image_id),

    -- Every image must belong to a real product
    -- Cascade delete: remove images when product is removed
    CONSTRAINT fk_product_images_product
        FOREIGN KEY (product_id)
        REFERENCES products (product_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Multiple images per product — ordered by sort_order';

-- =============================================================
-- INDEXES
--
-- Query patterns:
--   1. "Get all images for product X"         → WHERE product_id = ?
--   2. "Get images in display order"          → ORDER BY sort_order
--   3. "Get the thumbnail for product X"      → WHERE product_id = ? AND is_primary = 1
-- =============================================================

-- Fetch all images for a product (most common query)
CREATE INDEX idx_product_images_product_id
    ON product_images (product_id);

-- Get primary thumbnail quickly
-- Composite: filters by product AND primary flag together
CREATE INDEX idx_product_images_primary
    ON product_images (product_id, is_primary);

-- Get images in display order for the gallery
CREATE INDEX idx_product_images_sort
    ON product_images (product_id, sort_order);

-- =============================================================
-- VERIFICATION QUERY
-- =============================================================
DESCRIBE product_images;

-- =============================================================
-- SAMPLE DATA (mental model — actual data comes in seeds/)
--
-- image_id | product_id | sort_order | is_primary | image_url
-- ---------+------------+------------+------------+---------------------------
--        1 |          1 |          0 |          1 | .../iphone15-front.jpg
--        2 |          1 |          1 |          0 | .../iphone15-back.jpg
--        3 |          1 |          2 |          0 | .../iphone15-side.jpg
--        4 |          2 |          0 |          1 | .../samsung-s24-front.jpg
--        5 |          2 |          1 |          0 | .../samsung-s24-back.jpg
--
-- product_id=1 (iPhone 15 Pro) has 3 images → image_id 1,2,3
-- product_id=2 (Samsung S24)   has 2 images → image_id 4,5
-- Each product has exactly one is_primary=1 image (the thumbnail)
-- Images display in sort_order sequence: 0, 1, 2...
-- =============================================================
