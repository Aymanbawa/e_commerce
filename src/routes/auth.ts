import { Hono } from "hono";
import { deleteCookie } from "hono/cookie";
import { HTTPException } from "hono/http-exception";
import { z } from "zod";
import type { AppEnv } from "../types";
import {
  hashPassword,
  verifyPassword,
  newSession,
  requireUser,
  authRateLimit,
} from "../security";
export const auth = new Hono<AppEnv>();
const credentials = z.object({
  email: z.string().trim().toLowerCase().email().max(255),
  password: z.string().min(10, "Use at least 10 characters.").max(128),
});
auth.post("/register", authRateLimit, async (c) => {
  const data = credentials
    .extend({
      first_name: z.string().trim().min(1).max(100),
      last_name: z.string().trim().min(1).max(100),
    })
    .parse(await c.req.json());
  const hash = await hashPassword(data.password);
  try {
    const r = await c.env.DB.prepare(
      "INSERT INTO users(email,password_hash,first_name,last_name) VALUES(?,?,?,?)",
    )
      .bind(data.email, hash, data.first_name, data.last_name)
      .run();
    await newSession(c, Number(r.meta.last_row_id));
    return c.json({ success: true }, 201);
  } catch (e) {
    if (String(e).includes("UNIQUE"))
      throw new HTTPException(409, {
        message: "This email is already registered. Please sign in.",
      });
    throw e;
  }
});
auth.post("/login", authRateLimit, async (c) => {
  const data = credentials.parse(await c.req.json());
  const u = await c.env.DB.prepare(
    "SELECT user_id,password_hash,is_active,deleted_at FROM users WHERE email=?",
  )
    .bind(data.email)
    .first<any>();
  const valid = await verifyPassword(
    data.password,
    u?.password_hash || "disabled",
  );
  if (!valid || !u?.is_active || u.deleted_at)
    throw new HTTPException(401, {
      message: "Email or password is incorrect.",
    });
  if (c.get("tokenHash"))
    await c.env.DB.prepare("DELETE FROM sessions WHERE token_hash=?")
      .bind(c.get("tokenHash"))
      .run();
  await newSession(c, u.user_id);
  return c.json({ success: true });
});
auth.post("/logout", async (c) => {
  if (c.get("tokenHash"))
    await c.env.DB.prepare("DELETE FROM sessions WHERE token_hash=?")
      .bind(c.get("tokenHash"))
      .run();
  deleteCookie(c, "shop_session", { path: "/" });
  return c.json({ success: true });
});
auth.get("/me", async (c) => c.json({ user: c.get("user") }));
auth.put("/password", requireUser, authRateLimit, async (c) => {
  const d = z
    .object({
      current_password: z.string().min(1).max(128),
      new_password: z.string().min(10).max(128),
    })
    .parse(await c.req.json());
  const uid = c.get("user")!.user_id;
  const row = await c.env.DB.prepare(
    "SELECT password_hash FROM users WHERE user_id=?",
  )
    .bind(uid)
    .first<{ password_hash: string }>();
  if (!row || !(await verifyPassword(d.current_password, row.password_hash)))
    throw new HTTPException(401, {
      message: "Your current password is incorrect.",
    });
  await c.env.DB.batch([
    c.env.DB.prepare("UPDATE users SET password_hash=? WHERE user_id=?").bind(
      await hashPassword(d.new_password),
      uid,
    ),
    c.env.DB.prepare("DELETE FROM sessions WHERE user_id=?").bind(uid),
  ]);
  await newSession(c, uid);
  return c.json({ success: true });
});
auth.patch("/profile", requireUser, async (c) => {
  const d = z
    .object({
      first_name: z.string().trim().min(1).max(100),
      last_name: z.string().trim().min(1).max(100),
      phone: z.string().max(20).optional(),
    })
    .parse(await c.req.json());
  await c.env.DB.prepare(
    "UPDATE users SET first_name=?,last_name=?,phone=? WHERE user_id=?",
  )
    .bind(d.first_name, d.last_name, d.phone || null, c.get("user")!.user_id)
    .run();
  return c.json({ success: true });
});
