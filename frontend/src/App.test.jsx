import React from 'react';
import { describe, test, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import App from './App.jsx';
import * as api from './api.js';

vi.mock('./api.js');

const products = [
  { id: 1, name: 'Keyboard', sku: 'KB-01', quantity: 3, priceCents: 1999 },
  { id: 2, name: 'Mouse', sku: 'MS-01', quantity: 20, priceCents: 999 },
];

beforeEach(() => {
  vi.clearAllMocks();
  api.listProducts.mockResolvedValue({ products, cache: 'MISS' });
  api.createProduct.mockResolvedValue({ id: 3 });
  api.deleteProduct.mockResolvedValue();
});

describe('App', () => {
  test('renders products from the API', async () => {
    render(<App />);
    expect(await screen.findByText('Keyboard')).toBeInTheDocument();
    expect(screen.getByText('Mouse')).toBeInTheDocument();
  });

  test('dashboard summarizes inventory', async () => {
    render(<App />);
    // 2 SKUs
    expect(await screen.findByText('2')).toBeInTheDocument();
    // total units = 3 + 20 = 23
    expect(screen.getByText('23')).toBeInTheDocument();
  });

  test('shows the cache badge', async () => {
    render(<App />);
    expect(await screen.findByText(/cache: MISS/)).toBeInTheDocument();
  });

  test('creating a product calls the API and refreshes', async () => {
    render(<App />);
    await screen.findByText('Keyboard');
    await userEvent.type(screen.getByLabelText('Name'), 'Monitor');
    await userEvent.type(screen.getByLabelText('SKU'), 'MN-01');
    await userEvent.click(screen.getByRole('button', { name: 'Add' }));
    await waitFor(() => expect(api.createProduct).toHaveBeenCalled());
    expect(api.createProduct).toHaveBeenCalledWith(
      expect.objectContaining({ name: 'Monitor', sku: 'MN-01' })
    );
  });

  test('surfaces API errors', async () => {
    api.listProducts.mockRejectedValueOnce(new Error('backend down'));
    render(<App />);
    expect(await screen.findByRole('alert')).toHaveTextContent('backend down');
  });
});
