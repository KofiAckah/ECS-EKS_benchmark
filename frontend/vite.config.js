import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// During local `vite dev`, proxy /api to the backend so the browser uses the
// same relative paths that Nginx serves in production. In containers, Nginx
// (not Vite) does the proxying — the app code never changes.
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: process.env.VITE_API_TARGET || 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: './src/test/setup.js',
  },
});
