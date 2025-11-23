const { query, getClient } = require('../config/postgres');
const { APIError, asyncHandler } = require('../middleware/errorHandler');
const logger = require('../utils/logger');

/**
 * Calculate health score based on metrics
 */
function calculateHealthScore(sleepHours, waterIntakeMl, exerciseMinutes) {
  let score = 0;

  // Sleep score (0-40 points)
  if (sleepHours >= 7 && sleepHours <= 9) {
    score += 40;
  } else if (sleepHours >= 6 && sleepHours < 7) {
    score += 30;
  } else if (sleepHours >= 5 && sleepHours < 6) {
    score += 20;
  } else if (sleepHours > 0) {
    score += 10;
  }

  // Water intake score (0-30 points)
  if (waterIntakeMl >= 2000) {
    score += 30;
  } else if (waterIntakeMl >= 1500) {
    score += 25;
  } else if (waterIntakeMl >= 1000) {
    score += 20;
  } else if (waterIntakeMl >= 500) {
    score += 10;
  } else if (waterIntakeMl > 0) {
    score += 5;
  }

  // Exercise score (0-30 points)
  if (exerciseMinutes >= 60) {
    score += 30;
  } else if (exerciseMinutes >= 30) {
    score += 25;
  } else if (exerciseMinutes >= 15) {
    score += 20;
  } else if (exerciseMinutes > 0) {
    score += 10;
  }

  return Math.min(100, score);
}

/**
 * Get health records for current user
 */
const getHealthRecords = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { startDate, endDate, limit = 30, offset = 0 } = req.query;

  let queryText = `
    SELECT *
    FROM health_records
    WHERE user_id = $1
  `;

  const params = [userId];
  let paramCount = 2;

  if (startDate) {
    queryText += ` AND record_date >= $${paramCount++}`;
    params.push(startDate);
  }

  if (endDate) {
    queryText += ` AND record_date <= $${paramCount++}`;
    params.push(endDate);
  }

  queryText += ` ORDER BY record_date DESC LIMIT $${paramCount++} OFFSET $${paramCount}`;
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
 * Get today's health record
 */
const getTodayHealthRecord = asyncHandler(async (req, res) => {
  const userId = req.user.id;

  const result = await query(
    `SELECT *
     FROM health_records
     WHERE user_id = $1 AND record_date = CURRENT_DATE`,
    [userId]
  );

  if (result.rows.length === 0) {
    return res.json({
      success: true,
      data: null,
      message: 'No health record for today yet',
    });
  }

  res.json({
    success: true,
    data: result.rows[0],
  });
});

/**
 * Get single health record
 */
const getHealthRecord = asyncHandler(async (req, res) => {
  const { date } = req.params;
  const userId = req.user.id;

  const result = await query(
    'SELECT * FROM health_records WHERE user_id = $1 AND record_date = $2',
    [userId, date]
  );

  if (result.rows.length === 0) {
    throw new APIError(404, 'Health record not found');
  }

  res.json({
    success: true,
    data: result.rows[0],
  });
});

/**
 * Create or update health record
 */
