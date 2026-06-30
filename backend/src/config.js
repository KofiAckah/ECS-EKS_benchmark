'use strict';

// 12-factor: every environment-specific value comes from the environment.
// The SAME image runs locally, on ECS, and on EKS — only these vars differ.
function requireEnv(name, fallback) {
  const value = process.env[name];
  if (value === undefined || value === '') {
    if (fallback !== undefined) return fallback;
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

const config = {
  port: parseInt(process.env.PORT || '8080', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  db: {
    host: requireEnv('DB_HOST', 'localhost'),
    port: parseInt(process.env.DB_PORT || '5432', 10),
    user: requireEnv('DB_USER', 'shopnow'),
    // Password is injected from Secrets Manager (ECS) / K8s Secret (EKS); never hardcoded.
    password: requireEnv('DB_PASSWORD', 'shopnow'),
    database: requireEnv('DB_NAME', 'shopnow'),
    max: parseInt(process.env.DB_POOL_MAX || '10', 10),
  },
  redis: {
    // redis://host:port — set via env in every environment.
    url: process.env.REDIS_URL || 'redis://localhost:6379',
    // Cache TTL for the product listing, in seconds.
    ttlSeconds: parseInt(process.env.CACHE_TTL_SECONDS || '30', 10),
    enabled: (process.env.CACHE_ENABLED || 'true').toLowerCase() === 'true',
  },
};

module.exports = config;
