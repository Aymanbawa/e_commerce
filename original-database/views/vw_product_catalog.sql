-- =============================================================
-- FILE: views/vw_product_catalog.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: View combining product, brand, category, stock
--              The main view used by the storefront
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP VIEW IF EXISTS vw_product_catalog;

-- =============================================================
-- VIEW: vw_product_catalog
--
-- WHY THIS VIEW EXISTS:
--   Every product listing page needs: product info + brand name
--   + category name + stock availability + average rating.
--   Writing this JOIN every time is repetitive and error-prone.
--   This view packages it as a single clean query.
--
-- HOW TO USE:
--   SELECT * FROM vw_product_catalog WHERE status = 'active';
--   SELECT * FROM vw_product_catalog WHERE category_name = 'Smartphones';
--   SELECT * FROM vw_product_catalog WHERE available_stock > 0;
-- =============================================================
CREATE VIEW vw_product_catalog AS
SELECT
    -- Product core fields
    p.product_id,
    p.name                                      AS product_name,
    p.slug,
    p.sku,
    p.short_desc,
    p.price,
    p.compare_price,
    p.status,
    p.is_featured,
    p.weight_grams,
    p.created_at,

    -- Savings amount (shown as "You save ₹X")
    CASE
        WHEN p.compare_price IS NOT NULL
        THEN ROUND(p.compare_price - p.price, 2)
        ELSE NULL
    END                                         AS savings_amount,

    -- Discount percentage (shown as "20% off")
    CASE
        WHEN p.compare_price IS NOT NULL AND p.compare_price > 0
        THEN ROUND(((p.compare_price - p.price) / p.compare_price) * 100, 0)
        ELSE NULL
    END                                         AS discount_percent,

    -- Brand info
    b.brand_id,
    b.name                                      AS brand_name,
    b.slug                                      AS brand_slug,
    b.logo_url                                  AS brand_logo,

    -- Category info
    c.category_id,
    c.name                                      AS category_name,
    c.slug                                      AS category_slug,

    -- Primary image (thumbnail)
    pi.image_url                                AS primary_image_url,
    pi.alt_text                                 AS primary_image_alt,

    -- Inventory / stock
    COALESCE(i.quantity_in_stock, 0)            AS quantity_in_stock,
    COALESCE(i.quantity_reserved, 0)            AS quantity_reserved,
    GREATEST(0, COALESCE(i.quantity_in_stock, 0) - COALESCE(i.quantity_reserved, 0))
                                                AS available_stock,

    -- Stock status label
    CASE
        WHEN GREATEST(0, COALESCE(i.quantity_in_stock, 0) - COALESCE(i.quantity_reserved, 0)) = 0
            THEN 'Out of Stock'
        WHEN GREATEST(0, COALESCE(i.quantity_in_stock, 0) - COALESCE(i.quantity_reserved, 0)) <= 5
            THEN 'Low Stock'
        ELSE 'In Stock'
    END                                         AS stock_status,

    -- Review summary (calculated from reviews table)
    COALESCE(r.avg_rating, 0)                   AS avg_rating,
    COALESCE(r.review_count, 0)                 AS review_count

FROM products p

-- Brand — LEFT JOIN because brand_id is optional
LEFT JOIN brands b
    ON b.brand_id = p.brand_id

-- Category — always present (NOT NULL FK)
JOIN categories c
    ON c.category_id = p.category_id

-- Primary image — LEFT JOIN, product may have no image yet
LEFT JOIN product_images pi
    ON  pi.product_id = p.product_id
    AND pi.is_primary = 1

-- Inventory — LEFT JOIN, may not have row yet
LEFT JOIN inventory i
    ON i.product_id = p.product_id

-- Pre-aggregated review stats — subquery avoids GROUP BY on whole view
LEFT JOIN (
    SELECT
        product_id,
        ROUND(AVG(rating), 1)   AS avg_rating,
        COUNT(*)                AS review_count
    FROM reviews
    WHERE is_approved = 1
    GROUP BY product_id
) r ON r.product_id = p.product_id

-- Exclude soft-deleted products
WHERE p.deleted_at IS NULL;
