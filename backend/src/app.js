'use strict';

const express = require('express');
const helmet = require('helmet');
const morgan = require('morgan');

const db = require('./db');
const cache = require('./cache');
const productsRouter = require('./products.routes');

// Builds the Express app. Kept separate from server.js so tests can import the
// app without binding a port.
function createApp() {
  const app = express();

  app.use(helmet());
  app.use(express.json());
  if (process.env.NODE_ENV !== 'test') {
    app.use(morgan('combined'));
  }

  // Liveness: process is up. Cheap, no dependencies — used by ECS/k8s liveness.
  app.get('/healthz', (req, res) => res.json({ status: 'ok' }));

  // Readiness: dependencies reachable. Used by ECS target group / k8s readiness.
  app.get('/readyz', async (req, res) => {
    const checks = { db: 'ok', redis: 'ok' };
    let healthy = true;
    try {
      await db.ping();
    } catch (err) {
      checks.db = `error: ${err.message}`;
      healthy = false;
    }
    try {
      await cache.ping();
    } catch (err) {
      checks.redis = `error: ${err.message}`;
      healthy = false;
    }
    res.status(healthy ? 200 : 503).json({ status: healthy ? 'ready' : 'not-ready', checks });
  });

  app.use('/api/products', productsRouter);

  app.get('/', (req, res) => res.json({ service: 'shopnow-backend', version: '1.0.0' }));

  // 404
  app.use((req, res) => res.status(404).json({ error: 'Not found' }));

  // Centralized error handler
  // eslint-disable-next-line no-unused-vars
  app.use((err, req, res, next) => {
    // eslint-disable-next-line no-console
    console.error('[error]', err);
    res.status(500).json({ error: 'Internal server error' });
  });

  return app;
}

module.exports = { createApp };
