# ShopEase — AI-powered commerce

A working, responsive React + TypeScript storefront with a Hono API, Cloudflare D1 storage, secure sessions, demo checkout, verified-purchase reviews, and an isolated hybrid recommendation service.

## Live deployment

- **Website:** https://shopease-ai-7f8e17c2.pages.dev
- **Health:** https://shopease-ai-7f8e17c2.pages.dev/api/health
- **Admin UI:** https://shopease-ai-7f8e17c2.pages.dev/admin
- **Platform:** Cloudflare Pages with a Worker (`dist/_worker.js`) and D1, on the owner's Cloudflare account.
- **Database:** `shopease-ai-db`, binding `DB`, ID `339b045b-1276-435a-8368-438bad71000f`.
- **Status:** Deployed and live user flow verified on 2026-09-28.
- **Cost:** Free-tier-compatible architecture. No domain, VPS, paid API, or paid database service is required. Cloudflare quotas and the account's billing configuration still apply; this is not a promise of unlimited free usage.

## Completed functionality

- Responsive desktop/tablet/mobile storefront, product cards, search suggestions, loading/error/empty states, notifications, and local image fallback.
- Registration, login, logout, profile editing, password change, persistent HttpOnly sessions, and role-based administration.
- Database-backed product catalog, nested categories, description/category/name search, price ranges, sorting, pagination, detail pages, attributes, and reviews.
- Persistent per-account bag and wishlist. Login is required to save either.
- Atomic checkout using D1 `batch()`, server-side prices, unique idempotency keys, stock checks, inventory deductions, address snapshots, order items, and recorded **demo** payments.
- Order history/details, status progression, verified-purchase reviews, and review moderation.
- Personalized, similar, frequently bought together, popular, and recently viewed recommendations.
- Personalization opt-out clears browsing interactions and prevents new interaction tracking.
- Admin product creation/edit/archive, category creation/rename, customer suspension/reactivation, inventory overview, order fulfillment progression, review visibility, summary metrics, and recommendation dataset export.
- External Python recommendation adapter with timeout, schema validation, safe candidate filtering, and database fallback.
- Sentiment storage/import API; no trained NLP model is misrepresented as running.

## Original database preservation and migration

Source: https://github.com/mustheers-del/ecommerce-sql-database

Pinned source commit: `ab93963abf1d912dbc2ee424b22d639546f3f3c7`.

The source is vendored without changes in `original-database/` (its nested `.git` directory is omitted). `scripts/migrate.py` generates `migrations/0001_original_dataset.sql` from its actual schema and INSERT statements. No replacement catalog was invented.

Original data counts:

| Table              |                    Rows |
| ------------------ | ----------------------: |
| users              |                       7 |
| addresses          |                       6 |
| categories         |                      19 |
| brands             |                      10 |
| products           | 19 (18 active, 1 draft) |
| product_images     |                      10 |
| product_attributes |                      18 |
| inventory          |                      19 |
| coupons            |                       9 |
| orders             |                       5 |
| order_items        |                       6 |
| payments           |                       4 |
| shipments          |                       2 |
| reviews            |                       5 |
| wishlist           |                       0 |
| audit_log          |                       0 |

Compatibility changes are deliberately limited:

1. MySQL integer IDs become SQLite `INTEGER PRIMARY KEY AUTOINCREMENT`. Original IDs and foreign keys are preserved.
2. ENUMs become TEXT with CHECK constraints; strings/dates/JSON become TEXT; decimal columns use NUMERIC affinity.
3. MySQL `ON UPDATE CURRENT_TIMESTAMP` becomes SQLite update triggers.
4. MySQL engine/collation/database-selection directives and `DESCRIBE`/verification queries are omitted. Email comparisons use NOCASE.
5. MySQL FULLTEXT is replaced by parameterized LIKE search with recursive category matching, appropriate to this small dataset.
6. The order-item decimal multiplication CHECK uses a half-cent tolerance for SQLite binary floating-point arithmetic. Checkout rounds currency to two decimals, while the UI totals in integer paise.
7. Coupons are inserted before orders to satisfy the original foreign keys. Historical prices, totals, dates, statuses, expired coupons, and category assignments are not rewritten, even where source data is unusual (for example, self-help books are assigned to Fiction).
8. Stored procedures are preserved as reference files but do not execute in D1. Application checkout and SQLite stock/review guards replace the necessary transactional behavior. Original historical inventory is not deducted again during seeding.
9. A remote Wrangler parser rejected `SELECT CASE ... END` inside a trigger body. Equivalent trigger `WHEN` clauses solved this without changing records or relationships.
10. Original image URLs are preserved in `product_images`. An additive `product_media` table points to bundled, working assets. Missing exact imagery uses a generic placeholder; alternate appearance images are labeled illustrative.
11. The pending source review #5 references a product absent from its order. It is preserved but cannot be approved as verified and does not contribute to public ratings/recommendations.
12. The original users share a published bcrypt sample hash. Those rows are preserved, but the app deliberately rejects that hash format for login. Register new accounts; a separately provisioned private admin account is provided to the owner.

