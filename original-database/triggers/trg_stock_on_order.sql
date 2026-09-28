-- =============================================================
-- FILE: triggers/trg_stock_on_order.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Trigger to deduct stock when a shipment is dispatched
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP TRIGGER IF EXISTS trg_stock_on_shipment_dispatch;

DELIMITER $$

-- =============================================================
-- TRIGGER: trg_stock_on_shipment_dispatch
--
-- FIRES: AFTER UPDATE on shipments
-- WHEN:  The shipment status changes TO 'dispatched'
--
-- WHAT IT DOES:
--   When a shipment is marked as dispatched (physically left
--   the warehouse), we:
--   1. Decrease quantity_in_stock  (units physically left)
--   2. Decrease quantity_reserved  (units no longer "pending")
--
--   Before dispatch:
--     quantity_in_stock = 10, quantity_reserved = 2
--     (10 in warehouse, 2 held for orders)
--
--   After dispatch of 1 unit:
--     quantity_in_stock = 9,  quantity_reserved = 1
--     (9 remain, 1 still reserved for other pending orders)
--
-- WHY A TRIGGER AND NOT THE APPLICATION?
--   Triggers fire at the DATABASE level — they cannot be
--   bypassed. Even if someone updates the shipment directly
--   via SQL client, stock is always correctly adjusted.
-- =============================================================
CREATE TRIGGER trg_stock_on_shipment_dispatch
AFTER UPDATE ON shipments
FOR EACH ROW
BEGIN
    -- Only fire when status changes TO 'dispatched'
    -- Not on every shipments update
    IF OLD.status != 'dispatched' AND NEW.status = 'dispatched' THEN

        -- For every order_item in this shipment's order,
        -- deduct quantity from stock and release reservation
        UPDATE inventory i
        JOIN order_items oi ON oi.product_id = i.product_id
        SET
            i.quantity_in_stock = GREATEST(0, i.quantity_in_stock - oi.quantity),
            i.quantity_reserved = GREATEST(0, i.quantity_reserved - oi.quantity)
        WHERE oi.order_id = NEW.order_id;

    END IF;
END$$

DELIMITER ;
