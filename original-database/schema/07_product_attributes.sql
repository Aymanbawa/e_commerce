-- =============================================================
-- FILE: schema/07_product_attributes.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Creates the product_attributes table
--              Flexible key-value specs per product (EAV pattern)
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

DROP TABLE IF EXISTS product_attributes;

-- =============================================================
-- TABLE: product_attributes
--
-- WHY THIS TABLE EXISTS:
--   Different products have completely different specifications.
--   A phone has: RAM, Storage, Battery, Screen Size, Color
--   A T-shirt has: Size, Color, Material, Fit
--   A book has: Author, Pages, Language, ISBN
--
--   Bad approach — fixed columns on products table:
--     products.color, products.size, products.ram,
--     products.storage, products.author, products.pages...
--     Problem: a book has no RAM. A phone has no author.
--     You end up with hundreds of NULL columns on every row.
--     This is wasteful and breaks every time a new product
--     type is added.
--
--   Good approach — EAV (Entity-Attribute-Value) pattern:
--     One row per attribute. Each row is a key-value pair.
--     Phone gets RAM=8GB, Storage=256GB rows.
--     Book gets Author=Chetan Bhagat, Pages=280 rows.
--     No wasted columns. No schema change for new attributes.
--
-- TRADE-OFF (be honest in interviews):
--   EAV makes it harder to query specific attributes.
--   Searching "all phones with RAM > 8GB" requires more complex
--   SQL than a fixed column would. This is an accepted trade-off
--   for flexible catalogue systems (used by Amazon, Flipkart).
--
-- RELATIONSHIPS:
--   product_attributes → products (many attributes per product)
-- =============================================================
CREATE TABLE product_attributes (

    -- ---------------------------------------------------------
    -- PRIMARY KEY
    -- ---------------------------------------------------------
    attribute_id    BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,

    -- ---------------------------------------------------------
    -- FOREIGN KEY TO PRODUCTS
    -- Every attribute must belong to a real product.
    -- CASCADE: if product deleted, delete its attributes too.
    -- ---------------------------------------------------------
    product_id      BIGINT UNSIGNED     NOT NULL,

    -- ---------------------------------------------------------
    -- ATTRIBUTE NAME (the "key")
    -- What property is being described.
    -- Examples: "Color", "RAM", "Storage", "Size", "Material"
    -- VARCHAR(100) — attribute names are always short
    -- ---------------------------------------------------------
    attribute_name  VARCHAR(100)        NOT NULL,

    -- ---------------------------------------------------------
    -- ATTRIBUTE VALUE (the "value")
    -- The actual spec value for this product.
    -- Examples: "Midnight Blue", "8GB", "256GB", "XL", "Cotton"
    -- VARCHAR(255) — values can be longer (e.g. a color description)
    -- ---------------------------------------------------------
    attribute_value VARCHAR(255)        NOT NULL,

    -- ---------------------------------------------------------
    -- DISPLAY ORDER
    -- Controls the order specs are shown on the product page.
    -- Example: show Color first (0), then RAM (1), then Storage (2)
    -- ---------------------------------------------------------
    sort_order      TINYINT UNSIGNED    NOT NULL DEFAULT 0,

    -- ---------------------------------------------------------
    -- TIMESTAMP
    -- ---------------------------------------------------------
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- ---------------------------------------------------------
    -- CONSTRAINTS
    -- ---------------------------------------------------------
    CONSTRAINT pk_product_attributes PRIMARY KEY (attribute_id),

    -- Prevent duplicate attribute names for the same product.
    -- A phone cannot have two "Color" rows — that is ambiguous.
    -- One product + one attribute name = one unique row.
    CONSTRAINT uq_product_attribute
        UNIQUE (product_id, attribute_name),

    -- FK to products — cascade delete
    CONSTRAINT fk_product_attributes_product
        FOREIGN KEY (product_id)
        REFERENCES products (product_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE

) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_unicode_ci
  COMMENT = 'Flexible key-value product specs using EAV pattern';

-- =============================================================
-- INDEXES
--
-- Query patterns:
--   1. "Show all specs for product X"
--         → WHERE product_id = ?
--   2. "Find all products where Color = Blue"
--         → WHERE attribute_name = 'Color' AND attribute_value = 'Blue'
--   3. "Show specs in display order"
--         → ORDER BY sort_order
-- =============================================================

-- All attributes for a single product (product detail page)
CREATE INDEX idx_product_attributes_product_id
    ON product_attributes (product_id);

-- Filter products by a specific attribute value
-- e.g. all products where RAM = 8GB
CREATE INDEX idx_product_attributes_name_value
    ON product_attributes (attribute_name, attribute_value);

-- =============================================================
-- VERIFICATION QUERY
-- =============================================================
DESCRIBE product_attributes;

-- =============================================================
-- SAMPLE DATA (mental model — actual data comes in seeds/)
--
-- How a phone's specs look in this table:
--
-- attribute_id | product_id | attribute_name | attribute_value | sort_order
-- -------------+------------+----------------+-----------------+-----------
--            1 |          1 | Color          | Natural Titanium |         0
--            2 |          1 | RAM            | 8GB             |         1
--            3 |          1 | Storage        | 256GB           |         2
--            4 |          1 | Battery        | 3274 mAh        |         3
--            5 |          1 | Screen Size    | 6.1 inches      |         4
--
-- How a T-shirt's specs look in the same table:
--
-- attribute_id | product_id | attribute_name | attribute_value | sort_order
-- -------------+------------+----------------+-----------------+-----------
--            6 |          4 | Size           | XL              |         0
--            7 |          4 | Color          | Navy Blue       |         1
--            8 |          4 | Material       | 100% Cotton     |         2
--            9 |          4 | Fit            | Regular Fit     |         3
--
-- Same table structure handles completely different product types.
-- No new columns needed for new product categories — ever.
-- =============================================================
