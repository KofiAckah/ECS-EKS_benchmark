'use strict';

// Pure validation helpers — no I/O, so they are trivially unit-testable.

function validateProduct(body, { partial = false } = {}) {
  const errors = [];
  const out = {};

  const has = (k) => Object.prototype.hasOwnProperty.call(body || {}, k);

  if (!partial || has('name')) {
    if (typeof body.name !== 'string' || body.name.trim() === '') {
      errors.push('name is required and must be a non-empty string');
    } else {
      out.name = body.name.trim();
    }
  }

  if (!partial || has('sku')) {
    if (typeof body.sku !== 'string' || body.sku.trim() === '') {
      errors.push('sku is required and must be a non-empty string');
    } else {
      out.sku = body.sku.trim();
    }
  }

  if (!partial || has('quantity')) {
    const q = body.quantity;
    if (!Number.isInteger(q) || q < 0) {
      errors.push('quantity must be a non-negative integer');
    } else {
      out.quantity = q;
    }
  }

  if (!partial || has('priceCents')) {
    const p = body.priceCents;
    if (!Number.isInteger(p) || p < 0) {
      errors.push('priceCents must be a non-negative integer');
    } else {
      out.priceCents = p;
    }
  }

  return { valid: errors.length === 0, errors, value: out };
}

module.exports = { validateProduct };
