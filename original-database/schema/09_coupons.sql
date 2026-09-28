-- =============================================================
-- FILE: schema/09_coupons.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Creates the coupons table
--              Discount codes with full validation rules
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP TABLE IF EXISTS coupons;

-- =============================================================
-- TABLE: coupons
--
-- WHY THIS TABLE EXISTS:
--   Discount codes are a core e-commerce feature.
--   Every rule about a coupon lives here — type, value, limits,
--   validity period, usage count. The stored procedure and
--   function use this table to validate and apply discounts.
--
-- RELATIONSHIPS:
--   orders → coupons  (an order may use one coupon)
-- =============================================================
CREATE TABLE coupons (

    coupon_id           BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,

    -- The code customers type in — always stored UPPERCASE
    code                VARCHAR(50)         NOT NULL,

    description         VARCHAR(255)        NULL DEFAULT NULL,

    -- percentage = X% off | fixed_amount = flat ₹X off
    discount_type       ENUM('percentage', 'fixed_amount')
                                            NOT NULL,

    -- The number — e.g. 20 means 20% or ₹20 depending on type
    discount_value      DECIMAL(10, 2)      NOT NULL,

    -- Minimum cart value required to use this coupon
    min_order_amount    DECIMAL(10, 2)      NULL DEFAULT NULL,

    -- Cap on how much can be saved (for percentage coupons)
    -- e.g. 30% off but max ₹500 savings
    max_discount_amount DECIMAL(10, 2)      NULL DEFAULT NULL,

    -- How many times total this code can be used across all users
    -- NULL = unlimited
    usage_limit         INT UNSIGNED        NULL DEFAULT NULL,

    -- Tracks how many times it has been used so far
    usage_count         INT UNSIGNED        NOT NULL DEFAULT 0,

    is_active           TINYINT(1)          NOT NULL DEFAULT 1,

    -- NULL = valid immediately | date = activates on this date
    starts_at           DATETIME            NULL DEFAULT NULL,

    -- NULL = never expires | date = expires on this date
    expires_at          DATETIME            NULL DEFAULT NULL,

    created_at          DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP
                                            ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_coupons PRIMARY KEY (coupon_id),

    CONSTRAINT uq_coupons_code UNIQUE (code),

    CONSTRAINT chk_coupons_discount_value
        CHECK (discount_value > 0),

    -- Percentage discount cannot exceed 100%
    CONSTRAINT chk_coupons_percentage
        CHECK (discount_type != 'percentage' OR discount_value <= 100),

    CONSTRAINT chk_coupons_usage
        CHECK (usage_count <= COALESCE(usage_limit, usage_count + 1))

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Discount coupon codes with usage limits and validity rules';

CREATE INDEX idx_coupons_code
    ON coupons (code);

CREATE INDEX idx_coupons_active_dates
    ON coupons (is_active, starts_at, expires_at);

DESCRIBE coupons;
