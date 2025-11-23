const bcrypt = require('bcryptjs');
const { query, getClient } = require('../config/postgres');
const { APIError, asyncHandler } = require('../middleware/errorHandler');
const {
  generateAccessToken,
  generateRefreshToken,
  verifyToken,
  JWT_REFRESH_SECRET,
} = require('../middleware/auth');
const logger = require('../utils/logger');

/**
 * Register new user
 */
const register = asyncHandler(async (req, res) => {
  const { username, email, password, nickname } = req.body;

  // Validation
  if (!username || !email || !password) {
    throw new APIError(400, 'Username, email, and password are required');
  }

  if (password.length < 6) {
    throw new APIError(400, 'Password must be at least 6 characters long');
  }

  // Email validation
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    throw new APIError(400, 'Invalid email format');
  }

  // Username validation (alphanumeric and underscore only)
  const usernameRegex = /^[a-zA-Z0-9_]{3,50}$/;
  if (!usernameRegex.test(username)) {
    throw new APIError(400, 'Username must be 3-50 characters long and contain only letters, numbers, and underscores');
  }

  // Check if user already exists
  const existingUser = await query(
    'SELECT id FROM users WHERE email = $1 OR username = $2',
    [email, username]
  );

  if (existingUser.rows.length > 0) {
    throw new APIError(409, 'User with this email or username already exists');
  }

  // Hash password
  const salt = await bcrypt.genSalt(10);
  const passwordHash = await bcrypt.hash(password, salt);

  // Create user
  const result = await query(
    `INSERT INTO users (username, email, password_hash, nickname, created_at)
     VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
     RETURNING id, username, email, nickname, created_at`,
    [username, email, passwordHash, nickname || username]
  );

  const user = result.rows[0];

  // Generate tokens
  const accessToken = generateAccessToken(user.id, user.email);
  const refreshToken = generateRefreshToken(user.id, user.email);

  // Store refresh token in database
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days
  await query(
    'INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES ($1, $2, $3)',
    [user.id, refreshToken, expiresAt]
  );

  logger.info(`New user registered: ${user.username} (${user.email})`);

  res.status(201).json({
    success: true,
    data: {
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        nickname: user.nickname,
        createdAt: user.created_at,
      },
      tokens: {
        accessToken,
        refreshToken,
      },
    },
    message: 'User registered successfully',
  });
});

/**
 * Login user
 */
const login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  // Validation
  if (!email || !password) {
    throw new APIError(400, 'Email and password are required');
  }

  // Get user from database
  const result = await query(
    `SELECT id, username, email, password_hash, nickname, avatar_url, status, is_verified,
            total_focus_minutes, total_completed_tasks, current_streak
     FROM users WHERE email = $1`,
    [email]
  );

  if (result.rows.length === 0) {
    throw new APIError(401, 'Invalid email or password');
  }

  const user = result.rows[0];

  // Check if user is active
  if (user.status !== 'active') {
    throw new APIError(403, 'User account is not active');
  }

  // Verify password
  const isValidPassword = await bcrypt.compare(password, user.password_hash);

  if (!isValidPassword) {
    throw new APIError(401, 'Invalid email or password');
  }

  // Generate tokens
  const accessToken = generateAccessToken(user.id, user.email);
  const refreshToken = generateRefreshToken(user.id, user.email);

  // Store refresh token in database
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30 days
  await query(
    'INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES ($1, $2, $3)',
    [user.id, refreshToken, expiresAt]
  );

  // Update last login time
  await query(
    'UPDATE users SET last_login_at = CURRENT_TIMESTAMP WHERE id = $1',
    [user.id]
  );

  logger.info(`User logged in: ${user.username} (${user.email})`);

  res.json({
    success: true,
    data: {
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        nickname: user.nickname,
        avatarUrl: user.avatar_url,
        isVerified: user.is_verified,
        stats: {
          totalFocusMinutes: user.total_focus_minutes,
          totalCompletedTasks: user.total_completed_tasks,
          currentStreak: user.current_streak,
        },
      },
      tokens: {
        accessToken,
        refreshToken,
      },
    },
    message: 'Login successful',
  });
});

/**
 * Refresh access token
 */
const refreshAccessToken = asyncHandler(async (req, res) => {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    throw new APIError(400, 'Refresh token is required');
  }

  // Verify refresh token
  const decoded = verifyToken(refreshToken, JWT_REFRESH_SECRET);

  if (decoded.type !== 'refresh') {
    throw new APIError(401, 'Invalid token type');
  }

  // Check if refresh token exists in database and is not revoked
  const tokenResult = await query(
    'SELECT id, user_id, expires_at, revoked FROM refresh_tokens WHERE token = $1',
    [refreshToken]
  );

  if (tokenResult.rows.length === 0) {
    throw new APIError(401, 'Invalid refresh token');
  }

  const tokenData = tokenResult.rows[0];

  if (tokenData.revoked) {
    throw new APIError(401, 'Refresh token has been revoked');
  }

  if (new Date(tokenData.expires_at) < new Date()) {
    throw new APIError(401, 'Refresh token has expired');
  }

  // Get user
  const userResult = await query(
    'SELECT id, email, status FROM users WHERE id = $1',
    [tokenData.user_id]
  );

  if (userResult.rows.length === 0) {
    throw new APIError(401, 'User not found');
  }

  const user = userResult.rows[0];

  if (user.status !== 'active') {
    throw new APIError(403, 'User account is not active');
  }

  // Generate new access token
  const newAccessToken = generateAccessToken(user.id, user.email);

  res.json({
    success: true,
    data: {
      accessToken: newAccessToken,
    },
    message: 'Access token refreshed successfully',
  });
});

