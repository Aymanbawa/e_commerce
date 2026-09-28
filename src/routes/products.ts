import { Hono } from "hono";
import { HTTPException } from "hono/http-exception";
import { z } from "zod";
import type { AppEnv } from "../types";
import { productSelect, activeProduct } from "../db";
import { requireUser } from "../security";
export const products = new Hono<AppEnv>();
products.get("/categories", async (c) =>
  c.json({
    categories: (
      await c.env.DB.prepare(
        "SELECT category_id,parent_id,name,slug,description FROM categories WHERE is_active=1 ORDER BY sort_order,category_id",
      ).all()
    ).results,
  }),
);
products.get("/products", async (c) => {
  const q = z
    .object({
      q: z.string().max(200).default(""),
      category: z.coerce.number().int().nonnegative().default(0),
      min: z.coerce.number().nonnegative().default(0),
      max: z.coerce.number().nonnegative().default(10000000),
      page: z.coerce.number().int().min(1).max(10000).default(1),
      limit: z.coerce.number().int().min(1).max(50).default(12),
      sort: z
        .enum(["featured", "price-asc", "price-desc", "rating", "newest"])
        .default("featured"),
    })
    .parse(c.req.query());
  const filter = `${activeProduct} AND (?='' OR p.name LIKE ? OR COALESCE(p.description,'') LIKE ? OR p.category_id IN (WITH RECURSIVE matches(id) AS (SELECT category_id FROM categories WHERE name LIKE ? UNION ALL SELECT cat.category_id FROM categories cat JOIN matches m ON cat.parent_id=m.id) SELECT id FROM matches)) AND p.price BETWEEN ? AND ? AND (?=0 OR p.category_id IN (WITH RECURSIVE tree(id) AS (SELECT category_id FROM categories WHERE category_id=? UNION ALL SELECT c.category_id FROM categories c JOIN tree t ON c.parent_id=t.id) SELECT id FROM tree))`;
  const args = [
    q.q,
    ...Array(3).fill("%" + q.q + "%"),
    q.min,
    q.max,
    q.category,
    q.category,
  ];
  const sort = {
    featured: "p.is_featured DESC,p.product_id",
    "price-asc": "p.price ASC",
    "price-desc": "p.price DESC",
    rating: "rating DESC,p.product_id",
    newest: "p.product_id DESC",
  }[q.sort];
  const [items, count] = await Promise.all([
    c.env.DB.prepare(
      `${productSelect} WHERE ${filter} ORDER BY ${sort} LIMIT ? OFFSET ?`,
    )
      .bind(...args, q.limit, (q.page - 1) * q.limit)
      .all(),
    c.env.DB.prepare(
      `SELECT COUNT(*) total FROM products p JOIN categories c ON c.category_id=p.category_id WHERE ${filter}`,
    )
      .bind(...args)
      .first(),
  ]);
  return c.json({
    products: items.results,
    total: count!.total,
    page: q.page,
    limit: q.limit,
  });
});
products.get("/products/:id", async (c) => {
  const id = z.coerce.number().int().positive().parse(c.req.param("id"));
  const p = await c.env.DB.prepare(
    `${productSelect} WHERE ${activeProduct} AND p.product_id=?`,
  )
    .bind(id)
    .first();
  if (!p) throw new HTTPException(404, { message: "Product not found." });
  const [attributes, reviews] = await Promise.all([
    c.env.DB.prepare(
      "SELECT attribute_name,attribute_value FROM product_attributes WHERE product_id=? ORDER BY sort_order",
    )
      .bind(id)
      .all(),
    c.env.DB.prepare(
      `SELECT r.review_id,r.rating,r.title,r.body,r.created_at,u.first_name,1 verified FROM reviews r JOIN users u ON u.user_id=r.user_id WHERE r.product_id=? AND r.is_approved=1 AND EXISTS(SELECT 1 FROM orders o JOIN order_items oi ON oi.order_id=o.order_id WHERE o.order_id=r.order_id AND o.user_id=r.user_id AND oi.product_id=r.product_id AND o.status IN ('confirmed','processing','shipped','delivered')) ORDER BY r.created_at DESC LIMIT 100`,
    )
      .bind(id)
      .all(),
  ]);
  return c.json({
    product: p,
    attributes: attributes.results,
    reviews: reviews.results,
  });
});
products.post("/interactions", requireUser, async (c) => {
  const d = z
    .object({
      product_id: z.number().int().positive(),
      kind: z.enum(["view", "cart", "wishlist"]),
    })
    .parse(await c.req.json());
  const user = c.get("user")!;
  const pref = await c.env.DB.prepare(
    "SELECT enabled FROM recommendation_preferences WHERE user_id=?",
  )
    .bind(user.user_id)
    .first<any>();
  if (pref?.enabled === 0) return c.json({ success: true, recorded: false });
  const exists = await c.env.DB.prepare(
    `SELECT p.product_id FROM products p JOIN categories c ON c.category_id=p.category_id WHERE ${activeProduct} AND p.product_id=?`,
  )
    .bind(d.product_id)
    .first();
  if (!exists) throw new HTTPException(404, { message: "Product not found." });
  await c.env.DB.prepare(
    `INSERT INTO interactions(user_id,product_id,kind) VALUES(?,?,?) ON CONFLICT(user_id,product_id,kind) DO UPDATE SET weight=MIN(weight+1,20),updated_at=CURRENT_TIMESTAMP`,
  )
    .bind(user.user_id, d.product_id, d.kind)
    .run();
  return c.json({ success: true });
});
