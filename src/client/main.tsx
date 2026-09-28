import React from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { StoreProvider } from "./store";
import { Layout } from "./components/Layout";
import { Empty } from "./components/UI";
import { Home, ForYou } from "./pages/Home";
import { Catalog, ProductDetails } from "./pages/Catalog";
import { Auth } from "./pages/Auth";
import { Cart, Checkout } from "./pages/Checkout";
import {
  AccountLayout,
  Profile,
  Wishlist,
  Orders,
  OrderDetail,
  MyReviews,
  Preferences,
} from "./pages/Account";
import { Admin } from "./pages/Admin";
import { About } from "./pages/About";
import "./styles.css";
class ErrorBoundary extends React.Component<
  { children: React.ReactNode },
  { failed: boolean }
> {
  state = { failed: false };
  static getDerivedStateFromError() {
    return { failed: true };
  }
  render() {
    return this.state.failed ? (
      <div className="empty-state">
        <h1>Let’s try that again.</h1>
        <p>The page could not load. Please refresh to continue.</p>
        <button className="button primary" onClick={() => location.reload()}>
          Refresh
        </button>
      </div>
    ) : (
      this.props.children
    );
  }
}
createRoot(document.getElementById("root")!).render(
  <ErrorBoundary>
    <BrowserRouter>
      <StoreProvider>
        <Routes>
          <Route element={<Layout />}>
            <Route index element={<Home />} />
            <Route path="products" element={<Catalog />} />
            <Route path="products/:id" element={<ProductDetails />} />
            <Route path="for-you" element={<ForYou />} />
            <Route path="login" element={<Auth key="login" />} />
            <Route path="register" element={<Auth key="register" register />} />
            <Route path="cart" element={<Cart />} />
            <Route path="checkout" element={<Checkout />} />
            <Route path="account" element={<AccountLayout />}>
              <Route index element={<Profile />} />
              <Route path="wishlist" element={<Wishlist />} />
              <Route path="orders" element={<Orders />} />
              <Route path="orders/:id" element={<OrderDetail />} />
              <Route path="reviews" element={<MyReviews />} />
              <Route path="preferences" element={<Preferences />} />
            </Route>
            <Route path="admin" element={<Admin />} />
            <Route path="about" element={<About />} />
            <Route
              path="*"
              element={
                <Empty
                  title="A little off the beaten path"
                  description="We couldn’t find that page. Let’s find something you’ll love instead."
                />
              }
            />
          </Route>
        </Routes>
      </StoreProvider>
    </BrowserRouter>
  </ErrorBoundary>,
);
