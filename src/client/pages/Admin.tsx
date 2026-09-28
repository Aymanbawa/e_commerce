import { useState } from "react";
import { Navigate, Link } from "react-router-dom";
import {
  Plus,
  ArrowUpRight,
  Package,
  Users,
  IndianRupee,
  Activity,
  Download,
  Pencil,
} from "lucide-react";
import { useApi, mutate, money, api } from "../api";
import { useStore } from "../store";
import { Loading, ErrorState } from "../components/UI";
export function Admin() {
  const { user, ready } = useStore();
  if (!ready) return <Loading />;
  if (!user) return <Navigate to="/login?next=/admin" replace />;
  if (user.role !== "admin")
    return (
      <div className="container page">
        <ErrorState message="Administrator access is required. Your customer account cannot access this page." />
      </div>
    );
  return <AdminContent />;
}
function AdminContent() {
  const { data, error, loading, reload } = useApi("/admin/overview");
  const { toast } = useStore();
  const [tab, setTab] = useState("products"),
    [edit, setEdit] = useState<any>(null),
    [formError, setFormError] = useState(""),
    [busy, setBusy] = useState(false);
  async function action(path: string, method: string, body: any) {
    try {
      await mutate("/admin" + path, method, body);
      reload();
      toast("Changes saved.");
    } catch (e: any) {
      toast(e.message);
    }
  }
  async function exportData() {
    try {
      const d = await api("/admin/model-data");
      const url = URL.createObjectURL(
        new Blob([JSON.stringify(d, null, 2)], { type: "application/json" }),
      );
      const a = document.createElement("a");
      a.href = url;
      a.download = "shopease-model-data.json";
      a.click();
      URL.revokeObjectURL(url);
    } catch (e: any) {
      toast(e.message);
    }
  }
  if (loading && !data) return <Loading />;
  if (error)
    return (
      <div className="container page">
        <ErrorState message={error} retry={reload} />
      </div>
    );
  if (!data) return null;
  return (
    <div className="container page admin-page">
      <header className="section-heading">
        <div>
          <span className="eyebrow">SHOPEASE WORKSPACE</span>
          <h1>A clearer view of your store.</h1>
          <p>Catalog, customers and the little details that matter.</p>
        </div>
        <button className="button secondary" onClick={exportData}>
          <Download size={16} />
          Export model data
        </button>
      </header>
      <div className="stats-grid">
        {[
          [IndianRupee, "Order value", money(data.summary.revenue)],
          [Package, "Total orders", data.summary.orders],
          [Users, "Customers", data.summary.customers],
          [Activity, "Low-stock alerts", data.summary.low_stock],
        ].map(([Icon, title, value]: any) => (
          <article key={title}>
            <Icon size={21} />
            <span>{title}</span>
            <strong>{value}</strong>
            <small>Includes original sample and demo records</small>
          </article>
        ))}
      </div>
      <nav className="tabs">
        {[
          "products",
          "categories",
          "orders",
          "customers",
          "inventory",
          "reviews",
        ].map((t) => (
          <button
            className={tab === t ? "active" : ""}
            key={t}
            onClick={() => setTab(t)}
          >
            {t}
          </button>
        ))}
      </nav>
      <div className="admin-toolbar">
        <h2>{tab[0].toUpperCase() + tab.slice(1)}</h2>
        {["products", "categories"].includes(tab) && (
          <button
            className="button primary"
            onClick={() => {
              setEdit({ type: tab, new: true });
              setFormError("");
            }}
          >
            <Plus size={16} />
            Add {tab === "products" ? "product" : "category"}
          </button>
        )}
      </div>
      <div className="table-scroll">
        <table>
          <thead>
            <tr>
              {(tab === "products"
                ? ["Product", "Category", "Price", "Status", ""]
                : tab === "categories"
                  ? ["Name", "Slug", "Parent", ""]
                  : tab === "orders"
                    ? ["Order", "Customer", "Total", "Status", "Next step"]
                    : tab === "customers"
                      ? ["Customer", "Email", "Role", "Status", ""]
                      : tab === "inventory"
                        ? ["Product", "Available", "Status"]
                        : ["Product", "Rating", "Review", "Approval", ""]
              ).map((t, i) => (
                <th key={i}>{t}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {tab === "products"
              ? data.products.map((p: any) => (
                  <tr key={p.product_id}>
                    <td>
                      <Link to={"/products/" + p.product_id}>{p.name}</Link>
                    </td>
                    <td>{p.category_name}</td>
                    <td>{money(p.price)}</td>
                    <td>
                      <span className="status">{p.status}</span>
                    </td>
                    <td>
                      <button
                        className="icon-button"
                        aria-label={"Edit " + p.name}
                        onClick={() => {
                          setEdit({ ...p, type: "products" });
                          setFormError("");
                        }}
                      >
                        <Pencil size={16} />
                      </button>
                    </td>
                  </tr>
                ))
              : tab === "categories"
                ? data.categories.map((c: any) => (
                    <tr key={c.category_id}>
                      <td>{c.name}</td>
                      <td>{c.slug}</td>
                      <td>{c.parent_id || "Root"}</td>
                      <td>
                        <button
                          className="icon-button"
                          aria-label={"Edit " + c.name}
                          onClick={() => {
                            setEdit({ ...c, type: "categories" });
                            setFormError("");
                          }}
                        >
                          <Pencil size={16} />
                        </button>
                      </td>
                    </tr>
                  ))
                : tab === "orders"
                  ? data.orders.map((o: any) => (
                      <tr key={o.order_id}>
                        <td>{o.order_number}</td>
                        <td>{o.first_name}</td>
                        <td>{money(o.total_amount)}</td>
                        <td>
                          <span className={"status status-" + o.status}>
                            {o.status}
                          </span>
                        </td>
                        <td>
                          {["confirmed", "processing", "shipped"].includes(
                            o.status,
                          ) && (
                            <button
                              className="text-link"
                              onClick={() =>
                                action("/orders/" + o.order_id, "PATCH", {
                                  status: {
                                    confirmed: "processing",
                                    processing: "shipped",
                                    shipped: "delivered",
                                  }[o.status as string],
                                })
                              }
                            >
                              Mark{" "}
                              {
                                {
                                  confirmed: "processing",
                                  processing: "shipped",
                                  shipped: "delivered",
                                }[o.status as string]
                              }
                              <ArrowUpRight size={14} />
                            </button>
                          )}
                        </td>
                      </tr>
                    ))
                  : tab === "customers"
                    ? data.customers.map((u: any) => (
                        <tr key={u.user_id}>
                          <td>
                            {u.first_name} {u.last_name}
                          </td>
                          <td>{u.email}</td>
                          <td>{u.role}</td>
                          <td>{u.is_active ? "Active" : "Suspended"}</td>
                          <td>
                            {u.role !== "admin" && (
                              <button
                                className="text-link"
                                onClick={() =>
                                  action("/customers/" + u.user_id, "PATCH", {
                                    is_active: !u.is_active,
                                  })
                                }
                              >
                                {u.is_active ? "Suspend" : "Reactivate"}
                              </button>
                            )}
                          </td>
                        </tr>
                      ))
                    : tab === "inventory"
                      ? data.products.map((p: any) => (
                          <tr key={p.product_id}>
                            <td>{p.name}</td>
                            <td>{p.available} available</td>
                            <td>
                              <span className="status">
                                {p.available < 10 ? "Low stock" : "Healthy"}
                              </span>
                            </td>
                          </tr>
                        ))
                      : data.reviews.map((r: any) => (
                          <tr key={r.review_id}>
                            <td>{r.product_name}</td>
                            <td>{r.rating}/5</td>
                            <td>{r.title}</td>
                            <td>{r.is_approved ? "Published" : "Hidden"}</td>
                            <td>
                              <button
                                className="text-link"
                                onClick={() =>
                                  action("/reviews/" + r.review_id, "PATCH", {
                                    is_approved: !r.is_approved,
                                  })
                                }
                              >
                                {r.is_approved ? "Hide" : "Approve"}
                              </button>
                            </td>
                          </tr>
                        ))}
          </tbody>
        </table>
      </div>
      {edit && (
        <div className="modal-backdrop">
          <section
            className="modal"
            role="dialog"
            aria-modal="true"
            aria-label="Edit store item"
          >
            <button
              className="modal-close"
              aria-label="Close editor"
              onClick={() => setEdit(null)}
            >
              ×
            </button>
            <h2>
              {edit.new ? "Add" : "Edit"}{" "}
              {edit.type === "products" ? "product" : "category"}
            </h2>
            <form
              className="form-stack"
              onSubmit={async (e) => {
                e.preventDefault();
                setBusy(true);
                const d: any = Object.fromEntries(
                  new FormData(e.currentTarget),
                );
                if (edit.type === "products") {
                  d.price = Number(d.price);
                  if (edit.new) {
                    d.category_id = Number(d.category_id);
                    d.stock = Number(d.stock);
                  } else d.quantity_in_stock = Number(d.quantity_in_stock);
                }
                try {
                  await mutate(
                    "/admin/" +
                      edit.type +
                      (edit.new
                        ? ""
                        : "/" + (edit.product_id || edit.category_id)),
                    edit.new ? "POST" : "PATCH",
                    d,
                  );
                  setEdit(null);
                  reload();
                  toast("Saved successfully.");
                } catch (e: any) {
                  setFormError(e.message);
                } finally {
                  setBusy(false);
                }
              }}
            >
              <label>
                Name
                <input
                  name="name"
                  defaultValue={edit.name}
                  required
                  minLength={2}
                  maxLength={edit.type === "categories" ? 100 : 255}
                />
              </label>
              {edit.type === "products" && (
                <>
                  <label>
                    Price (INR)
                    <input
                      name="price"
                      type="number"
                      step="0.01"
                      min="0.01"
                      max="10000000"
                      defaultValue={edit.price}
                      required
                    />
                  </label>
                  {edit.new ? (
                    <>
                      <label>
                        Category
                        <select name="category_id">
                          {data.categories.map((c: any) => (
                            <option value={c.category_id} key={c.category_id}>
                              {c.name}
                            </option>
                          ))}
                        </select>
                      </label>
                      <label>
                        Description
                        <textarea
                          name="description"
                          minLength={10}
                          maxLength={5000}
                          required
                        />
                      </label>
                      <label>
                        Initial stock
                        <input
                          name="stock"
                          type="number"
                          min="0"
                          max="1000000"
                          defaultValue="10"
                          required
                        />
                      </label>
                    </>
                  ) : (
                    <>
                      <label>
                        Status
                        <select name="status" defaultValue={edit.status}>
                          {["active", "draft", "inactive", "archived"].map(
                            (s) => (
                              <option key={s}>{s}</option>
                            ),
                          )}
                        </select>
                      </label>
                      <label>
                        Physical stock (must include reserved units)
                        <input
                          name="quantity_in_stock"
                          type="number"
                          min={edit.quantity_reserved || 0}
                          max="1000000"
                          defaultValue={edit.quantity_in_stock}
                          required
                          placeholder="Set total warehouse stock"
                        />
                      </label>
                    </>
                  )}
                </>
              )}
              {formError && <p className="form-error">{formError}</p>}
              <button className="button primary" disabled={busy}>
                {busy ? "Saving…" : "Save changes"}
              </button>
            </form>
          </section>
        </div>
      )}
    </div>
  );
}
