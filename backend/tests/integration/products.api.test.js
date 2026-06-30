'use strict';

// API-level integration test. The repository is mocked so the suite runs in CI
// without a live Postgres/Redis — it exercises routing, validation, status
// codes, and error mapping end-to-end through Express.
const request = require('supertest');

jest.mock('../../src/products.repo');
jest.mock('../../src/db', () => ({ ping: jest.fn().mockResolvedValue(), init: jest.fn() }));
jest.mock('../../src/cache', () => ({
  ping: jest.fn().mockResolvedValue(true),
  connect: jest.fn().mockResolvedValue(null),
}));

const repo = require('../../src/products.repo');
const { createApp } = require('../../src/app');

const app = createApp();

const sample = {
  id: 1, name: 'Keyboard', sku: 'KB-01', quantity: 5, priceCents: 1999,
  createdAt: '2026-01-01T00:00:00Z', updatedAt: '2026-01-01T00:00:00Z',
};

beforeEach(() => jest.clearAllMocks());

describe('GET /healthz', () => {
  test('returns ok', async () => {
    const res = await request(app).get('/healthz');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});

describe('GET /readyz', () => {
  test('returns ready when deps are healthy', async () => {
    const res = await request(app).get('/readyz');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ready');
  });
});

describe('GET /api/products', () => {
  test('returns products and a cache header', async () => {
    repo.list.mockResolvedValue({ products: [sample], cached: false });
    const res = await request(app).get('/api/products');
    expect(res.status).toBe(200);
    expect(res.body.products).toHaveLength(1);
    expect(res.headers['x-cache']).toBe('MISS');
  });
});

describe('POST /api/products', () => {
  test('creates a valid product', async () => {
    repo.create.mockResolvedValue(sample);
    const res = await request(app)
      .post('/api/products')
      .send({ name: 'Keyboard', sku: 'KB-01', quantity: 5, priceCents: 1999 });
    expect(res.status).toBe(201);
    expect(res.body.product.sku).toBe('KB-01');
  });

  test('rejects an invalid product with 400', async () => {
    const res = await request(app).post('/api/products').send({ name: '' });
    expect(res.status).toBe(400);
    expect(res.body.errors.length).toBeGreaterThan(0);
    expect(repo.create).not.toHaveBeenCalled();
  });

  test('maps duplicate SKU to 409', async () => {
    repo.create.mockRejectedValue({ code: '23505' });
    const res = await request(app)
      .post('/api/products')
      .send({ name: 'Keyboard', sku: 'KB-01', quantity: 5, priceCents: 1999 });
    expect(res.status).toBe(409);
  });
});

describe('PUT /api/products/:id', () => {
  test('updates an existing product', async () => {
    repo.update.mockResolvedValue({ ...sample, quantity: 10 });
    const res = await request(app).put('/api/products/1').send({ quantity: 10 });
    expect(res.status).toBe(200);
    expect(res.body.product.quantity).toBe(10);
  });

  test('returns 404 for a missing product', async () => {
    repo.update.mockResolvedValue(null);
    const res = await request(app).put('/api/products/999').send({ quantity: 10 });
    expect(res.status).toBe(404);
  });
});

describe('DELETE /api/products/:id', () => {
  test('deletes an existing product', async () => {
    repo.remove.mockResolvedValue(true);
    const res = await request(app).delete('/api/products/1');
    expect(res.status).toBe(204);
  });

  test('returns 404 when nothing was deleted', async () => {
    repo.remove.mockResolvedValue(false);
    const res = await request(app).delete('/api/products/999');
    expect(res.status).toBe(404);
  });
});
