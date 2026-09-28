-- =============================================================
-- FILE: queries/customer_insights.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Customer analytics — LTV, repeat buyers, segments
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

-- -------------------------------------------------------------
-- QUERY 1: Customer Lifetime Value (LTV)
-- How much has each customer spent in total?
-- Key metric for every e-commerce business.
-- -------------------------------------------------------------
SELECT
    u.user_id,
    CONCAT(u.first_name, ' ', u.last_name)      AS customer_name,
    u.email,
    u.created_at                                AS member_since,
    COUNT(DISTINCT o.order_id)                  AS total_orders,
    SUM(o.total_amount)                         AS lifetime_value,
    ROUND(AVG(o.total_amount), 2)               AS avg_order_value,
    MIN(o.created_at)                           AS first_order_date,
    MAX(o.created_at)                           AS last_order_date,
    DATEDIFF(MAX(o.created_at), MIN(o.created_at))
                                                AS days_as_buyer
FROM users u
LEFT JOIN orders o
    ON  o.user_id = u.user_id
    AND o.status != 'cancelled'
WHERE u.role = 'customer'
  AND u.deleted_at IS NULL
GROUP BY u.user_id, u.first_name, u.last_name, u.email, u.created_at
ORDER BY lifetime_value DESC NULLS LAST;

-- -------------------------------------------------------------
-- QUERY 2: Customer segmentation using RFM
-- RFM = Recency, Frequency, Monetary
-- Standard marketing framework to classify customers.
-- -------------------------------------------------------------
WITH rfm_base AS (
    SELECT
        u.user_id,
        CONCAT(u.first_name, ' ', u.last_name)  AS customer_name,
        DATEDIFF(NOW(), MAX(o.created_at))       AS recency_days,
        COUNT(DISTINCT o.order_id)               AS frequency,
        SUM(o.total_amount)                      AS monetary
    FROM users u
    JOIN orders o ON o.user_id = u.user_id
    WHERE o.status NOT IN ('cancelled', 'refunded')
    GROUP BY u.user_id, u.first_name, u.last_name
)
SELECT
    user_id,
    customer_name,
    recency_days,
    frequency,
    monetary,
    CASE
        WHEN recency_days <= 30  AND frequency >= 3 AND monetary >= 10000
            THEN 'Champions'
        WHEN recency_days <= 60  AND frequency >= 2
            THEN 'Loyal Customers'
        WHEN recency_days <= 30  AND frequency = 1
            THEN 'New Customers'
        WHEN recency_days BETWEEN 61 AND 120
            THEN 'At Risk'
        WHEN recency_days > 120
            THEN 'Lost Customers'
        ELSE 'Potential Loyalists'
    END                                         AS customer_segment
FROM rfm_base
ORDER BY monetary DESC;

-- -------------------------------------------------------------
-- QUERY 3: Repeat vs one-time buyers
-- What percentage of customers ordered more than once?
-- -------------------------------------------------------------
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-Time Buyer'
        WHEN order_count BETWEEN 2 AND 3 THEN 'Repeat Buyer (2-3 orders)'
        WHEN order_count >= 4 THEN 'Loyal Buyer (4+ orders)'
    END                                         AS buyer_type,
    COUNT(*)                                    AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1)
                                                AS percentage
FROM (
    SELECT
        user_id,
        COUNT(order_id) AS order_count
    FROM orders
    WHERE status != 'cancelled'
    GROUP BY user_id
) order_counts
GROUP BY buyer_type
ORDER BY customer_count DESC;

-- -------------------------------------------------------------
-- QUERY 4: Most wished-for products (demand signal)
-- Products saved to wishlists but never purchased.
-- Great signal for inventory and pricing decisions.
-- -------------------------------------------------------------
SELECT
    p.product_id,
    p.name                                      AS product_name,
    b.name                                      AS brand,
    p.price,
    COUNT(w.wishlist_id)                        AS wishlist_count,
    fn_get_stock_level(p.product_id)            AS available_stock,
    COALESCE(purchased.times_purchased, 0)      AS times_purchased,
    ROUND(
        COUNT(w.wishlist_id) * 100.0 /
        NULLIF(COALESCE(purchased.times_purchased, 0) + COUNT(w.wishlist_id), 0),
    1)                                          AS wishlist_to_purchase_ratio
FROM products p
JOIN wishlist w ON w.product_id = p.product_id
LEFT JOIN brands b ON b.brand_id = p.brand_id
LEFT JOIN (
    SELECT product_id, SUM(quantity) AS times_purchased
    FROM order_items
    GROUP BY product_id
) purchased ON purchased.product_id = p.product_id
WHERE p.status = 'active'
GROUP BY p.product_id, p.name, b.name, p.price, purchased.times_purchased
ORDER BY wishlist_count DESC;
