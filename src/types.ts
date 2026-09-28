export type User = {
  user_id: number;
  email: string;
  first_name: string;
  last_name: string;
  role: "customer" | "admin";
  phone: string | null;
};
export type Env = {
  DB: D1Database;
  ML_API_URL?: string;
  ML_API_TOKEN?: string;
};
export type AppEnv = {
  Bindings: Env;
  Variables: { user: User | null; tokenHash: string | null };
};
export type Product = {
  product_id: number;
  name: string;
  slug: string;
  short_desc: string;
  description: string;
  price: number;
  compare_price: number | null;
  category_id: number;
  category_name: string;
  brand_id: number | null;
  brand_name: string | null;
  image_url: string;
  available: number;
  rating: number;
  review_count: number;
  is_featured: number;
  reason?: string;
  score?: number;
  is_illustrative?: number;
};
