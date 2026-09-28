-- Additive application capabilities; original records remain unchanged.
CREATE TABLE sessions (token_hash TEXT PRIMARY KEY, user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE, expires_at INTEGER NOT NULL);
CREATE INDEX sessions_expiry ON sessions(expires_at);
CREATE TABLE rate_limits (key TEXT PRIMARY KEY, count INTEGER NOT NULL, expires_at INTEGER NOT NULL);
CREATE TABLE cart_items (user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE, product_id INTEGER NOT NULL REFERENCES products(product_id), quantity INTEGER NOT NULL CHECK(quantity BETWEEN 1 AND 20), PRIMARY KEY(user_id,product_id));
CREATE TABLE interactions (user_id INTEGER NOT NULL REFERENCES users(user_id) ON DELETE CASCADE, product_id INTEGER NOT NULL REFERENCES products(product_id), kind TEXT NOT NULL CHECK(kind IN ('view','cart','wishlist')), weight INTEGER NOT NULL DEFAULT 1, updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(user_id,product_id,kind));
CREATE INDEX interactions_recent ON interactions(user_id,updated_at DESC);
CREATE TABLE recommendation_preferences (user_id INTEGER PRIMARY KEY REFERENCES users(user_id), enabled INTEGER NOT NULL DEFAULT 1 CHECK(enabled IN (0,1)));
CREATE TABLE review_sentiment (review_id INTEGER PRIMARY KEY REFERENCES reviews(review_id) ON DELETE CASCADE, score REAL NOT NULL CHECK(score BETWEEN -1 AND 1), model_version TEXT NOT NULL, analyzed_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE product_media (product_id INTEGER PRIMARY KEY REFERENCES products(product_id), image_url TEXT NOT NULL, source_url TEXT NOT NULL, is_illustrative INTEGER NOT NULL DEFAULT 0);
ALTER TABLE orders ADD COLUMN checkout_key TEXT;
CREATE UNIQUE INDEX orders_checkout_key ON orders(user_id,checkout_key) WHERE checkout_key IS NOT NULL;
CREATE TRIGGER checkout_stock BEFORE INSERT ON order_items WHEN NOT EXISTS (SELECT 1 FROM products p JOIN categories c ON c.category_id=p.category_id JOIN inventory i ON i.product_id=p.product_id WHERE p.product_id=NEW.product_id AND p.status='active' AND p.deleted_at IS NULL AND c.is_active=1 AND i.quantity_in_stock-i.quantity_reserved>=NEW.quantity) BEGIN
  SELECT RAISE(ABORT,'Product unavailable or insufficient inventory');
END;
CREATE TRIGGER checkout_decrement AFTER INSERT ON order_items BEGIN
  UPDATE inventory SET quantity_in_stock=quantity_in_stock-NEW.quantity WHERE product_id=NEW.product_id;
END;
CREATE TRIGGER verify_new_review BEFORE INSERT ON reviews WHEN NOT EXISTS (SELECT 1 FROM orders o JOIN order_items oi ON oi.order_id=o.order_id JOIN payments pay ON pay.order_id=o.order_id AND pay.payment_status='completed' WHERE o.order_id=NEW.order_id AND o.user_id=NEW.user_id AND oi.product_id=NEW.product_id AND o.status IN ('confirmed','processing','shipped','delivered')) BEGIN
  SELECT RAISE(ABORT,'Verified purchase required');
END;
CREATE TRIGGER audit_order_status AFTER UPDATE OF status ON orders WHEN NEW.status!=OLD.status BEGIN
 INSERT INTO audit_log(table_name,record_id,action,changed_by,old_values,new_values) VALUES('orders',NEW.order_id,'UPDATE',NULL,json_object('status',OLD.status),json_object('status',NEW.status));
END;
CREATE TRIGGER audit_user_role AFTER UPDATE OF role,is_active ON users BEGIN
 INSERT INTO audit_log(table_name,record_id,action,old_values,new_values) VALUES('users',NEW.user_id,'UPDATE',json_object('role',OLD.role,'is_active',OLD.is_active),json_object('role',NEW.role,'is_active',NEW.is_active));
END;
