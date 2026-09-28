import { useState } from "react";
import {
  Link,
  NavLink,
  Outlet,
  Navigate,
  useParams,
  useSearchParams,
} from "react-router-dom";
import {
  UserRound,
  Package,
  Heart,
  Star,
  Sparkles,
  LogOut,
  ArrowRight,
  CheckCircle2,
  ShieldCheck,
  Settings2,
  LayoutDashboard,
} from "lucide-react";
import { useStore } from "../store";
import { useApi, mutate, money } from "../api";
import {
  Empty,
  Loading,
  ErrorState,
  ProductGrid,
  RecommendationSection,
} from "../components/UI";
export function AccountLayout() {
  const { user, ready, logout } = useStore();
  if (!ready) return <Loading />;
  if (!user)
    return (
      <Navigate
        to={"/login?next=" + encodeURIComponent(location.pathname)}
        replace
      />
    );
  return (
    <div className="container page account-page">
      <header className="page-title">
        <span className="eyebrow">YOUR OWN LITTLE CORNER</span>
        <h1>Hello, {user.first_name}.</h1>
        <p>Your favorites, your discoveries, your everyday.</p>
      </header>
      <div className="account-layout">
        <aside className="account-nav">
          <div className="account-avatar">
            {user.first_name[0]}
            {user.last_name[0]}
          </div>
          <b>
            {user.first_name} {user.last_name}
          </b>
          <small>{user.email}</small>
          <nav>
            <NavLink to="/account" end>
              <UserRound size={18} />
              My profile
            </NavLink>
            <NavLink to="/account/orders">
              <Package size={18} />
              My orders
            </NavLink>
            <NavLink to="/account/wishlist">
              <Heart size={18} />
              Wishlist
            </NavLink>
            <NavLink to="/account/reviews">
              <Star size={18} />
              My reviews
            </NavLink>
            <NavLink to="/account/preferences">
              <Settings2 size={18} />
              My preferences
            </NavLink>
            {user.role === "admin" && (
              <Link to="/admin">
                <LayoutDashboard size={18} />
                Admin dashboard
              </Link>
            )}
            <button onClick={logout}>
              <LogOut size={18} />
              Sign out
            </button>
          </nav>
        </aside>
        <section className="account-content">
          <Outlet />
        </section>
      </div>
    </div>
  );
}
export function Profile() {
  const { user, refresh, toast } = useStore();
  const [error, setError] = useState(""),
    [busy, setBusy] = useState(false);
  return (
    <>
      <section className="form-panel">
        <h2>A little about you.</h2>
        <p className="section-description">Keep your details up to date.</p>
        <form
          className="form-stack"
          onSubmit={async (e) => {
            e.preventDefault();
            setBusy(true);
            try {
              await mutate(
                "/auth/profile",
                "PATCH",
                Object.fromEntries(new FormData(e.currentTarget)),
              );
              await refresh();
              toast("Your profile is up to date.");
              setError("");
            } catch (e: any) {
              setError(e.message);
            } finally {
              setBusy(false);
            }
          }}
        >
          <div className="form-row">
            <label>
              First name
              <input
                name="first_name"
                defaultValue={user!.first_name}
                required
                maxLength={100}
              />
            </label>
            <label>
              Last name
              <input
                name="last_name"
                defaultValue={user!.last_name}
                required
                maxLength={100}
              />
            </label>
          </div>
          <label>
            Email address
            <input value={user!.email} readOnly />
          </label>
          <label>
            Phone number
            <input
              name="phone"
              type="tel"
              defaultValue={user!.phone || ""}
              maxLength={20}
            />
          </label>
          {error && <p className="form-error">{error}</p>}
          <button className="button primary" disabled={busy}>
            {busy ? "Saving…" : "Save changes"}
            <ArrowRight size={16} />
          </button>
        </form>
      </section>
      <PasswordForm />
      <RecommendationSection
        path="/recommendations/for-you"
        title="A few things you might love"
        description="Inspired by your interests."
      />
    </>
  );
}
function PasswordForm() {
  const { toast } = useStore();
  const [error, setError] = useState(""),
    [busy, setBusy] = useState(false);
  return (
    <section className="form-panel">
      <h2>A little extra security.</h2>
      <p className="section-description">
        Update your password. Other sessions will be signed out.
      </p>
      <form
        className="form-stack"
        onSubmit={async (e) => {
          e.preventDefault();
          const form = e.currentTarget;
          setBusy(true);
          setError("");
          try {
            await mutate(
              "/auth/password",
              "PUT",
              Object.fromEntries(new FormData(form)),
            );
            form.reset();
            toast("Password updated. Other sessions have been signed out.");
          } catch (e: any) {
            setError(e.message);
          } finally {
            setBusy(false);
          }
        }}
      >
        <label>
          Current password
          <input
            name="current_password"
            type="password"
            autoComplete="current-password"
            required
            maxLength={128}
          />
        </label>
        <label>
          New password
          <input
            name="new_password"
            type="password"
            autoComplete="new-password"
            required
            minLength={10}
            maxLength={128}
          />
        </label>
        {error && (
          <p className="form-error" role="alert">
            {error}
          </p>
        )}
        <button className="button secondary" disabled={busy}>
          {busy ? "Updating…" : "Update password"}
        </button>
      </form>
    </section>
  );
}
export function Wishlist() {
  const { wishlist } = useStore();
  return (
    <>
      <h2>Saved for a little later.</h2>
      <p className="section-description">
        All the things that caught your eye.
      </p>
      {wishlist.length ? (
        <ProductGrid products={wishlist} />
      ) : (
        <Empty
          title="Your favorites will feel at home here"
          description="Tap the heart on anything you love to save it for later."
        />
      )}
    </>
  );
}
export function Orders() {
  const { data, error, loading, reload } = useApi("/orders");
  return (
    <>
      <h2>Your good finds, all in one place.</h2>
      <p className="section-description">
        Follow your orders and revisit your favorites.
      </p>
      {loading ? (
        <Loading />
      ) : error ? (
        <ErrorState message={error} retry={reload} />
      ) : !data?.orders.length ? (
        <Empty
          title="The first of many good discoveries"
          description="Your orders will appear here after your first demo checkout."
        />
      ) : (
        data.orders.map((o: any) => (
          <article className="order-card" key={o.order_id}>
            <header>
              <div>
                <small>ORDER</small>
                <b>{o.order_number}</b>
              </div>
              <div>
                <small>PLACED ON</small>
                <span>{new Date(o.created_at + "Z").toLocaleDateString()}</span>
              </div>
              <span className={"status status-" + o.status}>{o.status}</span>
            </header>
            {o.items.map((i: any) => (
              <div className="order-line" key={i.item_id}>
                <Link to={"/products/" + i.product_id}>
                  {i.product_name}
                  <small>Quantity {i.quantity}</small>
                </Link>
                <strong>{money(i.total_price)}</strong>
              </div>
            ))}
            <footer>
              <span>
                Total <b>{money(o.total_amount)}</b>
              </span>
              <Link className="text-link" to={"/account/orders/" + o.order_id}>
                View order & review
                <ArrowRight size={15} />
              </Link>
            </footer>
          </article>
        ))
      )}
    </>
  );
}
export function OrderDetail() {
  const { id } = useParams();
  const [params] = useSearchParams();
  const { data, error, loading, reload } = useApi("/orders/" + id);
  const [review, setReview] = useState<any>(null);
  const { toast } = useStore();
  const [formError, setFormError] = useState(""),
    [busy, setBusy] = useState(false);
  if (loading) return <Loading />;
  if (error) return <ErrorState message={error} retry={reload} />;
  if (!data) return null;
  const o = data.order;
  const stages = ["confirmed", "processing", "shipped", "delivered"];
  return (
    <>
      {params.has("success") && (
        <div className="success-panel">
          <CheckCircle2 size={35} />
          <div>
            <h2>A good find, officially yours.</h2>
            <p>Your demo order is confirmed. No payment was charged.</p>
          </div>
        </div>
      )}
      <Link className="text-link" to="/account/orders">
        ← Back to orders
      </Link>
      <div className="order-heading">
        <h2>{o.order_number}</h2>
        <span className={"status status-" + o.status}>{o.status}</span>
      </div>
      {stages.includes(o.status) && (
        <div className="order-progress">
          {stages.map((s, i) => (
            <div
              className={i <= stages.indexOf(o.status) ? "done" : ""}
              key={s}
            >
              <span>
                {i < stages.indexOf(o.status) ? (
                  <CheckCircle2 size={15} />
                ) : (
                  i + 1
                )}
              </span>
              <small>{s}</small>
            </div>
          ))}
        </div>
      )}
      <p className="demo-notice">
        Demonstration store: no physical fulfillment. Demo payments are recorded
        as completed.
      </p>
      <article className="order-card">
        {data.items.map((i: any) => (
          <div className="order-line" key={i.item_id}>
            <div>
              <Link to={"/products/" + i.product_id}>
                <b>{i.product_name}</b>
              </Link>
              <small>
                {i.quantity} × {money(i.unit_price)}
              </small>
              {stages.includes(o.status) && (
                <button
                  className="review-link"
                  onClick={() => {
                    setReview(i);
                    setFormError("");
                  }}
                >
                  <Star size={13} />
                  Write a review
                </button>
              )}
            </div>
            <strong>{money(i.total_price)}</strong>
          </div>
        ))}
        <footer>
          <span>Subtotal · Free demo shipping</span>
          <strong>{money(o.total_amount)}</strong>
        </footer>
      </article>
      <div className="form-row order-information">
        <section className="form-panel">
          <h3>Shipping address</h3>
          <p>
            {o.full_name}
            <br />
            {o.address_line1}
            <br />
            {o.city}, {o.state} {o.postal_code}
            <br />
            {o.country}
          </p>
        </section>
        <section className="form-panel">
          <h3>Payment details</h3>
          {data.payments.map((p: any, i: number) => (
            <p key={i}>
              {p.transaction_id?.startsWith("DEMO-")
                ? "Demo wallet"
                : p.payment_method}
              <br />
              <span className="green">{p.payment_status}</span> ·{" "}
              {money(p.amount)}
              <br />
              <small>{p.transaction_id}</small>
            </p>
          ))}
        </section>
      </div>
      {review && (
        <div className="modal-backdrop" onClick={() => setReview(null)}>
          <section
            className="modal"
            role="dialog"
            aria-modal="true"
            aria-label="Write a verified review"
            onClick={(e) => e.stopPropagation()}
          >
            <button
              className="modal-close"
              onClick={() => setReview(null)}
              aria-label="Close review"
            >
              ×
            </button>
            <span className="eyebrow">
              <ShieldCheck size={15} /> VERIFIED PURCHASE
            </span>
            <h2>How did you like it?</h2>
            <p>{review.product_name}</p>
            <form
              className="form-stack"
              onSubmit={async (e) => {
                e.preventDefault();
                setBusy(true);
                const d = Object.fromEntries(new FormData(e.currentTarget));
                try {
                  await mutate("/reviews", "POST", {
                    ...d,
                    rating: Number(d.rating),
                    product_id: review.product_id,
                    order_id: o.order_id,
                  });
                  setReview(null);
                  toast("Thank you! Your verified review is published.");
                } catch (e: any) {
                  setFormError(e.message);
                } finally {
                  setBusy(false);
                }
              }}
            >
              <label>
                Your rating
                <select name="rating" defaultValue="5">
                  {[5, 4, 3, 2, 1].map((n) => (
                    <option value={n} key={n}>
                      {n} {n === 1 ? "star" : "stars"}
                    </option>
                  ))}
                </select>
              </label>
              <label>
                Review title
                <input
                  name="title"
                  minLength={2}
                  maxLength={150}
                  required
                  placeholder="Sum up your experience"
                  autoFocus
                />
              </label>
              <label>
                Your experience
                <textarea
                  name="body"
                  minLength={10}
                  maxLength={3000}
                  required
                  placeholder="What did you love? What could be better?"
                  rows={4}
                />
              </label>
              {formError && (
                <p className="form-error" role="alert">
                  {formError}
                </p>
              )}
              <button className="button primary" disabled={busy}>
                {busy ? "Publishing…" : "Publish review"}
                <ArrowRight size={16} />
              </button>
            </form>
          </section>
        </div>
      )}
    </>
  );
}
export function MyReviews() {
  const { data, loading, error, reload } = useApi("/reviews");
  return (
    <>
      <h2>Your voice matters.</h2>
      <p className="section-description">
        Honest thoughts that help others find their favorites.
      </p>
      {loading ? (
        <Loading />
      ) : error ? (
        <ErrorState message={error} retry={reload} />
      ) : data?.reviews.length ? (
        data.reviews.map((r: any) => (
          <article className="review-card" key={r.review_id}>
            <Link className="text-link" to={"/products/" + r.product_id}>
              {r.product_name}
              <ArrowRight size={14} />
            </Link>
            <div className="stars">
              {r.rating} / 5 <Star size={14} fill="currentColor" />
            </div>
            <h3>{r.title}</h3>
            <p>{r.body}</p>
            <small>{r.is_approved ? "Published" : "Awaiting moderation"}</small>
          </article>
        ))
      ) : (
        <Empty
          title="Every opinion starts with a good find"
          description="After a demo purchase, share your experience from your orders."
          action="View my orders"
          to="/account/orders"
        />
      )}
    </>
  );
}
export function Preferences() {
  const { data, loading, error, reload } = useApi(
    "/recommendations/preferences",
  );
  const { toast } = useStore();
  return (
    <section className="form-panel">
      <h2>Your recommendations. Your choice.</h2>
      <p className="section-description">
        A shopping experience that feels right for you.
      </p>
      {loading ? (
        <Loading />
      ) : error ? (
        <ErrorState message={error} retry={reload} />
      ) : (
        <>
          <label className="preference-row">
            <span>
              <b>Personalized discoveries</b>
              <small>
                Use my purchase history and interactions to recommend products.
              </small>
            </span>
            <input
              type="checkbox"
              checked={data?.enabled || false}
              onChange={async (e) => {
                try {
                  await mutate("/recommendations/preferences", "PUT", {
                    enabled: e.target.checked,
                  });
                  reload();
                  toast("Preferences saved.");
                } catch (e: any) {
                  toast(e.message);
                }
              }}
            />
          </label>
          <p>
            When you turn this off, we clear your browsing interactions and show
            community favorites instead. Your orders and wishlist stay safe.
          </p>
          <Link className="text-link" to="/about">
            How our recommendations work <ArrowRight size={15} />
          </Link>
        </>
      )}
    </section>
  );
}