The original repository snapshot contains no explicit LICENSE file. Do not assume unrestricted commercial redistribution rights; confirm permission with its author before commercial reuse. Product imagery is for this demonstration and has source attribution in `scripts/assets.py` / `product_media`; trademarks belong to their respective owners. Generic shirt art is from FreeSVG. The application is not affiliated with the listed brands.

### Additive application tables

`0002_application.sql` adds `sessions`, `rate_limits`, `cart_items`, `interactions`, `recommendation_preferences`, `review_sentiment`, and `product_media`; it adds `orders.checkout_key` and necessary indexes/guards. `0003_media.sql` adds only image mappings, not products.

- Sessions: SHA-256 hash of an opaque random token, user ID, expiration.
- Cart: user/product composite key and constrained quantity.
- Interactions: user/product/type composite key with bounded count and latest timestamp.
- Sentiment: review ID, numeric score in [-1,1], model version, analysis time.
- Storage: all persistent application state lives in D1. There are no in-memory production stores or runtime filesystem dependencies.

## Quick user guide

1. Open the website and create an account with a unique password of at least 10 characters.
2. Explore products, search by name/description/category, filter or sort, and open a product.
3. Save products with the heart button or add them to your bag.
4. Open the bag, adjust quantities, and continue to checkout.
5. **Use fictional shipping details.** Select the demo wallet acknowledgment. No card details are collected and no money is charged.
6. Place the order, then visit **My orders**. Open an order and select **Write a review**.
7. Visit **For you** to see personalized results. Purchased products are excluded from personalized candidates.
8. Manage recommendations in **My preferences**. Change your password under **My profile**.

The separate private admin credential handoff is not in source control. Sign in and visit `/admin`. Change the initial password in `/account` immediately. Admin roles cannot be claimed during public registration.

## Source organization

```text
src/
  index.tsx                  Hono composition, security headers, HTML shell
  security.ts                Password hashing, sessions, access middleware, rate limits
  db.ts                      Shared safe product projection
  types.ts                   Worker bindings and common types
  routes/
    auth.ts                  Identity, profile, password endpoints
    products.ts              Catalog, categories, interactions
    commerce.ts              Cart, wishlist, checkout, orders, reviews
    recommendations.ts       Recommendation HTTP interface
    admin.ts                 Role-protected management and model data
  services/
    recommendationService.ts Hybrid ranking and external model adapter
  client/
    main.tsx                 React router and error boundary
    api.ts                   Request and loading/error helpers
    store.tsx                Auth/cart/wishlist context
    components/              Layout, cards, shared states
    pages/                   Storefront, account, admin pages
    styles.css               Responsive design system
migrations/                  D1 schema/data migrations
original-database/           Original source snapshot
scripts/                     Migration and image-asset preparation
public/static/               Bundled local images and generated frontend build
 tests/                      Playwright user-flow/security/admin tests
```

## Local setup

Requires Node.js 22+, npm, and Wrangler. Python 3 is only needed to regenerate migrations; Pillow is only needed to regenerate image files. Neither runs in production.

```bash
npm ci
cp .env.example .dev.vars
npm run db:local
npm run typecheck
npm run build
```

In this sandbox, start via PM2:

```bash
fuser -k 3000/tcp 2>/dev/null || true
pm2 start ecosystem.config.cjs
curl http://localhost:3000/api/health
```

