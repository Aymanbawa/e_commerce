-- Source commit: ab93963abf1d912dbc2ee424b22d639546f3f3c7
CREATE TABLE users (
user_id         INTEGER PRIMARY KEY AUTOINCREMENT,

    
    
    
    
    
    
    
    email           TEXT COLLATE NOCASE        NOT NULL,
    password_hash   TEXT        NOT NULL,

    
    
    
    
    
    first_name      TEXT        NOT NULL,
    last_name       TEXT        NOT NULL,
    phone           TEXT         NULL,

    
    
    
    
    
    
    
    role TEXT
                                        NOT NULL DEFAULT 'customer',

    
    
    
    
    
    
    
    
    is_verified     INTEGER NOT NULL DEFAULT 0,
    is_active       INTEGER NOT NULL DEFAULT 1,

    
    
    
    
    
    
    
    created_at      TEXT            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TEXT            NOT NULL DEFAULT CURRENT_TIMESTAMP
                                        ,

    
    
    
    
    
    
    
    
    deleted_at      TEXT            NULL DEFAULT NULL,

    
    
    
    

    
    
    
    
    
    CONSTRAINT uq_users_email UNIQUE (email),
    CHECK (role IN ('customer', 'admin'))
);

CREATE INDEX idx_users_email
    ON users (email);

CREATE INDEX idx_users_is_active
    ON users (is_active);

CREATE INDEX idx_users_deleted_at
    ON users (deleted_at);

CREATE INDEX idx_users_role_active
    ON users (role, is_active);

CREATE TRIGGER touch_users AFTER UPDATE ON users WHEN NEW.updated_at = OLD.updated_at BEGIN UPDATE users SET updated_at = CURRENT_TIMESTAMP WHERE user_id = NEW.user_id; END;

