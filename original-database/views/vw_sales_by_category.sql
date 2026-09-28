-- =============================================================
-- FILE: views/vw_sales_by_category.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Revenue and sales volume broken down by category
--              Used for business analytics and reporting
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP VIEW IF EXISTS vw_sales_by_category;

CREATE VIEW vw_sales_by_category AS
SELECT
    -- Category info
    c.category_id,
    c.name                                      AS category_name,
    c.slug                                      AS category_slug,

    -- Parent category name (for drill-down reports)
    parent_c.name                               AS parent_category_name,

    -- Sales metrics — only count delivered orders
    COUNT(DISTINCT o.order_id)                  AS total_orders,
    SUM(oi.quantity)                            AS total_units_sold,
    SUM(oi.total_price)                         AS gross_revenue,

    -- Average order value for this category
    ROUND(SUM(oi.total_price) / COUNT(DISTINCT o.order_id), 2)
                                                AS avg_order_value,

    -- Average unit price (useful for pricing strategy)
    ROUND(AVG(oi.unit_price), 2)                AS avg_unit_price,

    -- Number of distinct products sold in this category
    COUNT(DISTINCT oi.product_id)               AS products_sold,

    -- Date range of data
    MIN(o.created_at)                           AS first_sale_date,
    MAX(o.created_at)                           AS last_sale_date

FROM categories c

-- Parent category for hierarchy
LEFT JOIN categories parent_c
    ON parent_c.category_id = c.parent_id

-- Products in this category
JOIN products p
    ON  p.category_id = c.category_id
    AND p.deleted_at IS NULL

-- Order line items for this product
JOIN order_items oi
    ON oi.product_id = p.product_id

-- Only count delivered orders (confirmed revenue)
JOIN orders o
    ON  o.order_id = oi.order_id
    AND o.status = 'delivered'

GROUP BY
    c.category_id,
    c.name,
    c.slug,
    parent_c.name

ORDER BY gross_revenue DESC;