const upsertHealthRecord = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const {
    recordDate,
    sleepHours,
    waterIntakeMl,
    exerciseMinutes,
    mood,
    notes,
  } = req.body;

  // Validation
  const targetDate = recordDate || new Date().toISOString().split('T')[0];

  if (sleepHours !== undefined && (sleepHours < 0 || sleepHours > 24)) {
    throw new APIError(400, 'Sleep hours must be between 0 and 24');
  }

  if (waterIntakeMl !== undefined && waterIntakeMl < 0) {
    throw new APIError(400, 'Water intake must be non-negative');
  }

  if (exerciseMinutes !== undefined && exerciseMinutes < 0) {
    throw new APIError(400, 'Exercise minutes must be non-negative');
  }

  const validMoods = ['great', 'good', 'normal', 'bad', 'terrible'];
  if (mood && !validMoods.includes(mood)) {
    throw new APIError(400, `Mood must be one of: ${validMoods.join(', ')}`);
  }

  // Calculate health score
  const healthScore = calculateHealthScore(
    sleepHours || 0,
    waterIntakeMl || 0,
    exerciseMinutes || 0
  );

  // Upsert health record
  const result = await query(
    `INSERT INTO health_records
      (user_id, record_date, sleep_hours, water_intake_ml, exercise_minutes, mood, notes, health_score)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
     ON CONFLICT (user_id, record_date)
     DO UPDATE SET
       sleep_hours = COALESCE($3, health_records.sleep_hours),
       water_intake_ml = COALESCE($4, health_records.water_intake_ml),
       exercise_minutes = COALESCE($5, health_records.exercise_minutes),
       mood = COALESCE($6, health_records.mood),
       notes = COALESCE($7, health_records.notes),
       health_score = $8,
       updated_at = CURRENT_TIMESTAMP
     RETURNING *`,
    [userId, targetDate, sleepHours, waterIntakeMl, exerciseMinutes, mood, notes, healthScore]
  );

  logger.info(`Health record upserted for date: ${targetDate} (user: ${req.user.username})`);

  res.json({
    success: true,
    data: result.rows[0],
    message: 'Health record saved successfully',
  });
});

/**
 * Delete health record
 */
const deleteHealthRecord = asyncHandler(async (req, res) => {
  const { date } = req.params;
  const userId = req.user.id;

  const result = await query(
    'DELETE FROM health_records WHERE user_id = $1 AND record_date = $2 RETURNING id',
    [userId, date]
  );

  if (result.rows.length === 0) {
    throw new APIError(404, 'Health record not found');
  }

  logger.info(`Health record deleted for date: ${date} (user: ${req.user.username})`);

  res.json({
    success: true,
    message: 'Health record deleted successfully',
  });
});

/**
 * Get health statistics
 */
const getHealthStatistics = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { period = 'week' } = req.query;

  let dateFilter;
  switch (period) {
    case 'week':
      dateFilter = "record_date >= CURRENT_DATE - INTERVAL '7 days'";
      break;
    case 'month':
      dateFilter = "record_date >= CURRENT_DATE - INTERVAL '30 days'";
      break;
    case 'year':
      dateFilter = "record_date >= CURRENT_DATE - INTERVAL '365 days'";
      break;
    default:
      dateFilter = "record_date >= CURRENT_DATE - INTERVAL '7 days'";
  }

  const result = await query(
    `SELECT
       COUNT(*) as total_records,
       ROUND(AVG(health_score), 2) as avg_health_score,
       ROUND(AVG(sleep_hours), 2) as avg_sleep_hours,
       ROUND(AVG(water_intake_ml), 0) as avg_water_intake,
       ROUND(AVG(exercise_minutes), 0) as avg_exercise_minutes,
       COUNT(*) FILTER (WHERE mood = 'great') as great_mood_days,
       COUNT(*) FILTER (WHERE mood = 'good') as good_mood_days,
       COUNT(*) FILTER (WHERE mood = 'normal') as normal_mood_days,
       COUNT(*) FILTER (WHERE mood = 'bad') as bad_mood_days,
       COUNT(*) FILTER (WHERE mood = 'terrible') as terrible_mood_days
     FROM health_records
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

/**
 * Get health trends (daily data for charts)
 */
const getHealthTrends = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { days = 7 } = req.query;

  const result = await query(
    `SELECT
       record_date,
       health_score,
       sleep_hours,
       water_intake_ml,
       exercise_minutes,
       mood
     FROM health_records
     WHERE user_id = $1
       AND record_date >= CURRENT_DATE - INTERVAL '${parseInt(days)} days'
     ORDER BY record_date ASC`,
    [userId]
  );

  res.json({
    success: true,
    data: {
      days: parseInt(days),
      trends: result.rows,
    },
  });
});

module.exports = {
  getHealthRecords,
  getTodayHealthRecord,
  getHealthRecord,
  upsertHealthRecord,
  deleteHealthRecord,
  getHealthStatistics,
  getHealthTrends,
};
