import { useState, useEffect } from "react";
import {
  Link,
  NavLink,
  Outlet,
  useLocation,
  useNavigate,
} from "react-router-dom";
import {
  Search,
  Heart,
  ShoppingBag,
  UserRound,
  ArrowRight,
  ChevronDown,
  Menu,
  X,
  Sparkles,
  Truck,
  ShieldCheck,
  Leaf,
  ChevronRight,
} from "lucide-react";
import { useStore } from "../store";
import { useApi } from "../api";
export function Logo() {
  return (
    <Link className="logo" to="/" aria-label="ShopEase home">
      <span className="logo-icon">
        <ShoppingBag size={21} />
      </span>
      shop<span>ease</span>
      <i>®</i>
    </Link>
  );
}
export function Layout() {
  const { user, cart } = useStore();
  const [q, setQ] = useState(""),
    [debounced, setDebounced] = useState(""),
    [focus, setFocus] = useState(false),
    [menu, setMenu] = useState(false);
  const nav = useNavigate();
  const location = useLocation();
  useEffect(() => {
    window.scrollTo({ top: 0, behavior: "instant" });
    setMenu(false);
    setFocus(false);
  }, [location.pathname, location.search]);
  useEffect(() => {
    const t = setTimeout(() => setDebounced(q), 250);
    return () => clearTimeout(t);
  }, [q]);
  const suggestions = useApi(
    debounced.length > 1 && focus
      ? "/products?q=" + encodeURIComponent(debounced) + "&limit=4"
      : null,
  );
  const categories = useApi("/categories");
  const roots =
    categories.data?.categories.filter((c: any) => !c.parent_id) || [];
  return (
    <>
      <a className="skip-link" href="#main-content">
        Skip to content
      </a>
      <div className="announcement">
        <span>A little smarter. A little more you.</span>
        <span>
          Discover a new way to shop <ArrowRight size={13} />
        </span>
        <span>
          India <ChevronDown size={12} /> INR ₹
        </span>
      </div>
      <header className="site-header">
        <div className="header-main container">
          <Logo />
          <form
            className="header-search"
            role="search"
            onSubmit={(e) => {
              e.preventDefault();
              setFocus(false);
              nav("/products?q=" + encodeURIComponent(q));
            }}
          >
            <Search size={19} />
            <input
              aria-label="Search products"
              placeholder="Search for your next favorite thing…"
              value={q}
              onChange={(e) => setQ(e.target.value)}
              onFocus={() => setFocus(true)}
              onBlur={() => setTimeout(() => setFocus(false), 180)}
            />
            <kbd>⌘ K</kbd>
            {focus && debounced.length > 1 && (
              <div className="suggestions">
                {suggestions.loading ? (
                  <p>Searching…</p>
                ) : suggestions.error ? (
                  <p>Search unavailable. Please retry.</p>
                ) : suggestions.data?.products.length ? (
                  suggestions.data.products.map((p: any) => (
                    <Link key={p.product_id} to={"/products/" + p.product_id}>
                      <img src={p.image_url} alt="" />
                      <span>{p.name}</span>
                      <ChevronRight size={16} />
                    </Link>
                  ))
                ) : (
                  <p>No products found. Try a different name.</p>
                )}
              </div>
            )}
          </form>
          <div className="header-actions">
            <Link className="account-link" to={user ? "/account" : "/login"}>
              <UserRound size={22} />
              <span>
                <small>{user ? "Welcome back" : "Hello, welcome"}</small>
                <b>{user ? user.first_name : "Sign in"}</b>
              </span>
            </Link>
            <Link
              className="header-icon"
              to="/account/wishlist"
              aria-label="Your wishlist"
            >
              <Heart size={23} />
            </Link>
            <Link
              className="header-icon bag"
              to="/cart"
              aria-label="Shopping bag"
            >
              <ShoppingBag size={23} />
              <span>{cart.reduce((s, p) => s + p.quantity, 0)}</span>
            </Link>
            <button
              className="mobile-menu icon-button"
              onClick={() => setMenu(!menu)}
              aria-label="Toggle navigation"
            >
              {menu ? <X /> : <Menu />}
            </button>
          </div>
        </div>
        <nav
          className={"header-nav container " + (menu ? "open" : "")}
          aria-label="Main navigation"
        >
          <div>
            <NavLink to="/" end>
              Discover
            </NavLink>
            <NavLink to="/products" end>
              Shop all
            </NavLink>
            {roots.map((c: any) => (
              <Link
                key={c.category_id}
                to={"/products?category=" + c.category_id}
              >
                {c.name}
              </Link>
            ))}
          </div>
          <Link className="for-you-nav" to="/for-you">
            <Sparkles size={15} /> For you<span className="tiny-badge">AI</span>
          </Link>
        </nav>
      </header>
      <main id="main-content">
        <Outlet />
      </main>
      <section className="benefits container">
        <article>
          <Truck />
          <div>
            <b>A lighter checkout</b>
            <p>Free demo shipping on every order</p>
          </div>
        </article>
        <article>
          <ShieldCheck />
          <div>
            <b>Shop with confidence</b>
            <p>Secure accounts. Verified reviews.</p>
          </div>
        </article>
        <article>
          <Sparkles />
          <div>
            <b>Thoughtfully personalized</b>
            <p>Discover more of what you love</p>
          </div>
        </article>
        <article>
          <Leaf />
          <div>
            <b>Made for discovery</b>
            <p>Everyday essentials, all in one place</p>
          </div>
        </article>
      </section>
      <footer className="site-footer">
        <div className="container footer-grid">
          <div>
            <Logo />
            <p>
              Good finds. Better recommendations.
              <br />A shopping experience that gets you.
            </p>
            <span className="footer-note">
              An AI-powered commerce demonstration.
            </span>
          </div>
          <div>
            <h4>Explore</h4>
            <Link to="/products">All products</Link>
            <Link to="/for-you">Personalized for you</Link>
            <Link to="/products?sort=newest">New discoveries</Link>
          </div>
          <div>
            <h4>Your space</h4>
            <Link to="/account">My account</Link>
            <Link to="/account/orders">Orders & tracking</Link>
            <Link to="/account/wishlist">Your wishlist</Link>
          </div>
          <div>
            <h4>A little transparency</h4>
            <Link to="/about">How recommendations work</Link>
            <Link to="/about#privacy">Privacy & preferences</Link>
            <Link to="/about#demo">Demo shopping explained</Link>
          </div>
        </div>
        <div className="footer-bottom container">
          <span>
            © {new Date().getFullYear()} ShopEase. Thoughtfully put together.
          </span>
          <span>Demo payments only · No real charges or deliveries</span>
          <span>INR ₹ · India</span>
        </div>
      </footer>
    </>
  );
}
