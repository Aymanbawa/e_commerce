import {
  createContext,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from "react";
import { useNavigate } from "react-router-dom";
import { api, mutate } from "./api";
import type { User, Product } from "../types";
type CartItem = Product & { quantity: number };
type Store = {
  user: User | null;
  ready: boolean;
  cart: CartItem[];
  wishlist: Product[];
  refresh: () => Promise<void>;
  addCart: (p: Product) => Promise<void>;
  setQuantity: (id: number, q: number) => Promise<void>;
  toggleWish: (p: Product) => Promise<void>;
  toast: (s: string) => void;
  logout: () => Promise<void>;
};
const Context = createContext<Store>(null!);
export function StoreProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null),
    [ready, setReady] = useState(false),
    [cart, setCart] = useState<CartItem[]>([]),
    [wishlist, setWishlist] = useState<Product[]>([]),
    [message, setMessage] = useState("");
  const nav = useNavigate();
  async function refresh() {
    const d = await api("/auth/me");
    setUser(d.user);
    if (d.user) {
      const [c, w] = await Promise.all([api("/cart"), api("/wishlist")]);
      setCart(c.items);
      setWishlist(w.products);
    } else {
      setCart([]);
      setWishlist([]);
    }
    setReady(true);
  }
  useEffect(() => {
    refresh().catch(() => {
      setReady(true);
      setMessage("Could not connect. Please refresh the page.");
    });
  }, []);
  useEffect(() => {
    if (message) {
      const id = setTimeout(() => setMessage(""), 4000);
      return () => clearTimeout(id);
    }
  }, [message]);
  function signedIn() {
    if (user) return true;
    nav(
      "/login?next=" + encodeURIComponent(location.pathname + location.search),
    );
    setMessage("Sign in to keep your bag and wishlist synced.");
    return false;
  }
  async function setQuantity(id: number, q: number) {
    try {
      await mutate("/cart/" + id, "PUT", { quantity: q });
      const d = await api("/cart");
      setCart(d.items);
    } catch (e: any) {
      setMessage(e.message);
      throw e;
    }
  }
  async function addCart(p: Product) {
    if (!signedIn()) return;
    try {
      await setQuantity(
        p.product_id,
        (cart.find((c) => c.product_id === p.product_id)?.quantity || 0) + 1,
      );
      setMessage("Added to your bag");
      mutate("/interactions", "POST", {
        product_id: p.product_id,
        kind: "cart",
      }).catch(() => {});
    } catch {}
  }
  async function toggleWish(p: Product) {
    if (!signedIn()) return;
    const exists = wishlist.some((w) => w.product_id === p.product_id);
    try {
      await mutate("/wishlist/" + p.product_id, exists ? "DELETE" : "PUT");
      setWishlist(
        exists
          ? wishlist.filter((w) => w.product_id !== p.product_id)
          : [...wishlist, p],
      );
      setMessage(
        exists ? "Removed from your wishlist" : "Saved to your wishlist",
      );
      if (!exists)
        mutate("/interactions", "POST", {
          product_id: p.product_id,
          kind: "wishlist",
        }).catch(() => {});
    } catch (e: any) {
      setMessage(e.message);
    }
  }
  async function logout() {
    await mutate("/auth/logout", "POST");
    await refresh();
    nav("/");
    setMessage("You’re signed out.");
  }
  return (
    <Context.Provider
      value={{
        user,
        ready,
        cart,
        wishlist,
        refresh,
        addCart,
        setQuantity,
        toggleWish,
        toast: setMessage,
        logout,
      }}
    >
      {children}
      {message && (
        <aside className="toast" role="status">
          <span className="toast-dot" />
          {message}
          <button
            aria-label="Dismiss notification"
            onClick={() => setMessage("")}
          >
            ×
          </button>
        </aside>
      )}
    </Context.Provider>
  );
}
export const useStore = () => useContext(Context);
