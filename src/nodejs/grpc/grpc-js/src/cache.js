const redis = require('redis');

let client = null;
let connected = false;

async function getClient() {
  if (client && connected) {
    return client;
  }

  client = redis.createClient({
    url: process.env.REDIS_URL || 'redis://localhost:6379',
    socket: {
      connectTimeout: 5000,
      reconnectStrategy: (retries) => {
        if (retries > 10) {
          console.error('Redis: max reconnect attempts reached');
          return new Error('Max reconnect attempts');
        }
        return Math.min(retries * 100, 3000);
      },
    },
  });

  client.on('error', (err) => {
    console.error('Redis client error:', err.message);
    connected = false;
  });

  client.on('connect', () => {
    connected = true;
  });

  client.on('disconnect', () => {
    connected = false;
  });

  await client.connect();
  return client;
}

async function get(key) {
  try {
    const c = await getClient();
    const value = await c.get(key);
    return { value, hit: value !== null };
  } catch (err) {
    console.error('Cache get error:', err.message);
    return { value: null, hit: false };
  }
}

async function set(key, value, ttlSeconds = 300) {
  try {
    const c = await getClient();
    await c.setEx(key, ttlSeconds, value);
    return true;
  } catch (err) {
    console.error('Cache set error:', err.message);
    return false;
  }
}

async function healthCheck() {
  try {
    const c = await getClient();
    const result = await c.ping();
    return result === 'PONG' ? 'connected' : 'disconnected';
  } catch (err) {
    console.error('Cache health check failed:', err.message);
    return 'disconnected';
  }
}

async function close() {
  if (client) {
    await client.quit();
    client = null;
    connected = false;
  }
}

module.exports = { get, set, healthCheck, close };
