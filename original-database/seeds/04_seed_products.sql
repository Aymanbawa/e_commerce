-- =============================================================
-- FILE: seeds/04_seed_products.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: 20 realistic products with full details
-- AUTHOR: Your Name
-- NOTE: category_id and brand_id must match seeds 02 and 03
--       Category IDs: smartphones=14, earbuds=16, laptops=7,
--                     t-shirts=18, fiction=11, self-help=12
--       Brand IDs: Apple=1, Samsung=2, Sony=3, Nike=4,
--                  boAt=6, Levi's=7, Penguin=8, Lenovo=9, OnePlus=10
-- =============================================================

USE ecommerce_db;

INSERT INTO products
    (category_id, brand_id, name, slug, sku, short_desc, description, price, compare_price, cost_price, status, is_featured, weight_grams)
VALUES
-- Smartphones
(14, 1,  'iPhone 15 Pro',          'iphone-15-pro',          'APL-IP15P-256',  'A17 Pro chip, titanium design, 48MP camera',                    'The iPhone 15 Pro features the A17 Pro chip built on 3nm technology, a titanium frame, and a 48MP main camera system.',  134900.00, NULL,       95000.00, 'active', 1, 187),
(14, 2,  'Samsung Galaxy S24',     'samsung-galaxy-s24',     'SAM-S24-256',    '6.2" Dynamic AMOLED, Snapdragon 8 Gen 3',                       'The Galaxy S24 brings AI-powered features, a bright AMOLED display, and Snapdragon 8 Gen 3 for powerful performance.',       79999.00, 89999.00,  55000.00, 'active', 1, 167),
(14, 10, 'OnePlus 12',             'oneplus-12',             'OP-12-256',      'Snapdragon 8 Gen 3, 50MP Hasselblad camera, 100W charging',     'OnePlus 12 packs flagship performance with Snapdragon 8 Gen 3, Hasselblad-tuned cameras, and 100W SUPERVOOC charging.',      64999.00, 69999.00,  42000.00, 'active', 0, 220),
(14, 2,  'Samsung Galaxy A55',     'samsung-galaxy-a55',     'SAM-A55-128',    'Mid-range with OIS camera and 6.6" AMOLED display',             'Great everyday performance with a 6.6-inch AMOLED display, OIS camera, and long battery life.',                             37999.00, 41999.00,  25000.00, 'active', 0, 213),

-- Laptops
(7,  1,  'MacBook Air M3 13"',     'macbook-air-m3-13',      'APL-MBA-M3-13',  'M3 chip, 8GB RAM, 256GB SSD, 18hr battery',                    'Supercharged by M3, MacBook Air delivers exceptional performance in an incredibly thin design with up to 18 hours of battery.', 114900.00, NULL,       82000.00, 'active', 1, 1240),
(7,  9,  'Lenovo IdeaPad Slim 5',  'lenovo-ideapad-slim5',   'LEN-IPS5-512',   'AMD Ryzen 5 7530U, 16GB RAM, 512GB SSD',                       'A well-rounded laptop for students and professionals with AMD Ryzen 5, 16GB RAM, and 512GB fast SSD storage.',                 62990.00, 71990.00,  42000.00, 'active', 0, 1560),

-- Audio
(16, 6,  'boAt Airdopes 141',      'boat-airdopes-141',      'BOT-AD141-BLK',  'Bluetooth 5.1, 42hr total playback, IPX4 rated',               'Truly wireless earbuds with 6mm drivers, Bluetooth 5.1, 42 hours total playback, and IPX4 sweat resistance.',                 1299.00,  1999.00,    650.00, 'active', 0, 38),
(16, 3,  'Sony WF-1000XM5',        'sony-wf-1000xm5',        'SNY-WF1000XM5', 'Industry-leading ANC, 24hr battery, LDAC support',             'Sony\'s flagship TWS earbuds with best-in-class noise cancellation, LDAC hi-res audio, and up to 24 hours total battery.',    24990.00, 28990.00,  16000.00, 'active', 1, 50),
(16, 1,  'AirPods Pro 2nd Gen',    'airpods-pro-2nd-gen',    'APL-APP2-WHT',   'H2 chip, adaptive ANC, 30hr total with case',                  'AirPods Pro with the H2 chip deliver 2x more Active Noise Cancellation, Adaptive Transparency, and Personalized Spatial Audio.', 24900.00, NULL,       17000.00, 'active', 1, 50),

-- Men's Clothing (category 9 = Men's Clothing)
(9,  4,  'Nike Dri-FIT T-Shirt',   'nike-dri-fit-tshirt',   'NK-DFIT-TEE-M',  'Moisture-wicking fabric, regular fit, multiple colours',       'The Nike Dri-FIT technology moves sweat away from your body to help keep you dry and comfortable throughout your workout.',       1995.00,  2495.00,     900.00, 'active', 0, 180),
(9,  5,  'Adidas Essentials Tee',  'adidas-essentials-tee', 'ADI-ESS-TEE-M',  '100% cotton, embroidered logo, relaxed fit',                   'A classic everyday tee made from soft cotton with the iconic 3-Stripes on the sleeves and embroidered Adidas logo.',              1499.00,  NULL,        700.00, 'active', 0, 175),

