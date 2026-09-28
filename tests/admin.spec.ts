import { test, expect, request as factory } from "@playwright/test";
import { execFileSync } from "node:child_process";
import { randomUUID } from "node:crypto";
const password = "Admin-Test-" + randomUUID();
function sql(command: string) {
  return execFileSync(
    "npx",
    [
      "wrangler",
      "d1",
      "execute",
      "shopease-ai-db",
      "--local",
      "--command",
      command,
    ],
    { cwd: process.cwd(), stdio: "pipe" },
  );
}
test("admin workflow, transaction rollback, concurrent stock protection and password rotation", async ({
  request,
  page,
  baseURL,
}) => {
  test.skip(
    !!process.env.TEST_BASE_URL,
    "Administrative mutation fixtures run on local D1 only.",
  );
  const email = `admin.${Date.now()}@example.test`;
  let r = await request.post("/api/auth/register", {
    data: { email, password, first_name: "Test", last_name: "Administrator" },
  });
  expect(r.status(), await r.text()).toBe(201);
  const { user } = await (await request.get("/api/auth/me")).json();
  sql(`UPDATE users SET role='admin' WHERE user_id=${user.user_id};`);
  expect((await request.get("/api/admin/overview")).ok()).toBe(true);
  // UI admin actions operate on an isolated test product, never source records.
  await page.goto("/login?next=/admin");
  await page.getByLabel("Email address").fill(email);
  await page.getByLabel("Password", { exact: true }).fill(password);
  await page.getByRole("button", { name: "Sign in", exact: true }).click();
  await expect(
    page.getByRole("heading", { name: "A clearer view of your store." }),
  ).toBeVisible();
  await page.getByRole("button", { name: "Add product" }).click();
  const name = "Isolated Test Item " + Date.now();
  await page.getByLabel("Name", { exact: true }).fill(name);
  await page.getByLabel("Price (INR)").fill("100");
  await page
    .getByLabel("Description")
    .fill(
      "An isolated automated test record, not part of the original dataset.",
    );
  await page.getByLabel("Initial stock").fill("1");
  await page.getByRole("button", { name: "Save changes" }).click();
  await expect(page.getByRole("status")).toContainText("Saved successfully");
  const overview = await (await request.get("/api/admin/overview")).json();
  const p = overview.products.find((x: any) => x.name === name);
  expect(p.available).toBe(1);
  await page.getByRole("button", { name: "Edit " + name, exact: true }).click();
  await expect(
    page.getByLabel("Physical stock (must include reserved units)"),
  ).toHaveValue("1");
  await page.getByRole("button", { name: "Save changes" }).click();
  await expect(page.getByRole("status")).toContainText("Saved successfully");
  for (const tab of [
    "categories",
    "orders",
    "customers",
    "inventory",
    "reviews",
  ]) {
    await page.getByRole("button", { name: tab, exact: true }).click();
    await expect(page.locator("table")).toBeVisible();
  }
  await page.screenshot({ path: "tests/admin-desktop.png", fullPage: true });
  await page.setViewportSize({ width: 390, height: 844 });
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= innerWidth,
    ),
  ).toBe(true);
  // Only one of two buyers can purchase the last unit; losing transaction rolls back.
  const a = await factory.newContext({ baseURL }),
    b = await factory.newContext({ baseURL });
  const clients = [a, b];
  for (let i = 0; i < 2; i++) {
    r = await clients[i].post("/api/auth/register", {
      data: {
        email: `race${i}.${Date.now()}@example.test`,
        password,
        first_name: "Race",
        last_name: "Test",
      },
    });
    expect(r.status()).toBe(201);
    expect(
      (
        await clients[i].put("/api/cart/" + p.product_id, {
          data: { quantity: 1 },
        })
      ).status(),
    ).toBe(200);
  }
  const address = {
    full_name: "Test Buyer",
    phone: "0000000000",
    address_line1: "123 Test Street",
    city: "Test City",
    state: "Test State",
    postal_code: "000000",
    country: "India",
    demo_payment: true,
  };
  const results = await Promise.all(
    clients.map((c) =>
      c.post("/api/checkout", {
        data: { ...address, checkout_key: randomUUID() },
      }),
    ),
  );
  expect(results.map((r) => r.status()).sort()).toEqual([201, 409]);
  expect(
    (await (await request.get("/api/products/" + p.product_id)).json()).product
      .available,
  ).toBe(0);
  const winner = results.findIndex((r) => r.status() === 201);
  const order = (await results[winner].json()).order;
  expect(
    (await (await clients[1 - winner].get("/api/orders")).json()).orders,
  ).toHaveLength(0);
  expect(
    (await (await clients[1 - winner].get("/api/cart")).json()).items,
  ).toHaveLength(1);
  for (const status of ["processing", "shipped", "delivered"])
    expect(
      (
        await request.patch("/api/admin/orders/" + order.order_id, {
          data: { status },
        })
      ).status(),
    ).toBe(200);
  expect(
    (
      await request.patch("/api/admin/orders/" + order.order_id, {
        data: { status: "confirmed" },
      })
    ).status(),
  ).toBe(409);
  expect(
    (
      await request.patch("/api/admin/reviews/5", {
        data: { is_approved: true },
      })
    ).status(),
  ).toBe(400);
  const model = await (await request.get("/api/admin/model-data")).json();
  expect(model.products.length).toBeGreaterThan(18);
  expect(JSON.stringify(model)).not.toContain("password_hash");
  const second = await factory.newContext({ baseURL });
  await second.post("/api/auth/login", { data: { email, password } });
  expect(
    (
      await request.put("/api/auth/password", {
        data: {
          current_password: password,
          new_password: password + "-changed",
        },
      })
    ).status(),
  ).toBe(200);
  expect((await second.get("/api/orders")).status()).toBe(401);
  expect((await request.get("/api/admin/overview")).status()).toBe(200);
  for (const client of [a, b, second]) await client.dispose();
  // Archive fixture so subsequent original-catalog tests see the same 18 products.
  await request.patch("/api/admin/products/" + p.product_id, {
    data: { name, price: 100, status: "archived", quantity_in_stock: 0 },
  });
});
