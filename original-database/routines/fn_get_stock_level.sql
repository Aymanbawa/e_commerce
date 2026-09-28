-- =============================================================
-- FILE: routines/fn_get_stock_level.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Function that returns available stock for a product
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP FUNCTION IF EXISTS fn_get_stock_level;

DELIMITER $$

-- =============================================================
-- FUNCTION: fn_get_stock_level
--
-- WHAT IT DOES:
--   Returns the number of units actually available for a customer
--   to purchase right now.
--
--   Available = quantity_in_stock - quantity_reserved
--
--   quantity_reserved = units already locked for pending orders
--   These units are in the warehouse but already spoken for.
--
-- PARAMETERS:
--   p_product_id — the product to check
--
-- RETURNS:
--   INT — available units (0 if product not found or out of stock)
--
-- USAGE:
--   SELECT fn_get_stock_level(1);     -- returns e.g. 7
--   Used in product listings, cart validation, and admin reports.
-- =============================================================
CREATE FUNCTION fn_get_stock_level(
    p_product_id BIGINT UNSIGNED
)
RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_in_stock      INT UNSIGNED DEFAULT 0;
    DECLARE v_reserved      INT UNSIGNED DEFAULT 0;
    DECLARE v_available     INT DEFAULT 0;

    SELECT
        quantity_in_stock,
        quantity_reserved
    INTO
        v_in_stock,
        v_reserved
    FROM inventory
    WHERE product_id = p_product_id;

    -- Product has no inventory row — treat as zero stock
    IF v_in_stock IS NULL THEN
        RETURN 0;
    END IF;

    SET v_available = v_in_stock - v_reserved;

    -- Safety guard — never return negative
    RETURN GREATEST(0, v_available);

END$$

DELIMITER ;

-- =============================================================
-- HOW TO USE THIS FUNCTION:
--
-- Check available stock for one product:
-- SELECT fn_get_stock_level(1) AS available_stock;
-- -- Returns: 7
--
-- Use in a query to show availability on product listing:
-- SELECT
--     p.name,
--     p.price,
--     fn_get_stock_level(p.product_id) AS available_stock,
--     CASE
--         WHEN fn_get_stock_level(p.product_id) = 0 THEN 'Out of Stock'
--         WHEN fn_get_stock_level(p.product_id) <= 5 THEN 'Low Stock'
--         ELSE 'In Stock'
--     END AS stock_status
-- FROM products p
-- WHERE p.status = 'active';
-- =============================================================
