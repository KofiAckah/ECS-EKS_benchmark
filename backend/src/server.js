'use strict';

const { createApp } = require('./app');
const config = require('./config');
const db = require('./db');
const cache = require('./cache');

async function start() {
  // Best-effort dependency bootstrap. We retry the schema init so the API can
  // start slightly before Postgres is fully ready (common in orchestrators).
  await connectWithRetry();
  await cache.connect().catch((err) => {
    // eslint-disable-next-line no-console
    console.error('[startup] redis connect failed (continuing):', err.message);
  });

  const app = createApp();
  const server = app.listen(config.port, () => {
    // eslint-disable-next-line no-console
    console.log(`[startup] shopnow-backend listening on :${config.port}`);
  });

  const shutdown = (signal) => {
    // eslint-disable-next-line no-console
    console.log(`[shutdown] received ${signal}, closing server`);
    server.close(() => process.exit(0));
  };
  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

async function connectWithRetry(attempts = 10, delayMs = 3000) {
  for (let i = 1; i <= attempts; i += 1) {
    try {
      await db.init();
      // eslint-disable-next-line no-console
      console.log('[startup] database schema ready');
      return;
    } catch (err) {
      // eslint-disable-next-line no-console
      console.error(`[startup] db not ready (attempt ${i}/${attempts}): ${err.message}`);
      if (i === attempts) throw err;
      await new Promise((r) => setTimeout(r, delayMs));
    }
  }
}

start().catch((err) => {
  // eslint-disable-next-line no-console
  console.error('[fatal] failed to start:', err);
  process.exit(1);
});
