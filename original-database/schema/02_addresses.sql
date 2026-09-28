-- =============================================================
-- FILE: schema/02_addresses.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Creates the addresses table
--              Stores shipping and billing addresses for users
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

-- -------------------------------------------------------------
-- Drop table if it exists (for clean re-runs during development)
-- NOTE: addresses references users, so if you ever drop BOTH,
--       drop addresses FIRST, then users (child before parent)
-- -------------------------------------------------------------
DROP TABLE IF EXISTS addresses;

-- =============================================================
-- TABLE: addresses
--
-- WHY THIS TABLE EXISTS:
--   A user can have multiple addresses — home, office, parents
--   house, etc. Instead of putting address columns directly on
--   the users table (which allows only ONE address), we create
--   a separate table so each user can have unlimited addresses.
--
--   Also, when an order is placed, we record WHICH address was
--   used. If the user later edits or deletes that address, the
--   order still remembers the correct delivery location.
--
-- REAL WORLD EXAMPLE:
--   Amazon lets you save 10+ addresses and pick one at checkout.
--   That is exactly what this table enables.
--
-- RELATIONSHIPS:
--   addresses → users    (many addresses belong to one user)
--   orders    → addresses (one address used per order)
-- =============================================================
CREATE TABLE addresses (

    -- ---------------------------------------------------------
    -- PRIMARY KEY
    -- ---------------------------------------------------------
    address_id      BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,

    -- ---------------------------------------------------------
    -- FOREIGN KEY TO USERS
    -- Every address must belong to a real user.
    -- If the user is deleted, what happens to their addresses?
    --   ON DELETE CASCADE = delete addresses too
    -- WHY CASCADE here:
    --   Addresses without an owner are useless orphan rows.
    --   Unlike orders (which must stay for history), an address
    --   has no value if the user account is gone.
    -- ---------------------------------------------------------
    user_id         BIGINT UNSIGNED     NOT NULL,

    -- ---------------------------------------------------------
    -- ADDRESS TYPE
    -- Tells us what this address is used for.
    -- 'shipping'  = deliver orders here
    -- 'billing'   = charge payments to this address
    -- 'both'      = use for both shipping and billing
    -- ---------------------------------------------------------
    type            ENUM('shipping', 'billing', 'both')
                                        NOT NULL DEFAULT 'both',

    -- ---------------------------------------------------------
    -- RECIPIENT DETAILS
    -- full_name: the person receiving the delivery
    --   This can differ from the account holder's name.
    --   Example: ordering a gift for your mother — her name
    --   goes here, not yours.
    -- phone: courier calls this number if there is a problem
    -- ---------------------------------------------------------
    full_name       VARCHAR(200)        NOT NULL,
    phone           VARCHAR(20)         NOT NULL,

    -- ---------------------------------------------------------
    -- ADDRESS LINES
    -- address_line1: required — street, building, house number
    -- address_line2: optional — flat number, floor, landmark
    --   Not everyone has a flat/suite number, so this is NULL.
    -- ---------------------------------------------------------
    address_line1   VARCHAR(255)        NOT NULL,
    address_line2   VARCHAR(255)        NULL DEFAULT NULL,

    -- ---------------------------------------------------------
    -- LOCATION FIELDS
    -- All required — a delivery cannot be made without all four
    -- ---------------------------------------------------------
    city            VARCHAR(100)        NOT NULL,
    state           VARCHAR(100)        NOT NULL,
    postal_code     VARCHAR(20)         NOT NULL,
    country         VARCHAR(100)        NOT NULL DEFAULT 'India',

    -- ---------------------------------------------------------
    -- DEFAULT ADDRESS FLAG
    -- TINYINT(1) = boolean (0 = no, 1 = yes)
    -- is_default = 1 means this address is pre-selected
    --   at checkout so the user doesn't have to pick every time.
    -- Only ONE address per user should have is_default = 1.
    -- This is enforced at the application layer.
    -- ---------------------------------------------------------
    is_default      TINYINT(1)          NOT NULL DEFAULT 0,

    -- ---------------------------------------------------------
    -- TIMESTAMP
    -- We only need created_at here.
    -- Addresses are rarely edited — users usually add new ones.
    -- ---------------------------------------------------------
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- ---------------------------------------------------------
    -- PRIMARY KEY
    -- ---------------------------------------------------------
    CONSTRAINT pk_addresses PRIMARY KEY (address_id),

    -- ---------------------------------------------------------
    -- FOREIGN KEY CONSTRAINT
    -- user_id must exist in the users table.
    -- ON DELETE CASCADE: if user is deleted, delete their addresses.
    -- ON UPDATE CASCADE: if user_id changes (rare), update here too.
    -- ---------------------------------------------------------
    CONSTRAINT fk_addresses_user
        FOREIGN KEY (user_id)
        REFERENCES users (user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Stores shipping and billing addresses for each user';

-- =============================================================
-- INDEXES
--
-- Most common query patterns on this table:
--   1. "Show me all addresses for user X"   → idx on user_id
--   2. "What is user X's default address?"  → idx on user_id + is_default
--   3. "Find all addresses in city Y"       → idx on city (for admin)
-- =============================================================

-- Fetch all addresses for a specific user (most common query)
CREATE INDEX idx_addresses_user_id
    ON addresses (user_id);

-- Find default address for a user quickly at checkout
CREATE INDEX idx_addresses_user_default
    ON addresses (user_id, is_default);

-- Filter by country for region-based shipping rules
CREATE INDEX idx_addresses_country
    ON addresses (country);

-- =============================================================
-- VERIFICATION QUERY
-- =============================================================
DESCRIBE addresses;

-- =============================================================
-- SAMPLE ROWS (mental model — not actual INSERT yet)
--
-- User 1 has two addresses:
--
-- address_id | user_id | type     | full_name      | city      | is_default
-- -----------+---------+----------+----------------+-----------+-----------
--          1 |       1 | both     | Rahul Sharma   | Mumbai    |          1
--          2 |       1 | shipping | Rahul Sharma   | Pune      |          0
--
-- Notice:
--   - Same user_id (1) — two addresses, perfectly valid
--   - Only address_id=1 is the default (is_default=1)
--   - Address 2 is a secondary shipping-only address
-- =============================================================
