-- =============================================================
-- FILE: seeds/02_seed_categories.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Sample category tree — 3 levels deep
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

-- Level 1: Top-level categories (parent_id = NULL)
INSERT INTO categories (parent_id, name, slug, description, sort_order, is_active) VALUES
    (NULL, 'Electronics',    'electronics',    'Gadgets, devices and tech accessories',     1, 1),
    (NULL, 'Clothing',       'clothing',       'Fashion for men, women and kids',           2, 1),
    (NULL, 'Books',          'books',          'Fiction, non-fiction, textbooks and more',  3, 1),
    (NULL, 'Home & Kitchen', 'home-kitchen',   'Appliances, furniture and kitchen tools',   4, 1),
    (NULL, 'Sports',         'sports',         'Equipment, clothing and accessories',       5, 1);

-- Level 2: Sub-categories (parent_id points to level 1)
INSERT INTO categories (parent_id, name, slug, description, sort_order, is_active) VALUES
    (1, 'Mobile Phones',    'mobile-phones',   'Smartphones and feature phones',    1, 1),
    (1, 'Laptops',          'laptops',         'Notebooks and ultrabooks',          2, 1),
    (1, 'Audio',            'audio',           'Headphones, earbuds and speakers',  3, 1),
    (2, 'Men\'s Clothing',  'mens-clothing',   'Shirts, jeans, jackets and more',   1, 1),
    (2, 'Women\'s Clothing','womens-clothing',  'Dresses, tops, sarees and more',    2, 1),
    (3, 'Fiction',          'fiction',         'Novels and short stories',          1, 1),
    (3, 'Self Help',        'self-help',       'Personal development and mindset',  2, 1),
    (4, 'Kitchen Appliances','kitchen-appliances','Mixers, ovens and more',         1, 1);

-- Level 3: Leaf categories (parent_id points to level 2)
INSERT INTO categories (parent_id, name, slug, description, sort_order, is_active) VALUES
    (6, 'Smartphones',   'smartphones',   'Android and iOS smartphones', 1, 1),
    (6, 'Feature Phones','feature-phones','Basic calling phones',        2, 1),
    (8, 'Earbuds',       'earbuds',       'True wireless earbuds',       1, 1),
    (8, 'Over-ear Headphones','over-ear-headphones','Studio and gaming headphones', 2, 1),
    (9, 'T-Shirts',      't-shirts',      'Casual and formal tees',      1, 1),
    (9, 'Jeans',         'jeans',         'Slim, straight and bootcut',  2, 1);

SELECT CONCAT('Categories seeded: ', COUNT(*), ' rows') AS status FROM categories;
