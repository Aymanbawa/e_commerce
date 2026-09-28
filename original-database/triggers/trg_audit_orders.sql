-- =============================================================
-- FILE: triggers/trg_audit_orders.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Trigger that logs every order status change
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP TRIGGER IF EXISTS trg_audit_orders_update;

DELIMITER $$

-- =============================================================
-- TRIGGER: trg_audit_orders_update
--
-- FIRES: AFTER UPDATE on orders
-- WHEN:  The order status actually changes value
--
-- WHAT IT DOES:
--   Every time an order moves from one status to another
--   (e.g. pending → confirmed → shipped → delivered),
--   we record the transition in audit_log with timestamps.
--
--   This creates a complete, immutable history of every
--   order's lifecycle — essential for:
--   - Customer support disputes ("when did my order ship?")
--   - Financial auditing ("when was payment confirmed?")
--   - Operations analysis ("average time from order to delivery")
-- =============================================================
CREATE TRIGGER trg_audit_orders_update
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
    -- Only log when the status field actually changes
    -- Prevents noise from other order field updates
    IF OLD.status != NEW.status THEN
        INSERT INTO audit_log (
            table_name, record_id, action, changed_by, old_values, new_values, changed_at
        ) VALUES (
            'orders',
            NEW.order_id,
            'UPDATE',
            NULL,           -- system-level; app can set this via session variable
            JSON_OBJECT(
                'status',           OLD.status,
                'total_amount',     OLD.total_amount
            ),
            JSON_OBJECT(
                'status',           NEW.status,
                'total_amount',     NEW.total_amount
            ),
            NOW()
        );
    END IF;
END$$

DELIMITER ;

-- =============================================================
-- WHAT THE AUDIT TRAIL LOOKS LIKE FOR ONE ORDER:
--
-- log_id | record_id | old_values              | new_values              | changed_at
-- -------+-----------+-------------------------+-------------------------+---------------------
--      5 |      1042 | {"status":"pending"}    | {"status":"confirmed"}  | 2024-03-15 10:01:00
--      6 |      1042 | {"status":"confirmed"}  | {"status":"processing"} | 2024-03-15 10:05:00
--      7 |      1042 | {"status":"processing"} | {"status":"shipped"}    | 2024-03-16 09:30:00
--      8 |      1042 | {"status":"shipped"}    | {"status":"delivered"}  | 2024-03-18 14:22:00
--
-- Full lifecycle of order 1042 — 4 rows — permanent, uneditable.
-- =============================================================
