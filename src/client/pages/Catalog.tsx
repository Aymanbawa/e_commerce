import { useEffect, useState } from "react";
import { Link, useSearchParams, useParams } from "react-router-dom";
import {
  Search,
  SlidersHorizontal,
  ArrowRight,
  ChevronRight,
  Heart,
  ShoppingBag,
  Star,
  ShieldCheck,
  Truck,
  Check,
  Sparkles,
  Minus,
  Plus,
} from "lucide-react";
import { api, useApi, mutate, money } from "../api";
import { useStore } from "../store";
import {
  ProductGrid,
  Loading,
  ErrorState,
  Empty,
  ProductImage,
  SectionHeading,
} from "../components/UI";
export function Catalog() {
  const [params, setParams] = useSearchParams();
  const { data, loading, error, reload } = useApi(
    "/products?" + params.toString(),
  );
  const cats = useApi("/categories");
  const [filters, setFilters] = useState(false);
  const [query, setQuery] = useState(params.get("q") || "");
  const [min, setMin] = useState(params.get("min") || ""),
    [max, setMax] = useState(params.get("max") || "");
  useEffect(() => {
    setQuery(params.get("q") || "");
    setMin(params.get("min") || "");
    setMax(params.get("max") || "");
  }, [params.toString()]);
  function change(k: string, v: string) {
    const p = new URLSearchParams(params);
    if (v) p.set(k, v);
    else p.delete(k);
    if (k !== "page") p.delete("page");
    setParams(p);
  }
  const category = cats.data?.categories.find(
    (c: any) => String(c.category_id) === params.get("category"),
  );
  const page = Number(params.get("page") || 1);
  return (
    <div className="container page catalog-page">
      <p className="breadcrumb">
        <Link to="/">Home</Link>
        <ChevronRight size={13} />
        The collection
      </p>
      <header className="page-title">
        <span className="eyebrow">FIND YOUR KIND OF EXTRAORDINARY</span>
        <h1>{category?.name || "The collection."}</h1>
        <p>
          {category?.description ||
            "Thoughtfully selected. Ready for your everyday."}
        </p>
      </header>
      <div className="catalog-toolbar">
        <button
          className="button secondary mobile-filter"
          onClick={() => setFilters(!filters)}
        >
          <SlidersHorizontal size={17} />
          Filters
        </button>
        <form
          className="catalog-search"
          onSubmit={(e) => {
            e.preventDefault();
            change("q", query);
          }}
        >
          <Search size={18} />
          <input
            aria-label="Search collection"
            placeholder="Find something you love…"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
          <button aria-label="Submit search">
            <ArrowRight size={17} />
          </button>
        </form>
        <span className="result-count">
          {data?.total ?? "…"} thoughtful finds
        </span>
        <label className="sort-label">
          Sort by{" "}
          <select
            aria-label="Sort products"
            value={params.get("sort") || "featured"}
            onChange={(e) => change("sort", e.target.value)}
          >
            <option value="featured">Featured</option>
            <option value="price-asc">Price: low to high</option>
            <option value="price-desc">Price: high to low</option>
            <option value="rating">Top rated</option>
            <option value="newest">Newest</option>
          </select>
        </label>
      </div>
      <div className="catalog-layout">
        <aside className={"catalog-filters " + (filters ? "open" : "")}>
          <div className="filter-title">
            <h3>Filters</h3>
            <button onClick={() => setParams({})}>Reset all</button>
          </div>
          <h4>Category</h4>
          <label className="filter-option">
            <input
              type="radio"
              name="category"
              checked={!params.get("category")}
              onChange={() => change("category", "")}
            />
            All discoveries
          </label>
          {cats.data?.categories
            .filter((c: any) => !c.parent_id)
            .map((c: any) => (
              <label className="filter-option" key={c.category_id}>
                <input
                  type="radio"
                  name="category"
                  checked={params.get("category") === String(c.category_id)}
                  onChange={() => change("category", String(c.category_id))}
                />
                {c.name}
              </label>
            ))}
          <details>
            <summary>More categories</summary>
            {cats.data?.categories
              .filter((c: any) => c.parent_id)
              .map((c: any) => (
                <label className="filter-option small" key={c.category_id}>
                  <input
                    type="radio"
                    name="category"
                    checked={params.get("category") === String(c.category_id)}
                    onChange={() => change("category", String(c.category_id))}
                  />
                  {c.name}
                </label>
              ))}
          </details>
          <div className="filter-divider" />
          <h4>Price range</h4>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              const p = new URLSearchParams(params);
              min ? p.set("min", min) : p.delete("min");
              max ? p.set("max", max) : p.delete("max");
              p.delete("page");
              setParams(p);
            }}
          >
            <div className="price-inputs">
              <label>
                Min (₹)
                <input
                  type="number"
                  min="0"
                  aria-label="Minimum price"
                  value={min}
                  placeholder="0"
                  onChange={(e) => setMin(e.target.value)}
                />
              </label>
              <span>—</span>
              <label>
                Max (₹)
                <input
                  type="number"
                  min={min || 0}
                  aria-label="Maximum price"
                  value={max}
                  placeholder="Any"
                  onChange={(e) => setMax(e.target.value)}
                />
              </label>
            </div>
            <button className="button secondary full" type="submit">
              Apply price
            </button>
          </form>
          <div className="filter-tip">
            <Sparkles size={20} />
            <h4>
              Less searching.
              <br />
              More discovering.
            </h4>
            <p>Let your interests lead the way.</p>
            <Link to="/for-you">
              See your picks <ArrowRight size={14} />
            </Link>
          </div>
        </aside>
        <section className="catalog-results">
          {loading ? (
            <Loading cards />
          ) : error ? (
            <ErrorState message={error} retry={reload} />
          ) : data?.products.length ? (
            <>
              <ProductGrid products={data.products} />
              <nav className="pagination" aria-label="Product pages">
                <button
                  className="button secondary"
                  disabled={page === 1}
                  onClick={() => change("page", String(page - 1))}
                >
                  Previous
                </button>
                <span>
                  Page {page} of {Math.ceil(data.total / data.limit)}
                </span>
                <button
                  className="button secondary"
                  disabled={page * data.limit >= data.total}
                  onClick={() => change("page", String(page + 1))}
                >
                  Next
                </button>
              </nav>
            </>
          ) : (
            <Empty
              title="No finds this time"
              description="Try a broader search or reset your filters."
            />
          )}
        </section>
      </div>
    </div>
  );
}
export function ProductDetails() {
  const { id } = useParams();
  const { data, loading, error, reload } = useApi("/products/" + id);
  const rec = useApi("/recommendations/product/" + id);
  const { user, addCart, toggleWish, wishlist } = useStore();
  const [tab, setTab] = useState("details");
  const [busy, setBusy] = useState(false);
  useEffect(() => {
    setTab("details");
    if (user)
      mutate("/interactions", "POST", {
        product_id: Number(id),
        kind: "view",
      }).catch(() => {});
  }, [id, user?.user_id]);
  if (loading)
    return (
      <div className="container page">
        <Loading />
      </div>
    );
  if (error)
    return (
      <div className="container page">
        <ErrorState message={error} retry={reload} />
      </div>
    );
  if (!data) return null;
  const p = data.product;
  const saved = wishlist.some((w) => w.product_id === p.product_id);
  return (
    <div className="container page product-page">
      <p className="breadcrumb">
        <Link to="/">Home</Link>
        <ChevronRight size={13} />
        <Link to="/products">The collection</Link>
        <ChevronRight size={13} />
        <Link to={"/products?category=" + p.category_id}>
          {p.category_name}
        </Link>
        <ChevronRight size={13} />
        <span>{p.name}</span>
      </p>
      <section className="product-detail">
        <div>
          <div className="detail-image">
            <ProductImage product={p} />
            {p.is_featured > 0 && (
              <span className="pick-badge">The everyday edit</span>
            )}
          </div>
          {p.is_illustrative > 0 && (
            <p className="image-disclaimer">
              Illustrative image. Refer to the product description for exact
              specifications.
            </p>
          )}
        </div>
        <div className="detail-info">
          <span className="eyebrow">{p.brand_name || p.category_name}</span>
          <h1>{p.name}</h1>
          <p className="detail-short">{p.short_desc}</p>
          <div className="detail-rating">
            <Star size={16} fill="currentColor" />
            <b>
              {p.review_count ? Number(p.rating).toFixed(1) : "New discovery"}
            </b>
            <span>
              {p.review_count} verified review{p.review_count === 1 ? "" : "s"}
            </span>
          </div>
          <div className="detail-price">
            <strong>{money(p.price)}</strong>
            {p.compare_price && (
              <>
                <del>{money(p.compare_price)}</del>
                <span>Save {money(p.compare_price - p.price)}</span>
              </>
            )}
          </div>
          <p className="fine-print">
            INR · Demo prices as listed · Free demo shipping
          </p>
          <p className={"stock " + (p.available ? "" : "out-of-stock")}>
            <span />
            {p.available
              ? "In stock — ready for your everyday"
              : "Currently out of stock"}
          </p>
          {data.attributes.length > 0 && (
            <div className="attribute-preview">
              {data.attributes.slice(0, 3).map((a: any) => (
                <span key={a.attribute_name}>
                  <small>{a.attribute_name}</small>
                  <b>{a.attribute_value}</b>
                </span>
              ))}
            </div>
          )}
          <div className="detail-actions">
            <button
              className="button primary"
              disabled={!p.available || busy}
              onClick={async () => {
                setBusy(true);
                await addCart(p);
                setBusy(false);
              }}
            >
              <ShoppingBag size={19} />
              {busy ? "Adding…" : "Add to bag"}
              <ArrowRight size={18} />
            </button>
            <button
              className={"button secondary " + (saved ? "saved" : "")}
              onClick={() => toggleWish(p)}
              aria-label="Save product to wishlist"
            >
              <Heart size={20} fill={saved ? "currentColor" : "none"} />
            </button>
          </div>
          <div className="detail-promises">
            <p>
              <Truck size={18} />
              <span>
                <b>Free demo shipping</b>No delivery fees, no hidden surprises.
              </span>
            </p>
            <p>
              <ShieldCheck size={18} />
              <span>
                <b>A secure place to shop</b>Demo payments. Never enter real
                card details.
              </span>
            </p>
          </div>
        </div>
      </section>
      <section className="product-information">
        <nav className="tabs">
          <button
            className={tab === "details" ? "active" : ""}
            onClick={() => setTab("details")}
          >
            The details
          </button>
          <button
            className={tab === "reviews" ? "active" : ""}
            onClick={() => setTab("reviews")}
          >
            Reviews ({p.review_count})
          </button>
        </nav>
        {tab === "details" ? (
          <div className="detail-copy">
            <div>
              <h3>Made for your everyday.</h3>
              <p>{p.description}</p>
              <p className="fine-print">SKU: {p.sku}</p>
            </div>
            <dl>
              {data.attributes.map((a: any) => (
                <div key={a.attribute_name}>
                  <dt>{a.attribute_name}</dt>
                  <dd>{a.attribute_value}</dd>
                </div>
              ))}
            </dl>
          </div>
        ) : (
          <div className="reviews-list">
            <div className="review-intro">
              <div>
                <h3>Real purchases. Honest opinions.</h3>
                <p>Only verified buyers can share a review.</p>
              </div>
              <Link className="button secondary" to="/account/orders">
                Review a purchase <ArrowRight size={16} />
              </Link>
            </div>
            {data.reviews.length ? (
              data.reviews.map((r: any) => (
                <article className="review-card" key={r.review_id}>
                  <header>
                    <span className="avatar">{r.first_name[0]}</span>
                    <div>
                      <b>{r.first_name}</b>
                      <small>
                        <ShieldCheck size={12} />
                        Verified purchase
                      </small>
                    </div>
                    <time>
                      {new Date(r.created_at + "Z").toLocaleDateString()}
                    </time>
                  </header>
                  <div className="stars">
                    {Array.from({ length: 5 }, (_, i) => (
                      <Star
                        key={i}
                        size={14}
                        fill={i < r.rating ? "currentColor" : "none"}
                      />
                    ))}
                  </div>
                  <h4>{r.title}</h4>
                  <p>{r.body}</p>
                </article>
              ))
            ) : (
              <p className="subtle-empty">
                Be the first to share your experience after a demo purchase.
              </p>
            )}
          </div>
        )}
      </section>
      <section className="section">
        <SectionHeading
          title="Similar products"
          description="A few more finds that might be your thing."
        />
        {rec.loading ? (
          <Loading cards />
        ) : rec.error ? (
          <ErrorState message={rec.error} retry={rec.reload} />
        ) : rec.data?.similar.products.length ? (
          <ProductGrid
            products={rec.data.similar.products.slice(0, 4)}
            reason
          />
        ) : (
          <p className="subtle-empty">No related products available yet.</p>
        )}
      </section>
      <section className="section">
        <SectionHeading
          title="Customers also bought"
          description="Better together, based on real purchase patterns."
        />
        {rec.data?.together.products.length ? (
          <ProductGrid
            products={rec.data.together.products.slice(0, 4)}
            reason
          />
        ) : (
          <p className="subtle-empty">
            Not enough shared purchases yet. We’ll surface pairings as the
            community grows.
          </p>
        )}
      </section>
    </div>
  );
}
