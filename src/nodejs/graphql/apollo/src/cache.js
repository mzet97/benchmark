'use strict';

import { createClient } from 'redis';

const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';

const client = createClient({ url: redisUrl });

let connected = false;

async function ensureConnected() {
  if (!connected) {
    await client.connect();
    connected = true;
  }
}

// Exported as named functions rather than as one object literal, so
// `import * as cache from './cache.js'` resolves cache.get / cache.set / cache.ttl
// / cache.ping. `export { async get(key) {...} }` is not valid syntax: the object
// shorthand only exists inside an object literal, and this module was CommonJS
// while the package declares "type": "module".
export async function get(key) {
  await ensureConnected();
  return client.get(key);
}

export async function set(key, value, ...args) {
  await ensureConnected();
  return client.set(key, value, ...args);
}

export async function ttl(key) {
  await ensureConnected();
  return client.ttl(key);
}

export async function ping() {
  await ensureConnected();
  return client.ping();
}
