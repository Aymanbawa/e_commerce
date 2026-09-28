-- =============================================================
-- FILE: views/vw_order_summary.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: View combining orders, customer, payment, shipment
--              Used by admin dashboard and customer order history
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP VIEW IF EXISTS vw_order_summary;

CREATE VIEW vw_order_summary AS
SELECT
    -- Order details
    o.order_id,
    o.order_number,
    o.status                                    AS order_status,
    o.subtotal,
    o.discount_amount,
    o.tax_amount,
    o.shipping_amount,
    o.total_amount,
    o.notes,
    o.created_at                                AS order_date,

    -- Customer details
    u.user_id,
    u.email                                     AS customer_email,
    CONCAT(u.first_name, ' ', u.last_name)      AS customer_name,
    u.phone                                     AS customer_phone,

    -- Shipping address
    a.full_name                                 AS ship_to_name,
    a.address_line1,
    a.address_line2,
    a.city,
    a.state,
    a.postal_code,
    a.country,

    -- Coupon used (if any)
    c.code                                      AS coupon_code,

    -- Payment info (most recent successful payment)
    pay.payment_method,
    pay.payment_status,
    pay.transaction_id,
    pay.paid_at,

    -- Shipment info
    sh.shipment_id,
    sh.tracking_number,
    sh.courier_name,
    sh.status                                   AS shipment_status,
    sh.estimated_delivery,
    sh.delivered_at,

    -- Item count for this order
    oi_summary.item_count,
    oi_summary.total_quantity

FROM orders o

-- Customer
JOIN users u
    ON u.user_id = o.user_id

-- Shipping address
JOIN addresses a
    ON a.address_id = o.address_id

-- Coupon (optional)
LEFT JOIN coupons c
    ON c.coupon_id = o.coupon_id

-- Latest completed payment (or any payment if none completed)
LEFT JOIN payments pay
    ON pay.payment_id = (
        SELECT payment_id FROM payments
        WHERE order_id = o.order_id
        ORDER BY
            FIELD(payment_status, 'completed', 'pending', 'failed', 'refunded'),
            created_at DESC
        LIMIT 1
    )

-- Shipment
LEFT JOIN shipments sh
    ON sh.order_id = o.order_id

-- Item count summary
LEFT JOIN (
    SELECT
        order_id,
        COUNT(*)            AS item_count,
        SUM(quantity)       AS total_quantity
    FROM order_items
    GROUP BY order_id
) oi_summary ON oi_summary.order_id = o.order_id;
