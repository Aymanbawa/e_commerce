import { Hono } from "hono";
import { HTTPException } from "hono/http-exception";
import { z } from "zod";
import type { AppEnv } from "../types";
import { RecommendationService } from "../services/recommendationService";
import { productSelect, activeProduct } from "../db";
import { requireUser } from "../security";
export const recommendations = new Hono<AppEnv>();
recommendations.get("/popular", async (c) =>
  c.json(await new RecommendationService(c.env).getPopularProducts()),
);
recommendations.get("/for-you", async (c) => {
  const s = new RecommendationService(c.env);
  return c.json(
    c.get("user")
      ? await s.getPersonalizedRecommendations(c.get("user")!.user_id)
      : await s.getPopularProducts(),
  );
});
recommendations.get("/user/:id", requireUser, async (c) => {
  const id = z.coerce.number().int().positive().parse(c.req.param("id"));
  if (id !== c.get("user")!.user_id)
    throw new HTTPException(403, {
      message: "You can only access your own recommendations.",
    });
  return c.json(
    await new RecommendationService(c.env).getPersonalizedRecommendations(id),
  );
});
recommendations.get("/product/:id", async (c) => {
  const id = z.coerce.number().int().positive().parse(c.req.param("id"));
  const exists = await c.env.DB.prepare(
    `SELECT p.product_id FROM products p JOIN categories c ON c.category_id=p.category_id WHERE ${activeProduct} AND p.product_id=?`,
  )
    .bind(id)
    .first();
  if (!exists) throw new HTTPException(404, { message: "Product not found." });
  const s = new RecommendationService(c.env);
  const [similar, together] = await Promise.all([
    s.getSimilarProducts(id),
    s.getFrequentlyBoughtTogether(id),
  ]);
  return c.json({ similar, together });
});
recommendations.get("/recent", requireUser, async (c) =>
  c.json({
    products: (
      await c.env.DB.prepare(
        `${productSelect} JOIN interactions ev ON ev.product_id=p.product_id WHERE ${activeProduct} AND ev.user_id=? AND ev.kind='view' ORDER BY ev.updated_at DESC LIMIT 8`,
      )
        .bind(c.get("user")!.user_id)
        .all()
    ).results,
  }),
);
recommendations.get("/preferences", requireUser, async (c) => {
  const p = await c.env.DB.prepare(
    "SELECT enabled FROM recommendation_preferences WHERE user_id=?",
  )
    .bind(c.get("user")!.user_id)
    .first();
  return c.json({ enabled: p ? !!p.enabled : true });
});
recommendations.put("/preferences", requireUser, async (c) => {
  const d = z.object({ enabled: z.boolean() }).parse(await c.req.json());
  const uid = c.get("user")!.user_id;
  await c.env.DB.batch([
    c.env.DB.prepare(
      "INSERT INTO recommendation_preferences(user_id,enabled) VALUES(?,?) ON CONFLICT(user_id) DO UPDATE SET enabled=excluded.enabled",
    ).bind(uid, d.enabled ? 1 : 0),
    ...(!d.enabled
      ? [c.env.DB.prepare("DELETE FROM interactions WHERE user_id=?").bind(uid)]
      : []),
  ]);
  return c.json({ success: true });
});
