-- =============================================================
-- FILE: seeds/01_seed_users.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Sample users — customers and one admin
-- AUTHOR: Your Name
-- =============================================================

USE ecommerce_db;

-- Password hashes below are bcrypt hashes of 'Password@123'
-- In real apps, the application generates these before INSERT
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
-- user_id=7 (Nisha) is_active=0 → suspended account, for testing

-- Addresses for users
INSERT INTO addresses
    (user_id, type, full_name, phone, address_line1, address_line2, city, state, postal_code, country, is_default)
VALUES
    (2, 'both',     'Rahul Sharma',  '9811234567', '42 MG Road',          'Flat 3B',    'Mumbai',    'Maharashtra', '400001', 'India', 1),
    (2, 'shipping', 'Rahul Sharma',  '9811234567', '7 Bandra West',       NULL,          'Mumbai',    'Maharashtra', '400050', 'India', 0),
    (3, 'both',     'Priya Mehta',   '9822345678', '15 Koramangala',      'Block 5',    'Bengaluru', 'Karnataka',   '560034', 'India', 1),
    (4, 'both',     'Arjun Verma',   '9833456789', '88 Sector 18',        NULL,          'Noida',     'Uttar Pradesh','201301','India',1),
    (5, 'shipping', 'Sneha Patel',   '9844567890', '23 Ashram Road',      'Near Lake',  'Ahmedabad', 'Gujarat',     '380009', 'India', 1),
    (6, 'both',     'Karan Gupta',   '9855678901', '11 Park Street',      '2nd Floor',  'Kolkata',   'West Bengal', '700016', 'India', 1);

SELECT CONCAT('Users seeded: ', COUNT(*), ' rows') AS status FROM users;
SELECT CONCAT('Addresses seeded: ', COUNT(*), ' rows') AS status FROM addresses;
