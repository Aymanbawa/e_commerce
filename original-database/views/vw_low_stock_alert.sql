-- =============================================================
-- FILE: views/vw_low_stock_alert.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Products at or below their reorder threshold
--              Used by operations team for restocking decisions
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP VIEW IF EXISTS vw_low_stock_alert;

CREATE VIEW vw_low_stock_alert AS
SELECT
    -- Product info
    p.product_id,
    p.name                                                          AS product_name,
    p.sku,
    p.status                                                        AS product_status,

    -- Brand and category for context
    b.name                                                          AS brand_name,
    c.name                                                          AS category_name,

    -- Stock numbers
    i.quantity_in_stock,
    i.quantity_reserved,
    GREATEST(0, i.quantity_in_stock - i.quantity_reserved)          AS available_stock,
    i.reorder_threshold,

    -- How many units below threshold are we?
    -- Positive number = how short we are
    GREATEST(0, i.reorder_threshold - i.quantity_in_stock)          AS units_below_threshold,

    -- Alert severity
    CASE
        WHEN i.quantity_in_stock = 0
            THEN 'CRITICAL — Out of Stock'
        WHEN i.quantity_in_stock <= ROUND(i.reorder_threshold * 0.5, 0)
            THEN 'HIGH — Very Low Stock'
        ELSE
            'MEDIUM — Below Reorder Point'
    END                                                             AS alert_level,

    -- Last time stock was updated
    i.updated_at                                                    AS stock_last_updated

FROM inventory i

JOIN products p
    ON  p.product_id = i.product_id
    AND p.status = 'active'
    AND p.deleted_at IS NULL

LEFT JOIN brands b
    ON b.brand_id = p.brand_id

JOIN categories c
    ON c.category_id = p.category_id

-- Only show products AT or BELOW their reorder threshold
WHERE i.quantity_in_stock <= i.reorder_threshold

ORDER BY
    i.quantity_in_stock ASC,    -- most critical (zero stock) first
    i.reorder_threshold DESC;
