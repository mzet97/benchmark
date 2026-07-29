const Redis = require("ioredis");

const redis = new Redis({
  host: process.env.REDIS_HOST || "localhost",
  port: parseInt(process.env.REDIS_PORT || "6379"),
  password: process.env.REDIS_PASSWORD || "",
  db: parseInt(process.env.REDIS_DB || "0"),
  maxRetriesPerRequest: 3,
  retryStrategy(times) {
    return Math.min(times * 50, 2000);
  },
});

async function healthCheck() {
  try {
    const result = await redis.ping();
    return result === "PONG" ? "connected" : "disconnected";
  } catch (err) {
    console.error("Cache health check failed:", err.message);
    return "disconnected";
  }
}

async function get(key) {
  try {
    const value = await redis.get(key);
    return { value, hit: value !== null };
  } catch (err) {
    console.error("Cache get error:", err.message);
    return { value: null, hit: false };
  }
}

async function set(key, value, ttlSeconds = 300) {
  try {
    await redis.set(key, value, "EX", ttlSeconds);
    return true;
  } catch (err) {
    console.error("Cache set error:", err.message);
    return false;
  }
}

async function close() {
  await redis.quit();
}

module.exports = { get, set, healthCheck, close };
