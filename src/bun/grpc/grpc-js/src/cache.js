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

async function checkHealth() {
  try {
    await redis.ping();
    return "connected";
  } catch {
    return "disconnected";
  }
}

async function getValue(key) {
  const value = await redis.get(key);
  if (value !== null) {
    const ttl = await redis.ttl(key);
    return { value, cached: true, ttl: ttl > 0 ? ttl : 0 };
  }

  // Cache miss: generate a value, store it, return
  const generatedValue = `generated_value_${key}_${Date.now()}`;
  await redis.set(key, generatedValue, "EX", 3600);
  return { value: generatedValue, cached: false, ttl: 3600 };
}

async function close() {
  await redis.quit();
}

module.exports = { checkHealth, getValue, close };
