const { query, getClient } = require('../config/postgres');
const { APIError, asyncHandler } = require('../middleware/errorHandler');
const logger = require('../utils/logger');

/**
 * Get all focus sessions for current user
 */
const getFocusSessions = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { status, limit = 50, offset = 0, startDate, endDate } = req.query;

  let queryText = `
    SELECT fs.*, t.title as task_title, sr.room_code as study_room_code
    FROM focus_sessions fs
    LEFT JOIN tasks t ON fs.task_id = t.id
    LEFT JOIN study_rooms sr ON fs.study_room_id = sr.id
    WHERE fs.user_id = $1
  `;

  const params = [userId];
  let paramCount = 2;

  if (status) {
    queryText += ` AND fs.status = $${paramCount++}`;
    params.push(status);
  }

  if (startDate) {
    queryText += ` AND fs.started_at >= $${paramCount++}`;
    params.push(startDate);
  }

  if (endDate) {
    queryText += ` AND fs.started_at <= $${paramCount++}`;
    params.push(endDate);
  }

  queryText += ` ORDER BY fs.started_at DESC LIMIT $${paramCount++} OFFSET $${paramCount}`;
  params.push(parseInt(limit), parseInt(offset));

  const result = await query(queryText, params);

  res.json({
    success: true,
    data: result.rows,
    pagination: {
      limit: parseInt(limit),
      offset: parseInt(offset),
      total: result.rows.length,
    },
  });
});

/**
 * Get today's focus sessions
 */
const getTodayFocusSessions = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  const result = await query(
    `SELECT fs.*, t.title as task_title
     FROM focus_sessions fs
     LEFT JOIN tasks t ON fs.task_id = t.id
     WHERE fs.user_id = $1
       AND fs.started_at >= CURRENT_DATE
       AND fs.started_at < CURRENT_DATE + INTERVAL '1 day'
     ORDER BY fs.started_at DESC`,
    [userId]
  );

  // Calculate total focus minutes today
  const totalMinutes = result.rows
    .filter(session => session.is_completed)
    .reduce((sum, session) => sum + (session.actual_duration_minutes || 0), 0);

  res.json({
    success: true,
    data: {
      sessions: result.rows,
      totalFocusMinutes: totalMinutes,
      completedSessions: result.rows.filter(s => s.is_completed).length,
      totalSessions: result.rows.length,
    },
  });
});

/**
 * Get single focus session
 */
const getFocusSession = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  const result = await query(
    `SELECT fs.*, t.title as task_title, t.category as task_category,
            sr.room_code, sr.name as study_room_name
     FROM focus_sessions fs
     LEFT JOIN tasks t ON fs.task_id = t.id
     LEFT JOIN study_rooms sr ON fs.study_room_id = sr.id
     WHERE fs.id = $1 AND fs.user_id = $2`,
    [id, userId]
  );

  if (result.rows.length === 0) {
    throw new APIError(404, 'Focus session not found');
  }

  res.json({
    success: true,
    data: result.rows[0],
  });
});

/**
 * Start new focus session
 */
const startFocusSession = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const {
    taskId,
    studyRoomId,
    durationMinutes,
    focusMode = 'pomodoro',
  } = req.body;

  // Validation
  if (!durationMinutes || durationMinutes <= 0) {
    throw new APIError(400, 'Duration minutes must be greater than 0');
  }

  const validFocusModes = ['pomodoro', 'custom', 'deep_work'];
  if (!validFocusModes.includes(focusMode)) {
    throw new APIError(400, `Focus mode must be one of: ${validFocusModes.join(', ')}`);
  }

  // Verify task belongs to user if taskId provided
  if (taskId) {
    const taskResult = await query(
      'SELECT id FROM tasks WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL',
      [taskId, userId]
    );

    if (taskResult.rows.length === 0) {
      throw new APIError(404, 'Task not found');
    }
  }

  // Create focus session
  const result = await query(
    `INSERT INTO focus_sessions
      (user_id, task_id, study_room_id, duration_minutes, focus_mode, status, started_at)
     VALUES ($1, $2, $3, $4, $5, 'active', CURRENT_TIMESTAMP)
     RETURNING *`,
    [userId, taskId || null, studyRoomId || null, durationMinutes, focusMode]
  );

  logger.info(`Focus session started: ${result.rows[0].id} (user: ${req.user.username}, duration: ${durationMinutes}min)`);

  res.status(201).json({
    success: true,
    data: result.rows[0],
    message: 'Focus session started successfully',
  });
});

/**
 * Complete focus session
 */
