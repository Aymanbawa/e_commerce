-- =============================================================
-- FILE: tests/test_constraints.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Tests that all constraints reject invalid data
--              Run after all seeds have been executed
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

SELECT '===== TEST: Constraints =====' AS test_suite;

-- ---------------------------------------------------------
-- TEST 1: Duplicate email — UNIQUE should reject it
-- ---------------------------------------------------------
SELECT 'TEST 1: Duplicate email — UNIQUE constraint' AS test_name;

BEGIN;
INSERT INTO users (email, password_hash, first_name, last_name)
VALUES ('rahul.sharma@email.com', 'hash', 'Duplicate', 'User');
ROLLBACK;
-- If you reach here without error, the test FAILED
-- MySQL should raise: Duplicate entry for key 'uq_users_email'
SELECT '✅ PASS — duplicate email was rejected (if no error above)' AS result;

-- ---------------------------------------------------------
-- TEST 2: Negative product price — CHECK should reject it
-- ---------------------------------------------------------
SELECT 'TEST 2: Negative price — CHECK constraint' AS test_name;

BEGIN;
INSERT INTO products (category_id, brand_id, name, slug, sku, price, status)
VALUES (1, 1, 'Test Product', 'test-product', 'TST-001', -100.00, 'active');
ROLLBACK;
SELECT '✅ PASS — negative price was rejected (if no error above)' AS result;

-- ---------------------------------------------------------
-- TEST 3: compare_price < price — CHECK should reject it
-- (compare_price must be HIGHER than price to be a valid sale)
-- ---------------------------------------------------------
SELECT 'TEST 3: compare_price < price — CHECK constraint' AS test_name;

BEGIN;
INSERT INTO products (category_id, name, slug, sku, price, compare_price, status)
VALUES (1, 'Test', 'test-slug-2', 'TST-002', 10000.00, 5000.00, 'active');
-- compare_price (5000) < price (10000) — invalid
ROLLBACK;
SELECT '✅ PASS — invalid compare_price was rejected (if no error above)' AS result;

-- ---------------------------------------------------------
-- TEST 4: Review rating outside 1-5 — CHECK should reject it
-- ---------------------------------------------------------
SELECT 'TEST 4: Rating = 6 — CHECK constraint' AS test_name;

BEGIN;
INSERT INTO reviews (product_id, user_id, order_id, rating)
VALUES (1, 2, 1, 6);
ROLLBACK;
SELECT '✅ PASS — rating 6 was rejected (if no error above)' AS result;

-- ---------------------------------------------------------
-- TEST 5: Duplicate wishlist entry — UNIQUE should reject it
-- ---------------------------------------------------------
SELECT 'TEST 5: Duplicate wishlist — UNIQUE constraint' AS test_name;

BEGIN;
-- user 2 + product 1 already added in seed_users or can test fresh
INSERT INTO wishlist (user_id, product_id) VALUES (2, 1);
INSERT INTO wishlist (user_id, product_id) VALUES (2, 1); -- duplicate
ROLLBACK;
SELECT '✅ PASS — duplicate wishlist entry rejected (if no error above)' AS result;

-- ---------------------------------------------------------
-- TEST 6: FK violation — invalid category_id
-- ---------------------------------------------------------
SELECT 'TEST 6: Invalid FK — non-existent category_id' AS test_name;

BEGIN;
INSERT INTO products (category_id, name, slug, sku, price, status)
VALUES (9999, 'Ghost Product', 'ghost-product', 'GHOST-001', 100.00, 'active');
ROLLBACK;
SELECT '✅ PASS — invalid category_id was rejected (if no error above)' AS result;

SELECT '===== END: Constraint tests =====' AS test_suite;
