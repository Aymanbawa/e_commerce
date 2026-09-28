# 🛒 Production-Ready E-Commerce SQL Database

A production-ready **MySQL 8** database built for a modern E-Commerce platform. This project demonstrates industry-standard database design, normalization, SQL programming, and reporting techniques commonly used in real-world applications.

---

## 👨‍💻 Author

**Mustheer Shaikh**

📍 Goa, India

- 🔗 GitHub: https://github.com/mustheers-del
- 💼 LinkedIn: https://www.linkedin.com/in/mustheer-shaikh-81ab55320

---

## 📌 Project Overview

This project simulates the backend database of an online shopping platform. It includes customer management, products, inventory, orders, payments, shipments, reviews, coupons, reporting, and audit logging.

The database is fully normalized and designed following best practices to ensure data integrity, scalability, and maintainability.

---

## 🚀 Features

- ✅ 16 Fully Normalized Tables (3NF)
- ✅ Primary & Foreign Key Relationships
- ✅ Stored Procedures
- ✅ SQL Functions
- ✅ Database Triggers
- ✅ Analytical Views
- ✅ Performance Indexes
- ✅ Audit Logging
- ✅ Realistic Seed Data
- ✅ Reporting Queries
- ✅ Test Scripts
- ✅ Production-Oriented Folder Structure

---

# 🗂 Project Structure

```text
ecommerce-sql-database/
│
├── docs/               # Documentation
├── schema/             # Database schema
├── indexes/            # Index definitions
├── routines/           # Stored procedures & functions
├── triggers/           # Database triggers
├── views/              # SQL views
├── seeds/              # Sample data
├── queries/            # Analytical queries
├── tests/              # Testing scripts
├── setup.sql           # Complete project setup
└── README.md
```

---

# 🏗 Database Modules

| Module | Description |
|---------|-------------|
| Users | Customer accounts |
| Addresses | Shipping & Billing Addresses |
| Categories | Product Categories |
| Brands | Product Brands |
| Products | Product Catalogue |
| Inventory | Stock Management |
| Coupons | Discount System |
| Orders | Customer Orders |
| Order Items | Purchased Products |
| Payments | Payment Records |
| Shipments | Shipping Information |
| Reviews | Customer Reviews |
| Wishlist | Saved Products |
| Audit Log | Database Activity Logs |

---

# ⚙ Technologies Used

- MySQL 8
- SQL
- MySQL Workbench
- Git
- GitHub

---

# 📊 Database Design

The database follows **Third Normal Form (3NF)** to eliminate redundancy and maintain consistency.

### Normalization

- ✔ First Normal Form (1NF)
- ✔ Second Normal Form (2NF)
- ✔ Third Normal Form (3NF)

### Design Principles

- Proper Primary Keys
- Foreign Key Constraints
- Referential Integrity
- Cascading Relationships
- Data Validation
- Optimized Indexing

---

# 📈 Business Features

- Customer Registration
- Address Management
- Product Catalogue
- Inventory Tracking
- Coupon Management
- Order Processing
- Payment Processing
- Shipment Tracking
- Product Reviews
- Wishlist
- Sales Reporting
- Customer Analytics
- Low Stock Alerts
- Audit Logging

---

# 📷 Entity Relationship Diagram

The complete ER Diagram is available in:

```text
docs/erd.png
```

---

# 📁 Folder Summary

| Folder | Files | Purpose |
|---------|------:|---------|
| schema | 17 | Database Tables |
| routines | 5 | Stored Procedures & Functions |
| triggers | 3 | Automation |
| views | 4 | Reporting Views |
| queries | 4 | Analytics |
| seeds | 8 | Sample Data |
| tests | 3 | Validation |
| docs | 4 | Documentation |

---

# ▶ Getting Started

## Clone the Repository

```bash
git clone https://github.com/mustheers-del/ecommerce-sql-database.git
```

## Run Complete Database

```sql
SOURCE setup.sql;
```

Or execute each SQL file individually from the `schema/` directory.

---

# 📊 Sample Analytics

The project includes SQL queries for:

- Total Revenue
- Monthly Sales
- Best Selling Products
- Customer Insights
- Coupon Performance
- Inventory Reports
- Low Stock Alerts

---

# 💼 Skills Demonstrated

- Relational Database Design
- SQL Programming
- Database Normalization
- Stored Procedures
- Functions
- Triggers
- Views
- Index Optimization
- Query Writing
- Reporting
- Data Integrity
- Business Logic
- Database Testing

---

# ⭐ Repository Highlights

- Production-Level Database Design
- Clean Folder Structure
- Modular SQL Scripts
- Realistic Sample Data
- Easy Setup
- Portfolio Ready

---

## 🧪 How to Test

After running setup.sql, test the project with these commands:

### Place an Order
```sql
CALL sp_place_order(
    3, 3, 'SAVE200',
    '[{"product_id":7,"quantity":2},{"product_id":13,"quantity":1}]',
    'Leave at door',
    @order_id
);
SELECT @order_id;
```

### Process Payment
```sql
CALL sp_process_payment(
    @order_id, 'upi', 0,
    'UPI123456789', 'completed',
    '{"gateway":"razorpay"}',
    @success, @message
);
SELECT @success, @message;
```

### Check Low Stock
```sql
SELECT product_name, quantity_in_stock, alert_level
FROM vw_low_stock_alert;
```

### View All Orders
```sql
SELECT order_number, customer_name, order_status, total_amount
FROM vw_order_summary;
```

# 📄 License

This project is released for educational and portfolio purposes.
