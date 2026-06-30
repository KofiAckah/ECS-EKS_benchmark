import React, { useCallback, useEffect, useState } from 'react';
import Dashboard from './Dashboard.jsx';
import ProductForm from './ProductForm.jsx';
import { listProducts, createProduct, updateProduct, deleteProduct } from './api.js';

export default function App() {
  const [products, setProducts] = useState([]);
  const [cache, setCache] = useState(null);
  const [editing, setEditing] = useState(null);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);

  const refresh = useCallback(async () => {
    try {
      setLoading(true);
      const { products: list, cache: cacheState } = await listProducts();
      setProducts(list);
      setCache(cacheState);
      setError(null);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const handleSubmit = async (data) => {
    try {
      if (editing) {
        await updateProduct(editing.id, data);
        setEditing(null);
      } else {
        await createProduct(data);
      }
      await refresh();
    } catch (err) {
      setError(err.message);
    }
  };

  const handleDelete = async (id) => {
    try {
      await deleteProduct(id);
      await refresh();
    } catch (err) {
      setError(err.message);
    }
  };

  return (
    <main className="app">
      <header>
        <h1>ShopNow Inventory</h1>
        {cache && <span className={`badge cache-${cache.toLowerCase()}`}>cache: {cache}</span>}
      </header>

      <Dashboard products={products} />

      {error && <p role="alert" className="error">{error}</p>}

      <ProductForm editing={editing} onSubmit={handleSubmit} onCancel={() => setEditing(null)} />

      <section aria-label="Products">
        {loading ? (
          <p>Loading…</p>
        ) : products.length === 0 ? (
          <p>No products yet. Add one above.</p>
        ) : (
          <table>
            <thead>
              <tr>
                <th>SKU</th><th>Name</th><th>Qty</th><th>Price</th><th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {products.map((p) => (
                <tr key={p.id}>
                  <td>{p.sku}</td>
                  <td>{p.name}</td>
                  <td>{p.quantity}</td>
                  <td>${(p.priceCents / 100).toFixed(2)}</td>
                  <td>
                    <button onClick={() => setEditing(p)}>Edit</button>
                    <button className="danger" onClick={() => handleDelete(p.id)}>Delete</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </main>
  );
}