-- Jeans (category 19 = Jeans)
(19, 7,  'Levi\'s 511 Slim Jeans', 'levis-511-slim-jeans',  'LEV-511-SLIM-32','Slim fit below waist, sits lower on the waist',               'Levi\'s 511 Slim jeans sit below the waist with a slim leg from hip to ankle. Made with a touch of stretch for all-day comfort.',  3499.00,  4499.00,    1800.00, 'active', 0, 650),

-- Books — Fiction (category 11)
(11, 8,  'Atomic Habits',          'atomic-habits',          'BK-ATOMHAB-EN',  'James Clear — Build good habits and break bad ones',           'Atomic Habits is a practical guide to breaking bad behaviours and adopting good ones. Tiny changes lead to remarkable results.',    599.00,   799.00,     200.00, 'active', 1, 250),
(11, 8,  'The Psychology of Money','psychology-of-money',   'BK-PSYMNY-EN',   'Morgan Housel — Timeless lessons on wealth and greed',         'Doing well with money isn\'t necessarily about what you know. It\'s about how you behave. Morgan Housel explains with 19 stories.',  499.00,   699.00,     175.00, 'active', 0, 230),
(11, 8,  'Rich Dad Poor Dad',      'rich-dad-poor-dad',     'BK-RCHDD-EN',    'Robert Kiyosaki — What the rich teach their kids about money', 'Rich Dad Poor Dad is about Robert Kiyosaki and his two dads — his real father and the father of his best friend — and how both men shaped his thoughts about money.',  399.00,   499.00,     150.00, 'active', 0, 220),

-- Home & Kitchen
(13, NULL,'Prestige Iris 750W Mixer','prestige-iris-750-mixer','PRE-IRIS750',  '3 jars, 750W motor, 5-year warranty',                          'The Prestige Iris mixer grinder comes with a 750W copper motor, 3 stainless steel jars, and a 5-year motor warranty.',           3299.00,  3999.00,    1900.00, 'active', 0, 2800),

-- Sports
(5,  4,  'Nike Air Max 90',        'nike-air-max-90',        'NK-AM90-WHT-9',  'Iconic cushioning, classic silhouette, durable sole',           'The Nike Air Max 90 stays true to its OG roots with the iconic Waffle outsole, stitched overlays, and classic Max Air cushioning.',  8995.00,  10995.00,   5000.00, 'active', 1, 420),
(5,  5,  'Adidas Ultraboost 22',   'adidas-ultraboost-22',  'ADI-UB22-BLK-9', 'Responsive BOOST midsole, Primeknit+ upper',                   'The Adidas Ultraboost 22 running shoe features a Primeknit+ upper and BOOST midsole for ultimate energy return.',                9999.00,  12999.00,   6000.00, 'active', 0, 390),

-- Draft product (not visible yet)
(14, 1,  'iPhone 15 Pro Max',      'iphone-15-pro-max',     'APL-IP15PM-512', 'Coming soon — 512GB, 5× optical zoom',                         'The most powerful iPhone ever made.',                                                                                          159900.00, NULL,      115000.00, 'draft',  0, 221);

-- Product images (primary images for key products)
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

-- Product attributes for a few products
INSERT INTO product_attributes (product_id, attribute_name, attribute_value, sort_order) VALUES
    -- iPhone 15 Pro
    (1, 'Color',        'Natural Titanium', 0),
    (1, 'RAM',          '8GB',              1),
    (1, 'Storage',      '256GB',            2),
    (1, 'Chip',         'A17 Pro',          3),
    (1, 'Battery',      '3274 mAh',         4),
    (1, 'Screen Size',  '6.1 inches',       5),
    -- Samsung Galaxy S24
    (2, 'Color',        'Phantom Black',    0),
    (2, 'RAM',          '8GB',              1),
    (2, 'Storage',      '256GB',            2),
    (2, 'Processor',    'Snapdragon 8 Gen 3', 3),
    -- boAt Airdopes
    (7, 'Color',            'Black',        0),
    (7, 'Connectivity',     'Bluetooth 5.1',1),
    (7, 'Battery Life',     '42 Hours',     2),
    (7, 'Water Resistance', 'IPX4',         3),
    -- Nike Dri-FIT Tee
    (10,'Size',         'M',                0),
    (10,'Color',        'White',            1),
    (10,'Material',     '100% Polyester',   2),
    (10,'Fit',          'Regular Fit',      3);

SELECT CONCAT('Products seeded: ', COUNT(*), ' rows') AS status FROM products;
SELECT CONCAT('Product images seeded: ', COUNT(*), ' rows') AS status FROM product_images;
SELECT CONCAT('Product attributes seeded: ', COUNT(*), ' rows') AS status FROM product_attributes;
