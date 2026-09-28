import type { Env, Product } from "../types";
import { allProducts } from "../db";
import { z } from "zod";
type Mode = "personalized" | "similar" | "together" | "popular";
export class RecommendationService {
  constructor(private env: Env) {}
  getPersonalizedRecommendations(userId: number) {
    return this.rank("personalized", userId);
  }
  getSimilarProducts(productId: number) {
    return this.rank("similar", undefined, productId);
  }
  getPopularProducts() {
    return this.rank("popular");
  }
  getFrequentlyBoughtTogether(productId: number) {
    return this.rank("together", undefined, productId);
  }
  private async rank(
    mode: Mode,
    userId?: number,
    productId?: number,
  ): Promise<{
    products: Product[];
    source: string;
    strategy: Mode;
    signals?: string[];
  }> {
    const db = this.env.DB;
    if (userId) {
      const pref = await db
        .prepare(
          "SELECT enabled FROM recommendation_preferences WHERE user_id=?",
        )
        .bind(userId)
        .first<{ enabled: number }>();
      if (pref?.enabled === 0) return this.getPopularProducts();
    }
    const [catalog, purchases, categories, attrs, sentiment, events] =
      await Promise.all([
        allProducts(db),
        db
          .prepare(
            `SELECT o.user_id,oi.product_id,oi.order_id,SUM(oi.quantity) quantity FROM order_items oi JOIN orders o ON o.order_id=oi.order_id WHERE o.status IN ('confirmed','processing','shipped','delivered') AND EXISTS(SELECT 1 FROM payments pay WHERE pay.order_id=o.order_id AND pay.payment_status='completed') GROUP BY o.user_id,oi.product_id,oi.order_id LIMIT 10000`,
          )
          .all<any>(),
        db.prepare("SELECT category_id,parent_id FROM categories").all<any>(),
        db
          .prepare(
            "SELECT product_id,attribute_name,attribute_value FROM product_attributes",
          )
          .all<any>(),
        db
          .prepare(
            `SELECT r.product_id,AVG(s.score) score FROM review_sentiment s JOIN reviews r ON r.review_id=s.review_id WHERE r.is_approved=1 AND EXISTS(SELECT 1 FROM orders o JOIN order_items oi ON oi.order_id=o.order_id WHERE o.order_id=r.order_id AND o.user_id=r.user_id AND oi.product_id=r.product_id AND o.status IN ('confirmed','processing','shipped','delivered')) GROUP BY r.product_id`,
          )
          .all<any>(),
        userId
          ? db
              .prepare(
                "SELECT product_id,kind,weight FROM interactions WHERE user_id=? ORDER BY updated_at DESC LIMIT 100",
              )
              .bind(userId)
              .all<any>()
          : Promise.resolve({ results: [] }),
      ]);
    const target = catalog.find((p) => p.product_id === productId);
    const mine = new Set<number>(
      purchases.results
        .filter((p) => p.user_id === userId)
        .map((p) => p.product_id),
    );
    const preference = new Map<number, number>();
    for (const id of mine) preference.set(id, 4);
    for (const e of events.results)
      preference.set(
        e.product_id,
        (preference.get(e.product_id) || 0) +
          (e.kind === "view" ? 1 : 2) * Math.log2(e.weight + 1),
      );
    const roots = new Map(
      categories.results.map((c) => [c.category_id, c.parent_id]),
    );
    const root = (id: number) => {
      let n = 0;
      while (roots.get(id) && n++ < 20) id = roots.get(id);
      return id;
    };
    const similar = (a: Product, b: Product) => {
      const category =
        a.category_id === b.category_id
          ? 1
          : root(a.category_id) === root(b.category_id)
            ? 0.35
            : 0;
      const shared = attrs.results
        .filter((v) => v.product_id === a.product_id)
        .some((v) =>
          attrs.results.some(
            (w) =>
              w.product_id === b.product_id &&
              w.attribute_name === v.attribute_name &&
              w.attribute_value === v.attribute_value,
          ),
        )
        ? 1
        : 0;
      return (
        0.6 * category +
        0.15 * (a.brand_id && a.brand_id === b.brand_id ? 1 : 0) +
        0.15 * (1 - Math.abs(a.price - b.price) / Math.max(a.price, b.price)) +
        0.1 * shared
      );
    };
    const peers = new Set(
      purchases.results
        .filter((p) => mine.has(p.product_id) && p.user_id !== userId)
        .map((p) => p.user_id),
    );
    const togetherOrders = new Set(
      purchases.results
        .filter((p) => p.product_id === productId)
        .map((p) => p.order_id),
    );
    const sales = new Map<number, number>();
    for (const p of purchases.results)
      sales.set(p.product_id, (sales.get(p.product_id) || 0) + p.quantity);
    const maxSales = Math.max(1, ...sales.values());
    const allowed = catalog.filter(
      (p) =>
        p.available > 0 &&
        p.product_id !== productId &&
        !(mode === "personalized" && mine.has(p.product_id)),
    );
    const results = allowed
      .map((p) => {
        const popularity = (sales.get(p.product_id) || 0) / maxSales;
        const rating =
          (p.rating * p.review_count + 3.5 * 3) / (p.review_count + 3) / 5;
        const nlp = sentiment.results.find(
          (s) => s.product_id === p.product_id,
        )?.score;
        const quality =
          nlp === undefined ? rating : 0.6 * rating + (0.4 * (nlp + 1)) / 2;
        const collaborative =
          purchases.results.filter(
            (s) => s.product_id === p.product_id && peers.has(s.user_id),
          ).length / Math.max(1, peers.size);
        const content = target
          ? similar(target, p)
          : [...preference].reduce((sum, [id, w]) => {
              const from = catalog.find((v) => v.product_id === id);
              return sum + (from ? similar(from, p) * w : 0);
            }, 0) /
            Math.max(
              1,
              [...preference.values()].reduce((a, b) => a + b, 0),
            );
        const co = purchases.results.filter(
          (s) =>
            s.product_id === p.product_id && togetherOrders.has(s.order_id),
        ).length;
        let score = 0.7 * popularity + 0.3 * quality,
          reason =
            popularity > 0
              ? "Popular with our shoppers"
              : "Discover something new";
        if (mode === "similar") {
          score = 0.85 * content + 0.15 * quality;
          reason =
            target && target.category_id === p.category_id
              ? "Similar category & features"
              : "Related to your discovery";
        }
        if (mode === "personalized" && preference.size) {
          score =
            0.35 * collaborative +
            0.4 * content +
            0.15 * popularity +
            0.1 * quality;
          reason =
            collaborative > 0
              ? "Shoppers with similar tastes"
              : content > 0.3
                ? "Inspired by your interests"
                : "A popular discovery for you";
        }
        if (mode === "together") {
          score = co;
          reason = "Purchased in the same order";
        }
        return { ...p, score: Math.round(score * 1000) / 1000, reason };
      })
      .filter((p) => mode !== "together" || p.score > 0)
      .sort((a, b) => b.score - a.score || a.product_id - b.product_id);
    // External model sees no email/address/password. All returned IDs are revalidated.
    if (this.env.ML_API_URL) {
      try {
        const url = new URL(this.env.ML_API_URL);
        if (url.protocol !== "https:") throw Error("HTTPS required");
        const response = await fetch(url.toString(), {
          method: "POST",
          redirect: "error",
          headers: {
            "Content-Type": "application/json",
            ...(this.env.ML_API_TOKEN
              ? { Authorization: `Bearer ${this.env.ML_API_TOKEN}` }
              : {}),
          },
          body: JSON.stringify({
            mode,
            user_id: userId,
            product_id: productId,
            limit: 8,
            candidate_ids: results.map((p) => p.product_id),
            interactions: events.results,
            purchased_product_ids: [...mine],
          }),
          signal: AbortSignal.timeout(1500),
        });
        if (!response.ok) throw Error("Model unavailable");
        const payload = z
          .object({ product_ids: z.array(z.number().int().positive()).max(50) })
          .parse(await response.json());
        const selected = [...new Set(payload.product_ids)]
          .map((id) => results.find((p) => p.product_id === id))
          .filter(Boolean) as Product[];
        if (selected.length)
          return {
            products: selected
              .slice(0, 8)
              .map((p) => ({
                ...p,
                reason: "Selected by your recommendation model",
              })),
            source: "external-model",
            strategy: mode,
          };
      } catch {
        /* Bounded fail-open to local data-derived ranking. */
      }
    }
    return {
      products: results.slice(0, 8),
      source: "database-hybrid",
      strategy: mode,
      signals: [
        "purchases",
        "category",
        "brand",
        "attributes",
        "ratings",
        ...(sentiment.results.length ? ["model-sentiment"] : []),
      ],
    };
  }
}
