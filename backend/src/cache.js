'use strict';

const { createClient } = require('redis');
const config = require('./config');

// Lazily-connected Redis client. If Redis is down or disabled, the API still
// works (cache-aside degrades gracefully) — failures are logged, not thrown.
let client = null;
let connected = false;

async function connect() {
  if (!config.redis.enabled) return null;
  if (client) return client;
  client = createClient({ url: config.redis.url });
  client.on('error', (err) => {
    connected = false;
    // eslint-disable-next-line no-console
    console.error('[cache] redis error:', err.message);
  });
  client.on('ready', () => {
    connected = true;
  });
  await client.connect();
  return client;
}

async function get(key) {
  if (!config.redis.enabled || !client || !connected) return null;
  try {
    const raw = await client.get(key);
    return raw ? JSON.parse(raw) : null;
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[cache] get failed:', err.message);
    return null;
  }
}

async function set(key, value, ttlSeconds = config.redis.ttlSeconds) {
  if (!config.redis.enabled || !client || !connected) return;
  try {
    await client.set(key, JSON.stringify(value), { EX: ttlSeconds });
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[cache] set failed:', err.message);
  }
}

async function del(key) {
  if (!config.redis.enabled || !client || !connected) return;
  try {
    await client.del(key);
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('[cache] del failed:', err.message);
  }
}

async function ping() {
  if (!config.redis.enabled) return true; // disabled == not a readiness blocker
  if (!client) await connect();
  await client.ping();
  return true;
}

function isEnabled() {
  return config.redis.enabled;
}

module.exports = { connect, get, set, del, ping, isEnabled };