const completeFocusSession = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;
  const { actualDurationMinutes, interruptionCount = 0 } = req.body;

  const client = await getClient();

  try {
    await client.query('BEGIN');

    // Get focus session
    const sessionResult = await client.query(
      'SELECT * FROM focus_sessions WHERE id = $1 AND user_id = $2',
      [id, userId]
    );

    if (sessionResult.rows.length === 0) {
      throw new APIError(404, 'Focus session not found');
    }

    const session = sessionResult.rows[0];

    if (session.status !== 'active') {
      throw new APIError(400, 'Focus session is not active');
    }

    // Update focus session
    const updateResult = await client.query(
      `UPDATE focus_sessions
       SET status = 'completed',
           is_completed = true,
           actual_duration_minutes = $1,
           interruption_count = $2,
           completed_at = CURRENT_TIMESTAMP
       WHERE id = $3
       RETURNING *`,
      [actualDurationMinutes || session.duration_minutes, interruptionCount, id]
    );

    const completedSession = updateResult.rows[0];

    // Update user statistics
    await client.query(
      `UPDATE users
       SET total_focus_minutes = total_focus_minutes + $1,
           total_study_sessions = total_study_sessions + 1,
           total_focus_sessions = total_focus_sessions + 1,
           total_focus_hours = total_focus_hours + $2
       WHERE id = $3`,
      [
        completedSession.actual_duration_minutes,
        (completedSession.actual_duration_minutes / 60).toFixed(2),
        userId
      ]
    );

    // Update task if associated
    if (session.task_id) {
      await client.query(
        `UPDATE tasks
         SET actual_pomodoros = actual_pomodoros + 1
         WHERE id = $1`,
        [session.task_id]
      );
    }

    // Check and update study room eligibility
    const userStats = await client.query(
      `SELECT days_since_registration, total_focus_sessions, total_focus_hours
       FROM users WHERE id = $1`,
      [userId]
    );

    const stats = userStats.rows[0];
    const hasMinDays = stats.days_since_registration >= 3;
    const hasMinSessions = stats.total_focus_sessions >= 5;
    const hasMinHours = parseFloat(stats.total_focus_hours) >= 3;

    if (hasMinDays && (hasMinSessions || hasMinHours)) {
      await client.query(
        'UPDATE users SET can_create_study_room = true WHERE id = $1',
        [userId]
      );
    }

    await client.query('COMMIT');

    logger.info(`Focus session completed: ${id} (user: ${req.user.username}, duration: ${completedSession.actual_duration_minutes}min)`);

    res.json({
      success: true,
      data: completedSession,
      message: 'Focus session completed successfully',
    });
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
});

/**
 * Cancel/interrupt focus session
 */
const cancelFocusSession = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;
  const { reason = 'cancelled' } = req.body;

  const result = await query(
    `UPDATE focus_sessions
     SET status = $1,
         completed_at = CURRENT_TIMESTAMP
     WHERE id = $2 AND user_id = $3 AND status = 'active'
     RETURNING *`,
    [reason, id, userId]
  );

  if (result.rows.length === 0) {
    throw new APIError(404, 'Active focus session not found');
  }

  logger.info(`Focus session cancelled: ${id} (user: ${req.user.username}, reason: ${reason})`);

  res.json({
    success: true,
    data: result.rows[0],
    message: 'Focus session cancelled',
  });
});

/**
 * Get focus statistics
 */
const getFocusStatistics = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { period = 'week' } = req.query;

  let dateFilter;
  switch (period) {
    case 'day':
      dateFilter = "started_at >= CURRENT_DATE";
      break;
    case 'week':
      dateFilter = "started_at >= CURRENT_DATE - INTERVAL '7 days'";
      break;
    case 'month':
      dateFilter = "started_at >= CURRENT_DATE - INTERVAL '30 days'";
      break;
    case 'year':
      dateFilter = "started_at >= CURRENT_DATE - INTERVAL '365 days'";
      break;
    default:
      dateFilter = "started_at >= CURRENT_DATE - INTERVAL '7 days'";
  }

  const result = await query(
    `SELECT
       COUNT(*) FILTER (WHERE is_completed = true) as completed_sessions,
       COUNT(*) as total_sessions,
       SUM(actual_duration_minutes) FILTER (WHERE is_completed = true) as total_focus_minutes,
       ROUND(AVG(actual_duration_minutes) FILTER (WHERE is_completed = true), 2) as avg_session_duration,
       SUM(interruption_count) as total_interruptions,
       COUNT(*) FILTER (WHERE focus_mode = 'pomodoro') as pomodoro_count,
       COUNT(*) FILTER (WHERE focus_mode = 'deep_work') as deep_work_count
     FROM focus_sessions
     WHERE user_id = $1 AND ${dateFilter}`,
    [userId]
  );

  res.json({
    success: true,
    data: {
      period,
      statistics: result.rows[0],
    },
  });
});

module.exports = {
  getFocusSessions,
  getTodayFocusSessions,
  getFocusSession,
  startFocusSession,
  completeFocusSession,
  cancelFocusSession,
  getFocusStatistics,
};
