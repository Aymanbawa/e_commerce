-- =============================================================
-- FILE: setup.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Master script — runs ALL files in the correct order
--              Run this ONE file to set up the entire database
-- AUTHOR: Your Name
-- USAGE: SOURCE /your/path/to/ecommerce-sql-project/setup.sql
-- =============================================================

SELECT 'Starting E-Commerce Database Setup...' AS status;
SELECT NOW() AS started_at;

-- =============================================================
-- PHASE 1: DATABASE
-- =============================================================
SELECT '--- Phase 1: Creating Database ---' AS phase;
SOURCE schema/00_create_database.sql;

-- =============================================================
-- PHASE 2: SCHEMA — Tables (ORDER MATTERS — parent before child)
-- =============================================================
SELECT '--- Phase 2: Creating Tables ---' AS phase;
SOURCE schema/01_users.sql;
SOURCE schema/02_addresses.sql;
SOURCE schema/03_categories.sql;
SOURCE schema/04_brands.sql;
SOURCE schema/05_products.sql;
SOURCE schema/06_product_images.sql;
SOURCE schema/07_product_attributes.sql;
SOURCE schema/08_inventory.sql;
SOURCE schema/09_coupons.sql;
SOURCE schema/10_orders.sql;
SOURCE schema/11_order_items.sql;
SOURCE schema/12_payments.sql;
SOURCE schema/13_shipments.sql;
SOURCE schema/14_reviews.sql;
SOURCE schema/15_wishlist.sql;
SOURCE schema/16_audit_log.sql;

-- =============================================================
-- PHASE 3: INDEXES
-- =============================================================
SELECT '--- Phase 3: Creating Indexes ---' AS phase;
SOURCE indexes/indexes.sql;

-- =============================================================
-- PHASE 4: FUNCTIONS (before procedures that use them)
-- =============================================================
SELECT '--- Phase 4: Creating Functions ---' AS phase;
SOURCE routines/fn_calculate_discount.sql;
SOURCE routines/fn_get_stock_level.sql;

-- =============================================================
-- PHASE 5: STORED PROCEDURES
-- =============================================================
SELECT '--- Phase 5: Creating Stored Procedures ---' AS phase;
SOURCE routines/sp_place_order.sql;
SOURCE routines/sp_cancel_order.sql;
SOURCE routines/sp_process_payment.sql;

-- =============================================================
-- PHASE 6: TRIGGERS
-- =============================================================
SELECT '--- Phase 6: Creating Triggers ---' AS phase;
SOURCE triggers/trg_audit_users.sql;
SOURCE triggers/trg_audit_orders.sql;
SOURCE triggers/trg_stock_on_order.sql;

-- =============================================================
-- PHASE 7: VIEWS
-- =============================================================
SELECT '--- Phase 7: Creating Views ---' AS phase;
SOURCE views/vw_product_catalog.sql;
SOURCE views/vw_order_summary.sql;
SOURCE views/vw_sales_by_category.sql;
SOURCE views/vw_low_stock_alert.sql;

-- =============================================================
-- PHASE 8: SEED DATA (ORDER MATTERS — parent data before child)
-- =============================================================
SELECT '--- Phase 8: Inserting Seed Data ---' AS phase;
SOURCE seeds/01_seed_users.sql;
SOURCE seeds/02_seed_categories.sql;
SOURCE seeds/03_seed_brands.sql;
SOURCE seeds/04_seed_products.sql;
SOURCE seeds/05_seed_inventory.sql;
SOURCE seeds/08_seed_coupons.sql;
SOURCE seeds/06_seed_orders.sql;
SOURCE seeds/07_seed_reviews.sql;

-- =============================================================
-- PHASE 9: VERIFICATION — confirm everything was created
-- =============================================================
SELECT '--- Phase 9: Verification ---' AS phase;

SELECT
    TABLE_NAME          AS 'Table',
    TABLE_ROWS          AS 'Approx Rows',
    TABLE_COMMENT       AS 'Description'
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'ecommerce_db'
  AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

SELECT COUNT(*) AS total_tables
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'ecommerce_db' AND TABLE_TYPE = 'BASE TABLE';

SELECT COUNT(*) AS total_views
FROM information_schema.VIEWS
WHERE TABLE_SCHEMA = 'ecommerce_db';

SELECT COUNT(*) AS total_routines
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = 'ecommerce_db';

SELECT COUNT(*) AS total_triggers
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = 'ecommerce_db';

-- Quick data counts
SELECT 'users'      AS tbl, COUNT(*) AS rows FROM users      UNION ALL
SELECT 'products'   AS tbl, COUNT(*) AS rows FROM products   UNION ALL
SELECT 'categories' AS tbl, COUNT(*) AS rows FROM categories UNION ALL
SELECT 'brands'     AS tbl, COUNT(*) AS rows FROM brands     UNION ALL
SELECT 'orders'     AS tbl, COUNT(*) AS rows FROM orders     UNION ALL
SELECT 'inventory'  AS tbl, COUNT(*) AS rows FROM inventory  UNION ALL
SELECT 'coupons'    AS tbl, COUNT(*) AS rows FROM coupons    UNION ALL
SELECT 'reviews'    AS tbl, COUNT(*) AS rows FROM reviews;

SELECT '✅ Setup Complete! E-Commerce database is ready.' AS status;
SELECT NOW() AS completed_at;
