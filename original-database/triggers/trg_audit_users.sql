-- =============================================================
-- FILE: triggers/trg_audit_users.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Triggers that log every change to the users table
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP TRIGGER IF EXISTS trg_audit_users_insert;
DROP TRIGGER IF EXISTS trg_audit_users_update;
DROP TRIGGER IF EXISTS trg_audit_users_delete;

DELIMITER $$

-- =============================================================
-- TRIGGER 1: Log new user registrations
-- FIRES: AFTER INSERT on users
-- =============================================================
CREATE TRIGGER trg_audit_users_insert
AFTER INSERT ON users
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (
        table_name, record_id, action, changed_by, old_values, new_values, changed_at
    ) VALUES (
        'users',
        NEW.user_id,
        'INSERT',
        NEW.user_id,        -- the user themselves registered
        NULL,               -- nothing existed before
        JSON_OBJECT(
            'email',        NEW.email,
            'first_name',   NEW.first_name,
            'last_name',    NEW.last_name,
            'role',         NEW.role,
            'is_active',    NEW.is_active
        ),
        NOW()
    );
END$$

-- =============================================================
-- TRIGGER 2: Log user updates (role change, suspension, etc.)
-- FIRES: AFTER UPDATE on users
-- Only logs if something meaningful actually changed
-- =============================================================
CREATE TRIGGER trg_audit_users_update
AFTER UPDATE ON users
FOR EACH ROW
BEGIN
    -- Only log if something important actually changed
    -- Avoids noise from trivial updated_at-only refreshes
    IF OLD.email       != NEW.email       OR
       OLD.role        != NEW.role        OR
       OLD.is_active   != NEW.is_active   OR
       OLD.is_verified != NEW.is_verified OR
       (OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL) THEN

        INSERT INTO audit_log (
            table_name, record_id, action, changed_by, old_values, new_values, changed_at
        ) VALUES (
            'users',
            NEW.user_id,
            'UPDATE',
            NULL,           -- changed_by unknown at DB trigger level
            JSON_OBJECT(
                'email',        OLD.email,
                'role',         OLD.role,
                'is_active',    OLD.is_active,
                'is_verified',  OLD.is_verified,
                'deleted_at',   OLD.deleted_at
            ),
            JSON_OBJECT(
                'email',        NEW.email,
                'role',         NEW.role,
                'is_active',    NEW.is_active,
                'is_verified',  NEW.is_verified,
                'deleted_at',   NEW.deleted_at
            ),
            NOW()
        );
    END IF;
END$$

-- =============================================================
-- TRIGGER 3: Log hard deletes (rare — we use soft delete)
-- FIRES: AFTER DELETE on users
-- =============================================================
CREATE TRIGGER trg_audit_users_delete
AFTER DELETE ON users
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (
        table_name, record_id, action, changed_by, old_values, new_values, changed_at
    ) VALUES (
        'users',
        OLD.user_id,
        'DELETE',
        NULL,
        JSON_OBJECT(
            'email',        OLD.email,
            'role',         OLD.role,
            'is_active',    OLD.is_active
        ),
        NULL,
        NOW()
    );
END$$

DELIMITER ;
