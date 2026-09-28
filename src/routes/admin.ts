import { Hono } from "hono";
import { HTTPException } from "hono/http-exception";
import { z } from "zod";
import type { AppEnv } from "../types";
import { requireAdmin } from "../security";
import { productSelect } from "../db";
export const admin = new Hono<AppEnv>();
admin.use("*", requireAdmin);
admin.get("/overview", async (c) => {
  const [summary, products, orders, customers, categories, reviews] =
    await c.env.DB.batch([
      c.env.DB.prepare(
        `SELECT (SELECT COUNT(*) FROM users WHERE role='customer') customers,(SELECT COUNT(*) FROM orders) orders,(SELECT COALESCE(SUM(total_amount),0) FROM orders WHERE status IN ('confirmed','processing','shipped','delivered')) revenue,(SELECT COUNT(*) FROM inventory WHERE quantity_in_stock-quantity_reserved<=reorder_threshold) low_stock`,
      ),
      c.env.DB.prepare(
        `${productSelect.replace("SELECT p.product_id", "SELECT i.quantity_in_stock,i.quantity_reserved,p.product_id")} ORDER BY p.product_id LIMIT 200`,
      ),
      c.env.DB.prepare(
        "SELECT o.order_id,o.order_number,o.status,o.total_amount,o.created_at,u.first_name FROM orders o JOIN users u ON u.user_id=o.user_id ORDER BY o.order_id DESC LIMIT 100",
      ),
      c.env.DB.prepare(
        "SELECT user_id,first_name,last_name,email,role,is_active,created_at FROM users ORDER BY user_id DESC LIMIT 100",
      ),
      c.env.DB.prepare("SELECT * FROM categories ORDER BY category_id"),
      c.env.DB.prepare(
        "SELECT r.*,p.name product_name FROM reviews r JOIN products p ON p.product_id=r.product_id ORDER BY review_id DESC LIMIT 100",
      ),
    ]);
  return c.json({
    summary: summary.results[0],
    products: products.results,
    orders: orders.results,
    customers: customers.results,
    categories: categories.results,
    reviews: reviews.results,
  });
});
admin.patch("/products/:id", async (c) => {
  const id = z.coerce.number().int().positive().parse(c.req.param("id"));
  const d = z
    .object({
      name: z.string().trim().min(2).max(255),
      price: z.number().positive().max(10000000),
      status: z.enum(["active", "inactive", "draft", "archived"]),
      quantity_in_stock: z.number().int().min(0).max(1000000),
    })
    .parse(await c.req.json());
  const p = await c.env.DB.prepare(
    "SELECT product_id FROM products WHERE product_id=?",
  )
    .bind(id)
    .first();
  if (!p) throw new HTTPException(404, { message: "Product not found." });
  await c.env.DB.batch([
    c.env.DB.prepare(
      "UPDATE products SET name=?,price=?,compare_price=CASE WHEN compare_price<=? THEN NULL ELSE compare_price END,status=? WHERE product_id=?",
    ).bind(d.name, d.price, d.price, d.status, id),
    c.env.DB.prepare(
      "UPDATE inventory SET quantity_in_stock=? WHERE product_id=?",
    ).bind(d.quantity_in_stock, id),
  ]);
  return c.json({ success: true });
});
admin.post("/products", async (c) => {
  const d = z
    .object({
      name: z.string().trim().min(2).max(255),
      category_id: z.number().int().positive(),
      price: z.number().positive().max(10000000),
      description: z.string().trim().min(10).max(5000),
      stock: z.number().int().min(0).max(1000000),
    })
    .parse(await c.req.json());
  const sku = "SE-" + crypto.randomUUID().slice(0, 8);
  const slug =
    d.name.toLowerCase().replace(/[^a-z0-9]+/g, "-") + "-" + sku.toLowerCase();
  await c.env.DB.batch([
    c.env.DB.prepare(
      "INSERT INTO products(name,category_id,price,description,short_desc,sku,slug,status) VALUES(?,?,?,?,?,?,?,'active')",
    ).bind(
      d.name,
      d.category_id,
      d.price,
      d.description,
      d.description.slice(0, 200),
      sku,
      slug,
    ),
    c.env.DB.prepare(
      "INSERT INTO inventory(product_id,quantity_in_stock) VALUES(last_insert_rowid(),?)",
    ).bind(d.stock),
  ]);
  return c.json({ success: true }, 201);
});
admin.patch("/orders/:id", async (c) => {
  const id = z.coerce.number().int().positive().parse(c.req.param("id"));
  const d = z
    .object({
      status: z.enum(["confirmed", "processing", "shipped", "delivered"]),
    })
    .parse(await c.req.json());
  const current = await c.env.DB.prepare(
    "SELECT status FROM orders WHERE order_id=?",
  )
    .bind(id)
    .first<any>();
  const transitions: Record<string, string[]> = {
    confirmed: ["processing"],
    processing: ["shipped"],
    shipped: ["delivered"],
  };
  if (!current) throw new HTTPException(404, { message: "Order not found." });
  if (!transitions[current.status]?.includes(d.status))
    throw new HTTPException(409, {
      message: "Only the next fulfillment step is allowed.",
    });
  await c.env.DB.prepare(
    "UPDATE orders SET status=? WHERE order_id=? AND status=?",
  )
    .bind(d.status, id, current.status)
    .run();
  return c.json({ success: true });
});
admin.patch("/customers/:id", async (c) => {
  const id = z.coerce.number().int().positive().parse(c.req.param("id"));
  const d = z.object({ is_active: z.boolean() }).parse(await c.req.json());
  if (id === c.get("user")!.user_id)
    throw new HTTPException(400, {
      message: "You cannot suspend your own account.",
    });
  await c.env.DB.batch([
    c.env.DB.prepare(
      "UPDATE users SET is_active=? WHERE user_id=? AND role='customer'",
    ).bind(d.is_active ? 1 : 0, id),
    c.env.DB.prepare("DELETE FROM sessions WHERE user_id=?").bind(id),
  ]);
  return c.json({ success: true });
});
admin.patch("/reviews/:id", async (c) => {
  const id = z.coerce.number().int().positive().parse(c.req.param("id"));
  const d = z.object({ is_approved: z.boolean() }).parse(await c.req.json());
  if (d.is_approved) {
    const valid = await c.env.DB.prepare(
      `SELECT r.review_id FROM reviews r JOIN orders o ON o.order_id=r.order_id JOIN order_items oi ON oi.order_id=o.order_id AND oi.product_id=r.product_id WHERE r.review_id=? AND o.user_id=r.user_id AND o.status IN ('confirmed','processing','shipped','delivered')`,
    )
      .bind(id)
      .first();
    if (!valid)
      throw new HTTPException(400, {
        message: "This review does not have a valid purchase.",
      });
  }
  await c.env.DB.prepare("UPDATE reviews SET is_approved=? WHERE review_id=?")
    .bind(d.is_approved ? 1 : 0, id)
    .run();
  return c.json({ success: true });
});
admin.post("/categories", async (c) => {
  const d = z
    .object({ name: z.string().trim().min(2).max(100) })
    .parse(await c.req.json());
  await c.env.DB.prepare("INSERT INTO categories(name,slug) VALUES(?,?)")
    .bind(
      d.name,
      d.name.toLowerCase().replace(/[^a-z0-9]+/g, "-") +
        "-" +
        crypto.randomUUID().slice(0, 6),
    )
    .run();
  return c.json({ success: true }, 201);
});
admin.patch("/categories/:id", async (c) => {
  const d = z
    .object({ name: z.string().trim().min(2).max(100) })
    .parse(await c.req.json());
  await c.env.DB.prepare("UPDATE categories SET name=? WHERE category_id=?")
    .bind(d.name, z.coerce.number().int().positive().parse(c.req.param("id")))
    .run();
  return c.json({ success: true });
});
admin.get("/model-data", async (c) => {
  const data = await c.env.DB.batch([
    c.env.DB.prepare(
      "SELECT product_id,category_id,brand_id,name,description,price FROM products WHERE deleted_at IS NULL",
    ),
    c.env.DB.prepare(
      `SELECT o.user_id,oi.product_id,oi.quantity FROM orders o JOIN order_items oi ON oi.order_id=o.order_id WHERE o.status IN ('confirmed','processing','shipped','delivered') AND EXISTS(SELECT 1 FROM payments pay WHERE pay.order_id=o.order_id AND pay.payment_status='completed')`,
    ),
    c.env.DB.prepare(
      "SELECT review_id,product_id,rating,body FROM reviews WHERE is_approved=1",
    ),
    c.env.DB.prepare(
      "SELECT product_id,attribute_name,attribute_value FROM product_attributes",
    ),
  ]);
  return c.json({
    products: data[0].results,
    purchases: data[1].results,
    reviews: data[2].results,
    attributes: data[3].results,
  });
});
admin.put("/sentiment", async (c) => {
  const d = z
    .object({
      review_id: z.number().int().positive(),
      score: z.number().min(-1).max(1),
      model_version: z.string().min(1).max(100),
    })
    .parse(await c.req.json());
  await c.env.DB.prepare(
    "INSERT INTO review_sentiment(review_id,score,model_version) VALUES(?,?,?) ON CONFLICT(review_id) DO UPDATE SET score=excluded.score,model_version=excluded.model_version,analyzed_at=CURRENT_TIMESTAMP",
  )
    .bind(d.review_id, d.score, d.model_version)
    .run();
  return c.json({ success: true });
});
