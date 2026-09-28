-- =============================================================
-- FILE: queries/inventory_report.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Inventory health — stock levels, slow movers
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

-- -------------------------------------------------------------
-- QUERY 1: Full inventory health dashboard
-- Shows all products with stock status and reorder alerts.
-- -------------------------------------------------------------
SELECT
    p.product_id,
    p.sku,
    p.name                                              AS product_name,
    b.name                                              AS brand,
    c.name                                              AS category,
    i.quantity_in_stock,
    i.quantity_reserved,
    fn_get_stock_level(p.product_id)                    AS available_to_sell,
    i.reorder_threshold,
    CASE
        WHEN i.quantity_in_stock = 0          THEN '🔴 OUT OF STOCK'
        WHEN i.quantity_in_stock <= i.reorder_threshold THEN '🟡 LOW STOCK'
        ELSE '🟢 HEALTHY'
    END                                                 AS stock_status,
    i.updated_at                                        AS last_stock_update
FROM inventory i
JOIN products p ON p.product_id = i.product_id AND p.deleted_at IS NULL
LEFT JOIN brands b ON b.brand_id = p.brand_id
JOIN categories c ON c.category_id = p.category_id
ORDER BY i.quantity_in_stock ASC;

-- -------------------------------------------------------------
-- QUERY 2: Slow-moving products
-- Products with high stock but few or no recent sales.
-- These may need promotions or clearance pricing.
-- -------------------------------------------------------------
SELECT
    p.product_id,
    p.name                                              AS product_name,
    p.price,
    i.quantity_in_stock,
    COALESCE(recent.units_sold_30d, 0)                  AS units_sold_last_30d,
    COALESCE(recent.units_sold_90d, 0)                  AS units_sold_last_90d,
    CASE
        WHEN COALESCE(recent.units_sold_30d, 0) = 0 THEN 'No recent sales'
        WHEN i.quantity_in_stock / NULLIF(recent.units_sold_30d, 0) > 6
            THEN 'Overstocked (6+ months supply)'
        ELSE 'Normal'
    END                                                 AS slow_move_flag
FROM products p
JOIN inventory i ON i.product_id = p.product_id
LEFT JOIN (
    SELECT
        oi.product_id,
        SUM(CASE WHEN o.created_at >= NOW() - INTERVAL 30 DAY
                 THEN oi.quantity ELSE 0 END)           AS units_sold_30d,
        SUM(CASE WHEN o.created_at >= NOW() - INTERVAL 90 DAY
                 THEN oi.quantity ELSE 0 END)           AS units_sold_90d
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.status NOT IN ('cancelled', 'refunded')
    GROUP BY oi.product_id
) recent ON recent.product_id = p.product_id
WHERE p.status = 'active'
  AND p.deleted_at IS NULL
  AND i.quantity_in_stock > 0
ORDER BY units_sold_last_30d ASC, i.quantity_in_stock DESC;

-- -------------------------------------------------------------
-- QUERY 3: Stock turnover rate
-- How quickly is each product selling relative to stock?
-- High turnover = popular / fast-moving product.
-- -------------------------------------------------------------
SELECT
    p.name                                              AS product_name,
    b.name                                              AS brand,
    i.quantity_in_stock                                 AS current_stock,
    COALESCE(total_sales.total_sold, 0)                 AS total_units_sold,
    COALESCE(total_sales.total_revenue, 0)              AS total_revenue,
    CASE
        WHEN i.quantity_in_stock = 0 THEN NULL
        ELSE ROUND(COALESCE(total_sales.total_sold, 0) / i.quantity_in_stock, 2)
    END                                                 AS turnover_ratio
FROM products p
JOIN inventory i ON i.product_id = p.product_id
LEFT JOIN brands b ON b.brand_id = p.brand_id
LEFT JOIN (
    SELECT
        oi.product_id,
        SUM(oi.quantity)            AS total_sold,
        SUM(oi.total_price)         AS total_revenue
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.status NOT IN ('cancelled', 'refunded')
    GROUP BY oi.product_id
) total_sales ON total_sales.product_id = p.product_id
WHERE p.status = 'active' AND p.deleted_at IS NULL
ORDER BY turnover_ratio DESC NULLS LAST;
