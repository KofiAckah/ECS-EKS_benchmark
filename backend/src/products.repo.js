'use strict';

const { pool } = require('./db');
const cache = require('./cache');

const LIST_CACHE_KEY = 'products:list';

function rowToProduct(row) {
  return {
    id: row.id,
    name: row.name,
    sku: row.sku,
    quantity: row.quantity,
    priceCents: row.price_cents,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

// Cache-aside read of the full listing. Invalidated on every write below.
async function list() {
  const cached = await cache.get(LIST_CACHE_KEY);
  if (cached) return { products: cached, cached: true };

  const { rows } = await pool.query(
    'SELECT * FROM products ORDER BY id ASC'
  );
  const products = rows.map(rowToProduct);
  await cache.set(LIST_CACHE_KEY, products);
  return { products, cached: false };
}

async function getById(id) {
  const { rows } = await pool.query('SELECT * FROM products WHERE id = $1', [id]);
  return rows[0] ? rowToProduct(rows[0]) : null;
}

async function create({ name, sku, quantity, priceCents }) {
  const { rows } = await pool.query(
    `INSERT INTO products (name, sku, quantity, price_cents)
     VALUES ($1, $2, $3, $4) RETURNING *`,
    [name, sku, quantity ?? 0, priceCents ?? 0]
  );
  await cache.del(LIST_CACHE_KEY);
  return rowToProduct(rows[0]);
}

async function update(id, fields) {
  const sets = [];
  const values = [];
  let i = 1;
  const map = { name: 'name', sku: 'sku', quantity: 'quantity', priceCents: 'price_cents' };
  for (const [key, col] of Object.entries(map)) {
    if (fields[key] !== undefined) {
      sets.push(`${col} = $${i++}`);
      values.push(fields[key]);
    }
  }
  if (sets.length === 0) return getById(id);
  sets.push('updated_at = now()');
  values.push(id);
  const { rows } = await pool.query(
    `UPDATE products SET ${sets.join(', ')} WHERE id = $${i} RETURNING *`,
    values
  );
  await cache.del(LIST_CACHE_KEY);
  return rows[0] ? rowToProduct(rows[0]) : null;
}

async function remove(id) {
  const { rowCount } = await pool.query('DELETE FROM products WHERE id = $1', [id]);
  await cache.del(LIST_CACHE_KEY);
  return rowCount > 0;
}

module.exports = { list, getById, create, update, remove, LIST_CACHE_KEY };
