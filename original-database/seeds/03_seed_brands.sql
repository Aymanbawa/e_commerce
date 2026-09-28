-- =============================================================
-- FILE: seeds/03_seed_brands.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Sample brand data — realistic brand names
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

INSERT INTO brands (name, slug, website_url, description, is_active) VALUES
    ('Apple',         'apple',         'https://www.apple.com',      'Premium consumer electronics and software',     1),
    ('Samsung',       'samsung',       'https://www.samsung.com',    'Global leader in electronics and displays',     1),
    ('Sony',          'sony',          'https://www.sony.com',       'Audio, gaming and consumer electronics',        1),
    ('Nike',          'nike',          'https://www.nike.com',       'Athletic footwear, apparel and equipment',      1),
    ('Adidas',        'adidas',        'https://www.adidas.com',     'Sports and lifestyle brand',                    1),
    ('boAt',          'boat',          'https://www.boat-lifestyle.com','Affordable audio and accessories for India', 1),
    ('Levi\'s',       'levis',         'https://www.levi.com',       'Iconic denim and casual wear',                  1),
    ('Penguin Books', 'penguin-books', 'https://www.penguin.co.in',  'Leading book publisher worldwide',              1),
    ('Lenovo',        'lenovo',        'https://www.lenovo.com',     'Laptops, tablets and enterprise hardware',      1),
    ('OnePlus',       'oneplus',       'https://www.oneplus.in',     'Premium Android smartphones',                   1);

SELECT CONCAT('Brands seeded: ', COUNT(*), ' rows') AS status FROM brands;
