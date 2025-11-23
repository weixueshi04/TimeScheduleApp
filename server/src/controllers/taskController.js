const { query, getClient } = require('../config/postgres');
const { APIError, asyncHandler } = require('../middleware/errorHandler');
const logger = require('../utils/logger');

/**
 * Get all tasks for current user
 */
const getTasks = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { status, category, priority, dueDate, limit = 100, offset = 0 } = req.query;

  let queryText = `
    SELECT id, user_id, title, description, category, priority, status,
           is_completed, due_date, completed_at, estimated_pomodoros,
           actual_pomodoros, created_at, updated_at
    FROM tasks
    WHERE user_id = $1 AND deleted_at IS NULL
  `;

  const params = [userId];
  let paramCount = 2;

  // Add filters
  if (status) {
    queryText += ` AND status = $${paramCount++}`;
    params.push(status);
  }

  if (category) {
    queryText += ` AND category = $${paramCount++}`;
    params.push(category);
  }

  if (priority) {
    queryText += ` AND priority = $${paramCount++}`;
    params.push(priority);
  }

  if (dueDate) {
    queryText += ` AND due_date = $${paramCount++}`;
    params.push(dueDate);
  }

  queryText += ` ORDER BY
    CASE priority
      WHEN 'urgent' THEN 1
      WHEN 'high' THEN 2
      WHEN 'medium' THEN 3
      WHEN 'low' THEN 4
    END,
    due_date ASC NULLS LAST,
    created_at DESC
    LIMIT $${paramCount++} OFFSET $${paramCount}
  `;

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
 * Get today's tasks
 */
const getTodayTasks = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  const result = await query(
    `SELECT id, title, description, category, priority, status, is_completed,
            due_date, estimated_pomodoros, actual_pomodoros, created_at
     FROM tasks
     WHERE user_id = $1
       AND deleted_at IS NULL
       AND (due_date = CURRENT_DATE OR (status = 'in_progress' AND due_date IS NULL))
     ORDER BY
       CASE priority
         WHEN 'urgent' THEN 1
         WHEN 'high' THEN 2
         WHEN 'medium' THEN 3
         WHEN 'low' THEN 4
       END,
       created_at DESC`,
    [userId]
  );

  res.json({
    success: true,
    data: result.rows,
  });
});

/**
 * Get single task
 */
const getTask = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  const result = await query(
    `SELECT * FROM tasks WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`,
    [id, userId]
  );

  if (result.rows.length === 0) {
    throw new APIError(404, 'Task not found');
  }

  res.json({
    success: true,
    data: result.rows[0],
  });
});

/**
 * Create new task
 */
const createTask = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const {
    title,
    description,
    category,
    priority = 'medium',
    dueDate,
    estimatedPomodoros = 1,
  } = req.body;

  // Validation
  if (!title || !category) {
    throw new APIError(400, 'Title and category are required');
  }

  const validCategories = ['work', 'study', 'life', 'health', 'other'];
  if (!validCategories.includes(category)) {
    throw new APIError(400, `Category must be one of: ${validCategories.join(', ')}`);
  }

  const validPriorities = ['low', 'medium', 'high', 'urgent'];
  if (!validPriorities.includes(priority)) {
    throw new APIError(400, `Priority must be one of: ${validPriorities.join(', ')}`);
  }

  const result = await query(
    `INSERT INTO tasks (user_id, title, description, category, priority, due_date, estimated_pomodoros)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING *`,
    [userId, title, description, category, priority, dueDate || null, estimatedPomodoros]
  );

  logger.info(`Task created: ${title} (user: ${req.user.username})`);

  res.status(201).json({
    success: true,
    data: result.rows[0],
    message: 'Task created successfully',
  });
});

/**
 * Update task
 */
