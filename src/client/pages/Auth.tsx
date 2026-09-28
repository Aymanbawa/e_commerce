import { useState } from "react";
import { Link, useNavigate, useSearchParams, Navigate } from "react-router-dom";
import {
  ArrowRight,
  Eye,
  EyeOff,
  Sparkles,
  ShieldCheck,
  Heart,
  ShoppingBag,
} from "lucide-react";
import { mutate } from "../api";
import { useStore } from "../store";
export function Auth({ register = false }: { register?: boolean }) {
  const { user, refresh } = useStore();
  const nav = useNavigate();
  const [params] = useSearchParams();
  const [error, setError] = useState(""),
    [busy, setBusy] = useState(false),
    [show, setShow] = useState(false);
  const requested = params.get("next") || "/account";
  const next =
    requested.startsWith("/") &&
    !requested.startsWith("//") &&
    !requested.includes("\\")
      ? requested
      : "/account";
  if (user) return <Navigate to={next} replace />;
  async function submit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setError("");
    setBusy(true);
    const data = Object.fromEntries(new FormData(e.currentTarget));
    try {
      await mutate("/auth/" + (register ? "register" : "login"), "POST", data);
      await refresh();
      nav(next, { replace: true });
    } catch (e: any) {
      setError(e.message);
    } finally {
      setBusy(false);
    }
  }
  return (
    <div className="container auth-page">
      <section className="auth-story">
        <span className="eyebrow">YOUR NEXT FAVORITE STARTS HERE</span>
        <h1>
          Good finds.
          <br />
          Great company.
          <br />
          <em>Your kind of store.</em>
        </h1>
        <p>A little space for everything you love.</p>
        <ul>
          <li>
            <Sparkles size={20} />
            Recommendations shaped around you
          </li>
          <li>
            <Heart size={20} />
            All your favorites, saved in one place
          </li>
          <li>
            <ShoppingBag size={20} />A simpler, more thoughtful checkout
          </li>
        </ul>
        <div className="auth-art">
          <img src="/static/images/shoe.webp" alt="Nike Air Max 90" />
          <span>EVERYDAY EXTRAORDINARY</span>
        </div>
      </section>
      <section className="auth-form-panel">
        <span className="small-icon">
          <UserIcon />
        </span>
        <h2>{register ? "Make yourself at home." : "Welcome back."}</h2>
        <p>
          {register
            ? "Create an account for a more personal way to shop."
            : "Your favorites are right where you left them."}
        </p>
        <form onSubmit={submit} className="form-stack">
          {register && (
            <div className="form-row">
              <label>
                First name
                <input
                  name="first_name"
                  autoComplete="given-name"
                  required
                  maxLength={100}
                  placeholder="Your first name"
                />
              </label>
              <label>
                Last name
                <input
                  name="last_name"
                  autoComplete="family-name"
                  required
                  maxLength={100}
                  placeholder="Your last name"
                />
              </label>
            </div>
          )}
          <label>
            Email address
            <input
              name="email"
              type="email"
              autoComplete="email"
              required
              maxLength={255}
              placeholder="you@example.com"
            />
          </label>
          <label>
            Password
            <div className="password-input">
              <input
                name="password"
                type={show ? "text" : "password"}
                autoComplete={register ? "new-password" : "current-password"}
                minLength={10}
                maxLength={128}
                required
                placeholder={
                  register ? "At least 10 characters" : "Enter your password"
                }
              />
              <button
                type="button"
                aria-label={show ? "Hide password" : "Show password"}
                onClick={() => setShow(!show)}
              >
                {show ? <EyeOff size={18} /> : <Eye size={18} />}
              </button>
            </div>
          </label>
          {register && (
            <p className="fine-print">
              Use a unique password with at least 10 characters.
            </p>
          )}
          {error && (
            <p className="form-error" role="alert">
              {error}
            </p>
          )}
          <button className="button primary full" disabled={busy}>
            {busy ? "Just a moment…" : register ? "Create account" : "Sign in"}
            <ArrowRight size={17} />
          </button>
        </form>
        <p className="auth-switch">
          {register ? "Already part of the community?" : "New around here?"}{" "}
          <Link
            to={
              (register ? "/login" : "/register") +
              "?next=" +
              encodeURIComponent(next)
            }
          >
            {register ? "Sign in" : "Create an account"}
          </Link>
        </p>
        <div className="auth-security">
          <ShieldCheck size={16} />
          Secure sign-in. No real payment details needed.
        </div>
        <p className="fine-print center">
          By continuing, you acknowledge this is a demonstration store.
          <br />
          <Link to="/about#privacy">Read about your data and privacy.</Link>
        </p>
      </section>
    </div>
  );
}
function UserIcon() {
  return <ShoppingBag size={22} />;
}
