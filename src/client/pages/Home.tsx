import { Link } from "react-router-dom";
import {
  ArrowRight,
  ArrowUpRight,
  Sparkles,
  Check,
  Headphones,
  Smartphone,
  Shirt,
  BookOpen,
  Armchair,
  Footprints,
  SlidersHorizontal,
} from "lucide-react";
import { useApi, money } from "../api";
import { useStore } from "../store";
import {
  ProductGrid,
  Loading,
  ErrorState,
  SectionHeading,
  RecommendationSection,
} from "../components/UI";
export function Home() {
  const { user } = useStore();
  const featured = useApi("/products?limit=4&sort=featured");
  const catalog = useApi("/products?limit=30");
  const cats = useApi("/categories");
  const all = catalog.data?.products || [];
  const hero = all.find((p: any) => p.slug === "sony-wf-1000xm5");
  const shoe = all.find((p: any) => p.slug === "nike-air-max-90");
  const book = all.find((p: any) => p.slug === "atomic-habits");
  const icons = [Smartphone, Shirt, BookOpen, Armchair, Footprints];
  const pictures = ["phone", "shirt", "book", "mixer", "shoe"];
  return (
    <div className="home container">
      <section className="hero" id="hero-section">
        <div className="hero-content">
          <span className="hero-label">
            <span /> NOT JUST MORE. MORE YOU.
          </span>
          <h1>
            Find your everyday
            <br />
            <em>extraordinary.</em>
          </h1>
          <p>
            Thoughtful finds for the way you live.
            <br />
            Discover things you’ll love, picked just for you.
          </p>
          <div className="hero-buttons">
            <Link className="button primary" to="/products">
              Explore the collection <ArrowRight size={17} />
            </Link>
            <Link className="hero-secondary" to="/for-you">
              <Sparkles size={16} /> Find my favorites
            </Link>
          </div>
          <div className="hero-proof">
            <div className="proof-icon">
              <Sparkles size={20} />
            </div>
            <div>
              <b>A little intelligence. A lot of inspiration.</b>
              <span>Recommendations that get better as you explore.</span>
            </div>
          </div>
        </div>
        <div
          className="hero-visual"
          aria-label="A selection of our everyday favorites"
        >
          <div className="hero-orbit orbit-one" />
          <div className="hero-orbit orbit-two" />
          <span className="hero-star star-one">✳</span>
          <span className="hero-star star-two">✳</span>
          <div className="hero-note">
            <Sparkles size={16} />
            <span>Good taste. Great discoveries.</span>
          </div>
          {hero && (
            <Link
              className="hero-main-product"
              to={"/products/" + hero.product_id}
            >
              <span className="hero-product-kicker">YOUR DAILY SOUNDTRACK</span>
              <img src={hero.image_url} alt={hero.name} />
              <div>
                <span>
                  <b>{hero.name}</b>
                  <small>Less noise. More you.</small>
                </span>
                <span className="circle-arrow">
                  <ArrowUpRight size={21} />
                </span>
              </div>
            </Link>
          )}
          {shoe && (
            <Link
              className="hero-mini hero-shoe"
              to={"/products/" + shoe.product_id}
            >
              <img src={shoe.image_url} alt={shoe.name} />
              <span>
                Everyday icons <ArrowUpRight size={14} />
              </span>
            </Link>
          )}
          {book && (
            <Link
              className="hero-mini hero-book"
              to={"/products/" + book.product_id}
            >
              <img src={book.image_url} alt={book.name} />
            </Link>
          )}
          <div className="match-tag">
            <span>
              <Check size={13} />
            </span>{" "}
            A world of good finds
          </div>
          <div className="hero-visual-caption">
            <span>CURATED FOR EVERYDAY LIVING</span>
            <span>01 — 03</span>
          </div>
        </div>
      </section>
      <div className="discovery-strip">
        <p>
          <Sparkles size={17} />
          <strong>Your next favorite is closer than you think.</strong>
          <span>Explore. Discover. Make it yours.</span>
        </p>
        <Link to="/about">
          Meet your personal shopping assistant <ArrowUpRight size={16} />
        </Link>
      </div>
      <section className="section categories-section">
        <SectionHeading
          title="A little something for every side of you"
          description="Find your kind of everyday essentials."
          to="/products"
          action="Explore all categories"
        />
        <div className="category-grid">
          {cats.data?.categories
            .filter((c: any) => !c.parent_id)
            .map((c: any, i: number) => {
              const Icon = icons[i % icons.length];
              return (
                <Link
                  className={"category-card category-" + i}
                  to={"/products?category=" + c.category_id}
                  key={c.category_id}
                >
                  <div className="category-image">
                    <img
                      src={
                        "/static/images/" +
                        pictures[i % pictures.length] +
                        ".webp"
                      }
                      alt=""
                      onError={(e) => {
                        e.currentTarget.src = "/static/images/placeholder.svg";
                      }}
                    />
                  </div>
                  <span>
                    <b>{c.name}</b>
                    <ArrowUpRight size={17} />
                  </span>
                </Link>
              );
            })}
        </div>
      </section>
      <section className="section featured-section">
        <SectionHeading
          eyebrow="THE GOOD-FINDS EDIT"
          title="Everyday favorites. Anything but ordinary."
          description="A few standout pieces we think you’ll love."
          to="/products"
          action="Shop the edit"
        />
        {featured.loading ? (
          <Loading cards />
        ) : featured.error ? (
          <ErrorState message={featured.error} retry={featured.reload} />
        ) : (
          <ProductGrid products={featured.data.products} />
        )}
      </section>
      <section className="personalized-panel">
        <div className="personalized-heading">
          <span className="ai-symbol">
            <Sparkles size={24} />
          </span>
          <div>
            <span className="eyebrow">A STOREFRONT THAT GETS YOU</span>
            <h2>Good finds, with your name on them.</h2>
            <p>
              {user
                ? "Your interests. Your discoveries. A little more personal."
                : "The more you explore, the more it feels like your kind of store."}
            </p>
          </div>
          <Link className="button secondary" to="/for-you">
            Discover your picks <ArrowUpRight size={16} />
          </Link>
        </div>
        <RecommendationSection
          path={
            "/recommendations/for-you" + (user ? "?user=" + user.user_id : "")
          }
          title="Personalized for you"
          description={
            user
              ? "Inspired by your purchases and discoveries."
              : "Start with community favorites. Sign in to make them yours."
          }
        />
      </section>
      <section className="editorial-banner">
        <div>
          <p className="eyebrow">SMALL UPGRADES. BIG DIFFERENCE.</p>
          <h2>
            Make room for
            <br />
            your next favorite.
          </h2>
          <p>
            From your morning read to your everyday soundtrack,
            <br />
            find the little things that make life better.
          </p>
          <Link className="button primary" to="/products?sort=newest">
            Discover something new <ArrowRight size={17} />
          </Link>
        </div>
        <div className="editorial-images">
          <img
            className="editorial-book"
            src="/static/images/book.webp"
            alt="Atomic Habits"
          />
          <img
            className="editorial-earbuds"
            src="/static/images/earbuds.webp"
            alt="Sony wireless earbuds"
          />
          <span>THE EVERYDAY EDIT</span>
        </div>
      </section>
      <RecommendationSection
        path="/recommendations/popular"
        title="Loved by the community"
        description="Popular picks, backed by real purchases and reviews."
      />
      <RecommendationSection
        path={user ? "/recommendations/recent" : null}
        title="Another look?"
        description="Pick up where your curiosity left off."
        hideEmpty
      />
      <section className="join-banner">
        <div>
          <span className="eyebrow">LESS SCROLLING. MORE DISCOVERING.</span>
          <h2>Your taste. Your space.</h2>
          <p>Save what you love and discover what’s next.</p>
        </div>
        <Link className="button primary" to={user ? "/account" : "/register"}>
          {user ? "Go to my account" : "Make yourself at home"}
          <ArrowRight size={18} />
        </Link>
      </section>
    </div>
  );
}
export function ForYou() {
  const { user } = useStore();
  return (
    <div className="container page">
      <header className="page-title">
        <span className="eyebrow">
          <Sparkles size={15} /> YOUR PERSONAL DISCOVERY SPACE
        </span>
        <h1>A little more you.</h1>
        <p>
          {user
            ? "Welcome back, " +
              user.first_name +
              ". Your next favorite is waiting."
            : "Great discoveries start here. Sign in for recommendations shaped by you."}
        </p>
        {!user && (
          <Link className="button primary" to="/login?next=/for-you">
            Sign in for your picks <ArrowRight size={16} />
          </Link>
        )}
      </header>
      <RecommendationSection
        path="/recommendations/for-you"
        title="Personalized for you"
        description="Purchase patterns, shared interests, and thoughtful matches."
        limit={8}
      />
      <RecommendationSection
        path={user ? "/recommendations/recent" : null}
        title="Recently viewed"
        description="Worth a second look."
        hideEmpty
      />
      <RecommendationSection
        path="/recommendations/popular"
        title="Popular products"
        description="Community favorites for a little inspiration."
      />
    </div>
  );
}