Outside this sandbox, update the absolute `cwd` in `ecosystem.config.cjs` to your checkout, or use `npx wrangler pages dev dist --port 3000`. Rebuild after frontend or backend changes; the preview watches the built output.

`npm run build` first builds React into `public/static`, then builds the Hono Worker and copies assets to `dist`. Frontend production mode is explicitly defined to avoid leaking Node's `process` global into browser code.

Optional original migration verification (does not modify a running database):

```bash
python3 scripts/migrate.py
```

Do not run the original `setup.sql` against D1: it is a destructive MySQL setup script. Deploy only the versioned D1 migrations. Never overwrite an already-applied migration to make a production change; add a new numbered migration.

## Deployment / redeployment

The current project is already deployed; the commands below are for future updates.

1. Configure the owner's Cloudflare API token in the project Deploy panel, with Pages and D1 permissions. Do not paste it into frontend code, git, or chat.
2. Authenticate through that panel's token setup; no interactive `wrangler login` is used in this sandbox.
3. The Pages project is `shopease-ai-7f8e17c2`, production branch `main`; D1 settings are in `wrangler.jsonc`.

```bash
npx wrangler whoami
npm ci
npm run typecheck
npm run db:remote
npm run build
npx wrangler pages deploy dist --project-name shopease-ai-7f8e17c2 --branch main
curl https://shopease-ai-7f8e17c2.pages.dev/api/health
```

For a different Cloudflare account, create a new D1 database and Pages project, update the database ID and project name, apply migrations, then deploy. Never point another account at this database ID.

Promote a newly registered, trusted owner manually using your Cloudflare account (replace the example email):

```bash
npx wrangler d1 execute shopease-ai-db --remote --command="UPDATE users SET role='admin' WHERE email='your-registered-email@example.com';"
```

The frontend never receives your Cloudflare token or database credentials. D1 is a server binding, not a browser connection string.

## Backend API

All responses are JSON. Mutation requests require `Content-Type: application/json`. Browser requests must be same-origin. Authentication uses the `shop_session` HttpOnly cookie, not localStorage. Errors use `{ "error": "message" }`.

| Method     | Path                 | Purpose / access                                    |
| ---------- | -------------------- | --------------------------------------------------- |
| GET        | `/api/health`        | D1 connectivity and demo-payment status             |
| POST       | `/api/auth/register` | email, password, first_name, last_name              |
| POST       | `/api/auth/login`    | email, password                                     |
| POST       | `/api/auth/logout`   | invalidate current session                          |
| GET        | `/api/auth/me`       | safe current user or null                           |
| PATCH      | `/api/auth/profile`  | own first_name, last_name, optional phone           |
| PUT        | `/api/auth/password` | current_password, new_password; revoke old sessions |
| GET        | `/api/categories`    | active nested categories                            |
| GET        | `/api/products`      | q, category, min, max, page, limit, sort            |
| GET        | `/api/products/:id`  | product, attributes, verified public reviews        |
| POST       | `/api/interactions`  | signed-in product_id and kind: view/cart/wishlist   |
| GET        | `/api/cart`          | own items, quantities, total                        |
| PUT        | `/api/cart/:id`      | own quantity, 0 to remove, maximum 20               |
| GET        | `/api/wishlist`      | own saved products                                  |
| PUT/DELETE | `/api/wishlist/:id`  | save/remove                                         |
| POST       | `/api/checkout`      | own cart → atomic demo order                        |
| GET        | `/api/orders`        | own latest 100 orders                               |
| GET        | `/api/orders/:id`    | own order, items, address, payment summary          |
| GET/POST   | `/api/reviews`       | own reviews / submit verified review                |

Catalog sort values: `featured`, `price-asc`, `price-desc`, `rating`, `newest`. Catalog page size defaults to 12, capped at 50. Root category filters include descendants. Draft/inactive/deleted products are excluded from public discovery.

Checkout request:

```json
{
  "full_name": "Demo Buyer",
  "phone": "0000000000",
  "address_line1": "123 Example Street",
  "city": "Demo City",
  "state": "Demo State",
  "postal_code": "000000",
  "country": "India",
  "demo_payment": true,
  "checkout_key": "a-client-generated-uuid-v4"
}
```

