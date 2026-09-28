-- =============================================================
-- FILE: schema/00_create_database.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Creates the database with correct settings
-- AUTHOR: Your Name
-- =============================================================

-- -------------------------------------------------------------
-- STEP 1: Drop the database if it already exists
-- WHY: This lets you re-run this file cleanly during development
--      without getting "database already exists" errors.
--      NEVER do this in production — you would lose all data.
-- -------------------------------------------------------------
DROP DATABASE IF EXISTS ecommerce_db;

-- -------------------------------------------------------------
-- STEP 2: Create the database
-- 
-- CHARACTER SET utf8mb4:
--   utf8mb4 is the CORRECT UTF-8 for MySQL.
--   The older "utf8" in MySQL only supports 3-byte characters
--   and will BREAK on emojis and many non-Latin scripts.
--   utf8mb4 supports ALL Unicode characters including emojis. ✅
--
-- COLLATION utf8mb4_unicode_ci:
--   Collation controls how text is sorted and compared.
--   "unicode_ci" means:
--     - unicode = uses Unicode rules for sorting
--     - ci      = case-insensitive (so "Apple" = "apple" in searches)
--   This is the industry standard for e-commerce databases.
-- -------------------------------------------------------------
CREATE DATABASE ecommerce_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- -------------------------------------------------------------
-- STEP 3: Select the database for all following statements
-- WHY: Every SQL file after this one will use this database.
--      When you run setup.sql it all chains together.
-- -------------------------------------------------------------
USE ecommerce_db;

-- -------------------------------------------------------------
-- STEP 4: Set session-level settings for safe development
--
-- FOREIGN_KEY_CHECKS = 1:
--   Ensures foreign key constraints are enforced.
--   We set this explicitly so the session always starts safe.
--
-- SQL_MODE with STRICT_TRANS_TABLES:
--   Strict mode means MySQL will REJECT bad data instead of
--   silently saving a wrong value (e.g. truncating a string
--   or inserting 0 instead of rejecting a missing required field).
--   In non-strict mode, MySQL quietly corrupts your data.
--   Strict mode is what every production database uses.
-- -------------------------------------------------------------
SET FOREIGN_KEY_CHECKS = 1;

SET sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -------------------------------------------------------------
-- STEP 5: Confirm the database was created successfully
-- WHY: This gives you visual confirmation in your SQL client
--      that everything worked. Useful during development.
-- -------------------------------------------------------------
SELECT
    SCHEMA_NAME        AS 'Database',
    DEFAULT_CHARACTER_SET_NAME AS 'Character Set',
    DEFAULT_COLLATION_NAME      AS 'Collation'
FROM information_schema.SCHEMATA
WHERE SCHEMA_NAME = 'ecommerce_db';

-- =============================================================
-- EXPECTED OUTPUT:
-- +---------------+---------------+--------------------+
-- | Database      | Character Set | Collation          |
-- +---------------+---------------+--------------------+
-- | ecommerce_db  | utf8mb4       | utf8mb4_unicode_ci |
-- +---------------+---------------+--------------------+
-- =============================================================