/**
 * Logout user - revoke refresh token
 */
const logout = asyncHandler(async (req, res) => {
  const { refreshToken } = req.body;

  if (refreshToken) {
    // Revoke refresh token
    await query(
      'UPDATE refresh_tokens SET revoked = true WHERE token = $1',
      [refreshToken]
    );
  }

  logger.info(`User logged out: ${req.user?.username || 'unknown'}`);

  res.json({
    success: true,
    message: 'Logout successful',
  });
});

/**
 * Get current user profile
 */
const getCurrentUser = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  const result = await query(
    `SELECT
      id, username, email, nickname, avatar_url, bio, phone,
      total_focus_minutes, total_completed_tasks, total_study_sessions,
      current_streak, longest_streak, is_verified,
      days_since_registration, total_focus_sessions, total_focus_hours,
      can_create_study_room, created_at, last_login_at
    FROM users WHERE id = $1`,
    [userId]
  );

  if (result.rows.length === 0) {
    throw new APIError(404, 'User not found');
  }

  const user = result.rows[0];

  res.json({
    success: true,
    data: {
      id: user.id,
      username: user.username,
      email: user.email,
      nickname: user.nickname,
      avatarUrl: user.avatar_url,
      bio: user.bio,
      phone: user.phone,
      isVerified: user.is_verified,
      stats: {
        totalFocusMinutes: user.total_focus_minutes,
        totalCompletedTasks: user.total_completed_tasks,
        totalStudySessions: user.total_study_sessions,
        currentStreak: user.current_streak,
        longestStreak: user.longest_streak,
      },
      studyRoomEligibility: {
        daysSinceRegistration: user.days_since_registration,
        totalFocusSessions: user.total_focus_sessions,
        totalFocusHours: parseFloat(user.total_focus_hours),
        canCreateStudyRoom: user.can_create_study_room,
      },
      createdAt: user.created_at,
      lastLoginAt: user.last_login_at,
    },
  });
});

/**
 * Update user profile
 */
const updateProfile = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { nickname, bio, avatarUrl } = req.body;

  const updates = [];
  const values = [];
  let paramCount = 1;

  if (nickname !== undefined) {
    updates.push(`nickname = $${paramCount++}`);
    values.push(nickname);
  }

  if (bio !== undefined) {
    updates.push(`bio = $${paramCount++}`);
    values.push(bio);
  }

  if (avatarUrl !== undefined) {
    updates.push(`avatar_url = $${paramCount++}`);
    values.push(avatarUrl);
  }

  if (updates.length === 0) {
    throw new APIError(400, 'No fields to update');
  }

  values.push(userId);

  const result = await query(
    `UPDATE users SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP
     WHERE id = $${paramCount}
     RETURNING id, username, email, nickname, avatar_url, bio`,
    values
  );

  if (result.rows.length === 0) {
    throw new APIError(404, 'User not found');
  }

  logger.info(`User profile updated: ${result.rows[0].username}`);

  res.json({
    success: true,
    data: result.rows[0],
    message: 'Profile updated successfully',
  });
});

/**
 * Change password
 */
const changePassword = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { currentPassword, newPassword } = req.body;

  if (!currentPassword || !newPassword) {
    throw new APIError(400, 'Current password and new password are required');
  }

  if (newPassword.length < 6) {
    throw new APIError(400, 'New password must be at least 6 characters long');
  }

  // Get current password hash
  const result = await query(
    'SELECT password_hash FROM users WHERE id = $1',
    [userId]
  );

  if (result.rows.length === 0) {
    throw new APIError(404, 'User not found');
  }

  // Verify current password
  const isValidPassword = await bcrypt.compare(currentPassword, result.rows[0].password_hash);

  if (!isValidPassword) {
    throw new APIError(401, 'Current password is incorrect');
  }

  // Hash new password
  const salt = await bcrypt.genSalt(10);
  const newPasswordHash = await bcrypt.hash(newPassword, salt);

  // Update password
  await query(
    'UPDATE users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2',
    [newPasswordHash, userId]
  );

  // Revoke all existing refresh tokens for security
  await query(
    'UPDATE refresh_tokens SET revoked = true WHERE user_id = $1',
    [userId]
  );

  logger.info(`Password changed for user: ${req.user.username}`);

  res.json({
    success: true,
    message: 'Password changed successfully. Please login again.',
  });
});

module.exports = {
  register,
  login,
  refreshAccessToken,
  logout,
  getCurrentUser,
  updateProfile,
  changePassword,
};
