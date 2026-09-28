-- =============================================================
-- FILE: seeds/08_seed_coupons.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Sample coupons — active, expired, and exhausted
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

INSERT INTO coupons
    (code, description, discount_type, discount_value, min_order_amount, max_discount_amount, usage_limit, usage_count, is_active, starts_at, expires_at)
VALUES
-- Active coupons
('WELCOME10',  'New user welcome discount — 10% off',          'percentage',   10,    500,   200,   1000, 45,  1, '2024-01-01 00:00:00', '2025-12-31 23:59:59'),
('SAVE200',    'Flat ₹200 off on orders above ₹1000',          'fixed_amount', 200,   1000,  NULL,  500,  87,  1, '2024-01-01 00:00:00', '2025-06-30 23:59:59'),
('TECH15',     '15% off on electronics — max ₹1500 discount',  'percentage',   15,    2000,  1500,  NULL, 23,  1, '2024-03-01 00:00:00', '2025-03-31 23:59:59'),
('FLAT500',    'Flat ₹500 off on orders above ₹5000',          'fixed_amount', 500,   5000,  NULL,  200,  61,  1, '2024-02-01 00:00:00', '2025-08-31 23:59:59'),
('BOOKWORM20', '20% off all books — max ₹100',                 'percentage',   20,    NULL,  100,   NULL, 12,  1, '2024-01-01 00:00:00', NULL),              -- never expires
('FREESHIP',   'Free shipping — ₹99 off shipping on any order','fixed_amount', 99,    NULL,  99,    2000, 340, 1, '2024-01-01 00:00:00', '2025-12-31 23:59:59'),

-- Expired coupons (for testing expiry logic)
('DIWALI23',   'Diwali 2023 sale — 25% off',                   'percentage',   25,    1000,  2000,  5000, 4823,0, '2023-10-20 00:00:00', '2023-11-05 23:59:59'),

-- Exhausted coupon (usage_count = usage_limit)
('EARLYBIRD',  'First 50 users only — flat ₹300 off',          'fixed_amount', 300,   1500,  NULL,  50,   50,  1, '2024-01-01 00:00:00', '2025-12-31 23:59:59'),

-- Inactive/disabled coupon
('TESTCODE',   'Internal test coupon — do not publish',         'fixed_amount', 999,   NULL,  NULL,  NULL, 0,   0, NULL,                  NULL);

SELECT CONCAT('Coupons seeded: ', COUNT(*), ' rows') AS status FROM coupons;
