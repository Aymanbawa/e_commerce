-- =============================================================
-- FILE: schema/14_reviews.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Creates the reviews table
--              Product ratings and written reviews by verified buyers
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP TABLE IF EXISTS reviews;

-- =============================================================
-- TABLE: reviews
--
-- WHY THIS TABLE EXISTS:
--   Customer reviews build trust and influence purchase decisions.
--   This table enforces "verified buyer only" reviews — you can
--   only review a product you actually purchased and received.
--
--   The link to order_id proves the reviewer is a real buyer.
--   Without this, anyone could leave fake reviews.
--
-- RELATIONSHIPS:
--   reviews → products  (many reviews per product)
--   reviews → users     (one user writes the review)
--   reviews → orders    (proves the reviewer bought the product)
-- =============================================================
CREATE TABLE reviews (

    review_id       BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,

    -- Which product is being reviewed
    product_id      BIGINT UNSIGNED     NOT NULL,

    -- Who wrote the review
    user_id         BIGINT UNSIGNED     NOT NULL,

    -- Which order proves this is a verified purchase
    order_id        BIGINT UNSIGNED     NOT NULL,

    -- ---------------------------------------------------------
    -- RATING
    -- 1 = worst, 5 = best — the universal star rating system
    -- TINYINT UNSIGNED: small positive integer, perfect for 1-5
    -- CHECK constraint enforces the valid range
    -- ---------------------------------------------------------
    rating          TINYINT UNSIGNED    NOT NULL,

    -- Short headline: "Best phone I've ever bought!"
    title           VARCHAR(255)        NULL DEFAULT NULL,

    -- Full review text — no length limit
    body            TEXT                NULL DEFAULT NULL,

    -- ---------------------------------------------------------
    -- APPROVAL FLAG
    -- New reviews are hidden until an admin approves them.
    -- This prevents spam, offensive content, and fake reviews
    -- from appearing publicly before moderation.
    -- 0 = awaiting approval (default)
    -- 1 = approved and visible to all customers
    -- ---------------------------------------------------------
    is_approved     TINYINT(1)          NOT NULL DEFAULT 0,

    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP
                                        ON UPDATE CURRENT_TIMESTAMP,

    -- ---------------------------------------------------------
    -- CONSTRAINTS
    -- ---------------------------------------------------------
    CONSTRAINT pk_reviews PRIMARY KEY (review_id),

    -- Rating must be between 1 and 5 — no 0s or 6s allowed
    CONSTRAINT chk_reviews_rating
        CHECK (rating BETWEEN 1 AND 5),

    -- One review per product per order — no duplicate reviews
    -- A user cannot review the same product from the same order twice
    CONSTRAINT uq_reviews_product_user_order
        UNIQUE (product_id, user_id, order_id),

    CONSTRAINT fk_reviews_product
        FOREIGN KEY (product_id)
        REFERENCES products (product_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_reviews_user
        FOREIGN KEY (user_id)
        REFERENCES users (user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_reviews_order
        FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Product reviews by verified buyers — requires order proof';

-- =============================================================
-- INDEXES
-- =============================================================

-- All reviews for a product (product detail page)
CREATE INDEX idx_reviews_product_id
    ON reviews (product_id);

-- All reviews by a user (my reviews page)
CREATE INDEX idx_reviews_user_id
    ON reviews (user_id);

-- Only show approved reviews publicly
CREATE INDEX idx_reviews_approved
    ON reviews (product_id, is_approved);

-- Average rating calculation per product
CREATE INDEX idx_reviews_rating
    ON reviews (product_id, rating);

-- =============================================================
-- VERIFICATION QUERY
-- =============================================================
DESCRIBE reviews;
