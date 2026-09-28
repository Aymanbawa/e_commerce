import type { Product } from "./types";
export const productSelect = `SELECT p.product_id,p.name,p.slug,p.short_desc,p.description,p.price,p.compare_price,p.category_id,p.brand_id,p.is_featured,p.sku,p.status,c.name category_name,b.name brand_name,COALESCE(m.image_url,'/static/images/placeholder.svg') image_url,COALESCE(m.is_illustrative,1) is_illustrative,COALESCE(i.quantity_in_stock-i.quantity_reserved,0) available,COALESCE(r.rating,0) rating,COALESCE(r.review_count,0) review_count FROM products p JOIN categories c ON c.category_id=p.category_id LEFT JOIN brands b ON b.brand_id=p.brand_id LEFT JOIN inventory i ON i.product_id=p.product_id LEFT JOIN product_media m ON m.product_id=p.product_id LEFT JOIN (SELECT product_id,AVG(rating) rating,COUNT(*) review_count FROM reviews r WHERE is_approved=1 AND EXISTS(SELECT 1 FROM orders o JOIN order_items oi ON oi.order_id=o.order_id WHERE o.order_id=r.order_id AND o.user_id=r.user_id AND oi.product_id=r.product_id AND o.status IN ('confirmed','processing','shipped','delivered')) GROUP BY product_id) r ON r.product_id=p.product_id`;
export const activeProduct = `p.status='active' AND p.deleted_at IS NULL AND c.is_active=1`;
export async function allProducts(db: D1Database): Promise<Product[]> {
  return (
    await db.prepare(`${productSelect} WHERE ${activeProduct}`).all<Product>()
  ).results;
}
