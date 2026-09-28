-- =============================================================
-- =============================================================
-- FILE: seeds/06_seed_orders.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Sample orders in various statuses with payments
--              and shipments to demonstrate the full lifecycle
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

-- =========================================================
-- ORDER 1: Delivered — complete lifecycle (user 2, Rahul)
-- =========================================================
INSERT INTO orders (user_id, address_id, coupon_id, order_number, status,
    subtotal, discount_amount, tax_amount, shipping_amount, total_amount, notes, created_at)
VALUES (2, 1, 2, 'ORD-20240301-00001', 'delivered',
    134900.00, 200.00, 24966.00, 0.00, 159666.00, 'Leave at door', '2024-03-01 10:00:00');

INSERT INTO order_items (order_id, product_id, product_name, product_sku, quantity, unit_price, total_price)
VALUES (1, 1, 'iPhone 15 Pro', 'APL-IP15P-256', 1, 134900.00, 134900.00);

INSERT INTO payments (order_id, payment_method, payment_status, amount, currency, transaction_id, paid_at, created_at)
VALUES (1, 'upi', 'completed', 159666.00, 'INR', 'UPI20240301001', '2024-03-01 10:05:00', '2024-03-01 10:02:00');

INSERT INTO shipments (order_id, tracking_number, courier_name, status, estimated_delivery, delivered_at, created_at)
VALUES (1, 'BD1234567890IN', 'BlueDart', 'delivered', '2024-03-05', '2024-03-04 14:30:00', '2024-03-01 16:00:00');

-- =========================================================
-- ORDER 2: Shipped — in transit (user 3, Priya)
-- =========================================================
INSERT INTO orders (user_id, address_id, coupon_id, order_number, status,
    subtotal, discount_amount, tax_amount, shipping_amount, total_amount, notes, created_at)
VALUES (3, 3, NULL, 'ORD-20240310-00002', 'shipped',
    114900.00, 0.00, 20682.00, 0.00, 135582.00, NULL, '2024-03-10 14:30:00');

INSERT INTO order_items (order_id, product_id, product_name, product_sku, quantity, unit_price, total_price)
VALUES (2, 5, 'MacBook Air M3 13"', 'APL-MBA-M3-13', 1, 114900.00, 114900.00);

INSERT INTO payments (order_id, payment_method, payment_status, amount, currency, transaction_id, paid_at, created_at)
VALUES (2, 'credit_card', 'completed', 135582.00, 'INR', 'CC20240310002', '2024-03-10 14:35:00', '2024-03-10 14:32:00');

INSERT INTO shipments (order_id, tracking_number, courier_name, status, estimated_delivery, created_at)
VALUES (2, 'DTDC9876543210', 'DTDC', 'in_transit', '2024-03-15', '2024-03-11 09:00:00');

-- =========================================================
-- ORDER 3: Confirmed — payment done, not shipped yet (user 4)
-- =========================================================
INSERT INTO orders (user_id, address_id, coupon_id, order_number, status,
    subtotal, discount_amount, tax_amount, shipping_amount, total_amount, notes, created_at)
VALUES (4, 4, NULL, 'ORD-20240312-00003', 'confirmed',
    26289.00, 0.00, 4732.02, 0.00, 31021.02, NULL, '2024-03-12 09:15:00');

INSERT INTO order_items (order_id, product_id, product_name, product_sku, quantity, unit_price, total_price)
VALUES
    (3, 8,  'Sony WF-1000XM5',  'SNY-WF1000XM5', 1, 24990.00, 24990.00),
    (3, 7,  'boAt Airdopes 141','BOT-AD141-BLK',  1,  1299.00,  1299.00);

INSERT INTO payments (order_id, payment_method, payment_status, amount, currency, transaction_id, paid_at, created_at)
VALUES (3, 'net_banking', 'completed', 31021.02, 'INR', 'NB20240312003', '2024-03-12 09:20:00', '2024-03-12 09:17:00');

-- =========================================================
-- ORDER 4: Pending — placed, awaiting payment (user 2)
-- =========================================================
INSERT INTO orders (user_id, address_id, coupon_id, order_number, status,
    subtotal, discount_amount, tax_amount, shipping_amount, total_amount, notes, created_at)
VALUES (2, 1, 1, 'ORD-20240315-00004', 'pending',
    79999.00, 200.00, 14219.82, 0.00, 94018.82, NULL, '2024-03-15 18:00:00');

INSERT INTO order_items (order_id, product_id, product_name, product_sku, quantity, unit_price, total_price)
VALUES (4, 2, 'Samsung Galaxy S24', 'SAM-S24-256', 1, 79999.00, 79999.00);

INSERT INTO payments (order_id, payment_method, payment_status, amount, currency, transaction_id, created_at)
VALUES (4, 'credit_card', 'failed', 94018.82, 'INR', NULL, '2024-03-15 18:05:00');

-- =========================================================
-- ORDER 5: Cancelled — user cancelled after placing (user 6)
-- =========================================================
INSERT INTO orders (user_id, address_id, coupon_id, order_number, status,
    subtotal, discount_amount, tax_amount, shipping_amount, total_amount, notes, created_at)
VALUES (6, 6, NULL, 'ORD-20240308-00005', 'cancelled',
    3998.00, 0.00, 719.64, 0.00, 4717.64, 'Cancelled: changed my mind', '2024-03-08 11:00:00');

INSERT INTO order_items (order_id, product_id, product_name, product_sku, quantity, unit_price, total_price)
VALUES (5, 10, 'Nike Dri-FIT T-Shirt', 'NK-DFIT-TEE-M', 2, 1999.00, 3998.00);

SELECT CONCAT('Orders seeded: ', COUNT(*), ' rows') AS status FROM orders;
SELECT CONCAT('Order items seeded: ', COUNT(*), ' rows') AS status FROM order_items;
SELECT CONCAT('Payments seeded: ', COUNT(*), ' rows') AS status FROM payments;
SELECT CONCAT('Shipments seeded: ', COUNT(*), ' rows') AS status FROM shipments;