CREATE TABLE addresses (
address_id      INTEGER PRIMARY KEY AUTOINCREMENT,

    
    
    
    
    
    
    
    
    
    
    user_id         INTEGER      NOT NULL,

    
    
    
    
    
    
    
    type TEXT
                                        NOT NULL DEFAULT 'both',

    
    
    
    
    
    
    
    
    full_name       TEXT        NOT NULL,
    phone           TEXT         NOT NULL,

    
    
    
    
    
    
    address_line1   TEXT        NOT NULL,
    address_line2   TEXT        NULL DEFAULT NULL,

    
    
    
    
    city            TEXT        NOT NULL,
    state           TEXT        NOT NULL,
    postal_code     TEXT         NOT NULL,
    country         TEXT        NOT NULL DEFAULT 'India',

    
    
    
    
    
    
    
    
    is_default      INTEGER NOT NULL DEFAULT 0,

    
    
    
    
    
    created_at      TEXT            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    
    
    
    

    
    
    
    
    
    
    CONSTRAINT fk_addresses_user
        FOREIGN KEY (user_id)
        REFERENCES users (user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CHECK (type IN ('shipping', 'billing', 'both'))
);

CREATE INDEX idx_addresses_user_id
    ON addresses (user_id);

CREATE INDEX idx_addresses_user_default
    ON addresses (user_id, is_default);

CREATE INDEX idx_addresses_country
    ON addresses (country);

CREATE TABLE categories (
category_id     INTEGER PRIMARY KEY AUTOINCREMENT,

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    parent_id       INTEGER      NULL DEFAULT NULL,

    
    
    
    
    name            TEXT        NOT NULL,

    
    
    
    
    
    
    
    
    
    
    
    slug            TEXT        NOT NULL,

    
    
    
    
    
    description     TEXT                NULL DEFAULT NULL,

    
    
    
    
    
    
    sort_order      INTEGER    NOT NULL DEFAULT 0,

    
    
    
    
    
    
    is_active       INTEGER NOT NULL DEFAULT 1,

    
    
    
    created_at      TEXT            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TEXT            NOT NULL DEFAULT CURRENT_TIMESTAMP
                                        ,

    
    
    
    

    
    CONSTRAINT uq_categories_slug UNIQUE (slug),

    
    
    CONSTRAINT fk_categories_parent
        FOREIGN KEY (parent_id)
        REFERENCES categories (category_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

CREATE INDEX idx_categories_parent_id
    ON categories (parent_id);

CREATE INDEX idx_categories_slug
    ON categories (slug);

CREATE INDEX idx_categories_active
    ON categories (is_active);

CREATE INDEX idx_categories_sort_order
    ON categories (sort_order);

CREATE TRIGGER touch_categories AFTER UPDATE ON categories WHEN NEW.updated_at = OLD.updated_at BEGIN UPDATE categories SET updated_at = CURRENT_TIMESTAMP WHERE category_id = NEW.category_id; END;

CREATE TABLE brands (
brand_id        INTEGER PRIMARY KEY AUTOINCREMENT,

    
    
    
    
    name            TEXT        NOT NULL,

    
    
    
    
    
    slug            TEXT        NOT NULL,

    
    
    
    
    
    
    
    logo_url        TEXT        NULL DEFAULT NULL,

    
    
    
    
    
    website_url     TEXT        NULL DEFAULT NULL,

    
    
    
    
    
    description     TEXT                NULL DEFAULT NULL,

    
    
    
    
    
    
    is_active       INTEGER NOT NULL DEFAULT 1,

    
    
    
    created_at      TEXT            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TEXT            NOT NULL DEFAULT CURRENT_TIMESTAMP
                                        ,

    
    
    
    

    CONSTRAINT uq_brands_name UNIQUE (name),

    CONSTRAINT uq_brands_slug UNIQUE (slug)
);

CREATE INDEX idx_brands_slug
    ON brands (slug);

CREATE INDEX idx_brands_is_active
    ON brands (is_active);

CREATE TRIGGER touch_brands AFTER UPDATE ON brands WHEN NEW.updated_at = OLD.updated_at BEGIN UPDATE brands SET updated_at = CURRENT_TIMESTAMP WHERE brand_id = NEW.brand_id; END;

CREATE TABLE products (
product_id      INTEGER PRIMARY KEY AUTOINCREMENT,

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    category_id     INTEGER      NOT NULL,
    brand_id        INTEGER      NULL DEFAULT NULL,

    
    
    
    
    
    
    
    name            TEXT        NOT NULL,
    slug            TEXT        NOT NULL,
    sku             TEXT        NOT NULL,

    
    
    
    
    
    description     TEXT                NULL DEFAULT NULL,
    short_desc      TEXT        NULL DEFAULT NULL,

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    price           NUMERIC      NOT NULL,
    compare_price   NUMERIC      NULL DEFAULT NULL,
    cost_price      NUMERIC      NULL DEFAULT NULL,

    
    
    
    
    
    
    
    
    
    
    
    
    status TEXT
                                        NOT NULL DEFAULT 'draft',

    
    
    
    
    
    is_featured     INTEGER NOT NULL DEFAULT 0,

    
    
    
    
    
    
    weight_grams    INTEGER         NULL DEFAULT NULL,

    
    
    
    
    
    
    
    
    
    
    
    created_at      TEXT            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TEXT            NOT NULL DEFAULT CURRENT_TIMESTAMP
                                        ,
    deleted_at      TEXT            NULL DEFAULT NULL,

    
    
    
    

    CONSTRAINT uq_products_slug UNIQUE (slug),

    CONSTRAINT uq_products_sku  UNIQUE (sku),

    
    CONSTRAINT chk_products_price
        CHECK (price > 0),

    
    
    CONSTRAINT chk_products_compare_price
        CHECK (compare_price IS NULL OR compare_price > price),

    
    CONSTRAINT chk_products_cost_price
        CHECK (cost_price IS NULL OR cost_price > 0),

    
    
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id)
        REFERENCES categories (category_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    
    
    CONSTRAINT fk_products_brand
        FOREIGN KEY (brand_id)
        REFERENCES brands (brand_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    CHECK (status IN ('draft', 'active', 'inactive', 'archived'))
);

CREATE INDEX idx_products_category_id
    ON products (category_id);

CREATE INDEX idx_products_brand_id
    ON products (brand_id);

CREATE INDEX idx_products_status_deleted
    ON products (status, deleted_at);

CREATE INDEX idx_products_featured
    ON products (is_featured, status);

CREATE INDEX idx_products_price
    ON products (price);

CREATE INDEX idx_products_slug
    ON products (slug);

CREATE TRIGGER touch_products AFTER UPDATE ON products WHEN NEW.updated_at = OLD.updated_at BEGIN UPDATE products SET updated_at = CURRENT_TIMESTAMP WHERE product_id = NEW.product_id; END;

CREATE TABLE product_images (
image_id        INTEGER PRIMARY KEY AUTOINCREMENT,

    
    
    
    
    
    
    product_id      INTEGER      NOT NULL,

    
    
    
    
    
    
    
    
    image_url       TEXT        NOT NULL,

    
    
    
    
    
    
    
    
    
    alt_text        TEXT        NULL DEFAULT NULL,

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    sort_order      INTEGER     NOT NULL DEFAULT 0,

    
    
    
    
    
    
    
    
    
    is_primary      INTEGER NOT NULL DEFAULT 0,

    
    
    
    
    created_at      TEXT            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    
    
    
    

    
    
    CONSTRAINT fk_product_images_product
        FOREIGN KEY (product_id)
        REFERENCES products (product_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE INDEX idx_product_images_product_id
    ON product_images (product_id);

CREATE INDEX idx_product_images_primary
    ON product_images (product_id, is_primary);

CREATE INDEX idx_product_images_sort
    ON product_images (product_id, sort_order);

CREATE TABLE product_attributes (
attribute_id    INTEGER PRIMARY KEY AUTOINCREMENT,

    
    
    
    
    
    product_id      INTEGER      NOT NULL,

    
    
    
    
    
    
    attribute_name  TEXT        NOT NULL,

    
    
    
    
    
    
    attribute_value TEXT        NOT NULL,

    
    
    
    
    
    sort_order      INTEGER     NOT NULL DEFAULT 0,

    
    
    
    created_at      TEXT            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    
    
    
    

    
    
    
    CONSTRAINT uq_product_attribute
        UNIQUE (product_id, attribute_name),

    
    CONSTRAINT fk_product_attributes_product
        FOREIGN KEY (product_id)
        REFERENCES products (product_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE INDEX idx_product_attributes_product_id
    ON product_attributes (product_id);

CREATE INDEX idx_product_attributes_name_value
    ON product_attributes (attribute_name, attribute_value);

CREATE TABLE inventory (
inventory_id        INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id          INTEGER  NOT NULL,

    
    quantity_in_stock   INTEGER     NOT NULL DEFAULT 0,

    
    quantity_reserved   INTEGER     NOT NULL DEFAULT 0,

    
    reorder_threshold   INTEGER     NOT NULL DEFAULT 10,

    updated_at          TEXT        NOT NULL DEFAULT CURRENT_TIMESTAMP
                                        ,

    

    
    CONSTRAINT uq_inventory_product UNIQUE (product_id),

    
    CONSTRAINT chk_inventory_stock
        CHECK (quantity_in_stock >= 0),

    CONSTRAINT chk_inventory_reserved
        CHECK (quantity_reserved >= 0),

    
    CONSTRAINT chk_inventory_reserved_lte_stock
        CHECK (quantity_reserved <= quantity_in_stock),

    CONSTRAINT fk_inventory_product
        FOREIGN KEY (product_id)
        REFERENCES products (product_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE INDEX idx_inventory_product_id
    ON inventory (product_id);

CREATE INDEX idx_inventory_stock_level
    ON inventory (quantity_in_stock, reorder_threshold);

CREATE TRIGGER touch_inventory AFTER UPDATE ON inventory WHEN NEW.updated_at = OLD.updated_at BEGIN UPDATE inventory SET updated_at = CURRENT_TIMESTAMP WHERE inventory_id = NEW.inventory_id; END;

CREATE TABLE coupons (
coupon_id           INTEGER PRIMARY KEY AUTOINCREMENT,

    
    code                TEXT         NOT NULL,

    description         TEXT        NULL DEFAULT NULL,

    
    discount_type TEXT
                                            NOT NULL,

    
    discount_value      NUMERIC      NOT NULL,

    
    min_order_amount    NUMERIC      NULL DEFAULT NULL,

    
    
    max_discount_amount NUMERIC      NULL DEFAULT NULL,

    
    
    usage_limit         INTEGER         NULL DEFAULT NULL,

    
    usage_count         INTEGER         NOT NULL DEFAULT 0,

    is_active           INTEGER NOT NULL DEFAULT 1,

    
    starts_at           TEXT            NULL DEFAULT NULL,

    
    expires_at          TEXT            NULL DEFAULT NULL,

    created_at          TEXT            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TEXT            NOT NULL DEFAULT CURRENT_TIMESTAMP
                                            ,

    

    CONSTRAINT uq_coupons_code UNIQUE (code),

    CONSTRAINT chk_coupons_discount_value
        CHECK (discount_value > 0),

    
    CONSTRAINT chk_coupons_percentage
        CHECK (discount_type != 'percentage' OR discount_value <= 100),

    CONSTRAINT chk_coupons_usage
        CHECK (usage_count <= COALESCE(usage_limit, usage_count + 1)),
    CHECK (discount_type IN ('percentage', 'fixed_amount'))
);

CREATE INDEX idx_coupons_code
    ON coupons (code);

CREATE INDEX idx_coupons_active_dates
    ON coupons (is_active, starts_at, expires_at);

CREATE TRIGGER touch_coupons AFTER UPDATE ON coupons WHEN NEW.updated_at = OLD.updated_at BEGIN UPDATE coupons SET updated_at = CURRENT_TIMESTAMP WHERE coupon_id = NEW.coupon_id; END;

CREATE TABLE orders (
order_id        INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id         INTEGER      NOT NULL,
    address_id      INTEGER      NOT NULL,
    coupon_id       INTEGER      NULL DEFAULT NULL,

    
    
    order_number    TEXT         NOT NULL,

    
    status TEXT                   NOT NULL DEFAULT 'pending',

    
    subtotal        NUMERIC      NOT NULL,
    discount_amount NUMERIC      NOT NULL DEFAULT 0.00,
    tax_amount      NUMERIC      NOT NULL DEFAULT 0.00,
    shipping_amount NUMERIC      NOT NULL DEFAULT 0.00,

    
    total_amount    NUMERIC      NOT NULL,

    
    notes           TEXT                NULL DEFAULT NULL,

    created_at      TEXT            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TEXT            NOT NULL DEFAULT CURRENT_TIMESTAMP
                                        ,

    

    CONSTRAINT uq_orders_number UNIQUE (order_number),

    
    CONSTRAINT chk_orders_total
        CHECK (total_amount > 0),

    
    CONSTRAINT chk_orders_discount
        CHECK (discount_amount >= 0 AND discount_amount <= subtotal),

    CONSTRAINT fk_orders_user
        FOREIGN KEY (user_id)
        REFERENCES users (user_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_orders_address
        FOREIGN KEY (address_id)
        REFERENCES addresses (address_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_orders_coupon
        FOREIGN KEY (coupon_id)
        REFERENCES coupons (coupon_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    CHECK (status IN (
                        'pending',      
                        'confirmed',    
                        'processing',   
                        'shipped',      
                        'delivered',    
                        'cancelled',    
                        'refunded'      
                    ))
);

CREATE INDEX idx_orders_user_id
    ON orders (user_id);

CREATE INDEX idx_orders_status
    ON orders (status);

CREATE INDEX idx_orders_created_at
    ON orders (created_at);

CREATE INDEX idx_orders_order_number
    ON orders (order_number);

CREATE INDEX idx_orders_user_status
    ON orders (user_id, status);

CREATE TRIGGER touch_orders AFTER UPDATE ON orders WHEN NEW.updated_at = OLD.updated_at BEGIN UPDATE orders SET updated_at = CURRENT_TIMESTAMP WHERE order_id = NEW.order_id; END;

CREATE TABLE order_items (
item_id         INTEGER PRIMARY KEY AUTOINCREMENT,

    
    order_id        INTEGER      NOT NULL,

    
    product_id      INTEGER      NOT NULL,

    
    
    
    
    
    product_name    TEXT        NOT NULL,
    product_sku     TEXT        NOT NULL,

    
    quantity        INTEGER         NOT NULL,

    
    unit_price      NUMERIC      NOT NULL,

    
    
    total_price     NUMERIC      NOT NULL,

    created_at      TEXT            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    
    
    
    

    
    CONSTRAINT chk_order_items_quantity
        CHECK (quantity > 0),

    
    CONSTRAINT chk_order_items_unit_price
        CHECK (unit_price > 0),

    
    CONSTRAINT chk_order_items_total
        CHECK (ABS(total_price - quantity * unit_price) < 0.005),

    
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    
    
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES products (product_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE INDEX idx_order_items_order_id
    ON order_items (order_id);

CREATE INDEX idx_order_items_product_id
    ON order_items (product_id);

CREATE TABLE payments (
payment_id          INTEGER PRIMARY KEY AUTOINCREMENT,

    
    order_id            INTEGER      NOT NULL,

    
    
    
    
    
    
    payment_method TEXT                   NOT NULL,

    
    
    
    
    
    
    
    payment_status TEXT                   NOT NULL DEFAULT 'pending',

    
    amount              NUMERIC      NOT NULL,

    
    
    currency            TEXT             NOT NULL DEFAULT 'INR',

    
    
    
    
    
    
    
    
    
    
    
    transaction_id      TEXT        NULL DEFAULT NULL,
    gateway_response    TEXT                NULL DEFAULT NULL,

    
    
    paid_at             TEXT            NULL DEFAULT NULL,

    created_at          TEXT            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TEXT            NOT NULL DEFAULT CURRENT_TIMESTAMP
                                            ,

    
    
    
    

    
    CONSTRAINT chk_payments_amount
        CHECK (amount > 0),

    
    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CHECK (payment_method IN (
                            'credit_card',
                            'debit_card',
                            'upi',
                            'net_banking',
                            'wallet',
                            'cod'               
                        )),
    CHECK (payment_status IN (
                            'pending',
                            'completed',
                            'failed',
                            'refunded'
                        ))
);

CREATE INDEX idx_payments_order_id
    ON payments (order_id);

CREATE INDEX idx_payments_transaction_id
    ON payments (transaction_id);

CREATE INDEX idx_payments_status
    ON payments (payment_status);

CREATE INDEX idx_payments_paid_at
    ON payments (paid_at);

CREATE TRIGGER touch_payments AFTER UPDATE ON payments WHEN NEW.updated_at = OLD.updated_at BEGIN UPDATE payments SET updated_at = CURRENT_TIMESTAMP WHERE payment_id = NEW.payment_id; END;

CREATE TABLE shipments (
shipment_id         INTEGER PRIMARY KEY AUTOINCREMENT,

    
    order_id            INTEGER      NOT NULL,

    
    
    
    
    
    
    
    tracking_number     TEXT        NULL DEFAULT NULL,
    courier_name        TEXT        NULL DEFAULT NULL,

    
    
    
    
    
    
    
    
    
    
    status TEXT                   NOT NULL DEFAULT 'preparing',

    
    estimated_delivery  TEXT                NULL DEFAULT NULL,

    
    
    delivered_at        TEXT            NULL DEFAULT NULL,

    created_at          TEXT            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          TEXT            NOT NULL DEFAULT CURRENT_TIMESTAMP
                                            ,

    
    
    
    

    
    CONSTRAINT fk_shipments_order
        FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CHECK (status IN (
                            'preparing',
                            'dispatched',
                            'in_transit',
                            'out_for_delivery',
                            'delivered',
                            'returned'
                        ))
);

CREATE INDEX idx_shipments_order_id
    ON shipments (order_id);

CREATE INDEX idx_shipments_tracking
    ON shipments (tracking_number);

CREATE INDEX idx_shipments_status
    ON shipments (status);

CREATE TRIGGER touch_shipments AFTER UPDATE ON shipments WHEN NEW.updated_at = OLD.updated_at BEGIN UPDATE shipments SET updated_at = CURRENT_TIMESTAMP WHERE shipment_id = NEW.shipment_id; END;

CREATE TABLE reviews (
review_id       INTEGER PRIMARY KEY AUTOINCREMENT,

    
    product_id      INTEGER      NOT NULL,

    
    user_id         INTEGER      NOT NULL,

    
    order_id        INTEGER      NOT NULL,

    
    
    
    
    
    
    rating          INTEGER     NOT NULL,

    
    title           TEXT        NULL DEFAULT NULL,

    
    body            TEXT                NULL DEFAULT NULL,

    
    
    
    
    
    
    
    
    is_approved     INTEGER NOT NULL DEFAULT 0,

    created_at      TEXT            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TEXT            NOT NULL DEFAULT CURRENT_TIMESTAMP
                                        ,

    
    
    
    

    
    CONSTRAINT chk_reviews_rating
        CHECK (rating BETWEEN 1 AND 5),

    
    
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
);

CREATE INDEX idx_reviews_product_id
    ON reviews (product_id);

CREATE INDEX idx_reviews_user_id
    ON reviews (user_id);

CREATE INDEX idx_reviews_approved
    ON reviews (product_id, is_approved);

CREATE INDEX idx_reviews_rating
    ON reviews (product_id, rating);

CREATE TRIGGER touch_reviews AFTER UPDATE ON reviews WHEN NEW.updated_at = OLD.updated_at BEGIN UPDATE reviews SET updated_at = CURRENT_TIMESTAMP WHERE review_id = NEW.review_id; END;

CREATE TABLE wishlist (
wishlist_id     INTEGER PRIMARY KEY AUTOINCREMENT,

    
    user_id         INTEGER      NOT NULL,

    
    product_id      INTEGER      NOT NULL,

    
    
    created_at      TEXT            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    
    
    
    

    
    
    CONSTRAINT uq_wishlist_user_product
        UNIQUE (user_id, product_id),

    
    CONSTRAINT fk_wishlist_user
        FOREIGN KEY (user_id)
        REFERENCES users (user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    
    CONSTRAINT fk_wishlist_product
        FOREIGN KEY (product_id)
        REFERENCES products (product_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE INDEX idx_wishlist_user_id
    ON wishlist (user_id);

CREATE INDEX idx_wishlist_product_id
    ON wishlist (product_id);

CREATE TABLE audit_log (
log_id          INTEGER PRIMARY KEY AUTOINCREMENT,

    
    table_name      TEXT        NOT NULL,

    
    record_id       INTEGER      NOT NULL,

    
    action TEXT
                                        NOT NULL,

    
    
    
    changed_by      INTEGER      NULL DEFAULT NULL,

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    old_values      TEXT                NULL DEFAULT NULL,
    new_values      TEXT                NULL DEFAULT NULL,

    
    changed_at      TEXT            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CHECK (action IN ('INSERT', 'UPDATE', 'DELETE'))
);

CREATE INDEX idx_audit_table_name
    ON audit_log (table_name);

CREATE INDEX idx_audit_table_record
    ON audit_log (table_name, record_id);

CREATE INDEX idx_audit_changed_by
    ON audit_log (changed_by);

CREATE INDEX idx_audit_changed_at
    ON audit_log (changed_at);

INSERT INTO users
    (email, password_hash, first_name, last_name, phone, role, is_verified, is_active)
VALUES
    ('admin@shopease.com',   '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/lfLJM5vQr5EsMSYSi', 'Admin',   'User',    '9000000001', 'admin',    1, 1),
    ('rahul.sharma@email.com','$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/lfLJM5vQr5EsMSYSi', 'Rahul',   'Sharma',  '9811234567', 'customer', 1, 1),
    ('priya.mehta@email.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/lfLJM5vQr5EsMSYSi', 'Priya',   'Mehta',   '9822345678', 'customer', 1, 1),
    ('arjun.verma@email.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/lfLJM5vQr5EsMSYSi', 'Arjun',   'Verma',   '9833456789', 'customer', 1, 1),
    ('sneha.patel@email.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/lfLJM5vQr5EsMSYSi', 'Sneha',   'Patel',   '9844567890', 'customer', 0, 1),
    ('karan.gupta@email.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/lfLJM5vQr5EsMSYSi', 'Karan',   'Gupta',   NULL,         'customer', 1, 1),
    ('nisha.joshi@email.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/lfLJM5vQr5EsMSYSi', 'Nisha',   'Joshi',   '9866789012', 'customer', 1, 0);

INSERT INTO addresses
    (user_id, type, full_name, phone, address_line1, address_line2, city, state, postal_code, country, is_default)
VALUES
    (2, 'both',     'Rahul Sharma',  '9811234567', '42 MG Road',          'Flat 3B',    'Mumbai',    'Maharashtra', '400001', 'India', 1),
    (2, 'shipping', 'Rahul Sharma',  '9811234567', '7 Bandra West',       NULL,          'Mumbai',    'Maharashtra', '400050', 'India', 0),
    (3, 'both',     'Priya Mehta',   '9822345678', '15 Koramangala',      'Block 5',    'Bengaluru', 'Karnataka',   '560034', 'India', 1),
    (4, 'both',     'Arjun Verma',   '9833456789', '88 Sector 18',        NULL,          'Noida',     'Uttar Pradesh','201301','India',1),
    (5, 'shipping', 'Sneha Patel',   '9844567890', '23 Ashram Road',      'Near Lake',  'Ahmedabad', 'Gujarat',     '380009', 'India', 1),
    (6, 'both',     'Karan Gupta',   '9855678901', '11 Park Street',      '2nd Floor',  'Kolkata',   'West Bengal', '700016', 'India', 1);

INSERT INTO categories (parent_id, name, slug, description, sort_order, is_active) VALUES
    (NULL, 'Electronics',    'electronics',    'Gadgets, devices and tech accessories',     1, 1),
    (NULL, 'Clothing',       'clothing',       'Fashion for men, women and kids',           2, 1),
    (NULL, 'Books',          'books',          'Fiction, non-fiction, textbooks and more',  3, 1),
    (NULL, 'Home & Kitchen', 'home-kitchen',   'Appliances, furniture and kitchen tools',   4, 1),
    (NULL, 'Sports',         'sports',         'Equipment, clothing and accessories',       5, 1);

INSERT INTO categories (parent_id, name, slug, description, sort_order, is_active) VALUES
    (1, 'Mobile Phones',    'mobile-phones',   'Smartphones and feature phones',    1, 1),
    (1, 'Laptops',          'laptops',         'Notebooks and ultrabooks',          2, 1),
    (1, 'Audio',            'audio',           'Headphones, earbuds and speakers',  3, 1),
    (2, 'Men''s Clothing',  'mens-clothing',   'Shirts, jeans, jackets and more',   1, 1),
    (2, 'Women''s Clothing','womens-clothing',  'Dresses, tops, sarees and more',    2, 1),
    (3, 'Fiction',          'fiction',         'Novels and short stories',          1, 1),
    (3, 'Self Help',        'self-help',       'Personal development and mindset',  2, 1),
    (4, 'Kitchen Appliances','kitchen-appliances','Mixers, ovens and more',         1, 1);

INSERT INTO categories (parent_id, name, slug, description, sort_order, is_active) VALUES
    (6, 'Smartphones',   'smartphones',   'Android and iOS smartphones', 1, 1),
    (6, 'Feature Phones','feature-phones','Basic calling phones',        2, 1),
    (8, 'Earbuds',       'earbuds',       'True wireless earbuds',       1, 1),
    (8, 'Over-ear Headphones','over-ear-headphones','Studio and gaming headphones', 2, 1),
    (9, 'T-Shirts',      't-shirts',      'Casual and formal tees',      1, 1),
    (9, 'Jeans',         'jeans',         'Slim, straight and bootcut',  2, 1);

INSERT INTO brands (name, slug, website_url, description, is_active) VALUES
    ('Apple',         'apple',         'https://www.apple.com',      'Premium consumer electronics and software',     1),
    ('Samsung',       'samsung',       'https://www.samsung.com',    'Global leader in electronics and displays',     1),
    ('Sony',          'sony',          'https://www.sony.com',       'Audio, gaming and consumer electronics',        1),
    ('Nike',          'nike',          'https://www.nike.com',       'Athletic footwear, apparel and equipment',      1),
    ('Adidas',        'adidas',        'https://www.adidas.com',     'Sports and lifestyle brand',                    1),
    ('boAt',          'boat',          'https://www.boat-lifestyle.com','Affordable audio and accessories for India', 1),
    ('Levi''s',       'levis',         'https://www.levi.com',       'Iconic denim and casual wear',                  1),
    ('Penguin Books', 'penguin-books', 'https://www.penguin.co.in',  'Leading book publisher worldwide',              1),
    ('Lenovo',        'lenovo',        'https://www.lenovo.com',     'Laptops, tablets and enterprise hardware',      1),
    ('OnePlus',       'oneplus',       'https://www.oneplus.in',     'Premium Android smartphones',                   1);

INSERT INTO products
    (category_id, brand_id, name, slug, sku, short_desc, description, price, compare_price, cost_price, status, is_featured, weight_grams)
VALUES

(14, 1,  'iPhone 15 Pro',          'iphone-15-pro',          'APL-IP15P-256',  'A17 Pro chip, titanium design, 48MP camera',                    'The iPhone 15 Pro features the A17 Pro chip built on 3nm technology, a titanium frame, and a 48MP main camera system.',  134900.00, NULL,       95000.00, 'active', 1, 187),
(14, 2,  'Samsung Galaxy S24',     'samsung-galaxy-s24',     'SAM-S24-256',    '6.2" Dynamic AMOLED, Snapdragon 8 Gen 3',                       'The Galaxy S24 brings AI-powered features, a bright AMOLED display, and Snapdragon 8 Gen 3 for powerful performance.',       79999.00, 89999.00,  55000.00, 'active', 1, 167),
(14, 10, 'OnePlus 12',             'oneplus-12',             'OP-12-256',      'Snapdragon 8 Gen 3, 50MP Hasselblad camera, 100W charging',     'OnePlus 12 packs flagship performance with Snapdragon 8 Gen 3, Hasselblad-tuned cameras, and 100W SUPERVOOC charging.',      64999.00, 69999.00,  42000.00, 'active', 0, 220),
(14, 2,  'Samsung Galaxy A55',     'samsung-galaxy-a55',     'SAM-A55-128',    'Mid-range with OIS camera and 6.6" AMOLED display',             'Great everyday performance with a 6.6-inch AMOLED display, OIS camera, and long battery life.',                             37999.00, 41999.00,  25000.00, 'active', 0, 213),


(7,  1,  'MacBook Air M3 13"',     'macbook-air-m3-13',      'APL-MBA-M3-13',  'M3 chip, 8GB RAM, 256GB SSD, 18hr battery',                    'Supercharged by M3, MacBook Air delivers exceptional performance in an incredibly thin design with up to 18 hours of battery.', 114900.00, NULL,       82000.00, 'active', 1, 1240),
(7,  9,  'Lenovo IdeaPad Slim 5',  'lenovo-ideapad-slim5',   'LEN-IPS5-512',   'AMD Ryzen 5 7530U, 16GB RAM, 512GB SSD',                       'A well-rounded laptop for students and professionals with AMD Ryzen 5, 16GB RAM, and 512GB fast SSD storage.',                 62990.00, 71990.00,  42000.00, 'active', 0, 1560),


(16, 6,  'boAt Airdopes 141',      'boat-airdopes-141',      'BOT-AD141-BLK',  'Bluetooth 5.1, 42hr total playback, IPX4 rated',               'Truly wireless earbuds with 6mm drivers, Bluetooth 5.1, 42 hours total playback, and IPX4 sweat resistance.',                 1299.00,  1999.00,    650.00, 'active', 0, 38),
(16, 3,  'Sony WF-1000XM5',        'sony-wf-1000xm5',        'SNY-WF1000XM5', 'Industry-leading ANC, 24hr battery, LDAC support',             'Sony''s flagship TWS earbuds with best-in-class noise cancellation, LDAC hi-res audio, and up to 24 hours total battery.',    24990.00, 28990.00,  16000.00, 'active', 1, 50),
(16, 1,  'AirPods Pro 2nd Gen',    'airpods-pro-2nd-gen',    'APL-APP2-WHT',   'H2 chip, adaptive ANC, 30hr total with case',                  'AirPods Pro with the H2 chip deliver 2x more Active Noise Cancellation, Adaptive Transparency, and Personalized Spatial Audio.', 24900.00, NULL,       17000.00, 'active', 1, 50),


(9,  4,  'Nike Dri-FIT T-Shirt',   'nike-dri-fit-tshirt',   'NK-DFIT-TEE-M',  'Moisture-wicking fabric, regular fit, multiple colours',       'The Nike Dri-FIT technology moves sweat away from your body to help keep you dry and comfortable throughout your workout.',       1995.00,  2495.00,     900.00, 'active', 0, 180),
(9,  5,  'Adidas Essentials Tee',  'adidas-essentials-tee', 'ADI-ESS-TEE-M',  '100% cotton, embroidered logo, relaxed fit',                   'A classic everyday tee made from soft cotton with the iconic 3-Stripes on the sleeves and embroidered Adidas logo.',              1499.00,  NULL,        700.00, 'active', 0, 175),


(19, 7,  'Levi''s 511 Slim Jeans', 'levis-511-slim-jeans',  'LEV-511-SLIM-32','Slim fit below waist, sits lower on the waist',               'Levi''s 511 Slim jeans sit below the waist with a slim leg from hip to ankle. Made with a touch of stretch for all-day comfort.',  3499.00,  4499.00,    1800.00, 'active', 0, 650),


(11, 8,  'Atomic Habits',          'atomic-habits',          'BK-ATOMHAB-EN',  'James Clear — Build good habits and break bad ones',           'Atomic Habits is a practical guide to breaking bad behaviours and adopting good ones. Tiny changes lead to remarkable results.',    599.00,   799.00,     200.00, 'active', 1, 250),
(11, 8,  'The Psychology of Money','psychology-of-money',   'BK-PSYMNY-EN',   'Morgan Housel — Timeless lessons on wealth and greed',         'Doing well with money isn''t necessarily about what you know. It''s about how you behave. Morgan Housel explains with 19 stories.',  499.00,   699.00,     175.00, 'active', 0, 230),
(11, 8,  'Rich Dad Poor Dad',      'rich-dad-poor-dad',     'BK-RCHDD-EN',    'Robert Kiyosaki — What the rich teach their kids about money', 'Rich Dad Poor Dad is about Robert Kiyosaki and his two dads — his real father and the father of his best friend — and how both men shaped his thoughts about money.',  399.00,   499.00,     150.00, 'active', 0, 220),


(13, NULL,'Prestige Iris 750W Mixer','prestige-iris-750-mixer','PRE-IRIS750',  '3 jars, 750W motor, 5-year warranty',                          'The Prestige Iris mixer grinder comes with a 750W copper motor, 3 stainless steel jars, and a 5-year motor warranty.',           3299.00,  3999.00,    1900.00, 'active', 0, 2800),


(5,  4,  'Nike Air Max 90',        'nike-air-max-90',        'NK-AM90-WHT-9',  'Iconic cushioning, classic silhouette, durable sole',           'The Nike Air Max 90 stays true to its OG roots with the iconic Waffle outsole, stitched overlays, and classic Max Air cushioning.',  8995.00,  10995.00,   5000.00, 'active', 1, 420),
(5,  5,  'Adidas Ultraboost 22',   'adidas-ultraboost-22',  'ADI-UB22-BLK-9', 'Responsive BOOST midsole, Primeknit+ upper',                   'The Adidas Ultraboost 22 running shoe features a Primeknit+ upper and BOOST midsole for ultimate energy return.',                9999.00,  12999.00,   6000.00, 'active', 0, 390),


(14, 1,  'iPhone 15 Pro Max',      'iphone-15-pro-max',     'APL-IP15PM-512', 'Coming soon — 512GB, 5× optical zoom',                         'The most powerful iPhone ever made.',                                                                                          159900.00, NULL,      115000.00, 'draft',  0, 221);

INSERT INTO product_images (product_id, image_url, alt_text, sort_order, is_primary) VALUES
    (1,  'https://cdn.shopease.in/products/iphone-15-pro-front.jpg',    'iPhone 15 Pro front view in Natural Titanium', 0, 1),
    (1,  'https://cdn.shopease.in/products/iphone-15-pro-back.jpg',     'iPhone 15 Pro rear camera system',             1, 0),
    (2,  'https://cdn.shopease.in/products/samsung-s24-front.jpg',      'Samsung Galaxy S24 front view',                0, 1),
    (3,  'https://cdn.shopease.in/products/oneplus-12-front.jpg',       'OnePlus 12 front view',                        0, 1),
    (5,  'https://cdn.shopease.in/products/macbook-air-m3.jpg',         'MacBook Air M3 open on desk',                  0, 1),
    (7,  'https://cdn.shopease.in/products/boat-airdopes-141.jpg',      'boAt Airdopes 141 in charging case',           0, 1),
    (8,  'https://cdn.shopease.in/products/sony-wf1000xm5.jpg',        'Sony WF-1000XM5 in case',                      0, 1),
    (9,  'https://cdn.shopease.in/products/airpods-pro-2.jpg',         'AirPods Pro 2nd gen with MagSafe case',        0, 1),
    (13, 'https://cdn.shopease.in/products/atomic-habits.jpg',         'Atomic Habits book cover',                     0, 1),
    (17, 'https://cdn.shopease.in/products/nike-air-max-90.jpg',       'Nike Air Max 90 white colourway',              0, 1);

INSERT INTO product_attributes (product_id, attribute_name, attribute_value, sort_order) VALUES
    
    (1, 'Color',        'Natural Titanium', 0),
    (1, 'RAM',          '8GB',              1),
    (1, 'Storage',      '256GB',            2),
    (1, 'Chip',         'A17 Pro',          3),
    (1, 'Battery',      '3274 mAh',         4),
    (1, 'Screen Size',  '6.1 inches',       5),
    
    (2, 'Color',        'Phantom Black',    0),
    (2, 'RAM',          '8GB',              1),
    (2, 'Storage',      '256GB',            2),
    (2, 'Processor',    'Snapdragon 8 Gen 3', 3),
    
    (7, 'Color',            'Black',        0),
    (7, 'Connectivity',     'Bluetooth 5.1',1),
    (7, 'Battery Life',     '42 Hours',     2),
    (7, 'Water Resistance', 'IPX4',         3),
    
    (10,'Size',         'M',                0),
    (10,'Color',        'White',            1),
    (10,'Material',     '100% Polyester',   2),
    (10,'Fit',          'Regular Fit',      3);

INSERT INTO inventory (product_id, quantity_in_stock, quantity_reserved, reorder_threshold)
VALUES

    (1,          45,       3,        10),   
    (2,          80,       5,        15),   
    (3,          60,       2,        10),   
    (4,          120,      8,        20),   
    (5,          30,       1,        5),    
    (6,          55,       4,        10),   
    (7,          200,      12,       30),   
    (8,          25,       2,        5),    
    (9,          40,       3,        10),   
    (10,         150,      0,        25),   
    (11,         180,      6,        30),   
    (12,         90,       4,        15),   
    (13,         500,      10,       50),   
    (14,         400,      8,        40),   
    (15,         350,      5,        35),   
    (16,         35,       2,        10),   
    (17,         70,       6,        15),   
    (18,         85,       7,        15),   
    (19,         0,        0,        10);

INSERT INTO coupons
    (code, description, discount_type, discount_value, min_order_amount, max_discount_amount, usage_limit, usage_count, is_active, starts_at, expires_at)
VALUES

('WELCOME10',  'New user welcome discount — 10% off',          'percentage',   10,    500,   200,   1000, 45,  1, '2024-01-01 00:00:00', '2025-12-31 23:59:59'),
('SAVE200',    'Flat ₹200 off on orders above ₹1000',          'fixed_amount', 200,   1000,  NULL,  500,  87,  1, '2024-01-01 00:00:00', '2025-06-30 23:59:59'),
('TECH15',     '15% off on electronics — max ₹1500 discount',  'percentage',   15,    2000,  1500,  NULL, 23,  1, '2024-03-01 00:00:00', '2025-03-31 23:59:59'),
('FLAT500',    'Flat ₹500 off on orders above ₹5000',          'fixed_amount', 500,   5000,  NULL,  200,  61,  1, '2024-02-01 00:00:00', '2025-08-31 23:59:59'),
('BOOKWORM20', '20% off all books — max ₹100',                 'percentage',   20,    NULL,  100,   NULL, 12,  1, '2024-01-01 00:00:00', NULL),              
('FREESHIP',   'Free shipping — ₹99 off shipping on any order','fixed_amount', 99,    NULL,  99,    2000, 340, 1, '2024-01-01 00:00:00', '2025-12-31 23:59:59'),


('DIWALI23',   'Diwali 2023 sale — 25% off',                   'percentage',   25,    1000,  2000,  5000, 4823,0, '2023-10-20 00:00:00', '2023-11-05 23:59:59'),


('EARLYBIRD',  'First 50 users only — flat ₹300 off',          'fixed_amount', 300,   1500,  NULL,  50,   50,  1, '2024-01-01 00:00:00', '2025-12-31 23:59:59'),


('TESTCODE',   'Internal test coupon — do not publish',         'fixed_amount', 999,   NULL,  NULL,  NULL, 0,   0, NULL,                  NULL);

INSERT INTO orders (user_id, address_id, coupon_id, order_number, status,
    subtotal, discount_amount, tax_amount, shipping_amount, total_amount, notes, created_at)
VALUES (2, 1, 2, 'ORD-20240301-00001', 'delivered',
    134900.00, 200.00, 24966.00, 0.00, 159666.00, 'Leave at door', '2024-03-01 10:00:00');

INSERT INTO order_items (order_id, product_id, product_name, product_sku, quantity, unit_price, total_price)
VALUES (1, 1, 'iPhone 15 Pro', 'APL-IP15P-256', 1, 134900.00, 134900.00);

INSERT INTO payments (order_id, payment_method, payment_status, amount, currency, transaction_id, paid_at, created_at)
VALUES (1, 'upi', 'completed', 159666.00, 'INR', 'UPI20240301001', '2024-03-01 10:05:00', '2024-03-01 10:02:00');

INSERT INTO shipments (order_id, tracking_number, courier_name, status, estimated_delivery, delivered_at, created_at)
VALUES (1, 'BD1234567890IN', 'BlueDart', 'delivered', '2024-03-05', '2024-03-04 14:30:00', '2024-03-01 16:00:00');

INSERT INTO orders (user_id, address_id, coupon_id, order_number, status,
    subtotal, discount_amount, tax_amount, shipping_amount, total_amount, notes, created_at)
VALUES (3, 3, NULL, 'ORD-20240310-00002', 'shipped',
    114900.00, 0.00, 20682.00, 0.00, 135582.00, NULL, '2024-03-10 14:30:00');

INSERT INTO order_items (order_id, product_id, product_name, product_sku, quantity, unit_price, total_price)
VALUES (2, 5, 'MacBook Air M3 13"', 'APL-MBA-M3-13', 1, 114900.00, 114900.00);

INSERT INTO payments (order_id, payment_method, payment_status, amount, currency, transaction_id, paid_at, created_at)
VALUES (2, 'credit_card', 'completed', 135582.00, 'INR', 'CC20240310002', '2024-03-10 14:35:00', '2024-03-10 14:32:00');

INSERT INTO shipments (order_id, tracking_number, courier_name, status, estimated_delivery, created_at)
VALUES (2, 'DTDC9876543210', 'DTDC', 'in_transit', '2024-03-15', '2024-03-11 09:00:00');

INSERT INTO orders (user_id, address_id, coupon_id, order_number, status,
    subtotal, discount_amount, tax_amount, shipping_amount, total_amount, notes, created_at)
VALUES (4, 4, NULL, 'ORD-20240312-00003', 'confirmed',
    26289.00, 0.00, 4732.02, 0.00, 31021.02, NULL, '2024-03-12 09:15:00');

INSERT INTO order_items (order_id, product_id, product_name, product_sku, quantity, unit_price, total_price)
VALUES
    (3, 8,  'Sony WF-1000XM5',  'SNY-WF1000XM5', 1, 24990.00, 24990.00),
    (3, 7,  'boAt Airdopes 141','BOT-AD141-BLK',  1,  1299.00,  1299.00);

INSERT INTO payments (order_id, payment_method, payment_status, amount, currency, transaction_id, paid_at, created_at)
VALUES (3, 'net_banking', 'completed', 31021.02, 'INR', 'NB20240312003', '2024-03-12 09:20:00', '2024-03-12 09:17:00');

INSERT INTO orders (user_id, address_id, coupon_id, order_number, status,
    subtotal, discount_amount, tax_amount, shipping_amount, total_amount, notes, created_at)
VALUES (2, 1, 1, 'ORD-20240315-00004', 'pending',
    79999.00, 200.00, 14219.82, 0.00, 94018.82, NULL, '2024-03-15 18:00:00');

INSERT INTO order_items (order_id, product_id, product_name, product_sku, quantity, unit_price, total_price)
VALUES (4, 2, 'Samsung Galaxy S24', 'SAM-S24-256', 1, 79999.00, 79999.00);

INSERT INTO payments (order_id, payment_method, payment_status, amount, currency, transaction_id, created_at)
VALUES (4, 'credit_card', 'failed', 94018.82, 'INR', NULL, '2024-03-15 18:05:00');

INSERT INTO orders (user_id, address_id, coupon_id, order_number, status,
    subtotal, discount_amount, tax_amount, shipping_amount, total_amount, notes, created_at)
VALUES (6, 6, NULL, 'ORD-20240308-00005', 'cancelled',
    3998.00, 0.00, 719.64, 0.00, 4717.64, 'Cancelled: changed my mind', '2024-03-08 11:00:00');

INSERT INTO order_items (order_id, product_id, product_name, product_sku, quantity, unit_price, total_price)
VALUES (5, 10, 'Nike Dri-FIT T-Shirt', 'NK-DFIT-TEE-M', 2, 1999.00, 3998.00);

INSERT INTO reviews (product_id, user_id, order_id, rating, title, body, is_approved, created_at)
VALUES
    
    (1, 2, 1, 5,
     'Absolutely love this phone!',
     'Switched from Android after 8 years and I have zero regrets. The camera is insanely good, build quality is premium, and battery easily lasts a full day. The titanium frame feels amazing in hand. Best phone I have ever owned.',
     1, '2024-03-06 10:00:00'),

    
    (5, 3, 2, 5,
     'Perfect laptop for a developer',
     'The M3 chip handles everything I throw at it — Docker, VS Code with 20 tabs, Figma — all simultaneously without any fan noise because there is no fan! Battery life is genuinely 14-16 hours. Best laptop I have used.',
     1, '2024-03-17 09:30:00'),

    
    (8, 4, 3, 4,
     'Best ANC earbuds — worth every rupee',
     'The noise cancellation is absolutely class-leading. I use these on my daily metro commute and the outside world just disappears. Sound quality is rich and detailed. Only minor gripe — the case is a bit large for a pocket.',
     1, '2024-03-14 18:00:00'),

    
    (7, 4, 3, 3,
     'Good for the price, nothing more',
     'For ₹1299 these are perfectly fine. Bass is punchy, connection is stable. Don not expect premium audio or great ANC — there is none. But for gym and casual use, they do the job without any complaints.',
     1, '2024-03-14 18:15:00'),

    
    (1, 3, 2, 2,
     'Overpriced in my opinion',
     'Great phone but I don not think it justifies the price compared to Android flagships at half the cost. Camera is good but not twice as good.',
     0, '2024-03-20 11:00:00');
