-- =============================================================
-- FILE: queries/coupon_performance.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Coupon analytics — usage rates, revenue impact
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

-- -------------------------------------------------------------
-- QUERY 1: Complete coupon performance overview
-- -------------------------------------------------------------
SELECT
    c.code,
    c.discount_type,
    c.discount_value,
    c.min_order_amount,
    c.max_discount_amount,
    c.usage_limit,
    c.usage_count                               AS actual_usage,
    CASE
        WHEN c.usage_limit IS NULL THEN NULL
        ELSE ROUND(c.usage_count * 100.0 / c.usage_limit, 1)
    END                                         AS usage_rate_percent,
    CASE
        WHEN c.expires_at IS NULL THEN 'Never expires'
        WHEN c.expires_at < NOW() THEN '🔴 Expired'
        ELSE CONCAT('Expires: ', DATE(c.expires_at))
    END                                         AS expiry_status,
    c.is_active,
    COALESCE(usage_stats.orders_with_coupon, 0) AS orders_used_in,
    COALESCE(usage_stats.total_discount_given, 0) AS total_discount_given,
    COALESCE(usage_stats.total_revenue, 0)      AS revenue_from_coupon_orders
FROM coupons c
LEFT JOIN (
    SELECT
        coupon_id,
        COUNT(order_id)             AS orders_with_coupon,
        SUM(discount_amount)        AS total_discount_given,
        SUM(total_amount)           AS total_revenue
    FROM orders
    WHERE status != 'cancelled'
    GROUP BY coupon_id
) usage_stats ON usage_stats.coupon_id = c.coupon_id
ORDER BY COALESCE(usage_stats.total_revenue, 0) DESC;

-- -------------------------------------------------------------
-- QUERY 2: Do coupon users spend more?
-- Compare average order value: with vs without coupon.
-- -------------------------------------------------------------
SELECT
    CASE
        WHEN coupon_id IS NOT NULL THEN 'With Coupon'
        ELSE 'Without Coupon'
    END                                         AS order_type,
    COUNT(order_id)                             AS order_count,
    ROUND(AVG(total_amount), 2)                 AS avg_order_value,
    ROUND(AVG(subtotal), 2)                     AS avg_subtotal,
    ROUND(AVG(discount_amount), 2)              AS avg_discount,
    SUM(total_amount)                           AS total_revenue
FROM orders
WHERE status != 'cancelled'
GROUP BY CASE WHEN coupon_id IS NOT NULL THEN 'With Coupon' ELSE 'Without Coupon' END;
