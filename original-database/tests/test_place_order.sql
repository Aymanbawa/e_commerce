-- =============================================================
-- FILE: tests/test_place_order.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Tests for sp_place_order stored procedure
--              Run after all seeds have been executed
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

SELECT '===== TEST: sp_place_order =====' AS test_suite;

-- ---------------------------------------------------------
-- TEST 1: Successful order placement
-- User 2 (Rahul), address 1, coupon SAVE200, 1x product 2
-- EXPECT: p_order_id > 0, new row in orders + order_items
-- ---------------------------------------------------------
SELECT 'TEST 1: Valid order — should succeed' AS test_name;

CALL sp_place_order(
    2,
    1,
    'SAVE200',
    '[{"product_id":2,"quantity":1}]',
    'Test order - please ignore',
    @new_order_id
);

SELECT
    @new_order_id                                   AS returned_order_id,
    CASE WHEN @new_order_id > 0
         THEN '✅ PASS — order created'
         ELSE '❌ FAIL — order_id is 0'
    END                                             AS result;

-- Verify the order row was created
SELECT
    order_id,
    order_number,
    status,
    subtotal,
    discount_amount,
    total_amount
FROM orders
WHERE order_id = @new_order_id;

-- Verify order items
SELECT
    item_id,
    product_name,
    quantity,
    unit_price,
    total_price
FROM order_items
WHERE order_id = @new_order_id;

-- ---------------------------------------------------------
-- TEST 2: Invalid user — should fail
-- user_id = 9999 does not exist
-- EXPECT: Error raised by procedure
-- ---------------------------------------------------------
SELECT 'TEST 2: Invalid user — should fail' AS test_name;

BEGIN;
CALL sp_place_order(
    9999,
    1,
    NULL,
    '[{"product_id":2,"quantity":1}]',
    NULL,
    @bad_order_id
);
SELECT
    @bad_order_id                                   AS returned_order_id,
    CASE WHEN @bad_order_id = 0
         THEN '✅ PASS — correctly rejected'
         ELSE '❌ FAIL — should have returned 0'
    END                                             AS result;
ROLLBACK;

-- ---------------------------------------------------------
-- TEST 3: Empty items list — should fail
-- ---------------------------------------------------------
SELECT 'TEST 3: Empty items — should fail' AS test_name;

BEGIN;
CALL sp_place_order(
    2,
    1,
    NULL,
    '[]',
    NULL,
    @empty_order_id
);
SELECT
    @empty_order_id                                 AS returned_order_id,
    CASE WHEN @empty_order_id = 0
         THEN '✅ PASS — correctly rejected'
         ELSE '❌ FAIL — should not allow empty order'
    END                                             AS result;
ROLLBACK;

-- ---------------------------------------------------------
-- TEST 4: Verify stock was reserved after TEST 1
-- ---------------------------------------------------------
SELECT 'TEST 4: Check stock reservation after order' AS test_name;

SELECT
    i.product_id,
    p.name,
    i.quantity_in_stock,
    i.quantity_reserved,
    (i.quantity_in_stock - i.quantity_reserved)     AS available,
    CASE WHEN i.quantity_reserved >= 1
         THEN '✅ PASS — stock reserved'
         ELSE '❌ FAIL — no reservation found'
    END                                             AS result
FROM inventory i
JOIN products p ON p.product_id = i.product_id
WHERE i.product_id = 2;

SELECT '===== END: sp_place_order tests =====' AS test_suite;
