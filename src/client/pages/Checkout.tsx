import { useEffect, useState } from "react";
import { Link, useNavigate, Navigate } from "react-router-dom";
import {
  Minus,
  Plus,
  Trash2,
  ArrowRight,
  ArrowLeft,
  LockKeyhole,
  ShieldCheck,
  Check,
  ShoppingBag,
} from "lucide-react";
import { useStore } from "../store";
import { useApi, mutate, money } from "../api";
import {
  Empty,
  Loading,
  ProductImage,
  RecommendationSection,
} from "../components/UI";
export function Cart() {
  const { cart, user, ready, setQuantity } = useStore();
  const [busy, setBusy] = useState<number | null>(null);
  if (!ready) return <Loading />;
  const total =
    cart.reduce((n, p) => n + Math.round(p.price * 100) * p.quantity, 0) / 100;
  async function qty(id: number, q: number) {
    setBusy(id);
    try {
      await setQuantity(id, q);
    } catch {
    } finally {
      setBusy(null);
    }
  }
  return (
    <div className="container page">
      <p className="breadcrumb">
        <Link to="/products">The collection</Link> / Your bag
      </p>
      <header className="page-title">
        <span className="eyebrow">GOOD CHOICES, ALL TOGETHER</span>
        <h1>Your shopping bag.</h1>
        <p>
          {cart.length
            ? `${cart.reduce((s, p) => s + p.quantity, 0)} little reasons to look forward to your day.`
            : "A little room for your next favorite."}
        </p>
      </header>
      {!user ? (
        <Empty
          title="Your bag belongs with you"
          description="Sign in to save your bag across devices."
          action="Sign in"
          to="/login?next=/cart"
        />
      ) : !cart.length ? (
        <Empty
          title="Your bag is waiting for a good find"
          description="Start exploring and add something that feels like you."
        />
      ) : (
        <div className="checkout-layout">
          <section className="cart-items">
            {cart.map((p) => (
              <article className="cart-item" key={p.product_id}>
                <Link className="cart-image" to={"/products/" + p.product_id}>
                  <ProductImage product={p} />
                </Link>
                <div className="cart-description">
                  <span className="eyebrow">
                    {p.brand_name || p.category_name}
                  </span>
                  <Link to={"/products/" + p.product_id}>
                    <h3>{p.name}</h3>
                  </Link>
                  <p>{money(p.price)} each</p>
                  <div className="quantity-control">
                    <button
                      aria-label={"Decrease " + p.name}
                      disabled={busy === p.product_id}
                      onClick={() => qty(p.product_id, p.quantity - 1)}
                    >
                      <Minus size={14} />
                    </button>
                    <span>{p.quantity}</span>
                    <button
                      aria-label={"Increase " + p.name}
                      disabled={
                        busy === p.product_id ||
                        p.quantity >= Math.min(p.available, 20)
                      }
                      onClick={() => qty(p.product_id, p.quantity + 1)}
                    >
                      <Plus size={14} />
                    </button>
                  </div>
                  {p.available < p.quantity && (
                    <small className="form-error">
                      Please reduce the quantity: stock has changed.
                    </small>
                  )}
                </div>
                <div className="cart-item-total">
                  <strong>{money(p.price * p.quantity)}</strong>
                  <button
                    className="icon-button"
                    aria-label={"Remove " + p.name}
                    onClick={() => qty(p.product_id, 0)}
                  >
                    <Trash2 size={17} />
                  </button>
                </div>
              </article>
            ))}
            <Link className="text-link" to="/products">
              <ArrowLeft size={16} />A little more exploring
            </Link>
          </section>
          <aside className="order-summary">
            <h3>A lovely little summary</h3>
            <dl>
              <div>
                <dt>Subtotal</dt>
                <dd>{money(total)}</dd>
              </div>
              <div>
                <dt>Demo shipping</dt>
                <dd className="green">On us</dd>
              </div>
            </dl>
            <div className="summary-total">
              <span>Total</span>
              <strong>{money(total)}</strong>
            </div>
            <p className="fine-print">No extra taxes or fees in this demo.</p>
            <Link className="button primary full" to="/checkout">
              Continue to checkout
              <ArrowRight size={17} />
            </Link>
            <p className="secure-note">
              <LockKeyhole size={13} /> Secure, demo-only checkout
            </p>
          </aside>
        </div>
      )}
      <RecommendationSection
        path="/recommendations/for-you"
        title="A few more good finds"
        description="A little inspiration before you go."
      />
    </div>
  );
}
export function Checkout() {
  const { user, ready, cart, refresh } = useStore();
  const [error, setError] = useState(""),
    [busy, setBusy] = useState(false),
    [key] = useState(() => crypto.randomUUID());
  const nav = useNavigate();
  const total =
    cart.reduce((s, p) => s + Math.round(p.price * 100) * p.quantity, 0) / 100;
  if (!ready) return <Loading />;
  if (!user) return <Navigate to="/login?next=/checkout" replace />;
  if (!cart.length && !busy) return <Navigate to="/cart" replace />;
  async function submit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setBusy(true);
    setError("");
    const d = Object.fromEntries(new FormData(e.currentTarget));
    try {
      const result = await mutate("/checkout", "POST", {
        ...d,
        demo_payment: true,
        checkout_key: key,
      });
      await refresh();
      nav("/account/orders/" + result.order.order_id + "?success=1", {
        replace: true,
      });
    } catch (e: any) {
      setError(e.message);
      setBusy(false);
    }
  }
  return (
    <div className="container page checkout-page">
      <p className="breadcrumb">
        <Link to="/cart">Your bag</Link> / Checkout
      </p>
      <header className="page-title">
        <span className="eyebrow">ONE LAST LITTLE STEP</span>
        <h1>Make it yours.</h1>
        <p>A simple, secure checkout. Just the way it should be.</p>
      </header>
      <form className="checkout-layout" onSubmit={submit}>
        <div>
          <section className="form-panel">
            <h3>
              <span className="step-number">1</span> Your details
            </h3>
            <p className="fine-print">Signed in as {user.email}</p>
            <div className="form-stack">
              <label>
                Full name
                <input
                  name="full_name"
                  autoComplete="name"
                  required
                  minLength={2}
                  maxLength={200}
                  defaultValue={user.first_name + " " + user.last_name}
                />
              </label>
              <label>
                Phone number
                <input
                  name="phone"
                  type="tel"
                  autoComplete="tel"
                  required
                  minLength={5}
                  maxLength={20}
                  placeholder="Your contact number"
                />
              </label>
            </div>
          </section>
          <section className="form-panel">
            <h3>
              <span className="step-number">2</span> Shipping information
            </h3>
            <p className="fine-print">
              For demonstration only. Use a fictional address; nothing will be
              shipped.
            </p>
            <div className="form-stack">
              <label>
                Street address
                <input
                  name="address_line1"
                  autoComplete="street-address"
                  minLength={5}
                  maxLength={255}
                  placeholder="House, apartment and street"
                  required
                />
              </label>
              <div className="form-row">
                <label>
                  City
                  <input
                    name="city"
                    autoComplete="address-level2"
                    minLength={2}
                    maxLength={100}
                    required
                  />
                </label>
                <label>
                  State
                  <input
                    name="state"
                    autoComplete="address-level1"
                    minLength={2}
                    maxLength={100}
                    required
                  />
                </label>
              </div>
              <div className="form-row">
                <label>
                  Postal code
                  <input
                    name="postal_code"
                    autoComplete="postal-code"
                    minLength={3}
                    maxLength={20}
                    required
                  />
                </label>
                <label>
                  Country
                  <select name="country">
                    <option>India</option>
                  </select>
                </label>
              </div>
            </div>
          </section>
          <section className="form-panel">
            <h3>
              <span className="step-number">3</span> Payment
            </h3>
            <div className="demo-payment">
              <span className="radio-dot" />
              <div>
                <b>Demo wallet</b>
                <p>Simulate a successful payment. No real money is charged.</p>
              </div>
              <ShieldCheck size={24} />
            </div>
            <label className="checkbox-label">
              <input type="checkbox" required />I understand this is a demo
              purchase with no real charge or delivery.
            </label>
          </section>
        </div>
        <aside className="order-summary">
          <h3>Your good finds</h3>
          {cart.map((p) => (
            <div className="summary-item" key={p.product_id}>
              <ProductImage product={p} />
              <span>
                <b>{p.name}</b>
                <small>Quantity: {p.quantity}</small>
              </span>
              <strong>{money(p.price * p.quantity)}</strong>
            </div>
          ))}
          <dl>
            <div>
              <dt>Subtotal</dt>
              <dd>{money(total)}</dd>
            </div>
            <div>
              <dt>Demo shipping</dt>
              <dd className="green">Free</dd>
            </div>
          </dl>
          <div className="summary-total">
            <span>Total</span>
            <strong>{money(total)}</strong>
          </div>
          {error && (
            <p className="form-error" role="alert">
              {error}
            </p>
          )}
          <button type="submit" className="button primary full" disabled={busy}>
            {busy ? "Placing your order…" : "Place demo order"}
            <ArrowRight size={17} />
          </button>
          <p className="secure-note">
            <LockKeyhole size={13} />
            No payment information is collected
          </p>
        </aside>
      </form>
    </div>
  );
}
