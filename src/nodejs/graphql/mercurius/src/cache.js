'use strict';

const { createClient } = require('redis');

const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';

const client = createClient({ url: redisUrl });

let connected = false;

async function ensureConnected() {
  if (!connected) {
    await client.connect();
    connected = true;
  }
}

module.exports = {
  async get(key) {
    await ensureConnected();
    return client.get(key);
  },
  async set(key, value, ...args) {
    await ensureConnected();
    return client.set(key, value, ...args);
  },
  async ttl(key) {
    await ensureConnected();
    return client.ttl(key);
  },
  async ping() {
    await ensureConnected();
    return client.ping();
  }
};
