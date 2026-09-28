import { Link } from "react-router-dom";
import {
  Sparkles,
  Heart,
  Layers3,
  ShieldCheck,
  ArrowRight,
} from "lucide-react";
export function About() {
  return (
    <article className="container page about-page">
      <header className="page-title">
        <span className="eyebrow">A LITTLE INTELLIGENCE. A LOT OF HEART.</span>
        <h1>A store that gets you.</h1>
        <p>Thoughtful recommendations, explained simply.</p>
      </header>
      <section className="about-intro">
        <Sparkles size={38} />
        <h2>Not magic. Meaningful connections.</h2>
        <p>
          ShopEase connects what you like with what you might love next. Our
          initial recommendation engine blends real purchase patterns, product
          categories, brands, specifications, and customer ratings. No
          recommendations are hard-coded into the storefront.
        </p>
      </section>
      <div className="about-grid">
        <section className="form-panel">
          <h3>01 / Your kind of finds</h3>
          <p>
            When you sign in, your purchases and product interactions help shape
            a personalized ranking. We look at similar shoppers’ purchases and
            products that share your interests.
          </p>
        </section>
        <section className="form-panel">
          <h3>02 / Better together</h3>
          <p>
            “Customers also bought” only shows items that actually appear
            together in eligible paid orders. If there isn’t enough data, we say
            so instead of inventing a match.
          </p>
        </section>
        <section className="form-panel">
          <h3>03 / Room to grow</h3>
          <p>
            New visitors start with popular products. A dedicated backend
            service can connect to an external Python model without changing the
            storefront.
          </p>
        </section>
        <section className="form-panel">
          <h3>04 / Honest feedback</h3>
          <p>
            Verified reviews contribute ratings. A separate sentiment data layer
            is ready for NLP/BERT scores. We do not claim that an NLP model is
            currently running.
          </p>
        </section>
      </div>
      <section id="privacy" className="section">
        <h2>Your preferences matter.</h2>
        <p>
          Account details, hashed passwords, orders, wishlists, and product
          interactions are stored in Cloudflare D1. Your session is protected by
          a secure, HttpOnly cookie; the database stores only a hash of its
          random token.
        </p>
        <p>
          You can turn off personalized recommendations in your account. This
          removes browsing interactions and stops new interaction tracking.
          Order records remain for your order history. We don’t send names,
          email addresses, passwords, or shipping addresses to the
          recommendation model.
        </p>
        <Link className="text-link" to="/account/preferences">
          Manage my preferences <ArrowRight size={16} />
        </Link>
      </section>
      <section id="demo" className="section">
        <h2>A real application. A demonstration store.</h2>
        <p>
          This university-style AI commerce project uses the original
          mustheers-del/ecommerce-sql-database sample catalog and historical
          records. It is not affiliated with the listed brands. Prices and
          descriptions are preserved from that source, not live retail offers.
        </p>
        <p>
          Checkout simulates a successful wallet payment. No real money is
          charged, no card information is collected, and no products are
          shipped. Use fictional shipping details. A completed demo payment
          qualifies for the verified-purchase review flow.
        </p>
        <p>
          The historical sample catalog is small, so recommendation confidence
          is limited. More real interactions or your trained model will improve
          the signal. Product images may be illustrative where noted.
        </p>
      </section>
    </article>
  );
}