const updateTask = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;
  const {
    title,
    description,
    category,
    priority,
    status,
    dueDate,
    estimatedPomodoros,
  } = req.body;

  // Check if task exists and belongs to user
  const existingTask = await query(
    'SELECT * FROM tasks WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL',
    [id, userId]
  );

  if (existingTask.rows.length === 0) {
    throw new APIError(404, 'Task not found');
  }

  const updates = [];
  const values = [];
  let paramCount = 1;

  if (title !== undefined) {
    updates.push(`title = $${paramCount++}`);
    values.push(title);
  }

  if (description !== undefined) {
    updates.push(`description = $${paramCount++}`);
    values.push(description);
  }

  if (category !== undefined) {
    const validCategories = ['work', 'study', 'life', 'health', 'other'];
    if (!validCategories.includes(category)) {
      throw new APIError(400, `Category must be one of: ${validCategories.join(', ')}`);
    }
    updates.push(`category = $${paramCount++}`);
    values.push(category);
  }

  if (priority !== undefined) {
    const validPriorities = ['low', 'medium', 'high', 'urgent'];
    if (!validPriorities.includes(priority)) {
      throw new APIError(400, `Priority must be one of: ${validPriorities.join(', ')}`);
    }
    updates.push(`priority = $${paramCount++}`);
    values.push(priority);
  }

  if (status !== undefined) {
    const validStatuses = ['pending', 'in_progress', 'completed', 'cancelled'];
    if (!validStatuses.includes(status)) {
      throw new APIError(400, `Status must be one of: ${validStatuses.join(', ')}`);
    }
    updates.push(`status = $${paramCount++}`);
    values.push(status);
  }

  if (dueDate !== undefined) {
    updates.push(`due_date = $${paramCount++}`);
    values.push(dueDate);
  }

  if (estimatedPomodoros !== undefined) {
    updates.push(`estimated_pomodoros = $${paramCount++}`);
    values.push(estimatedPomodoros);
  }

  if (updates.length === 0) {
    throw new APIError(400, 'No fields to update');
  }

  values.push(id, userId);

  const result = await query(
    `UPDATE tasks
     SET ${updates.join(', ')}, updated_at = CURRENT_TIMESTAMP
     WHERE id = $${paramCount++} AND user_id = $${paramCount}
     RETURNING *`,
    values
  );

  logger.info(`Task updated: ${id} (user: ${req.user.username})`);

  res.json({
    success: true,
    data: result.rows[0],
    message: 'Task updated successfully',
  });
});

/**
 * Complete task
 */
const completeTask = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;
  const { actualPomodoros } = req.body;

  const client = await getClient();

  try {
    await client.query('BEGIN');

    // Update task
    const result = await client.query(
      `UPDATE tasks
       SET status = 'completed',
           is_completed = true,
           completed_at = CURRENT_TIMESTAMP,
           actual_pomodoros = $1,
           updated_at = CURRENT_TIMESTAMP
       WHERE id = $2 AND user_id = $3 AND deleted_at IS NULL
       RETURNING *`,
      [actualPomodoros || 1, id, userId]
    );

    if (result.rows.length === 0) {
      throw new APIError(404, 'Task not found');
    }

    // Update user statistics
    await client.query(
      `UPDATE users
       SET total_completed_tasks = total_completed_tasks + 1
       WHERE id = $1`,
      [userId]
    );

    await client.query('COMMIT');

    logger.info(`Task completed: ${id} (user: ${req.user.username})`);

    res.json({
      success: true,
      data: result.rows[0],
      message: 'Task completed successfully',
    });
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
});

/**
 * Delete task (soft delete)
 */
const deleteTask = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  const result = await query(
    `UPDATE tasks
     SET deleted_at = CURRENT_TIMESTAMP
     WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
     RETURNING id`,
    [id, userId]
  );

  if (result.rows.length === 0) {
    throw new APIError(404, 'Task not found');
  }

  logger.info(`Task deleted: ${id} (user: ${req.user.username})`);

  res.json({
    success: true,
    message: 'Task deleted successfully',
  });
});

/**
 * Get task statistics
 */
const getTaskStatistics = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { period = 'week' } = req.query; // day, week, month, year

  let dateFilter;
  switch (period) {
    case 'day':
      dateFilter = "created_at >= CURRENT_DATE";
      break;
    case 'week':
      dateFilter = "created_at >= CURRENT_DATE - INTERVAL '7 days'";
      break;
    case 'month':
      dateFilter = "created_at >= CURRENT_DATE - INTERVAL '30 days'";
      break;
    case 'year':
      dateFilter = "created_at >= CURRENT_DATE - INTERVAL '365 days'";
      break;
    default:
      dateFilter = "created_at >= CURRENT_DATE - INTERVAL '7 days'";
  }

  const result = await query(
    `SELECT
       COUNT(*) FILTER (WHERE status = 'completed') as completed_count,
       COUNT(*) FILTER (WHERE status = 'pending') as pending_count,
       COUNT(*) FILTER (WHERE status = 'in_progress') as in_progress_count,
       COUNT(*) as total_count,
       COUNT(*) FILTER (WHERE category = 'work') as work_count,
       COUNT(*) FILTER (WHERE category = 'study') as study_count,
       COUNT(*) FILTER (WHERE category = 'life') as life_count,
       COUNT(*) FILTER (WHERE category = 'health') as health_count,
       COUNT(*) FILTER (WHERE category = 'other') as other_count
     FROM tasks
     WHERE user_id = $1 AND deleted_at IS NULL AND ${dateFilter}`,
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
  getTasks,
  getTodayTasks,
  getTask,
  createTask,
  updateTask,
  completeTask,
  deleteTask,
  getTaskStatistics,
};
