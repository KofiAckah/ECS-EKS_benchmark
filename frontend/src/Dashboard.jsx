import React from 'react';

// Small inventory summary derived from the product list.
export default function Dashboard({ products }) {
  const totalSkus = products.length;
  const totalUnits = products.reduce((sum, p) => sum + p.quantity, 0);
  const inventoryValue = products.reduce((sum, p) => sum + p.quantity * p.priceCents, 0);
  const lowStock = products.filter((p) => p.quantity <= 5).length;

  const cards = [
    { label: 'SKUs', value: totalSkus },
    { label: 'Units in stock', value: totalUnits },
    { label: 'Inventory value', value: `$${(inventoryValue / 100).toFixed(2)}` },
    { label: 'Low stock (≤5)', value: lowStock },
  ];

  return (
    <section className="dashboard" aria-label="Inventory dashboard">
      {cards.map((c) => (
        <div className="card" key={c.label}>
          <div className="card-value">{c.value}</div>
          <div className="card-label">{c.label}</div>
        </div>
      ))}
    </section>
  );
}