Do not send totals or prices: the server reads them from D1. A replay with the same authenticated user and checkout key returns the existing order. Demo orders are confirmed, recorded as completed wallet payments with `DEMO-` transaction IDs, and have zero additional tax/shipping. This is an explicit demonstration rule, not a claim about real Indian tax requirements.

Admin routes require an active admin session:

- `GET /api/admin/overview`
- `POST /api/admin/products`, `PATCH /api/admin/products/:id` (archive instead of destructive delete)
- `POST /api/admin/categories`, `PATCH /api/admin/categories/:id`
- `PATCH /api/admin/orders/:id` — confirmed → processing → shipped → delivered
- `PATCH /api/admin/customers/:id` — is_active; revokes sessions
- `PATCH /api/admin/reviews/:id` — is_approved; cannot approve invalid purchase evidence
- `GET /api/admin/model-data` — product, attribute, purchase and review export without account credentials/contact fields
- `PUT /api/admin/sentiment` — review_id, score, model_version

## Recommendation API and Python integration

HTTP endpoints:

- `GET /api/recommendations/user/:userId` — authenticated self only
- `GET /api/recommendations/for-you` — personalized when signed in, popular for guests
- `GET /api/recommendations/product/:productId` — `{similar, together}`
- `GET /api/recommendations/popular`
- `GET /api/recommendations/recent` — signed-in recent views
- `GET/PUT /api/recommendations/preferences` — own enabled flag

The service `src/services/recommendationService.ts` exposes:

```text
getPersonalizedRecommendations(userId)
getSimilarProducts(productId)
getPopularProducts()
getFrequentlyBoughtTogether(productId)
```

### Initial database hybrid

- Collaborative signal: overlap with other customers' eligible paid purchase histories.
- Content signal: category/root-category similarity, matching brands, price proximity, and matching product attributes. Purchases and bounded interaction weights form the preference profile.
- Quality signal: Bayesian-smoothed approved/verified review ratings. Imported NLP sentiment augments quality only when available.
- Personalized ranking: 35% collaborative, 40% content, 15% popularity, 10% quality when a profile exists.
- Popular ranking: 70% normalized purchased quantity, 30% quality.
- Similar ranking: 85% content similarity, 15% quality.
- Frequently bought together: actual shared eligible paid orders; no fabricated pairings when data is sparse.
- Exclusions: unavailable/inactive products, current product, and already purchased products for personalized mode. Results include a source, strategy, score, and reason.

This is a deterministic, transparent **fallback recommender**, not a trained deep-learning model. The small original history limits confidence. Purchase scanning is capped at 10,000 grouped records; a large store should replace this with indexed aggregates or the external trained model.

### Connect your Python model

The running architecture is:

```text
React → Hono API → RecommendationService → [optional HTTPS Python endpoint]
                                  └────→ D1 fallback
```

1. Host your Python API separately; Cloudflare Workers cannot execute a Python model. The current website works without this service or any paid AI API.
2. The backend sends `POST` to the exact `ML_API_URL` (for example, `https://your-model.example/recommendations`) with:

```json
{
  "mode": "personalized",
  "user_id": 12,
  "limit": 8,
  "candidate_ids": [1, 2, 5, 8],
  "interactions": [{ "product_id": 8, "kind": "view", "weight": 2 }],
  "purchased_product_ids": [13]
}
```

`product_id` is included for similar/together calls. Return ranked IDs:

```json
{ "product_ids": [8, 5, 2] }
```

3. Set secrets server-side, never in React or `VITE_*` variables:

```bash
npx wrangler pages secret put ML_API_URL --project-name shopease-ai-7f8e17c2
npx wrangler pages secret put ML_API_TOKEN --project-name shopease-ai-7f8e17c2
npm run build
npx wrangler pages deploy dist --project-name shopease-ai-7f8e17c2 --branch main
```

Wrangler reads secret values from stdin. Use the matching names in `.dev.vars` for local integration testing. The server adds `Authorization: Bearer <ML_API_TOKEN>` if configured.

4. Use the admin model-data export to train or refresh your model. Original review bodies are available for BERT/NLP. Export is administrator-only; do not make it public. Review text is user-authored and may contain personal information: apply your own privacy/redaction policy before using an external training system.
5. Import sentiment via `PUT /api/admin/sentiment`, e.g. `{ "review_id": 1, "score": 0.87, "model_version": "bert-sentiment-v1" }`. Never replace a real trained score with an invented one.

