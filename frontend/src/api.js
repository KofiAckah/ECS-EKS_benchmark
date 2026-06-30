// Thin API client. All calls are RELATIVE (/api/...) so the browser hits
// whatever served the page — Vite dev proxy locally, Nginx in containers.
// The frontend never knows the backend's real address; that's service discovery.

const BASE = '/api/products';

async function handle(res) {
  if (res.status === 204) return null;
  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    const msg = body.error || (body.errors && body.errors.join(', ')) || `HTTP ${res.status}`;
    throw new Error(msg);
  }
  return body;
}

export async function listProducts() {
  const res = await fetch(BASE);
  const body = await handle(res);
  return { products: body.products, cache: res.headers.get('X-Cache') };
}

export async function createProduct(product) {
  const res = await fetch(BASE, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(product),
  });
  return (await handle(res)).product;
}

export async function updateProduct(id, fields) {
  const res = await fetch(`${BASE}/${id}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(fields),
  });
  return (await handle(res)).product;
}

export async function deleteProduct(id) {
  const res = await fetch(`${BASE}/${id}`, { method: 'DELETE' });
  await handle(res);
}
