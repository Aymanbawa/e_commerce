import { Hono } from "hono";
import { HTTPException } from "hono/http-exception";
import { serveStatic } from "hono/cloudflare-workers";
import { ZodError } from "zod";
import { bodyLimit } from "hono/body-limit";
import type { AppEnv } from "./types";
import { sessionMiddleware } from "./security";
import { auth } from "./routes/auth";
import { products } from "./routes/products";
import { commerce } from "./routes/commerce";
import { recommendations } from "./routes/recommendations";
import { admin } from "./routes/admin";
const app = new Hono<AppEnv>();
app.use("*", async (c, next) => {
  c.header("X-Content-Type-Options", "nosniff");
  c.header("Referrer-Policy", "strict-origin-when-cross-origin");
  c.header("X-Frame-Options", "DENY");
  c.header("Permissions-Policy", "camera=(), microphone=(), geolocation=()");
  c.header(
    "Content-Security-Policy",
    "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'",
  );
  if (new URL(c.req.url).protocol === "https:")
    c.header("Strict-Transport-Security", "max-age=31536000");
  await next();
});
app.use(
  "/api/*",
  bodyLimit({
    maxSize: 16000,
    onError: (c) => c.json({ error: "Request too large." }, 413),
  }),
);
app.use("/api/*", async (c, next) => {
  c.header("Cache-Control", "no-store");
  if (!["GET", "HEAD", "OPTIONS"].includes(c.req.method)) {
    const origin = c.req.header("Origin");
    if (origin && origin !== new URL(c.req.url).origin)
      throw new HTTPException(403, {
        message: "Cross-origin requests are not allowed.",
      });
    if (c.req.header("Sec-Fetch-Site") === "cross-site")
      throw new HTTPException(403, { message: "Cross-site request blocked." });
    if (!c.req.header("Content-Type")?.includes("application/json"))
      throw new HTTPException(415, { message: "JSON content type required." });
    const body = await c.req.text();
    if (body.length > 16000)
      throw new HTTPException(413, { message: "Request too large." });
  }
  await next();
});
app.get("/api/health", async (c) => {
  await c.env.DB.prepare("SELECT 1").first();
  return c.json({ status: "ok", database: "D1", payments: "demo" });
});
app.use("/api/*", sessionMiddleware);
app.route("/api/auth", auth);
app.route("/api", products);
app.route("/api/recommendations", recommendations);
app.route("/api/admin", admin);
app.route("/api", commerce);
app.all("/api/*", (c) => c.json({ error: "API endpoint not found." }, 404));
app.use("/static/*", serveStatic({ root: "./public" }));
app.get("*", (c) =>
  c.html(
    `<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="theme-color" content="#233f35"><meta name="description" content="ShopEase — thoughtful finds, personalized for you. Discover electronics, style, books and everyday essentials with intelligent recommendations."><title>ShopEase — Find your everyday extraordinary</title><link rel="icon" href="/static/favicon.svg" type="image/svg+xml"><link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;450;500;550;600;650;700&family=Manrope:wght@400;500;600;650;700;750;800&display=swap" rel="stylesheet"><link rel="stylesheet" href="/static/app.css"></head><body><div id="root"></div><script type="module" src="/static/app.js"></script></body></html>`,
  ),
);
app.onError((e, c) => {
  if (e instanceof ZodError)
    return c.json(
      {
        error: e.issues
          .map((i) => `${i.path.join(".")}: ${i.message}`)
          .join("; "),
      },
      400,
    );
  if (e instanceof HTTPException) return c.json({ error: e.message }, e.status);
  if (e instanceof SyntaxError)
    return c.json({ error: "Invalid JSON request." }, 400);
  console.error("request_failed", c.req.path, e.message);
  return c.json({ error: "Something went wrong. Please try again." }, 500);
});
export default app;
