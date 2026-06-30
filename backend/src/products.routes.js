'use strict';

const express = require('express');
const repo = require('./products.repo');
const { validateProduct } = require('./validation');

const router = express.Router();

function asyncHandler(fn) {
  return (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
}

// GET /api/products — cached listing (cache-aside via Redis)
router.get('/', asyncHandler(async (req, res) => {
  const { products, cached } = await repo.list();
  res.set('X-Cache', cached ? 'HIT' : 'MISS');
  res.json({ products });
}));

// GET /api/products/:id
router.get('/:id', asyncHandler(async (req, res) => {
  const product = await repo.getById(req.params.id);
  if (!product) return res.status(404).json({ error: 'Product not found' });
  return res.json({ product });
}));

// POST /api/products
router.post('/', asyncHandler(async (req, res) => {
  const { valid, errors, value } = validateProduct(req.body);
  if (!valid) return res.status(400).json({ errors });
  try {
    const product = await repo.create(value);
    return res.status(201).json({ product });
  } catch (err) {
    if (err.code === '23505') return res.status(409).json({ error: 'SKU already exists' });
    throw err;
  }
}));

// PUT /api/products/:id
router.put('/:id', asyncHandler(async (req, res) => {
  const { valid, errors, value } = validateProduct(req.body, { partial: true });
  if (!valid) return res.status(400).json({ errors });
  try {
    const product = await repo.update(req.params.id, value);
    if (!product) return res.status(404).json({ error: 'Product not found' });
    return res.json({ product });
  } catch (err) {
    if (err.code === '23505') return res.status(409).json({ error: 'SKU already exists' });
    throw err;
  }
}));

// DELETE /api/products/:id
router.delete('/:id', asyncHandler(async (req, res) => {
  const ok = await repo.remove(req.params.id);
  if (!ok) return res.status(404).json({ error: 'Product not found' });
  return res.status(204).send();
}));

module.exports = router;
