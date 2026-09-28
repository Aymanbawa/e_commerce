-- =============================================================
-- FILE: indexes/indexes.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Additional composite indexes for query performance
--              Run AFTER all schema files have been executed
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

-- =============================================================
-- WHY A SEPARATE INDEXES FILE?
--
-- Each schema file already creates basic indexes on individual
-- columns. This file adds COMPOSITE indexes — indexes on
-- multiple columns together — that support specific, frequent
-- query patterns across the entire application.
--
-- Rule of thumb: add an index when a query is:
--   1. Run very frequently (every page load)
--   2. Scanning a large table (products, orders)
--   3. Filtering on multiple columns together
--
-- Too many indexes slow down INSERT/UPDATE. We only add
-- indexes that serve real query patterns.
-- =============================================================

-- -------------------------------------------------------------
-- PRODUCTS — composite indexes for storefront queries
-- -------------------------------------------------------------

-- "Show active products in category X, sorted by price"
-- Covers: WHERE category_id = ? AND status = 'active' ORDER BY price
CREATE INDEX idx_products_cat_status_price
    ON products (category_id, status, price);

-- "Show active featured products for homepage"
-- Covers: WHERE is_featured = 1 AND status = 'active' AND deleted_at IS NULL
CREATE INDEX idx_products_featured_status
    ON products (is_featured, status, deleted_at);

-- "Show active products by brand"
-- Covers: WHERE brand_id = ? AND status = 'active'
CREATE INDEX idx_products_brand_status
    ON products (brand_id, status);

-- -------------------------------------------------------------
-- ORDERS — composite indexes for customer and admin queries
-- -------------------------------------------------------------

-- "Show all orders for user X ordered by date"
-- Covers: WHERE user_id = ? ORDER BY created_at DESC
CREATE INDEX idx_orders_user_created
    ON orders (user_id, created_at);

-- "Show all orders in a specific status for admin dashboard"
-- Covers: WHERE status = 'pending' ORDER BY created_at ASC
CREATE INDEX idx_orders_status_created
    ON orders (status, created_at);

-- "Revenue report — completed orders in date range"
-- Covers: WHERE status = 'delivered' AND created_at BETWEEN ? AND ?
CREATE INDEX idx_orders_status_date_range
    ON orders (status, created_at, total_amount);

-- -------------------------------------------------------------
-- PAYMENTS — indexes for financial reconciliation
-- -------------------------------------------------------------

-- "Find all completed payments in a date range"
-- Covers: WHERE payment_status = 'completed' AND paid_at BETWEEN ? AND ?
CREATE INDEX idx_payments_status_date
    ON payments (payment_status, paid_at);

-- "Revenue by payment method report"
-- Covers: GROUP BY payment_method WHERE payment_status = 'completed'
CREATE INDEX idx_payments_method_status
    ON payments (payment_method, payment_status);

-- -------------------------------------------------------------
-- REVIEWS — indexes for rating calculations
-- -------------------------------------------------------------

-- "Calculate average rating for a product (approved reviews only)"
-- Covers: WHERE product_id = ? AND is_approved = 1
CREATE INDEX idx_reviews_product_approved_rating
    ON reviews (product_id, is_approved, rating);

-- -------------------------------------------------------------
-- INVENTORY — indexes for stock management
-- -------------------------------------------------------------

-- "Find all products below reorder threshold"
-- Covers: WHERE quantity_in_stock <= reorder_threshold
-- Used by vw_low_stock_alert view
CREATE INDEX idx_inventory_stock_threshold
    ON inventory (quantity_in_stock, reorder_threshold);

-- -------------------------------------------------------------
-- AUDIT LOG — indexes for compliance queries
-- -------------------------------------------------------------

-- "Show audit trail for a specific record in date range"
-- Covers: WHERE table_name = ? AND record_id = ? AND changed_at BETWEEN ? AND ?
CREATE INDEX idx_audit_full_lookup
    ON audit_log (table_name, record_id, changed_at);

-- =============================================================
-- VERIFY ALL INDEXES CREATED
-- Run this to see all indexes across all tables
-- =============================================================
SELECT
    TABLE_NAME      AS 'Table',
    INDEX_NAME      AS 'Index Name',
    COLUMN_NAME     AS 'Column',
    NON_UNIQUE      AS 'Non Unique',
    INDEX_TYPE      AS 'Type'
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'ecommerce_db'
ORDER BY TABLE_NAME, INDEX_NAME;
