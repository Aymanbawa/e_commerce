import { Hono } from "hono";
import { HTTPException } from "hono/http-exception";
import { z } from "zod";
import type { AppEnv } from "../types";
import { productSelect, activeProduct } from "../db";
import { requireUser } from "../security";
export const commerce = new Hono<AppEnv>();
commerce.use("*", requireUser);
const positive = z.coerce.number().int().positive();
commerce.get("/cart", async (c) => {
  const uid = c.get("user")!.user_id;
  const [products, quantities] = await Promise.all([
    c.env.DB.prepare(
      `${productSelect} JOIN cart_items ci ON ci.product_id=p.product_id WHERE ci.user_id=?`,
    )
      .bind(uid)
      .all(),
    c.env.DB.prepare(
      "SELECT product_id,quantity FROM cart_items WHERE user_id=?",
    )
      .bind(uid)
      .all<any>(),
  ]);
  const items = products.results.map((p) => ({
    ...p,
    quantity: quantities.results.find((q) => q.product_id === p.product_id)!
      .quantity,
  }));
  return c.json({
    items,
    total:
      items.reduce(
        (sum: number, p: any) => sum + Math.round(p.price * 100) * p.quantity,
        0,
      ) / 100,
  });
});
commerce.get("/wishlist", async (c) =>
  c.json({
    products: (
      await c.env.DB.prepare(
        `${productSelect} JOIN wishlist w ON w.product_id=p.product_id WHERE ${activeProduct} AND w.user_id=? ORDER BY w.created_at DESC`,
      )
        .bind(c.get("user")!.user_id)
        .all()
    ).results,
  }),
);
commerce.put("/wishlist/:id", async (c) => {
  const id = positive.parse(c.req.param("id"));
  const p = await c.env.DB.prepare(
    `SELECT p.product_id FROM products p JOIN categories c ON c.category_id=p.category_id WHERE ${activeProduct} AND p.product_id=?`,
  )
    .bind(id)
    .first();
  if (!p) throw new HTTPException(404, { message: "Product not found." });
  await c.env.DB.prepare(
    "INSERT OR IGNORE INTO wishlist(user_id,product_id) VALUES(?,?)",
  )
    .bind(c.get("user")!.user_id, id)
    .run();
  return c.json({ success: true });
});
commerce.delete("/wishlist/:id", async (c) => {
  await c.env.DB.prepare(
    "DELETE FROM wishlist WHERE user_id=? AND product_id=?",
  )
    .bind(c.get("user")!.user_id, positive.parse(c.req.param("id")))
    .run();
  return c.json({ success: true });
});
commerce.put("/cart/:id", async (c) => {
  const id = positive.parse(c.req.param("id"));
  const d = z
    .object({ quantity: z.number().int().min(0).max(20) })
    .parse(await c.req.json());
  const uid = c.get("user")!.user_id;
  if (!d.quantity) {
    await c.env.DB.prepare(
      "DELETE FROM cart_items WHERE user_id=? AND product_id=?",
    )
      .bind(uid, id)
      .run();
    return c.json({ success: true });
  }
  const product = await c.env.DB.prepare(
    `${productSelect} WHERE ${activeProduct} AND p.product_id=?`,
  )
    .bind(id)
    .first<any>();
  if (!product) throw new HTTPException(404, { message: "Product not found." });
  if (product.available < d.quantity)
    throw new HTTPException(409, {
      message: "Not enough stock for this quantity.",
    });
  const n = await c.env.DB.prepare(
    "SELECT COUNT(*) n FROM cart_items WHERE user_id=?",
  )
    .bind(uid)
    .first<any>();
  if (n.n >= 40)
    throw new HTTPException(400, {
      message: "Your bag can hold up to 40 different products.",
    });
  await c.env.DB.prepare(
    "INSERT INTO cart_items(user_id,product_id,quantity) VALUES(?,?,?) ON CONFLICT(user_id,product_id) DO UPDATE SET quantity=excluded.quantity",
  )
    .bind(uid, id, d.quantity)
    .run();
  return c.json({ success: true });
});
commerce.get("/orders", async (c) => {
  const uid = c.get("user")!.user_id;
  const orders = (
    await c.env.DB.prepare(
      "SELECT order_id,order_number,status,subtotal,total_amount,created_at,notes FROM orders WHERE user_id=? ORDER BY order_id DESC LIMIT 100",
    )
      .bind(uid)
      .all()
  ).results;
  const items = (
    await c.env.DB.prepare(
      "SELECT oi.* FROM order_items oi JOIN orders o ON o.order_id=oi.order_id WHERE o.user_id=? ORDER BY o.order_id DESC LIMIT 1000",
    )
      .bind(uid)
      .all()
  ).results;
  return c.json({
    orders: orders.map((o) => ({
      ...o,
      items: items.filter((i) => i.order_id === o.order_id),
    })),
  });
});
commerce.get("/orders/:id", async (c) => {
  const order = await c.env.DB.prepare(
    "SELECT o.*,a.full_name,a.address_line1,a.city,a.state,a.postal_code,a.country FROM orders o JOIN addresses a ON a.address_id=o.address_id WHERE o.order_id=? AND o.user_id=?",
  )
    .bind(positive.parse(c.req.param("id")), c.get("user")!.user_id)
    .first();
  if (!order) throw new HTTPException(404, { message: "Order not found." });
  const [items, payments] = await Promise.all([
    c.env.DB.prepare("SELECT * FROM order_items WHERE order_id=?")
      .bind(order.order_id)
      .all(),
    c.env.DB.prepare(
      "SELECT payment_method,payment_status,amount,currency,transaction_id FROM payments WHERE order_id=?",
    )
      .bind(order.order_id)
      .all(),
  ]);
  return c.json({ order, items: items.results, payments: payments.results });
});
commerce.post("/checkout", async (c): Promise<Response> => {
  const d = z
    .object({
      full_name: z.string().trim().min(2).max(200),
      phone: z.string().trim().min(5).max(20),
      address_line1: z.string().trim().min(5).max(255),
      city: z.string().trim().min(2).max(100),
      state: z.string().trim().min(2).max(100),
      postal_code: z.string().trim().min(3).max(20),
      country: z.literal("India"),
      demo_payment: z.literal(true),
      checkout_key: z.string().uuid(),
    })
    .parse(await c.req.json());
  const uid = c.get("user")!.user_id;
  const db = c.env.DB;
  const previous = await db
    .prepare(
      "SELECT order_id,order_number FROM orders WHERE user_id=? AND checkout_key=?",
    )
    .bind(uid, d.checkout_key)
    .first();
  if (previous) return c.json({ order: previous });
  const n = await db
    .prepare("SELECT COUNT(*) n FROM cart_items WHERE user_id=?")
    .bind(uid)
    .first<any>();
  if (!n.n) throw new HTTPException(400, { message: "Your bag is empty." });
  const number = "SE-" + crypto.randomUUID().slice(0, 8).toUpperCase();
  const orderId = `(SELECT order_id FROM orders WHERE order_number=?)`;
  try {
    await db.batch([
      db
        .prepare(
          "INSERT INTO addresses(user_id,full_name,phone,address_line1,city,state,postal_code,country) VALUES(?,?,?,?,?,?,?,?)",
        )
        .bind(
          uid,
          d.full_name,
          d.phone,
          d.address_line1,
          d.city,
          d.state,
          d.postal_code,
          d.country,
        ),
      db
        .prepare(
          `INSERT INTO orders(user_id,address_id,order_number,status,subtotal,total_amount,notes,checkout_key) SELECT ?,last_insert_rowid(),?,'confirmed',ROUND(SUM(p.price*ci.quantity),2),ROUND(SUM(p.price*ci.quantity),2),'DEMO PAYMENT: no money charged; no physical fulfillment',? FROM cart_items ci JOIN products p ON p.product_id=ci.product_id WHERE ci.user_id=?`,
        )
        .bind(uid, number, d.checkout_key, uid),
      db
        .prepare(
          `INSERT INTO order_items(order_id,product_id,product_name,product_sku,quantity,unit_price,total_price) SELECT ${orderId},p.product_id,p.name,p.sku,ci.quantity,p.price,ROUND(p.price*ci.quantity,2) FROM cart_items ci JOIN products p ON p.product_id=ci.product_id WHERE ci.user_id=?`,
        )
        .bind(number, uid),
      db
        .prepare(
          `INSERT INTO payments(order_id,payment_method,payment_status,amount,transaction_id,gateway_response,paid_at) SELECT order_id,'wallet','completed',total_amount,?,'{"demo":true,"charged":false}',CURRENT_TIMESTAMP FROM orders WHERE order_number=?`,
        )
        .bind("DEMO-" + number, number),
      db.prepare("DELETE FROM cart_items WHERE user_id=?").bind(uid),
    ]);
  } catch (e) {
    const existing = await db
      .prepare(
        "SELECT order_id,order_number FROM orders WHERE user_id=? AND checkout_key=?",
      )
      .bind(uid, d.checkout_key)
      .first();
    if (existing) return c.json({ order: existing });
    if (/inventory|unavailable|NOT NULL|CHECK/.test(String(e)))
      throw new HTTPException(409, {
        message: "Your bag or stock changed. Refresh and try again.",
      });
    throw e;
  }
  return c.json(
    {
      order: await db
        .prepare(
          "SELECT order_id,order_number FROM orders WHERE order_number=?",
        )
        .bind(number)
        .first(),
    },
    201,
  );
});
commerce.get("/reviews", async (c) =>
  c.json({
    reviews: (
      await c.env.DB.prepare(
        "SELECT r.*,p.name product_name FROM reviews r JOIN products p ON p.product_id=r.product_id WHERE user_id=? ORDER BY review_id DESC",
      )
        .bind(c.get("user")!.user_id)
        .all()
    ).results,
  }),
);
commerce.post("/reviews", async (c) => {
  const d = z
    .object({
      product_id: z.number().int().positive(),
      order_id: z.number().int().positive(),
      rating: z.number().int().min(1).max(5),
      title: z.string().trim().min(2).max(150),
      body: z.string().trim().min(10).max(3000),
    })
    .parse(await c.req.json());
  try {
    await c.env.DB.prepare(
      "INSERT INTO reviews(product_id,user_id,order_id,rating,title,body,is_approved) VALUES(?,?,?,?,?,?,1)",
    )
      .bind(
        d.product_id,
        c.get("user")!.user_id,
        d.order_id,
        d.rating,
        d.title,
        d.body,
      )
      .run();
  } catch (e) {
    if (String(e).includes("Verified purchase"))
      throw new HTTPException(403, {
        message: "Only completed purchases can be reviewed.",
      });
    if (String(e).includes("UNIQUE"))
      throw new HTTPException(409, {
        message: "You have already reviewed this purchase.",
      });
    throw e;
  }
  return c.json({ success: true }, 201);
});
