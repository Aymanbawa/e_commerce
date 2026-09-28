-- =============================================================
-- FILE: seeds/07_seed_reviews.sql
-- PROJECT: E-Commerce SQL Portfolio Project
-- DESCRIPTION: Sample product reviews by verified buyers
-- AUTHOR: Your Name
-- NOTE: Reviews must link to real orders (verified buyer rule)
--       Order 1 = user 2 bought product 1 (iPhone 15 Pro)
-- =============================================================

USE ecommerce_db;

INSERT INTO reviews (product_id, user_id, order_id, rating, title, body, is_approved, created_at)
VALUES
    -- Rahul (user 2) reviews iPhone 15 Pro (from order 1)
    (1, 2, 1, 5,
     'Absolutely love this phone!',
     'Switched from Android after 8 years and I have zero regrets. The camera is insanely good, build quality is premium, and battery easily lasts a full day. The titanium frame feels amazing in hand. Best phone I have ever owned.',
     1, '2024-03-06 10:00:00'),

    -- Priya (user 3) reviews MacBook Air M3 (from order 2)
    (5, 3, 2, 5,
     'Perfect laptop for a developer',
     'The M3 chip handles everything I throw at it — Docker, VS Code with 20 tabs, Figma — all simultaneously without any fan noise because there is no fan! Battery life is genuinely 14-16 hours. Best laptop I have used.',
     1, '2024-03-17 09:30:00'),

    -- Arjun (user 4) reviews Sony WF-1000XM5 (from order 3)
    (8, 4, 3, 4,
     'Best ANC earbuds — worth every rupee',
     'The noise cancellation is absolutely class-leading. I use these on my daily metro commute and the outside world just disappears. Sound quality is rich and detailed. Only minor gripe — the case is a bit large for a pocket.',
     1, '2024-03-14 18:00:00'),

    -- Arjun (user 4) also reviews boAt Airdopes (from order 3)
    (7, 4, 3, 3,
     'Good for the price, nothing more',
     'For ₹1299 these are perfectly fine. Bass is punchy, connection is stable. Don not expect premium audio or great ANC — there is none. But for gym and casual use, they do the job without any complaints.',
     1, '2024-03-14 18:15:00'),

    -- Unapproved review — pending admin moderation
    (1, 3, 2, 2,
     'Overpriced in my opinion',
     'Great phone but I don not think it justifies the price compared to Android flagships at half the cost. Camera is good but not twice as good.',
     0, '2024-03-20 11:00:00');

SELECT CONCAT('Reviews seeded: ', COUNT(*), ' rows') AS status FROM reviews;
SELECT
    r.review_id,
    p.name AS product,
    u.first_name AS reviewer,
    r.rating,
    r.title,
    IF(r.is_approved=1,'✓ Approved','⏳ Pending') AS status
FROM reviews r
JOIN products p ON p.product_id = r.product_id
JOIN users u ON u.user_id = r.user_id;
