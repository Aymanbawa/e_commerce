-- =============================================================
-- FILE: schema/16_audit_log.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Creates the audit_log table
--              Tamper-evident log of all important data changes
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP TABLE IF EXISTS audit_log;

-- =============================================================
-- TABLE: audit_log
--
-- WHY THIS TABLE EXISTS:
--   In production systems you always need to answer:
--   "Who changed this? What did it look like before? When?"
--
--   This table is written to automatically by database TRIGGERS
--   — not by the application. This means changes are recorded
--   even if someone edits the database directly (bypassing the app).
--
--   It records the BEFORE and AFTER values as JSON, so you
--   can reconstruct the exact state of any row at any point in time.
--
--   This table is APPEND-ONLY — rows are never updated or deleted.
--   It is a permanent, tamper-evident history log.
--
-- WRITTEN BY:
--   trg_audit_users  → logs every users table change
--   trg_audit_orders → logs every orders status change
--
-- RELATIONSHIPS:
--   audit_log is standalone — it references no FK.
--   WHY: If we added FK to users, deleting a user would block
--   or cascade into the audit log — destroying the history.
--   The audit log must be independent to stay complete.
-- =============================================================
CREATE TABLE audit_log (

    log_id          BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,

    -- Which table was changed (e.g. 'users', 'orders')
    table_name      VARCHAR(100)        NOT NULL,

    -- The primary key value of the row that changed
    record_id       BIGINT UNSIGNED     NOT NULL,

    -- What type of operation happened
    action          ENUM('INSERT', 'UPDATE', 'DELETE')
                                        NOT NULL,

    -- Who made the change (user_id from users table)
    -- NULL = change made by system trigger or migration script
    -- No FK constraint intentionally — see WHY above
    changed_by      BIGINT UNSIGNED     NULL DEFAULT NULL,

    -- ---------------------------------------------------------
    -- BEFORE AND AFTER SNAPSHOTS
    -- Stored as JSON — flexible, captures any columns
    --
    -- old_values: what the row looked like BEFORE the change
    --   NULL on INSERT (nothing existed before)
    --
    -- new_values: what the row looks like AFTER the change
    --   NULL on DELETE (nothing exists after)
    --
    -- Example UPDATE on orders (status change):
    --   old_values = {"status": "confirmed"}
    --   new_values = {"status": "shipped"}
    -- ---------------------------------------------------------
    old_values      JSON                NULL DEFAULT NULL,
    new_values      JSON                NULL DEFAULT NULL,

    -- Exact timestamp of the change — set by trigger using NOW()
    changed_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- ---------------------------------------------------------
    -- CONSTRAINTS
    -- ---------------------------------------------------------
    CONSTRAINT pk_audit_log PRIMARY KEY (log_id)

    -- NOTE: No foreign keys on this table — intentional.
    -- The audit log must remain complete and independent.
    -- See WHY above.

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Append-only audit trail — written by triggers, never by application';

-- =============================================================
-- INDEXES
-- =============================================================

-- Find all changes to a specific table
CREATE INDEX idx_audit_table_name
    ON audit_log (table_name);

-- Find all changes to a specific record in a specific table
-- e.g. "show me the full history of order #1042"
CREATE INDEX idx_audit_table_record
    ON audit_log (table_name, record_id);

-- Find all changes made by a specific user
CREATE INDEX idx_audit_changed_by
    ON audit_log (changed_by);

-- Time-based audit queries (what changed today?)
CREATE INDEX idx_audit_changed_at
    ON audit_log (changed_at);

-- =============================================================
-- VERIFICATION QUERY
-- =============================================================
DESCRIBE audit_log;

-- =============================================================
-- SAMPLE DATA (mental model — written by triggers automatically)
--
-- log_id | table_name | record_id | action | old_values            | new_values
-- -------+------------+-----------+--------+-----------------------+----------------------
--      1 | users      |         5 | INSERT | NULL                  | {"email":"r@m.com"}
--      2 | orders     |      1042 | UPDATE | {"status":"confirmed"}| {"status":"shipped"}
--      3 | users      |         5 | UPDATE | {"is_active":1}       | {"is_active":0}
--
-- Row 2: Order 1042 status changed from confirmed → shipped.
--        Full history preserved. Cannot be altered.
-- =============================================================