The adapter requires HTTPS, blocks redirects, times out after 1.5 seconds, validates a maximum of 50 positive integer IDs, removes duplicates, filters against eligible candidates, and returns up to 8 results. A failure or empty valid result uses the local fallback. Account names, email addresses, passwords, and shipping addresses are not sent by this adapter. No frontend changes are required to switch models.

## Security and operational notes

- Passwords: Web Crypto PBKDF2-SHA256, per-user random salt, 100,000 iterations (the Workers Web Crypto iteration ceiling), timing-resistant comparison. For a real retail launch, reassess hashing against current guidance and consider an Argon2id-capable authentication provider.
- Sessions: random 256-bit opaque tokens; only token hashes in D1; seven-day expiry; HttpOnly, SameSite=Lax, Secure on HTTPS. Login/password change rotates sessions; logout invalidates server-side state.
- Authentication attempts are rate-limited per hashed IP in D1 (30 per 15 minutes). Additional abuse controls/CAPTCHA and per-account limits are recommended before a high-traffic launch.
- Parameterized SQL, Zod validation, bounded request bodies, origin/Fetch-Metadata checks, explicit admin guards, and owner predicates protect APIs.
- Checkout database guards prevent overselling. D1 batch failure rolls back addresses, orders, payment rows, and inventory changes together.
- Security headers include CSP, nosniff, frame denial, referrer policy and HTTPS HSTS. React escapes user-rendered text.
- No API keys, passwords, production session cookies, or private admin handoff files are committed. `.env.example` contains only names/documentation. Database IDs and project names are identifiers, not credentials.
- Current schema retains original soft-delete/status conventions. Admin archive does not delete historical orders.

## Tests and verification

```bash
npx playwright install --with-deps chromium
npm run typecheck
npm run build
npm test
TEST_BASE_URL=https://shopease-ai-7f8e17c2.pages.dev npm test
```

Local results: customer/public/security suites passed; admin suite passed separately. Live results: all three customer/public/security suites passed. Admin mutation fixtures intentionally skip on remote targets so the tests cannot create test products or alter your original production catalog.

Test coverage includes:

- Registration → explicit logout/login → products → search → detail → wishlist → cart quantities → demo checkout → order → verified review → recommendations.
- Database sample catalog, nested category filters, price sorting, no-result state, draft exclusion, image responses, and mobile viewport overflow checks.
- Cross-origin rejection, unauthorized APIs, admin separation, order ownership, invalid reviews, and invalid quantities.
- Idempotency replay, one-time inventory decrement, payment records, personalization opt-out, persistent session/wishlist, duplicate review rejection.
- Local admin UI, product management, inventory editing, dataset export, invalid-review moderation rejection, and order progression.
- Two buyers racing for one unit: exactly one success and one stock-conflict response; losing transaction keeps its cart and creates no order.
- Password change revokes a separately logged-in session.

Tests use clearly named test accounts and demo orders. They do not alter original seed rows except the expected stock changes from demo checkout. Avoid repeated live runs on a production retail catalog; use an isolated test deployment instead.

## Deliberate limitations / recommended next steps

- **Demo payments and fulfillment only.** No payment gateway, refunds/cancellations, real deliveries, carrier integration, or tax engine.
- Email verification, forgotten-password email delivery, MFA, account deletion workflows, and production-grade abuse defenses are not implemented. Authenticated password change is implemented.
- Coupon rows are preserved, but checkout coupon redemption is not implemented; expired historical coupons are not advertised as live offers.
- Admin product editing covers core fields and inventory; there is no media-upload workflow, variant editor, or hierarchical category reparenting UI.
- Recent views are stored only for signed-in users with personalization enabled. No anonymous tracking is performed.
- Recommendation training, evaluation metrics, vector indexes, and a running BERT model are future integrations, not part of the fallback.
- Prior to real commercial use: secure rights to data/images, replace illustration placeholders with authorized photography, complete a security/accessibility/load audit, implement production payments and email recovery, add monitoring/backup policy, and test free-tier usage limits.

The delivered app is a working capstone demonstration with production-style structure and transactional behavior—not a claim that it has completed a real-retail compliance audit.
