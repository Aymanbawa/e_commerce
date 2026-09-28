-- =============================================================
-- FILE: schema/15_wishlist.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Creates the wishlist table
--              Saved products per user (buy later list)
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP TABLE IF EXISTS wishlist;

-- =============================================================
-- TABLE: wishlist
--
-- WHY THIS TABLE EXISTS:
--   Users want to save products they like but aren't ready
--   to buy yet. This is a simple many-to-many join table
--   between users and products.
--
--   It is intentionally minimal — just the relationship
--   and a timestamp. No price stored here because users
--   should see the current live price when they revisit
--   their wishlist (not the price when they saved it).
--
-- RELATIONSHIPS:
--   wishlist → users    (many wishlist items per user)
--   wishlist → products (many users can save same product)
-- =============================================================
CREATE TABLE wishlist (

    wishlist_id     BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,

    -- Which user saved this product
    user_id         BIGINT UNSIGNED     NOT NULL,

    -- Which product was saved
    product_id      BIGINT UNSIGNED     NOT NULL,

    -- When the user added this to their wishlist
    -- Shown as "Added 3 days ago" on the wishlist page
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- ---------------------------------------------------------
    -- CONSTRAINTS
    -- ---------------------------------------------------------
    CONSTRAINT pk_wishlist PRIMARY KEY (wishlist_id),

    -- A user cannot save the same product twice
    -- Attempting to add a duplicate is rejected by MySQL
    CONSTRAINT uq_wishlist_user_product
        UNIQUE (user_id, product_id),

    -- If user is deleted, remove their wishlist
    CONSTRAINT fk_wishlist_user
        FOREIGN KEY (user_id)
        REFERENCES users (user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    -- If product is deleted, remove it from all wishlists
    CONSTRAINT fk_wishlist_product
        FOREIGN KEY (product_id)
        REFERENCES products (product_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'User saved products — simple join table with timestamp';

-- =============================================================
-- INDEXES
-- =============================================================

-- Show all wishlist items for a user
CREATE INDEX idx_wishlist_user_id
    ON wishlist (user_id);

-- Check how many users saved a product (popularity metric)
CREATE INDEX idx_wishlist_product_id
    ON wishlist (product_id);

-- =============================================================
-- VERIFICATION QUERY
-- =============================================================
DESCRIBE wishlist;

-- =============================================================
-- SAMPLE DATA (mental model)
--
-- wishlist_id | user_id | product_id | created_at
-- ------------+---------+------------+---------------------
--           1 |       1 |          1 |  2024-03-01 10:00:00
--           2 |       1 |          3 |  2024-03-05 14:30:00
--           3 |       2 |          1 |  2024-03-10 09:15:00
--
-- User 1 saved iPhone (1) and MacBook (3)
-- User 2 also saved iPhone (1) — popular product
-- =============================================================
