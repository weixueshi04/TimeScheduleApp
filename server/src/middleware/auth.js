const jwt = require('jsonwebtoken');
const { APIError, asyncHandler } = require('./errorHandler');
const { query } = require('../config/postgres');
const logger = require('../utils/logger');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-this';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'your-refresh-secret-change-this';
const JWT_REFRESH_EXPIRES_IN = process.env.JWT_REFRESH_EXPIRES_IN || '30d';

/**
 * Generate JWT access token
 */
function generateAccessToken(userId, email) {
  return jwt.sign(
    {
      id: userId,
      email,
      type: 'access',
    },
    JWT_SECRET,
    { expiresIn: JWT_EXPIRES_IN }
  );
}

/**
 * Generate JWT refresh token
 */
function generateRefreshToken(userId, email) {
  return jwt.sign(
    {
      id: userId,
      email,
      type: 'refresh',
    },
    JWT_REFRESH_SECRET,
    { expiresIn: JWT_REFRESH_EXPIRES_IN }
  );
}

/**
 * Verify JWT token
 */
function verifyToken(token, secret = JWT_SECRET) {
  try {
    return jwt.verify(token, secret);
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      throw new APIError(401, 'Token has expired');
    } else if (error.name === 'JsonWebTokenError') {
      throw new APIError(401, 'Invalid token');
    } else {
      throw new APIError(401, 'Token verification failed');
    }
  }
}

/**
 * Authentication middleware - verify JWT token
 */
const authenticate = asyncHandler(async (req, res, next) => {
  // Get token from header
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new APIError(401, 'No token provided');
  }

  const token = authHeader.substring(7); // Remove 'Bearer ' prefix

  // Verify token
  const decoded = verifyToken(token);

  // Check if token is an access token
  if (decoded.type !== 'access') {
    throw new APIError(401, 'Invalid token type');
  }

  // Get user from database
  const result = await query(
    'SELECT id, username, email, nickname, avatar_url, status, is_verified FROM users WHERE id = $1',
    [decoded.id]
  );

  if (result.rows.length === 0) {
    throw new APIError(401, 'User not found');
  }

  const user = result.rows[0];

  // Check if user is active
  if (user.status !== 'active') {
    throw new APIError(403, 'User account is not active');
  }

  // Attach user to request
  req.user = user;

  next();
});

/**
 * Optional authentication - attach user if token is valid, but don't require it
 */
const optionalAuth = asyncHandler(async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      const decoded = verifyToken(token);

      if (decoded.type === 'access') {
        const result = await query(
          'SELECT id, username, email, nickname, avatar_url, status FROM users WHERE id = $1',
          [decoded.id]
        );

        if (result.rows.length > 0 && result.rows[0].status === 'active') {
          req.user = result.rows[0];
        }
      }
    }
  } catch (error) {
    // Ignore authentication errors for optional auth
    logger.debug('Optional auth failed:', error.message);
  }

  next();
});

/**
 * Require verified email
 */
const requireVerified = asyncHandler(async (req, res, next) => {
  if (!req.user) {
    throw new APIError(401, 'Authentication required');
  }

  if (!req.user.is_verified) {
    throw new APIError(403, 'Email verification required');
  }

  next();
});

/**
 * Check if user can create study room (准入机制)
 */
const requireStudyRoomAccess = asyncHandler(async (req, res, next) => {
  if (!req.user) {
    throw new APIError(401, 'Authentication required');
  }

  // Get user's eligibility status
  const result = await query(
    `SELECT
      days_since_registration,
      total_focus_sessions,
      total_focus_hours,
      can_create_study_room
    FROM users WHERE id = $1`,
    [req.user.id]
  );

  if (result.rows.length === 0) {
    throw new APIError(404, 'User not found');
  }

  const userData = result.rows[0];

  // Check eligibility: 3 days registration + 5 focus sessions OR 3 hours total
  const hasMinDays = userData.days_since_registration >= 3;
  const hasMinSessions = userData.total_focus_sessions >= 5;
  const hasMinHours = parseFloat(userData.total_focus_hours) >= 3;

  const isEligible = hasMinDays && (hasMinSessions || hasMinHours);

  if (!isEligible) {
    throw new APIError(403, 'You need to complete the eligibility requirements to create study rooms', true, JSON.stringify({
      requirements: {
        days_since_registration: { required: 3, current: userData.days_since_registration },
        total_focus_sessions: { required: 5, current: userData.total_focus_sessions },
        total_focus_hours: { required: 3, current: parseFloat(userData.total_focus_hours) },
      },
      message: 'Complete 3 days registration AND (5 focus sessions OR 3 hours total focus time)',
    }));
  }

  // Update eligibility status if not already set
  if (!userData.can_create_study_room) {
    await query(
      'UPDATE users SET can_create_study_room = true WHERE id = $1',
      [req.user.id]
    );
  }

  next();
});

module.exports = {
  generateAccessToken,
  generateRefreshToken,
  verifyToken,
  authenticate,
  optionalAuth,
  requireVerified,
  requireStudyRoomAccess,
  JWT_SECRET,
  JWT_REFRESH_SECRET,
};
