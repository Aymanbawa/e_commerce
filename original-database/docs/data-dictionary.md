# 📖 Data Dictionary

This file explains every table, every column, its data type, and why it exists.  
Think of this as the "manual" for the entire database.

---

## Table of Contents

1. [users](#1-users)
2. [addresses](#2-addresses)
3. [categories](#3-categories)
4. [brands](#4-brands)
5. [products](#5-products)
6. [product_images](#6-product_images)
7. [product_attributes](#7-product_attributes)
8. [inventory](#8-inventory)
9. [coupons](#9-coupons)
10. [orders](#10-orders)
11. [order_items](#11-order_items)
12. [payments](#12-payments)
13. [shipments](#13-shipments)
14. [reviews](#14-reviews)
15. [wishlist](#15-wishlist)
16. [audit_log](#16-audit_log)

---

## 1. `users`

**Why this table exists:**  
Stores everyone who interacts with the platform — customers and admins.  
Keeping users in one table with a `role` column is simpler than two separate tables,  
and allows a user to be both a customer and an admin without duplication.

| Column           | Type                        | Constraints             | Description                                          |
|------------------|-----------------------------|-------------------------|------------------------------------------------------|
| `user_id`        | BIGINT UNSIGNED             | PK, AUTO_INCREMENT      | Unique identifier for every user                     |
| `email`          | VARCHAR(255)                | NOT NULL, UNIQUE        | Login email — must be unique across all users        |
| `password_hash`  | VARCHAR(255)                | NOT NULL                | Bcrypt-hashed password — never store plain text      |
| `first_name`     | VARCHAR(100)                | NOT NULL                | User's first name                                    |
| `last_name`      | VARCHAR(100)                | NOT NULL                | User's last name                                     |
| `phone`          | VARCHAR(20)                 | NULL                    | Optional contact number                              |
| `role`           | ENUM('customer','admin')    | NOT NULL, DEFAULT 'customer' | Controls access level in the application        |
| `is_verified`    | TINYINT(1)                  | NOT NULL, DEFAULT 0     | 1 = email verified, 0 = not yet verified             |
| `is_active`      | TINYINT(1)                  | NOT NULL, DEFAULT 1     | 0 = account suspended/banned                         |
| `created_at`     | DATETIME                    | NOT NULL, DEFAULT NOW() | When the account was created                         |
| `updated_at`     | DATETIME                    | NOT NULL                | Last time any field was changed                      |
| `deleted_at`     | DATETIME                    | NULL                    | Soft delete — NULL means active, date means deleted  |

**Key decisions:**
- `password_hash` — We store the hash, never the real password.
- `deleted_at` — Instead of deleting users, we "soft delete" them. This preserves all their order history.
- `role` ENUM — Only two valid values allowed. Bad data is impossible.

---

## 2. `addresses`

**Why this table exists:**  
A user can have multiple addresses (home, office, etc.).  
Orders need to record the exact address used at the time of purchase.  
Separating addresses into their own table avoids repeating address columns everywhere.

| Column          | Type                              | Constraints        | Description                                         |
|-----------------|-----------------------------------|--------------------|-----------------------------------------------------|
| `address_id`    | BIGINT UNSIGNED                   | PK, AUTO_INCREMENT | Unique identifier for this address                  |
| `user_id`       | BIGINT UNSIGNED                   | NOT NULL, FK       | Which user owns this address                        |
| `type`          | ENUM('shipping','billing','both') | NOT NULL           | What this address is used for                       |
| `full_name`     | VARCHAR(200)                      | NOT NULL           | Recipient name (may differ from account name)       |
| `phone`         | VARCHAR(20)                       | NOT NULL           | Contact number for delivery                         |
| `address_line1` | VARCHAR(255)                      | NOT NULL           | Street address, house number                        |
| `address_line2` | VARCHAR(255)                      | NULL               | Apartment, floor, suite — optional                  |
| `city`          | VARCHAR(100)                      | NOT NULL           | City name                                           |
| `state`         | VARCHAR(100)                      | NOT NULL           | State or province                                   |
| `postal_code`   | VARCHAR(20)                       | NOT NULL           | ZIP or postal code                                  |
| `country`       | VARCHAR(100)                      | NOT NULL           | Country name                                        |
| `is_default`    | TINYINT(1)                        | NOT NULL, DEFAULT 0| 1 = this is the user's default address              |
| `created_at`    | DATETIME                          | NOT NULL           | When this address was added                         |

---

## 3. `categories`

**Why this table exists:**  
Products belong to categories (e.g., Electronics → Phones → Smartphones).  
A self-referencing table lets us nest categories infinitely deep without adding new columns.

| Column        | Type             | Constraints        | Description                                              |
|---------------|------------------|--------------------|----------------------------------------------------------|
| `category_id` | BIGINT UNSIGNED  | PK, AUTO_INCREMENT | Unique identifier for this category                      |
| `parent_id`   | BIGINT UNSIGNED  | NULL, FK (self)    | Points to parent category. NULL = top-level category     |
| `name`        | VARCHAR(100)     | NOT NULL           | Category display name (e.g., "Smartphones")              |
| `slug`        | VARCHAR(120)     | NOT NULL, UNIQUE   | URL-friendly name (e.g., "smartphones") for web routes   |
| `description` | TEXT             | NULL               | Optional longer description of the category              |
| `is_active`   | TINYINT(1)       | NOT NULL, DEFAULT 1| 0 = hidden from the storefront                           |
| `created_at`  | DATETIME         | NOT NULL           | When this category was created                           |

**Key decision:**  
`parent_id` references the same `categories` table. This is called a **self-referencing foreign key**.  
Electronics (parent_id = NULL) → Phones (parent_id = Electronics) → Smartphones (parent_id = Phones).

---

## 4. `brands`

**Why this table exists:**  
Brands are reused across many products. Storing brand info once and referencing it by ID avoids  
repeating "Samsung", "Apple", etc. in every product row. If a brand name changes, you update one row.

| Column       | Type            | Constraints        | Description                              |
|--------------|-----------------|--------------------|------------------------------------------|
| `brand_id`   | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Unique identifier for this brand         |
| `name`       | VARCHAR(100)    | NOT NULL, UNIQUE   | Brand name (e.g., "Samsung")             |
| `slug`       | VARCHAR(120)    | NOT NULL, UNIQUE   | URL-friendly name (e.g., "samsung")      |
| `logo_url`   | VARCHAR(500)    | NULL               | Link to brand logo image                 |
| `is_active`  | TINYINT(1)      | NOT NULL, DEFAULT 1| 0 = brand hidden from storefront         |
| `created_at` | DATETIME        | NOT NULL           | When this brand was added                |

---

## 5. `products`

**Why this table exists:**  
The core of any e-commerce database. Each row is one product listed for sale.  
It links to brands and categories, holds pricing, and tracks status.

| Column            | Type                                    | Constraints        | Description                                          |
|-------------------|-----------------------------------------|--------------------|------------------------------------------------------|
| `product_id`      | BIGINT UNSIGNED                         | PK, AUTO_INCREMENT | Unique identifier for this product                   |
| `category_id`     | BIGINT UNSIGNED                         | NOT NULL, FK       | Which category this product belongs to               |
| `brand_id`        | BIGINT UNSIGNED                         | NULL, FK           | Which brand made this product (optional)             |
| `name`            | VARCHAR(255)                            | NOT NULL           | Product display name                                 |
| `slug`            | VARCHAR(300)                            | NOT NULL, UNIQUE   | URL-friendly name for product pages                  |
| `description`     | TEXT                                    | NULL               | Full product description                             |
| `short_desc`      | VARCHAR(500)                            | NULL               | One-line summary shown in listings                   |
| `sku`             | VARCHAR(100)                            | NOT NULL, UNIQUE   | Stock Keeping Unit — internal product code           |
| `price`           | DECIMAL(10,2)                           | NOT NULL           | Regular selling price                                |
| `compare_price`   | DECIMAL(10,2)                           | NULL               | Original price shown crossed out (for sale display)  |
| `cost_price`      | DECIMAL(10,2)                           | NULL               | What we paid for it — used for profit margin reports |
| `status`          | ENUM('draft','active','inactive','archived') | NOT NULL, DEFAULT 'draft' | Controls product visibility          |
| `is_featured`     | TINYINT(1)                              | NOT NULL, DEFAULT 0| 1 = show on homepage featured section                |
| `weight_grams`    | INT UNSIGNED                            | NULL               | Product weight — used for shipping cost calculation  |
| `created_at`      | DATETIME                                | NOT NULL           | When the product was added                           |
| `updated_at`      | DATETIME                                | NOT NULL           | Last time product info was changed                   |
| `deleted_at`      | DATETIME                                | NULL               | Soft delete — keeps product in order history         |

**Key decisions:**
- `DECIMAL(10,2)` for all prices — prevents floating-point errors (e.g., $9.999999 instead of $10.00).
- `compare_price` — this is what lets you show "Was $100, Now $79" on the frontend.
- `cost_price` — kept private for profit margin calculations. Not shown to customers.

---

## 6. `product_images`

**Why this table exists:**  
One product can have many photos. Storing them in a separate table (not as columns like  
`image1`, `image2`, `image3`) means you can add unlimited images without changing the schema.

| Column       | Type            | Constraints        | Description                                    |
|--------------|-----------------|--------------------|------------------------------------------------|
| `image_id`   | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Unique identifier for this image               |
| `product_id` | BIGINT UNSIGNED | NOT NULL, FK       | Which product this image belongs to            |
| `image_url`  | VARCHAR(500)    | NOT NULL           | Full URL to the image file                     |
| `alt_text`   | VARCHAR(255)    | NULL               | Description for screen readers / SEO           |
| `sort_order` | TINYINT UNSIGNED| NOT NULL, DEFAULT 0| Controls display order (0 = show first)        |
| `is_primary` | TINYINT(1)      | NOT NULL, DEFAULT 0| 1 = this is the main product thumbnail         |
| `created_at` | DATETIME        | NOT NULL           | When this image was uploaded                   |

---

## 7. `product_attributes`

**Why this table exists:**  
Different products have different specs. A phone has RAM and storage. A shirt has size and color.  
Instead of adding a new column for every possible attribute, we use a flexible key-value structure.  
This is a common pattern called the **EAV (Entity-Attribute-Value)** model.

| Column         | Type            | Constraints        | Description                                     |
|----------------|-----------------|--------------------|-------------------------------------------------|
| `attribute_id` | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Unique identifier for this attribute row        |
| `product_id`   | BIGINT UNSIGNED | NOT NULL, FK       | Which product this attribute belongs to         |
| `attribute_name`  | VARCHAR(100) | NOT NULL           | The spec name (e.g., "Color", "RAM", "Size")    |
| `attribute_value` | VARCHAR(255) | NOT NULL           | The spec value (e.g., "Blue", "8GB", "XL")      |
| `created_at`   | DATETIME        | NOT NULL           | When this attribute was added                   |

**Example rows:**
```
product_id=5, attribute_name="Color",   attribute_value="Midnight Blue"
product_id=5, attribute_name="RAM",     attribute_value="8GB"
product_id=5, attribute_name="Storage", attribute_value="256GB"
```

---

## 8. `inventory`

**Why this table exists:**  
Tracks how many units of each product are available.  
Keeping inventory separate from products means stock levels can change without touching product data.  
It also supports future expansion to multiple warehouses.

| Column              | Type            | Constraints             | Description                                         |
|---------------------|-----------------|-------------------------|-----------------------------------------------------|
| `inventory_id`      | BIGINT UNSIGNED | PK, AUTO_INCREMENT      | Unique identifier for this inventory row            |
| `product_id`        | BIGINT UNSIGNED | NOT NULL, FK, UNIQUE    | One inventory row per product                       |
| `quantity_in_stock` | INT UNSIGNED    | NOT NULL, DEFAULT 0     | Current units available for sale                    |
| `quantity_reserved` | INT UNSIGNED    | NOT NULL, DEFAULT 0     | Units held for pending orders (not yet shipped)     |
| `reorder_threshold` | INT UNSIGNED    | NOT NULL, DEFAULT 10    | Alert triggers when stock falls below this number   |
| `updated_at`        | DATETIME        | NOT NULL                | Last time stock was changed                         |

**Key concept:**  
`quantity_in_stock - quantity_reserved` = actual available quantity a customer can buy.

---

## 9. `coupons`

**Why this table exists:**  
Discount codes are a core e-commerce feature. This table stores all coupon rules  
so the database can validate and apply discounts consistently.

| Column             | Type                              | Constraints        | Description                                         |
|--------------------|-----------------------------------|--------------------|-----------------------------------------------------|
| `coupon_id`        | BIGINT UNSIGNED                   | PK, AUTO_INCREMENT | Unique identifier for this coupon                   |
| `code`             | VARCHAR(50)                       | NOT NULL, UNIQUE   | The code a customer types in (e.g., "SAVE20")       |
| `description`      | VARCHAR(255)                      | NULL               | Internal note about this coupon                     |
| `discount_type`    | ENUM('percentage','fixed_amount') | NOT NULL           | Is it 20% off or $20 off?                           |
| `discount_value`   | DECIMAL(10,2)                     | NOT NULL           | The amount — e.g., 20 means 20% or $20.00           |
| `min_order_amount` | DECIMAL(10,2)                     | NULL               | Minimum cart total to use this coupon               |
| `max_discount_amount` | DECIMAL(10,2)                  | NULL               | Cap on discount (e.g., percentage coupon max $50)   |
| `usage_limit`      | INT UNSIGNED                      | NULL               | Total times this coupon can be used. NULL = unlimited|
| `usage_count`      | INT UNSIGNED                      | NOT NULL, DEFAULT 0| How many times it has been used so far              |
| `is_active`        | TINYINT(1)                        | NOT NULL, DEFAULT 1| 0 = coupon is disabled                              |
| `starts_at`        | DATETIME                          | NULL               | When the coupon becomes valid                       |
| `expires_at`       | DATETIME                          | NULL               | When the coupon stops working. NULL = never expires |
| `created_at`       | DATETIME                          | NOT NULL           | When this coupon was created                        |

---

## 10. `orders`

**Why this table exists:**  
The order header — one row per customer order. It records the overall status,  
the customer, the address used, and the financial totals.  
Individual products within the order live in `order_items`.

| Column            | Type                                                  | Constraints        | Description                                          |
|-------------------|-------------------------------------------------------|--------------------|------------------------------------------------------|
| `order_id`        | BIGINT UNSIGNED                                       | PK, AUTO_INCREMENT | Unique identifier for this order                     |
| `user_id`         | BIGINT UNSIGNED                                       | NOT NULL, FK       | Which customer placed this order                     |
| `address_id`      | BIGINT UNSIGNED                                       | NOT NULL, FK       | Shipping address used for this order                 |
| `coupon_id`       | BIGINT UNSIGNED                                       | NULL, FK           | Coupon applied (if any)                              |
| `order_number`    | VARCHAR(50)                                           | NOT NULL, UNIQUE   | Human-readable ID shown to customer (e.g., ORD-10045)|
| `status`          | ENUM('pending','confirmed','processing','shipped','delivered','cancelled','refunded') | NOT NULL, DEFAULT 'pending' | Current order state |
| `subtotal`        | DECIMAL(10,2)                                         | NOT NULL           | Total before discount and tax                        |
| `discount_amount` | DECIMAL(10,2)                                         | NOT NULL, DEFAULT 0| Amount saved via coupon                              |
| `tax_amount`      | DECIMAL(10,2)                                         | NOT NULL, DEFAULT 0| Tax charged on this order                            |
| `shipping_amount` | DECIMAL(10,2)                                         | NOT NULL, DEFAULT 0| Shipping fee                                         |
| `total_amount`    | DECIMAL(10,2)                                         | NOT NULL           | Final amount charged (subtotal - discount + tax + shipping) |
| `notes`           | TEXT                                                  | NULL               | Customer delivery instructions                       |
| `created_at`      | DATETIME                                              | NOT NULL           | When the order was placed                            |
| `updated_at`      | DATETIME                                              | NOT NULL           | Last status change                                   |

**Order total formula:**  
`total_amount = subtotal - discount_amount + tax_amount + shipping_amount`

---

## 11. `order_items`

**Why this table exists:**  
Each order can contain multiple products. This table holds one row per product line  
within an order. Prices are recorded at purchase time — so if a product price changes later,  
the order history stays accurate.

| Column          | Type            | Constraints        | Description                                              |
|-----------------|-----------------|--------------------|----------------------------------------------------------|
| `item_id`       | BIGINT UNSIGNED | PK, AUTO_INCREMENT | Unique identifier for this line item                     |
| `order_id`      | BIGINT UNSIGNED | NOT NULL, FK       | Which order this item belongs to                         |
| `product_id`    | BIGINT UNSIGNED | NOT NULL, FK       | Which product was ordered                                |
| `product_name`  | VARCHAR(255)    | NOT NULL           | Product name copied at purchase time (snapshot)          |
| `product_sku`   | VARCHAR(100)    | NOT NULL           | SKU copied at purchase time (snapshot)                   |
| `quantity`      | INT UNSIGNED    | NOT NULL           | How many units were ordered                              |
| `unit_price`    | DECIMAL(10,2)   | NOT NULL           | Price per unit at time of purchase (snapshot)            |
| `total_price`   | DECIMAL(10,2)   | NOT NULL           | quantity × unit_price                                    |
| `created_at`    | DATETIME        | NOT NULL           | When this item was added to the order                    |

**Key decision — snapshots:**  
`product_name`, `product_sku`, and `unit_price` are copied from the products table when the order is placed.  
This is intentional. If the product is later renamed or repriced, old orders stay historically correct.

---

## 12. `payments`

**Why this table exists:**  
Tracks how an order was paid. An order might have multiple payment attempts  
(e.g., first card declined, second card succeeded), so payments are separate from orders.

| Column             | Type                                        | Constraints        | Description                                         |
|--------------------|---------------------------------------------|--------------------|-----------------------------------------------------|
| `payment_id`       | BIGINT UNSIGNED                             | PK, AUTO_INCREMENT | Unique identifier for this payment record           |
| `order_id`         | BIGINT UNSIGNED                             | NOT NULL, FK       | Which order this payment is for                     |
| `payment_method`   | ENUM('credit_card','debit_card','upi','net_banking','wallet','cod') | NOT NULL | How the customer paid |
| `payment_status`   | ENUM('pending','completed','failed','refunded') | NOT NULL, DEFAULT 'pending' | Current state of this payment       |
| `amount`           | DECIMAL(10,2)                               | NOT NULL           | Amount paid in this transaction                     |
| `currency`         | VARCHAR(3)                                  | NOT NULL, DEFAULT 'INR' | ISO currency code (INR, USD, EUR, etc.)        |
| `transaction_id`   | VARCHAR(255)                                | NULL               | Payment gateway reference ID                        |
| `gateway_response` | JSON                                        | NULL               | Raw response from payment gateway (for debugging)   |
| `paid_at`          | DATETIME                                    | NULL               | When payment was confirmed. NULL = not yet paid     |
| `created_at`       | DATETIME                                    | NOT NULL           | When payment attempt was initiated                  |

---

## 13. `shipments`

**Why this table exists:**  
An order needs to be physically delivered. This table tracks the shipment details  
including courier, tracking number, and delivery status.

| Column            | Type                                                  | Constraints        | Description                                       |
|-------------------|-------------------------------------------------------|--------------------|---------------------------------------------------|
| `shipment_id`     | BIGINT UNSIGNED                                       | PK, AUTO_INCREMENT | Unique identifier for this shipment               |
| `order_id`        | BIGINT UNSIGNED                                       | NOT NULL, FK       | Which order is being shipped                      |
| `tracking_number` | VARCHAR(100)                                          | NULL               | Courier tracking number                           |
| `courier_name`    | VARCHAR(100)                                          | NULL               | Courier company (e.g., "FedEx", "BlueDart")       |
| `status`          | ENUM('preparing','dispatched','in_transit','out_for_delivery','delivered','returned') | NOT NULL, DEFAULT 'preparing' | Shipment state |
| `estimated_delivery` | DATE                                               | NULL               | Expected delivery date shown to customer          |
| `delivered_at`    | DATETIME                                              | NULL               | Actual delivery timestamp                         |
| `created_at`      | DATETIME                                              | NOT NULL           | When shipment record was created                  |
| `updated_at`      | DATETIME                                              | NOT NULL           | Last status update                                |

---

## 14. `reviews`

**Why this table exists:**  
Product reviews build trust and drive purchase decisions.  
Each verified buyer can leave one review per product they purchased.

| Column       | Type            | Constraints             | Description                                        |
|--------------|-----------------|-------------------------|----------------------------------------------------|
| `review_id`  | BIGINT UNSIGNED | PK, AUTO_INCREMENT      | Unique identifier for this review                  |
| `product_id` | BIGINT UNSIGNED | NOT NULL, FK            | Which product is being reviewed                    |
| `user_id`    | BIGINT UNSIGNED | NOT NULL, FK            | Who wrote the review                               |
| `order_id`   | BIGINT UNSIGNED | NOT NULL, FK            | The order this review is tied to (verified buyer)  |
| `rating`     | TINYINT UNSIGNED| NOT NULL                | Score from 1 to 5                                  |
| `title`      | VARCHAR(255)    | NULL                    | Short headline for the review                      |
| `body`       | TEXT            | NULL                    | Full review text                                   |
| `is_approved`| TINYINT(1)      | NOT NULL, DEFAULT 0     | 1 = approved by admin, shown publicly              |
| `created_at` | DATETIME        | NOT NULL                | When the review was submitted                      |

**Key constraint:**  
UNIQUE on (`product_id`, `user_id`, `order_id`) — one review per product per order. No duplicates.

---

## 15. `wishlist`

**Why this table exists:**  
Users save products they want to buy later. Simple join table between users and products  
with a timestamp so you can show "Added 3 days ago".

| Column        | Type            | Constraints             | Description                                 |
|---------------|-----------------|-------------------------|---------------------------------------------|
| `wishlist_id` | BIGINT UNSIGNED | PK, AUTO_INCREMENT      | Unique identifier for this wishlist row     |
| `user_id`     | BIGINT UNSIGNED | NOT NULL, FK            | Which user saved this product               |
| `product_id`  | BIGINT UNSIGNED | NOT NULL, FK            | Which product was saved                     |
| `created_at`  | DATETIME        | NOT NULL                | When it was added to the wishlist           |

**Key constraint:**  
UNIQUE on (`user_id`, `product_id`) — a user can't save the same product twice.

---

## 16. `audit_log`

**Why this table exists:**  
In any production system, you need to know: who changed what, and when?  
This table automatically records every important change made to users and orders.  
It is written to by triggers — the application never writes to it directly.

| Column        | Type                               | Constraints        | Description                                           |
|---------------|------------------------------------|--------------------|-------------------------------------------------------|
| `log_id`      | BIGINT UNSIGNED                    | PK, AUTO_INCREMENT | Unique identifier for this log entry                  |
| `table_name`  | VARCHAR(100)                       | NOT NULL           | Which table was changed (e.g., "orders", "users")     |
| `record_id`   | BIGINT UNSIGNED                    | NOT NULL           | The PK of the row that was changed                    |
| `action`      | ENUM('INSERT','UPDATE','DELETE')   | NOT NULL           | What type of change happened                          |
| `changed_by`  | BIGINT UNSIGNED                    | NULL               | user_id of who made the change. NULL = system trigger |
| `old_values`  | JSON                               | NULL               | The data BEFORE the change                            |
| `new_values`  | JSON                               | NULL               | The data AFTER the change                             |
| `changed_at`  | DATETIME                           | NOT NULL           | Exactly when the change happened                      |

**Example row:**
```json
table_name  : "orders"
record_id   : 1042
action      : "UPDATE"
old_values  : { "status": "confirmed" }
new_values  : { "status": "shipped" }
changed_at  : "2024-03-15 14:32:01"
```

---

## 📐 Data Type Reference

| Type              | Used For                           | Why                                         |
|-------------------|------------------------------------|---------------------------------------------|
| `BIGINT UNSIGNED` | All primary and foreign keys       | Supports 18 quintillion rows. No negatives. |
| `DECIMAL(10,2)`   | All prices and money               | Exact arithmetic. No floating-point errors. |
| `VARCHAR(n)`      | Text with known max length         | Efficient storage. Enforces limit.          |
| `TEXT`            | Long descriptions, review bodies   | No length limit needed                      |
| `TINYINT(1)`      | Boolean flags (is_active, etc.)    | MySQL's boolean — 0 = false, 1 = true       |
| `DATETIME`        | Timestamps                         | Stores date and time together               |
| `JSON`            | Flexible data (gateway responses)  | Structured but variable data                |
| `ENUM`            | Status fields with fixed options   | Database enforces valid values              |

---

*Last updated: 2024 | Part of the E-Commerce SQL Portfolio Project*
