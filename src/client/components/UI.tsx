import { Link } from "react-router-dom";
import {
  Heart,
  Plus,
  ArrowUpRight,
  Sparkles,
  ArrowRight,
  ShoppingBag,
  Star,
  AlertCircle,
} from "lucide-react";
import type { Product } from "../../types";
import { useStore } from "../store";
import { money, useApi } from "../api";
export function ProductImage({
  product,
  className = "",
}: {
  product: Pick<Product, "name" | "image_url">;
  className?: string;
}) {
  return (
    <img
      className={className}
      src={product.image_url}
      alt={product.name}
      loading="lazy"
      onError={(e) => {
        const img = e.currentTarget;
        if (!img.src.endsWith("placeholder.svg"))
          img.src = "/static/images/placeholder.svg";
      }}
    />
  );
}
export function ProductCard({
  product: p,
  reason = false,
}: {
  product: Product;
  reason?: boolean;
}) {
  const { wishlist, toggleWish, addCart } = useStore();
  const saved = wishlist.some((w) => w.product_id === p.product_id);
  return (
    <article className="product-card">
      <div className="product-photo">
        <Link to={"/products/" + p.product_id} aria-label={"View " + p.name}>
          <ProductImage product={p} />
        </Link>
        <div className="product-flags">
          {p.compare_price ? (
            <span className="sale-badge">
              −{Math.round((1 - p.price / p.compare_price) * 100)}%
            </span>
          ) : p.is_featured ? (
            <span className="pick-badge">Editor's pick</span>
          ) : null}
        </div>
        <button
          className={"wish-button " + (saved ? "saved" : "")}
          aria-label={(saved ? "Remove " : "Save ") + p.name + " to wishlist"}
          onClick={() => toggleWish(p)}
        >
          <Heart size={18} fill={saved ? "currentColor" : "none"} />
        </button>
      </div>
      {reason && p.reason && (
        <p className="product-reason">
          <Sparkles size={12} />
          {p.reason}
        </p>
      )}
      <div className="product-meta">
        <span>{p.brand_name || p.category_name}</span>
        <span className="rating">
          <Star size={12} fill="currentColor" />
          {p.review_count ? Number(p.rating).toFixed(1) : "New"}
          {p.review_count > 0 && <small>({p.review_count})</small>}
        </span>
      </div>
      <Link className="product-name" to={"/products/" + p.product_id}>
        {p.name}
      </Link>
      <div className="product-bottom">
        <p>
          <strong>{money(p.price)}</strong>
          {p.compare_price && <del>{money(p.compare_price)}</del>}
        </p>
        <button
          className="add-button"
          disabled={p.available < 1}
          aria-label={"Add " + p.name + " to bag"}
          onClick={() => addCart(p)}
        >
          <Plus size={19} />
        </button>
      </div>
    </article>
  );
}
export function ProductGrid({
  products,
  reason = false,
}: {
  products: Product[];
  reason?: boolean;
}) {
  return (
    <div className="product-grid">
      {products.map((p) => (
        <ProductCard key={p.product_id} product={p} reason={reason} />
      ))}
    </div>
  );
}
export function Loading({ cards = false }: { cards?: boolean }) {
  return cards ? (
    <div className="product-grid" aria-label="Loading products">
      {[1, 2, 3, 4].map((i) => (
        <div className="skeleton-card" key={i}>
          <div />
          <span />
          <span />
        </div>
      ))}
    </div>
  ) : (
    <div className="loading" role="status">
      <span className="spinner" />
      Just a moment…
    </div>
  );
}
export function ErrorState({
  message,
  retry,
}: {
  message: string;
  retry?: () => void;
}) {
  return (
    <div className="empty-state" role="alert">
      <AlertCircle />
      <h3>Something didn’t go as planned</h3>
      <p>{message}</p>
      {retry && (
        <button className="button secondary" onClick={retry}>
          Try again
        </button>
      )}
    </div>
  );
}
export function Empty({
  title,
  description,
  action = "Explore products",
  to = "/products",
}: {
  title: string;
  description: string;
  action?: string;
  to?: string;
}) {
  return (
    <div className="empty-state">
      <ShoppingBag size={34} />
      <h3>{title}</h3>
      <p>{description}</p>
      <Link className="button secondary" to={to}>
        {action}
        <ArrowRight size={16} />
      </Link>
    </div>
  );
}
export function SectionHeading({
  eyebrow,
  title,
  description,
  to,
  action = "View all",
}: {
  eyebrow?: string;
  title: string;
  description?: string;
  to?: string;
  action?: string;
}) {
  return (
    <header className="section-heading">
      <div>
        {eyebrow && <p className="eyebrow">{eyebrow}</p>}
        <h2>{title}</h2>
        {description && <p>{description}</p>}
      </div>
      {to && (
        <Link className="text-link" to={to}>
          {action}
          <ArrowUpRight size={18} />
        </Link>
      )}
    </header>
  );
}
export function RecommendationSection({
  path,
  title,
  description,
  limit = 4,
  hideEmpty = false,
}: {
  path: string | null;
  title: string;
  description: string;
  limit?: number;
  hideEmpty?: boolean;
}) {
  const { data, loading, error, reload } = useApi(path);
  if (!path || (!loading && !error && hideEmpty && !data?.products?.length))
    return null;
  return (
    <section className="section recommendation-section">
      <SectionHeading title={title} description={description} />
      {loading ? (
        <Loading cards />
      ) : error ? (
        <ErrorState message={error} retry={reload} />
      ) : data?.products?.length ? (
        <ProductGrid products={data.products.slice(0, limit)} reason />
      ) : (
        <p className="subtle-empty">
          A little more exploring will help us discover your favorites.
        </p>
      )}
    </section>
  );
}
