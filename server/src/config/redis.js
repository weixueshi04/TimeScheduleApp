const redis = require('redis');
const logger = require('../utils/logger');

// Create Redis client
const redisClient = redis.createClient({
  socket: {
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT) || 6379,
  },
  password: process.env.REDIS_PASSWORD || undefined,
  database: parseInt(process.env.REDIS_DB) || 0,
});

// Error handling
redisClient.on('error', (error) => {
  logger.error('Redis Client Error:', error);
});

redisClient.on('connect', () => {
  logger.info('Redis Client Connected');
});

redisClient.on('ready', () => {
  logger.info('Redis Client Ready');
});

redisClient.on('reconnecting', () => {
  logger.warn('Redis Client Reconnecting');
});

// Connect to Redis
async function connectRedis() {
  try {
    await redisClient.connect();
    logger.info('Redis connection test successful');
    return true;
  } catch (error) {
    logger.error('Redis connection error:', error);
    throw error;
  }
}

// Cache helpers with expiration
async function setCache(key, value, expirationInSeconds = 3600) {
  try {
    const stringValue = typeof value === 'string' ? value : JSON.stringify(value);
    await redisClient.setEx(key, expirationInSeconds, stringValue);
    logger.debug(`Cache set: ${key} (TTL: ${expirationInSeconds}s)`);
  } catch (error) {
    logger.error(`Cache set error for key ${key}:`, error);
    throw error;
  }
}

async function getCache(key, parseJSON = true) {
  try {
    const value = await redisClient.get(key);
    if (!value) {
      return null;
    }

    if (parseJSON) {
      try {
        return JSON.parse(value);
      } catch {
        return value;
      }
    }

    return value;
  } catch (error) {
    logger.error(`Cache get error for key ${key}:`, error);
    throw error;
  }
}

async function deleteCache(key) {
  try {
    await redisClient.del(key);
    logger.debug(`Cache deleted: ${key}`);
  } catch (error) {
    logger.error(`Cache delete error for key ${key}:`, error);
    throw error;
  }
}

async function deleteCachePattern(pattern) {
  try {
    const keys = await redisClient.keys(pattern);
    if (keys.length > 0) {
      await redisClient.del(keys);
      logger.debug(`Cache deleted pattern: ${pattern} (${keys.length} keys)`);
    }
  } catch (error) {
    logger.error(`Cache delete pattern error for ${pattern}:`, error);
    throw error;
  }
}

// Study room matching queue helpers
async function addToMatchingQueue(userId, userData) {
  try {
    const queueKey = 'matching:queue';
    const timestamp = Date.now();
    await redisClient.zAdd(queueKey, {
      score: timestamp,
      value: JSON.stringify({ userId, ...userData, timestamp }),
    });
    logger.debug(`User ${userId} added to matching queue`);
  } catch (error) {
    logger.error(`Error adding user ${userId} to matching queue:`, error);
    throw error;
  }
}

async function removeFromMatchingQueue(userId) {
  try {
    const queueKey = 'matching:queue';
    const members = await redisClient.zRange(queueKey, 0, -1);

    for (const member of members) {
      const data = JSON.parse(member);
      if (data.userId === userId) {
        await redisClient.zRem(queueKey, member);
        logger.debug(`User ${userId} removed from matching queue`);
        break;
      }
    }
  } catch (error) {
    logger.error(`Error removing user ${userId} from matching queue:`, error);
    throw error;
  }
}

async function getMatchingQueue(limit = 100) {
  try {
    const queueKey = 'matching:queue';
    const members = await redisClient.zRange(queueKey, 0, limit - 1);
    return members.map(member => JSON.parse(member));
  } catch (error) {
    logger.error('Error getting matching queue:', error);
    throw error;
  }
}

// Study room state cache
async function setStudyRoomState(roomId, state) {
  const key = `room:${roomId}:state`;
  await setCache(key, state, 7200); // 2 hours expiration
}

async function getStudyRoomState(roomId) {
  const key = `room:${roomId}:state`;
  return await getCache(key);
}

async function deleteStudyRoomState(roomId) {
  const key = `room:${roomId}:state`;
  await deleteCache(key);
}

// User online status
async function setUserOnline(userId, socketId) {
  const key = `user:${userId}:online`;
  await setCache(key, { socketId, timestamp: Date.now() }, 3600);
}

async function getUserOnlineStatus(userId) {
  const key = `user:${userId}:online`;
  return await getCache(key);
}

async function setUserOffline(userId) {
  const key = `user:${userId}:online`;
  await deleteCache(key);
}

// Rate limiting helper
async function checkRateLimit(identifier, maxRequests = 10, windowSeconds = 60) {
  try {
    const key = `ratelimit:${identifier}`;
    const current = await redisClient.incr(key);

    if (current === 1) {
      await redisClient.expire(key, windowSeconds);
    }

    return {
      allowed: current <= maxRequests,
      current,
      limit: maxRequests,
      remaining: Math.max(0, maxRequests - current),
    };
  } catch (error) {
    logger.error(`Rate limit check error for ${identifier}:`, error);
    // Allow request on error to prevent false positives
    return { allowed: true, current: 0, limit: maxRequests, remaining: maxRequests };
  }
}

module.exports = {
  redisClient,
  connectRedis,
  setCache,
  getCache,
  deleteCache,
  deleteCachePattern,
  addToMatchingQueue,
  removeFromMatchingQueue,
  getMatchingQueue,
  setStudyRoomState,
  getStudyRoomState,
  deleteStudyRoomState,
  setUserOnline,
  getUserOnlineStatus,
  setUserOffline,
  checkRateLimit,
};
