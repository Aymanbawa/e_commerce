import { getCookie, setCookie } from "hono/cookie";
import { createMiddleware } from "hono/factory";
import { HTTPException } from "hono/http-exception";
import type { AppEnv, User } from "./types";
const encoder = new TextEncoder();
export const hex = (b: ArrayBuffer | Uint8Array) =>
  Array.from(new Uint8Array(b instanceof Uint8Array ? b.buffer : b))
    .map((v) => v.toString(16).padStart(2, "0"))
    .join("");
export async function digest(s: string) {
  return hex(await crypto.subtle.digest("SHA-256", encoder.encode(s)));
}
export async function hashPassword(
  password: string,
  salt = hex(crypto.getRandomValues(new Uint8Array(16))),
) {
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(password),
    "PBKDF2",
    false,
    ["deriveBits"],
  );
  const bits = await crypto.subtle.deriveBits(
    {
      name: "PBKDF2",
      hash: "SHA-256",
      salt: encoder.encode(salt),
      iterations: 100000,
    },
    key,
    256,
  );
  return `pbkdf2$100000$${salt}$${hex(bits)}`;
}
export async function verifyPassword(password: string, stored: string) {
  if (!stored.startsWith("pbkdf2$100000$")) {
    await hashPassword(password, "00000000000000000000000000000000");
    return false;
  }
  const candidate = await hashPassword(password, stored.split("$")[2]);
  let diff = candidate.length ^ stored.length;
  for (let i = 0; i < candidate.length; i++)
    diff |= candidate.charCodeAt(i) ^ (stored.charCodeAt(i) || 0);
  return diff === 0;
}
export const sessionMiddleware = createMiddleware<AppEnv>(async (c, next) => {
  c.set("user", null);
  c.set("tokenHash", null);
  const token = getCookie(c, "shop_session");
  if (token) {
    const tokenHash = await digest(token);
    const user = await c.env.DB.prepare(
      `SELECT u.user_id,u.email,u.first_name,u.last_name,u.phone,u.role FROM sessions s JOIN users u ON u.user_id=s.user_id WHERE s.token_hash=? AND s.expires_at>? AND u.is_active=1 AND u.deleted_at IS NULL`,
    )
      .bind(tokenHash, Date.now())
      .first<User>();
    if (user) {
      c.set("user", user);
      c.set("tokenHash", tokenHash);
    }
  }
  await next();
});
export const requireUser = createMiddleware<AppEnv>(async (c, next) => {
  if (!c.get("user"))
    throw new HTTPException(401, { message: "Please sign in to continue." });
  await next();
});
export const requireAdmin = createMiddleware<AppEnv>(async (c, next) => {
  if (c.get("user")?.role !== "admin")
    throw new HTTPException(403, { message: "Administrator access required." });
  await next();
});
export async function newSession(c: any, userId: number) {
  const token = hex(crypto.getRandomValues(new Uint8Array(32)));
  await c.env.DB.batch([
    c.env.DB.prepare("DELETE FROM sessions WHERE expires_at<?").bind(
      Date.now(),
    ),
    c.env.DB.prepare(
      "INSERT INTO sessions(token_hash,user_id,expires_at) VALUES(?,?,?)",
    ).bind(await digest(token), userId, Date.now() + 7 * 86400000),
  ]);
  setCookie(c, "shop_session", token, {
    httpOnly: true,
    secure: new URL(c.req.url).protocol === "https:",
    sameSite: "Lax",
    path: "/",
    maxAge: 7 * 86400,
  });
}
export const authRateLimit = createMiddleware<AppEnv>(async (c, next) => {
  const ip = c.req.header("CF-Connecting-IP") || "local";
  const now = Date.now();
  const key = await digest("auth:" + ip);
  const r = await c.env.DB.prepare(
    `INSERT INTO rate_limits(key,count,expires_at) VALUES(?,1,?) ON CONFLICT(key) DO UPDATE SET count=CASE WHEN expires_at<? THEN 1 ELSE count+1 END,expires_at=CASE WHEN expires_at<? THEN ? ELSE expires_at END RETURNING count`,
  )
    .bind(key, now + 900000, now, now, now + 900000)
    .first<{ count: number }>();
  if (r!.count > 30)
    throw new HTTPException(429, {
      message: "Too many attempts. Please try again in 15 minutes.",
    });
  await next();
});
