-- =============================================================
-- FILE: seeds/05_seed_inventory.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Initial stock levels for all products
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

-- One row per product — matches product_ids from seed 04
-- (product_id 18 is the draft iPhone — still gets inventory)
INSERT INTO inventory (product_id, quantity_in_stock, quantity_reserved, reorder_threshold)
VALUES
--  product_id  in_stock  reserved  reorder_threshold
    (1,          45,       3,        10),   -- iPhone 15 Pro
    (2,          80,       5,        15),   -- Samsung S24
    (3,          60,       2,        10),   -- OnePlus 12
    (4,          120,      8,        20),   -- Samsung A55
    (5,          30,       1,        5),    -- MacBook Air M3
    (6,          55,       4,        10),   -- Lenovo IdeaPad
    (7,          200,      12,       30),   -- boAt Airdopes 141 ← popular
    (8,          25,       2,        5),    -- Sony WF-1000XM5
    (9,          40,       3,        10),   -- AirPods Pro 2
    (10,         150,      0,        25),   -- Nike Dri-FIT Tee
    (11,         180,      6,        30),   -- Adidas Essentials Tee
    (12,         90,       4,        15),   -- Levi's 511 Slim
    (13,         500,      10,       50),   -- Atomic Habits ← bestseller
    (14,         400,      8,        40),   -- Psychology of Money
    (15,         350,      5,        35),   -- Rich Dad Poor Dad
    (16,         35,       2,        10),   -- Prestige Mixer
    (17,         70,       6,        15),   -- Nike Air Max 90
    (18,         85,       7,        15),   -- Adidas Ultraboost 22
    (19,         0,        0,        10);   -- iPhone 15 Pro Max (draft — no stock yet)

SELECT CONCAT('Inventory seeded: ', COUNT(*), ' rows') AS status FROM inventory;

-- Quick check: show available stock per product
SELECT
    p.name,
    i.quantity_in_stock,
    i.quantity_reserved,
    (i.quantity_in_stock - i.quantity_reserved) AS available,
    i.reorder_threshold,
    CASE WHEN i.quantity_in_stock <= i.reorder_threshold
         THEN '⚠ Low Stock' ELSE '✓ OK' END AS stock_health
FROM inventory i
JOIN products p ON p.product_id = i.product_id
ORDER BY available ASC;
