-- =============================================================
-- FILE: tests/test_triggers.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Tests that triggers fire correctly
--              Run after all seeds have been executed
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

SELECT '===== TEST: Triggers =====' AS test_suite;

-- ---------------------------------------------------------
-- TEST 1: Audit trigger fires on user INSERT
-- After inserting a user, audit_log should have a new row
-- ---------------------------------------------------------
SELECT 'TEST 1: User INSERT → audit_log entry created' AS test_name;

SET @before_count = (SELECT COUNT(*) FROM audit_log WHERE table_name = 'users' AND action = 'INSERT');

INSERT INTO users (email, password_hash, first_name, last_name)
VALUES ('trigger.test@email.com', '$2b$12$testhash', 'Trigger', 'Test');

SET @after_count = (SELECT COUNT(*) FROM audit_log WHERE table_name = 'users' AND action = 'INSERT');
SET @new_test_user_id = LAST_INSERT_ID();

SELECT
    @before_count                                   AS audit_rows_before,
    @after_count                                    AS audit_rows_after,
    CASE WHEN @after_count > @before_count
         THEN '✅ PASS — audit log entry created'
         ELSE '❌ FAIL — trigger did not fire'
    END                                             AS result;

-- Show the actual audit log entry
SELECT * FROM audit_log
WHERE table_name = 'users' AND record_id = @new_test_user_id;

-- Clean up test user
DELETE FROM users WHERE user_id = @new_test_user_id;

-- ---------------------------------------------------------
-- TEST 2: Audit trigger fires on order status UPDATE
-- Changing order status should create an audit_log row
-- ---------------------------------------------------------
SELECT 'TEST 2: Order UPDATE → audit_log entry created' AS test_name;

SET @before_order_audit = (SELECT COUNT(*) FROM audit_log WHERE table_name = 'orders');

-- Update order 1 status (it's 'delivered' → set to same value won't trigger,
-- so we check an actual status change in a test order)
-- First check current status of order 3 (which is 'confirmed')
SELECT status INTO @original_status FROM orders WHERE order_id = 3;

UPDATE orders SET status = 'processing' WHERE order_id = 3;

SET @after_order_audit = (SELECT COUNT(*) FROM audit_log WHERE table_name = 'orders');

SELECT
    @before_order_audit                             AS audit_rows_before,
    @after_order_audit                              AS audit_rows_after,
    CASE WHEN @after_order_audit > @before_order_audit
         THEN '✅ PASS — order status change logged'
         ELSE '❌ FAIL — trigger did not fire'
    END                                             AS result;

-- Show the audit entry
SELECT * FROM audit_log
WHERE table_name = 'orders' AND record_id = 3
ORDER BY changed_at DESC LIMIT 1;

-- Restore original status
UPDATE orders SET status = @original_status WHERE order_id = 3;

-- ---------------------------------------------------------
-- TEST 3: Stock deduction trigger on shipment dispatch
-- Dispatching a shipment should deduct stock
-- ---------------------------------------------------------
SELECT 'TEST 3: Shipment dispatched → stock deducted' AS test_name;

-- Check stock for product 5 (MacBook, in order 2) before
SELECT quantity_in_stock, quantity_reserved
INTO @stock_before, @reserved_before
FROM inventory WHERE product_id = 5;

-- Dispatch shipment for order 2
UPDATE shipments SET status = 'dispatched' WHERE order_id = 2;

-- Check stock after
SELECT quantity_in_stock, quantity_reserved
INTO @stock_after, @reserved_after
FROM inventory WHERE product_id = 5;

SELECT
    @stock_before                                   AS stock_before,
    @stock_after                                    AS stock_after,
    @reserved_before                                AS reserved_before,
    @reserved_after                                 AS reserved_after,
    CASE WHEN @stock_after < @stock_before
         THEN '✅ PASS — stock deducted on dispatch'
         ELSE '❌ FAIL — stock unchanged'
    END                                             AS result;

SELECT '===== END: Trigger tests =====' AS test_suite;
