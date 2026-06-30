'use strict';

const { Pool } = require('pg');
const config = require('./config');

// A single shared connection pool for the process.
const pool = new Pool({
  host: config.db.host,
  port: config.db.port,
  user: config.db.user,
  password: config.db.password,
  database: config.db.database,
  max: config.db.max,
  // Fail fast rather than hanging a request forever if the DB is unreachable.
  connectionTimeoutMillis: 5000,
  idleTimeoutMillis: 30000,
});

// Idempotent schema bootstrap. Keeps the lab self-contained (no migration tool needed).
const SCHEMA = `
  CREATE TABLE IF NOT EXISTS products (
    id          SERIAL PRIMARY KEY,
    name        TEXT        NOT NULL,
    sku         TEXT        NOT NULL UNIQUE,
    quantity    INTEGER     NOT NULL DEFAULT 0 CHECK (quantity >= 0),
    price_cents INTEGER     NOT NULL DEFAULT 0 CHECK (price_cents >= 0),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
  );
`;

async function init() {
  await pool.query(SCHEMA);
}

async function ping() {
  await pool.query('SELECT 1');
}

module.exports = { pool, init, ping };
