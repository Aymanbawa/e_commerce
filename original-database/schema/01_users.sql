-- =============================================================
-- FILE: schema/01_users.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Creates the users table
--              Stores all customers and admin accounts
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

-- -------------------------------------------------------------
-- Drop table if it exists (for clean re-runs during development)
-- WHY: During development you will re-run this file many times.
--      Without DROP, you get "table already exists" error.
-- -------------------------------------------------------------
DROP TABLE IF EXISTS users;

-- =============================================================
-- TABLE: users
--
-- WHY THIS TABLE EXISTS:
--   Every e-commerce platform needs user accounts.
--   This single table handles both customers and admins
--   using a "role" column — no need for two separate tables.
--
-- RELATIONSHIPS:
--   users → addresses      (one user, many addresses)
--   users → orders         (one user, many orders)
--   users → reviews        (one user, many reviews)
--   users → wishlist       (one user, many saved products)
--   users → audit_log      (one user, many change logs)
-- =============================================================
CREATE TABLE users (

    -- ---------------------------------------------------------
    -- PRIMARY KEY
    -- BIGINT UNSIGNED: supports up to 18,446,744,073,709,551,615 rows
    -- AUTO_INCREMENT: database assigns the next ID automatically
    -- We never manually set this value
    -- ---------------------------------------------------------
    user_id         BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,

    -- ---------------------------------------------------------
    -- LOGIN CREDENTIALS
    -- email: must be unique — no two accounts share an email
    -- password_hash: we NEVER store real passwords
    --   The application hashes the password with bcrypt first,
    --   then stores only the hash here (e.g. "$2b$12$abc...")
    -- ---------------------------------------------------------
    email           VARCHAR(255)        NOT NULL,
    password_hash   VARCHAR(255)        NOT NULL,

    -- ---------------------------------------------------------
    -- PERSONAL INFORMATION
    -- Kept separate from credentials for clarity
    -- phone is optional — many users skip this
    -- ---------------------------------------------------------
    first_name      VARCHAR(100)        NOT NULL,
    last_name       VARCHAR(100)        NOT NULL,
    phone           VARCHAR(20)         NULL,

    -- ---------------------------------------------------------
    -- ACCOUNT TYPE
    -- ENUM restricts values to ONLY these two options.
    -- Any other value is rejected by MySQL automatically.
    -- DEFAULT 'customer' means new signups are customers.
    -- Admins are assigned manually by another admin.
    -- ---------------------------------------------------------
    role            ENUM('customer', 'admin')
                                        NOT NULL DEFAULT 'customer',

    -- ---------------------------------------------------------
    -- ACCOUNT STATUS FLAGS
    -- is_verified: did the user click the email confirmation link?
    --   0 = not verified yet, 1 = verified
    -- is_active: is the account in good standing?
    --   0 = suspended or banned, 1 = active (default)
    -- TINYINT(1) is MySQL's way of storing a boolean.
    -- ---------------------------------------------------------
    is_verified     TINYINT(1)          NOT NULL DEFAULT 0,
    is_active       TINYINT(1)          NOT NULL DEFAULT 1,

    -- ---------------------------------------------------------
    -- TIMESTAMPS
    -- created_at: set once when account is created, never changed
    -- updated_at: automatically updates to NOW() on every change
    --   DEFAULT CURRENT_TIMESTAMP = set to now on INSERT
    --   ON UPDATE CURRENT_TIMESTAMP = auto-update on every UPDATE
    -- ---------------------------------------------------------
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP
                                        ON UPDATE CURRENT_TIMESTAMP,

    -- ---------------------------------------------------------
    -- SOFT DELETE
    -- deleted_at: NULL means the account is active.
    --   When a user "deletes" their account, we set this to NOW().
    --   The row stays in the database forever.
    -- WHY: Hard-deleting a user would break all their orders.
    --   With soft delete, order history is always intact.
    -- ---------------------------------------------------------
    deleted_at      DATETIME            NULL DEFAULT NULL,

    -- ---------------------------------------------------------
    -- PRIMARY KEY DEFINITION
    -- ---------------------------------------------------------
    CONSTRAINT pk_users PRIMARY KEY (user_id),

    -- ---------------------------------------------------------
    -- UNIQUE CONSTRAINTS
    -- Prevents two users registering with the same email.
    -- Named constraints are easier to debug in error messages.
    -- ---------------------------------------------------------
    CONSTRAINT uq_users_email UNIQUE (email)

-- ---------------------------------------------------------
-- STORAGE ENGINE & CHARACTER SET
-- InnoDB: MySQL's default engine. Supports:
--   - Foreign keys (MyISAM does NOT support these)
--   - Transactions (atomic operations — all or nothing)
--   - Row-level locking (better performance under load)
-- utf8mb4: inherits from database but stated explicitly
--   for clarity and portability
-- ---------------------------------------------------------
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Stores all user accounts — customers and admins';

-- =============================================================
-- INDEXES
-- WHY HERE: These are the most common lookup patterns:
--   1. Login → lookup by email
--   2. Admin filtering → find all active/inactive users
--   3. Soft delete queries → filter out deleted users
--
-- We only index columns we actually search/filter on.
-- Too many indexes slow down INSERT and UPDATE.
-- =============================================================

-- Login lookup — most frequent query on this table
CREATE INDEX idx_users_email
    ON users (email);

-- Filter active/inactive users (admin dashboard)
CREATE INDEX idx_users_is_active
    ON users (is_active);

-- Exclude soft-deleted users from all queries
CREATE INDEX idx_users_deleted_at
    ON users (deleted_at);

-- Combined index for role + active status
-- Used in queries like: "show me all active customers"
CREATE INDEX idx_users_role_active
    ON users (role, is_active);

-- =============================================================
-- VERIFICATION QUERY
-- Run this after creating the table to confirm structure
-- =============================================================
DESCRIBE users;

-- =============================================================
-- EXPECTED OUTPUT (13 columns):
-- +-----------------+-----------------------+------+-----+-------------------+
-- | Field           | Type                  | Null | Key | Default           |
-- +-----------------+-----------------------+------+-----+-------------------+
-- | user_id         | bigint unsigned       | NO   | PRI | NULL              |
-- | email           | varchar(255)          | NO   | UNI | NULL              |
-- | password_hash   | varchar(255)          | NO   |     | NULL              |
-- | first_name      | varchar(100)          | NO   |     | NULL              |
-- | last_name       | varchar(100)          | NO   |     | NULL              |
-- | phone           | varchar(20)           | YES  |     | NULL              |
-- | role            | enum('customer'...)   | NO   |     | customer          |
-- | is_verified     | tinyint(1)            | NO   |     | 0                 |
-- | is_active       | tinyint(1)            | NO   |     | 1                 |
-- | created_at      | datetime              | NO   |     | CURRENT_TIMESTAMP |
-- | updated_at      | datetime              | NO   |     | CURRENT_TIMESTAMP |
-- | deleted_at      | datetime              | YES  |     | NULL              |
-- +-----------------+-----------------------+------+-----+-------------------+
-- =============================================================


