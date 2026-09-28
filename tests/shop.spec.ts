import { test, expect, request as requestFactory } from "@playwright/test";
import { randomUUID } from "node:crypto";
const password = "Capstone-Test-" + randomUUID();
const address = {
  full_name: "Demo Test",
  phone: "0000000000",
  address_line1: "123 Example Street",
  city: "Demo City",
  state: "Demo State",
  postal_code: "000000",
  country: "India",
  demo_payment: true,
};
async function signup(request: any, prefix = "api") {
  const email = `${prefix}.${Date.now()}.${randomUUID().slice(0, 6)}@example.test`;
  const result = await request.post("/api/auth/register", {
    data: { email, password, first_name: "Demo", last_name: "Test" },
  });
  expect(result.status(), await result.text()).toBe(201);
  const { user } = await (await request.get("/api/auth/me")).json();
  return { email, user };
}
test("public storefront, original data, search, categories, images, mobile layout", async ({
  page,
  request,
}) => {
  const errors: string[] = [];
  page.on("pageerror", (e) => errors.push(e.message));
  const catalog = await (await request.get("/api/products?limit=50")).json();
  expect(catalog.total).toBeGreaterThanOrEqual(18);
  expect(catalog.products.some((p: any) => p.product_id === 19)).toBe(false);
  const one = await (await request.get("/api/products?q=Atomic")).json();
  expect(one.products[0].name).toBe("Atomic Habits");
  const books = await (await request.get("/api/products?category=3")).json();
  expect(books.total).toBe(3);
  const price = await (
    await request.get("/api/products?max=1000&sort=price-asc")
  ).json();
  expect(price.products.length).toBe(3);
  expect(price.products[0].price).toBeLessThanOrEqual(price.products[1].price);
  expect((await request.get("/api/products/19")).status()).toBe(404);
  const rec = await (
    await request.get("/api/recommendations/product/8")
  ).json();
  expect(rec.together.products.some((p: any) => p.product_id === 7)).toBe(true);
  for (const p of catalog.products) {
    const image = await request.get(p.image_url);
    expect(image.ok()).toBeTruthy();
    expect(image.headers()["content-type"]).toMatch(/image/);
  }
  await page.goto("/");
  await expect(page.locator(".product-card").first()).toBeVisible();
  await expect(
    page.getByRole("heading", { name: /Find your everyday/ }),
  ).toBeVisible();
  await page.screenshot({ path: "tests/home-desktop.png", fullPage: true });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.screenshot({ path: "tests/home-mobile.png", fullPage: true });
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= innerWidth,
    ),
  ).toBe(true);
  await page.goto("/products?q=zzznomatch");
  await expect(
    page.getByRole("heading", { name: "No finds this time" }),
  ).toBeVisible();
  expect(errors).toEqual([]);
});
test("registration → login → search → details → wishlist/cart → checkout → order → verified review → recommendations", async ({
  page,
}) => {
  const email = `browser.${Date.now()}@example.test`;
  const reviewTitle = `Thoughtful everyday reading ${Date.now()}`;
  const errors: string[] = [];
  page.on("pageerror", (e) => errors.push(e.message));
  await page.goto("/register");
  await page.getByLabel("First name").fill("Demo");
  await page.getByLabel("Last name").fill("Buyer");
  await page.getByLabel("Email address").fill(email);
  await page.getByLabel("Password", { exact: true }).fill(password);
  await page.getByRole("button", { name: "Create account" }).click();
  await expect(
    page.getByRole("heading", { name: "Hello, Demo." }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Sign out", exact: true }).click();
  await page.goto("/login");
  await page.getByLabel("Email address").fill(email);
  await page.getByLabel("Password", { exact: true }).fill(password);
  await page.getByRole("button", { name: "Sign in", exact: true }).click();
  await expect(
    page.getByRole("heading", { name: "Hello, Demo." }),
  ).toBeVisible();
  await page.goto("/products");
  await page.getByRole("textbox", { name: "Search collection" }).fill("Atomic");
  await page.getByRole("button", { name: "Submit search" }).click();
  await page
    .locator(".product-name")
    .filter({ hasText: "Atomic Habits" })
    .click();
  await expect(
    page.getByRole("heading", { name: "Atomic Habits", exact: true }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Save product to wishlist" }).click();
  await expect(page.getByRole("status")).toContainText(
    "Saved to your wishlist",
  );
  await page.getByRole("button", { name: "Add to bag", exact: true }).click();
  await expect(page.getByRole("status")).toContainText("Added to your bag");
  await page.goto("/cart");
  await expect(page.locator(".cart-item")).toHaveCount(1);
  await page.getByRole("button", { name: "Increase Atomic Habits" }).click();
  await expect(page.locator(".quantity-control span")).toHaveText("2");
  await page.getByRole("button", { name: "Decrease Atomic Habits" }).click();
  await expect(page.locator(".quantity-control span")).toHaveText("1");
  await page.getByRole("link", { name: "Continue to checkout" }).click();
  await page.getByLabel("Phone number").fill("0000000000");
  await page.getByLabel("Street address").fill("123 Example Street");
  await page.getByLabel("City", { exact: true }).fill("Demo City");
  await page.getByLabel("State", { exact: true }).fill("Demo State");
  await page.getByLabel("Postal code").fill("000000");
  await page.getByRole("checkbox").check();
  await page.getByRole("button", { name: "Place demo order" }).click();
  await expect(
    page.getByRole("heading", { name: "A good find, officially yours." }),
  ).toBeVisible();
  await expect(page.locator(".order-card")).toContainText("Atomic Habits");
  await page.getByRole("button", { name: "Write a review" }).click();
  await page.getByLabel("Review title").fill(reviewTitle);
  await page
    .getByLabel("Your experience")
    .fill(
      "Demo purchase review: a clear and helpful read with practical advice.",
    );
  await page.getByRole("button", { name: "Publish review" }).click();
  await expect(page.getByRole("status")).toContainText(
    "Your verified review is published",
  );
  await page.goto("/products/13");
  await page.getByRole("button", { name: /Reviews \(/ }).click();
  await expect(
    page.getByRole("heading", { name: reviewTitle }),
  ).toBeVisible();
  await page.goto("/for-you");
  await expect(
    page.getByRole("heading", { name: "Personalized for you" }),
  ).toBeVisible();
  await expect(page.locator(".product-card").first()).toBeVisible();
  await page.goto("/account/wishlist");
  await expect(page.locator(".product-card")).toHaveCount(1);
  await page.reload();
  await expect(page.locator(".product-card")).toHaveCount(1);
  expect(errors).toEqual([]);
});
test("API security, idempotency, purchase ownership, recommendations and preferences", async ({
  request,
  baseURL,
}) => {
  expect((await request.get("/api/cart")).status()).toBe(401);
  expect(
    (
      await request.post("/api/auth/register", {
        headers: { Origin: "https://evil.example" },
        data: {},
      })
    ).status(),
  ).toBe(403);
  expect((await request.get("/api/products?sort=DROP_TABLE")).status()).toBe(
    400,
  );
  const { email, user } = await signup(request);
  expect(user.password_hash).toBeUndefined();
  expect((await request.get("/api/admin/overview")).status()).toBe(403);
  expect((await request.get("/api/recommendations/user/2")).status()).toBe(403);
  expect((await request.get("/api/orders/1")).status()).toBe(404);
  expect(
    (
      await request.post("/api/reviews", {
        data: {
          product_id: 1,
          order_id: 1,
          rating: 5,
          title: "Not a buyer",
          body: "I did not actually buy this product.",
        },
      })
    ).status(),
  ).toBe(403);
  expect(
    (await request.put("/api/cart/13", { data: { quantity: -1 } })).status(),
  ).toBe(400);
  expect(
    (await request.put("/api/cart/19", { data: { quantity: 1 } })).status(),
  ).toBe(404);
  expect(
    (await request.put("/api/cart/13", { data: { quantity: 1 } })).ok(),
  ).toBe(true);
  const before = await (await request.get("/api/products/13")).json();
  const key = randomUUID();
  const first = await request.post("/api/checkout", {
    data: { ...address, checkout_key: key },
  });
  expect(first.status(), await first.text()).toBe(201);
  const order = (await first.json()).order;
  const again = await request.post("/api/checkout", {
    data: { ...address, checkout_key: key },
  });
  expect((await again.json()).order.order_id).toBe(order.order_id);
  const after = await (await request.get("/api/products/13")).json();
  expect(after.product.available).toBe(before.product.available - 1);
  const detail = await (
    await request.get("/api/orders/" + order.order_id)
  ).json();
  expect(detail.order.total_amount).toBe(599);
  expect(detail.payments[0].payment_status).toBe("completed");
  expect(detail.payments[0].transaction_id).toMatch(/^DEMO-/);
  const review = {
    product_id: 13,
    order_id: order.order_id,
    rating: 4,
    title: "Verified API review",
    body: "A complete test of the verified purchase flow.",
  };
  expect((await request.post("/api/reviews", { data: review })).status()).toBe(
    201,
  );
  expect((await request.post("/api/reviews", { data: review })).status()).toBe(
    409,
  );
  const recommendations = await (
    await request.get("/api/recommendations/user/" + user.user_id)
  ).json();
  expect(recommendations.source).toBe("database-hybrid");
  expect(recommendations.products.some((p: any) => p.product_id === 13)).toBe(
    false,
  );
  await request.post("/api/interactions", {
    data: { product_id: 14, kind: "view" },
  });
  expect(
    (await (await request.get("/api/recommendations/recent")).json()).products
      .length,
  ).toBeGreaterThan(0);
  await request.put("/api/recommendations/preferences", {
    data: { enabled: false },
  });
  await request.post("/api/interactions", {
    data: { product_id: 1, kind: "view" },
  });
  expect(
    (await (await request.get("/api/recommendations/recent")).json()).products
      .length,
  ).toBe(0);
  expect(
    (await (await request.get("/api/recommendations/for-you")).json()).strategy,
  ).toBe("popular");
  const stranger = await requestFactory.newContext({ baseURL });
  await signup(stranger, "stranger");
  expect((await stranger.get("/api/orders/" + order.order_id)).status()).toBe(
    404,
  );
  await stranger.dispose();
  await request.post("/api/auth/logout", { data: {} });
  expect((await request.get("/api/orders")).status()).toBe(401);
  expect(
    (
      await request.post("/api/auth/login", {
        data: { email, password: "wrongpasswordtest" },
      })
    ).status(),
  ).toBe(401);
  expect(
    (
      await request.post("/api/auth/login", { data: { email, password } })
    ).status(),
  ).toBe(200);
});
