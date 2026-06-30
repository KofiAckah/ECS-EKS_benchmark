import React, { useEffect, useState } from 'react';

const EMPTY = { name: '', sku: '', quantity: '0', price: '0.00' };

// Add/Edit form. `editing` (a product or null) toggles between create/update.
export default function ProductForm({ editing, onSubmit, onCancel }) {
  const [form, setForm] = useState(EMPTY);

  useEffect(() => {
    if (editing) {
      setForm({
        name: editing.name,
        sku: editing.sku,
        quantity: String(editing.quantity),
        price: (editing.priceCents / 100).toFixed(2),
      });
    } else {
      setForm(EMPTY);
    }
  }, [editing]);

  const change = (e) => setForm({ ...form, [e.target.name]: e.target.value });

  const submit = (e) => {
    e.preventDefault();
    onSubmit({
      name: form.name.trim(),
      sku: form.sku.trim(),
      quantity: parseInt(form.quantity, 10),
      priceCents: Math.round(parseFloat(form.price) * 100),
    });
    if (!editing) setForm(EMPTY);
  };

  return (
    <form className="product-form" onSubmit={submit}>
      <h2>{editing ? `Edit ${editing.sku}` : 'Add product'}</h2>
      <label>
        Name
        <input name="name" value={form.name} onChange={change} required />
      </label>
      <label>
        SKU
        <input name="sku" value={form.sku} onChange={change} required disabled={!!editing} />
      </label>
      <label>
        Quantity
        <input name="quantity" type="number" min="0" value={form.quantity} onChange={change} required />
      </label>
      <label>
        Price (USD)
        <input name="price" type="number" min="0" step="0.01" value={form.price} onChange={change} required />
      </label>
      <div className="form-actions">
        <button type="submit">{editing ? 'Save' : 'Add'}</button>
        {editing && (
          <button type="button" className="secondary" onClick={onCancel}>
            Cancel
          </button>
        )}
      </div>
    </form>
  );
}
