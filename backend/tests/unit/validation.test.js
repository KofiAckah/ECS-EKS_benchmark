'use strict';

const { validateProduct } = require('../../src/validation');

describe('validateProduct', () => {
  test('accepts a fully valid product', () => {
    const { valid, value } = validateProduct({
      name: '  Keyboard  ',
      sku: 'KB-01',
      quantity: 5,
      priceCents: 1999,
    });
    expect(valid).toBe(true);
    expect(value).toEqual({ name: 'Keyboard', sku: 'KB-01', quantity: 5, priceCents: 1999 });
  });

  test('rejects empty name and sku', () => {
    const { valid, errors } = validateProduct({ name: '', sku: '   ', quantity: 1, priceCents: 1 });
    expect(valid).toBe(false);
    expect(errors).toEqual(expect.arrayContaining([
      expect.stringContaining('name'),
      expect.stringContaining('sku'),
    ]));
  });

  test('rejects negative and non-integer quantity/price', () => {
    const { valid, errors } = validateProduct({
      name: 'X', sku: 'Y', quantity: -1, priceCents: 1.5,
    });
    expect(valid).toBe(false);
    expect(errors).toEqual(expect.arrayContaining([
      expect.stringContaining('quantity'),
      expect.stringContaining('priceCents'),
    ]));
  });

  test('partial mode only validates provided fields', () => {
    const { valid, value } = validateProduct({ quantity: 3 }, { partial: true });
    expect(valid).toBe(true);
    expect(value).toEqual({ quantity: 3 });
  });

  test('partial mode still rejects an invalid provided field', () => {
    const { valid } = validateProduct({ quantity: -5 }, { partial: true });
    expect(valid).toBe(false);
  });
});
