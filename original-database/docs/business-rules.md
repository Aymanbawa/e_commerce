# 📋 Business Rules

This file documents every real-world rule that this database enforces.  
These rules exist to protect data integrity and reflect how a real e-commerce business operates.

Understanding these rules will help you:
- Know WHY certain constraints, triggers, and stored procedures exist
- Answer interview questions like "how did you handle stock management?"
- Explain your design decisions confidently

---

## Table of Contents

1. [User Rules](#1-user-rules)
2. [Product & Inventory Rules](#2-product--inventory-rules)
3. [Order Rules](#3-order-rules)
4. [Coupon Rules](#4-coupon-rules)
5. [Payment Rules](#5-payment-rules)
6. [Shipment Rules](#6-shipment-rules)
7. [Review Rules](#7-review-rules)
8. [Wishlist Rules](#8-wishlist-rules)
9. [Audit Rules](#9-audit-rules)
10. [How Rules Are Enforced](#10-how-rules-are-enforced)

---

## 1. User Rules

### BR-U1 — Email must be unique
Every user account must have a different email address.  
Two people cannot share the same login email.

```
ENFORCED BY: UNIQUE constraint on users.email
```

### BR-U2 — Passwords are never stored as plain text
The database only ever stores a bcrypt hash of the password.  
Even a database admin cannot read a user's real password.

```
ENFORCED BY: Application layer (hash before INSERT)
NOTED IN: data-dictionary.md — password_hash column
```

### BR-U3 — Deleted users are never physically removed
When an account is "deleted", we set `deleted_at` to the current timestamp.  
The row stays in the database forever to preserve order history.

```
ENFORCED BY: Soft delete pattern — deleted_at IS NOT NULL = deleted
WHY: If we hard-deleted a user, all their orders would lose their owner.
     Past orders must always point to a valid user record.
```

### BR-U4 — A suspended user cannot place new orders
If `users.is_active = 0`, the application must reject any new order attempt.

```
ENFORCED BY: Application layer check before INSERT into orders
```

### BR-U5 — Only admins can manage products, coupons, and users
The `role` column controls who can do what.  
`customer` = can browse, buy, review.  
`admin` = can do everything.

```
ENFORCED BY: ENUM('customer','admin') on users.role
             Application layer permission checks
```

---

## 2. Product & Inventory Rules

### BR-P1 — Every product must belong to a category
A product without a category cannot be inserted.

```
ENFORCED BY: NOT NULL + FK constraint on products.category_id
```

### BR-P2 — Product SKUs must be unique across the entire catalog
No two products can have the same SKU (Stock Keeping Unit).

```
ENFORCED BY: UNIQUE constraint on products.sku
```

### BR-P3 — Product prices must be greater than zero
A product cannot have a zero or negative price.

```
ENFORCED BY: CHECK constraint — price > 0
```

### BR-P4 — compare_price must be higher than the sale price
If a product shows "Was $100, Now $79", the compare_price ($100)  
must always be greater than the actual price ($79).

```
ENFORCED BY: CHECK constraint — compare_price > price (when compare_price IS NOT NULL)
```

### BR-P5 — Stock quantity can never go negative
You cannot sell more units than you have in stock.  
The available quantity floor is always zero.

```
ENFORCED BY: CHECK constraint — inventory.quantity_in_stock >= 0
             Stored procedure sp_place_order validates stock before deducting
```

### BR-P6 — Deleted products stay in order history
If a product is removed from the catalog, its `deleted_at` is set.  
Old order_items still reference the product safely.

```
ENFORCED BY: Soft delete on products.deleted_at
             Snapshots of product_name and unit_price in order_items
```

### BR-P7 — A product can only have one primary image
Only one image per product can have `is_primary = 1`.

```
ENFORCED BY: Application layer when setting is_primary
```

### BR-P8 — Only active products can be ordered
Products with status = 'draft', 'inactive', or 'archived' cannot be purchased.

```
ENFORCED BY: Stored procedure sp_place_order checks products.status = 'active'
```

---

## 3. Order Rules

### BR-O1 — An order must have at least one item
You cannot create an empty order with no products in it.

```
ENFORCED BY: Stored procedure sp_place_order — validates item list is not empty
```

### BR-O2 — Order totals must be mathematically consistent
The total_amount must always equal:  
`subtotal - discount_amount + tax_amount + shipping_amount`

```
ENFORCED BY: Stored procedure sp_place_order calculates and sets all totals
             CHECK constraint — total_amount > 0
```

### BR-O3 — Price is locked at the time of purchase
When an order is placed, the current product name, SKU, and price  
are copied into `order_items`. Future price changes do not affect past orders.

```
ENFORCED BY: INSERT into order_items copies name, sku, price as snapshots
WHY: A customer's receipt must always show what they actually paid.
```

### BR-O4 — Stock is reserved immediately when order is placed
When an order is placed, inventory.quantity_reserved increases.  
When the order ships, quantity_in_stock decreases and quantity_reserved decreases.

```
ENFORCED BY: Stored procedure sp_place_order (reserve)
             Trigger trg_stock_on_order (deduct on shipment)
```

### BR-O5 — Cancelled orders restore stock
If an order is cancelled, any reserved stock is released back.

```
ENFORCED BY: Stored procedure sp_cancel_order
```

### BR-O6 — Order status must follow a valid path
Orders can only move forward through valid states:

```
pending → confirmed → processing → shipped → delivered
                                           ↘ cancelled
                    ↘ cancelled
         ↘ cancelled

delivered → refunded (only after delivery)
```

Any other status transition is rejected.

```
ENFORCED BY: Stored procedure sp_cancel_order validates current status
             Application layer guards status transitions
```

### BR-O7 — Order number is human-readable and unique
Every order gets a unique order number like `ORD-000001` shown on receipts.

```
ENFORCED BY: UNIQUE constraint on orders.order_number
             Generated by stored procedure sp_place_order
```

---

## 4. Coupon Rules

### BR-C1 — Coupon codes are case-insensitive and unique
`SAVE20` and `save20` are treated as the same coupon.

```
ENFORCED BY: UNIQUE constraint on coupons.code
             Application normalises code to UPPERCASE before lookup
```

### BR-C2 — Expired coupons cannot be applied
A coupon past its `expires_at` date is rejected even if otherwise valid.

```
ENFORCED BY: fn_calculate_discount checks NOW() < expires_at
```

### BR-C3 — Coupons not yet started cannot be applied
A coupon before its `starts_at` date is also rejected.

```
ENFORCED BY: fn_calculate_discount checks NOW() >= starts_at
```

### BR-C4 — Usage limit is respected
If `usage_limit = 100` and `usage_count = 100`, the coupon is exhausted.

```
ENFORCED BY: fn_calculate_discount checks usage_count < usage_limit
             sp_place_order increments usage_count after successful apply
```

### BR-C5 — Minimum order amount is enforced
A coupon with `min_order_amount = 500` cannot be applied to a cart below ₹500.

```
ENFORCED BY: fn_calculate_discount checks subtotal >= min_order_amount
```

### BR-C6 — Percentage discounts are capped
If a coupon gives 30% off but has `max_discount_amount = 200`,  
a ₹1000 order gets ₹200 off (not ₹300).

```
ENFORCED BY: fn_calculate_discount applies MIN(calculated_discount, max_discount_amount)
```

### BR-C7 — One coupon per order
A single order can use at most one coupon code.

```
ENFORCED BY: orders table has a single coupon_id column (not a list)
```

---

## 5. Payment Rules

### BR-PAY1 — Payment amount must match order total
The payment amount must equal the order's `total_amount`.

```
ENFORCED BY: sp_process_payment validates amount = orders.total_amount
```

### BR-PAY2 — A completed order cannot be paid again
If `payment_status = 'completed'` already exists for an order,  
no new completed payment can be added.

```
ENFORCED BY: sp_process_payment checks for existing completed payment
```

### BR-PAY3 — Failed payments are recorded but don't update order status
If a payment attempt fails, it is saved with `payment_status = 'failed'`  
so we have a record of the attempt. The order stays in 'pending'.

```
ENFORCED BY: sp_process_payment INSERT with status='failed', no order UPDATE
```

### BR-PAY4 — Refunds are only allowed on delivered orders
You can only refund an order after it has been delivered.

```
ENFORCED BY: Application layer checks order.status = 'delivered' before refund
```

---

## 6. Shipment Rules

### BR-SH1 — A shipment is only created after payment is confirmed
Orders in 'pending' or 'failed' payment state cannot be shipped.

```
ENFORCED BY: Application layer — shipment INSERT only after payment_status = 'completed'
```

### BR-SH2 — Tracking number is set when shipment is dispatched
When `shipments.status` changes to 'dispatched', a tracking number must be provided.

```
ENFORCED BY: Application layer validation
```

### BR-SH3 — Delivered timestamp is recorded automatically
When status changes to 'delivered', `delivered_at` is set to NOW().

```
ENFORCED BY: Application layer or UPDATE trigger on shipments
```

---

## 7. Review Rules

### BR-R1 — Only verified buyers can leave reviews
A review must be linked to a real `order_id` that belongs to the same `user_id`  
and contains the `product_id` being reviewed.

```
ENFORCED BY: FK constraints on reviews (order_id, user_id, product_id)
             Application layer validates user owns order and ordered this product
```

### BR-R2 — One review per product per order
A user cannot submit two reviews for the same product from the same order.

```
ENFORCED BY: UNIQUE constraint on reviews(product_id, user_id, order_id)
```

### BR-R3 — Ratings must be between 1 and 5
No rating of 0, 6, or any other value is allowed.

```
ENFORCED BY: CHECK constraint — rating BETWEEN 1 AND 5
```

### BR-R4 — Reviews require admin approval before going public
A new review is hidden (`is_approved = 0`) until an admin approves it.

```
ENFORCED BY: DEFAULT 0 on reviews.is_approved
             Application layer only shows reviews WHERE is_approved = 1
```

---

## 8. Wishlist Rules

### BR-W1 — No duplicate wishlist entries
A user cannot save the same product to their wishlist twice.

```
ENFORCED BY: UNIQUE constraint on wishlist(user_id, product_id)
```

### BR-W2 — Wishlist items are user-private
A user can only see their own wishlist items.

```
ENFORCED BY: Application layer always filters WHERE user_id = current_user
```

---

## 9. Audit Rules

### BR-A1 — All user record changes are logged
Every INSERT, UPDATE, or DELETE on the `users` table  
is automatically recorded in `audit_log`.

```
ENFORCED BY: Trigger trg_audit_users
```

### BR-A2 — All order status changes are logged
Every time an order status changes, the before and after values  
are saved in `audit_log`.

```
ENFORCED BY: Trigger trg_audit_orders
```

### BR-A3 — Audit log is append-only
Rows in `audit_log` are never updated or deleted.  
The log is a permanent, tamper-evident history.

```
ENFORCED BY: No UPDATE or DELETE permissions granted on audit_log in production
             Application never writes to audit_log directly
```

---

## 10. How Rules Are Enforced

Different rules need different enforcement mechanisms. Here's the full picture:

| Mechanism              | What It Does                                                  | Example Rule         |
|------------------------|---------------------------------------------------------------|----------------------|
| **NOT NULL**           | Column must always have a value                               | BR-P1                |
| **UNIQUE**             | No two rows can have the same value in this column            | BR-U1, BR-W1         |
| **FOREIGN KEY**        | Value must exist in the referenced table                      | BR-R1                |
| **CHECK constraint**   | Value must satisfy a condition                                | BR-P3, BR-R3         |
| **DEFAULT value**      | Automatically fills in a safe value when none is provided     | BR-R4                |
| **ENUM**               | Column only accepts values from a fixed list                  | BR-U5, BR-O6         |
| **Stored Procedure**   | Business logic runs atomically inside the database            | BR-O1, BR-C4         |
| **Trigger**            | Automatic action fires when data changes                      | BR-A1, BR-O4         |
| **Application layer**  | Checks done in the backend before touching the database       | BR-U2, BR-U4         |

---

## Summary — Rules at a Glance

| Category   | Count | Hardest Rule to Get Right         |
|------------|-------|-----------------------------------|
| Users      | 5     | Soft deletes preserving order history |
| Products   | 8     | Stock never going negative         |
| Orders     | 7     | Price snapshot on purchase         |
| Coupons    | 7     | Stacking all validation conditions |
| Payments   | 4     | Preventing double payment          |
| Shipments  | 3     | Requiring payment before shipping  |
| Reviews    | 4     | Verified buyer only                |
| Wishlist   | 2     | Duplicate prevention               |
| Audit      | 3     | Append-only, tamper-evident log    |
| **Total**  | **43**| —                                 |

---

*Last updated: 2024 | Part of the E-Commerce SQL Portfolio Project*
