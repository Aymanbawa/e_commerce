-- =============================================================
-- FILE: queries/sales_report.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Sales analytics — revenue, top products, trends
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

-- -------------------------------------------------------------
-- QUERY 1: Monthly revenue summary
-- Shows total revenue, order count, and average order value
-- by month. Uses only delivered orders (confirmed revenue).
-- -------------------------------------------------------------
SELECT
    DATE_FORMAT(o.created_at, '%Y-%m')          AS month,
    COUNT(DISTINCT o.order_id)                  AS total_orders,
    SUM(o.total_amount)                         AS gross_revenue,
    SUM(o.discount_amount)                      AS total_discounts_given,
    SUM(o.tax_amount)                           AS total_tax_collected,
    SUM(o.total_amount - o.tax_amount)          AS net_revenue,
    ROUND(AVG(o.total_amount), 2)               AS avg_order_value,
    COUNT(DISTINCT o.user_id)                   AS unique_customers
FROM orders o
WHERE o.status = 'delivered'
GROUP BY DATE_FORMAT(o.created_at, '%Y-%m')
ORDER BY month DESC;

-- -------------------------------------------------------------
-- QUERY 2: Top 10 best-selling products by revenue
-- Uses a CTE (Common Table Expression) for readability.
-- -------------------------------------------------------------
WITH product_sales AS (
    SELECT
        oi.product_id,
        oi.product_name,
        oi.product_sku,
        SUM(oi.quantity)                        AS units_sold,
        SUM(oi.total_price)                     AS total_revenue,
        COUNT(DISTINCT oi.order_id)             AS order_count,
        ROUND(AVG(oi.unit_price), 2)            AS avg_selling_price
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.status IN ('delivered', 'shipped', 'confirmed')
    GROUP BY oi.product_id, oi.product_name, oi.product_sku
)
SELECT
    RANK() OVER (ORDER BY total_revenue DESC)   AS `rank`,
    product_name,
    product_sku,
    units_sold,
    total_revenue,
    order_count,
    avg_selling_price
FROM product_sales
ORDER BY total_revenue DESC
LIMIT 10;

-- -------------------------------------------------------------
-- QUERY 3: Revenue by day of week (which day sells most?)
-- Useful for planning promotions and marketing campaigns.
-- -------------------------------------------------------------
SELECT
    DAYNAME(o.created_at)                       AS day_of_week,
    DAYOFWEEK(o.created_at)                     AS day_number,
    COUNT(o.order_id)                           AS orders_placed,
    SUM(o.total_amount)                         AS revenue
FROM orders o
WHERE o.status != 'cancelled'
GROUP BY DAYNAME(o.created_at), DAYOFWEEK(o.created_at)
ORDER BY day_number;

-- -------------------------------------------------------------
-- QUERY 4: Coupon effectiveness report
-- Shows how much revenue each coupon generated vs discount given.
-- -------------------------------------------------------------
SELECT
    c.code                                      AS coupon_code,
    c.discount_type,
    c.discount_value,
    COUNT(o.order_id)                           AS times_used,
    SUM(o.discount_amount)                      AS total_discount_given,
    SUM(o.total_amount)                         AS total_revenue_generated,
    ROUND(SUM(o.total_amount) / COUNT(o.order_id), 2)
                                                AS avg_order_value_with_coupon,
    ROUND(
        (SUM(o.discount_amount) / SUM(o.subtotal)) * 100, 2
    )                                           AS avg_discount_percent
FROM coupons c
JOIN orders o ON o.coupon_id = c.coupon_id
WHERE o.status != 'cancelled'
GROUP BY c.coupon_id, c.code, c.discount_type, c.discount_value
ORDER BY total_revenue_generated DESC;

-- -------------------------------------------------------------
-- QUERY 5: Running total revenue (cumulative sum)
-- Demonstrates window functions — great for portfolio.
-- -------------------------------------------------------------
SELECT
    DATE_FORMAT(o.created_at, '%Y-%m-%d')       AS order_date,
    COUNT(o.order_id)                           AS daily_orders,
    SUM(o.total_amount)                         AS daily_revenue,
    SUM(SUM(o.total_amount))
        OVER (ORDER BY DATE(o.created_at))      AS cumulative_revenue
FROM orders o
WHERE o.status = 'delivered'
GROUP BY DATE(o.created_at)
ORDER BY order_date;
