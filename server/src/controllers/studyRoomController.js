const { query, getClient } = require('../config/postgres');
const { APIError, asyncHandler } = require('../middleware/errorHandler');
const {
  setStudyRoomState,
  getStudyRoomState,
  deleteStudyRoomState,
  addToMatchingQueue,
  removeFromMatchingQueue,
  getMatchingQueue,
} = require('../config/redis');
const logger = require('../utils/logger');

/**
 * Generate unique room code
 */
function generateRoomCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = '';
  for (let i = 0; i < 8; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

/**
 * Calculate matching score between two users
 * Time overlap: 40%, Task similarity: 30%, Completion rate: 20%, Profile: 10%
 */
function calculateMatchingScore(user1, user2) {
  let score = 0;

  // Time overlap (40 points)
  const time1Start = new Date(user1.scheduledStartTime);
  const time1End = new Date(user1.scheduledEndTime);
  const time2Start = new Date(user2.scheduledStartTime);
  const time2End = new Date(user2.scheduledEndTime);

  const overlapStart = Math.max(time1Start.getTime(), time2Start.getTime());
  const overlapEnd = Math.min(time1End.getTime(), time2End.getTime());
  const overlap = Math.max(0, overlapEnd - overlapStart) / (1000 * 60); // minutes

  const duration1 = (time1End.getTime() - time1Start.getTime()) / (1000 * 60);
  const duration2 = (time2End.getTime() - time2Start.getTime()) / (1000 * 60);
  const avgDuration = (duration1 + duration2) / 2;

  const timeScore = (overlap / avgDuration) * 40;
  score += timeScore;

  // Task similarity (30 points) - same category
  if (user1.taskCategory && user2.taskCategory && user1.taskCategory === user2.taskCategory) {
    score += 30;
  } else if (user1.taskCategory && user2.taskCategory) {
    score += 15; // Different categories but both have tasks
  }

  // Completion rate similarity (20 points)
  const rate1 = user1.completionRate || 0;
  const rate2 = user2.completionRate || 0;
  const rateDiff = Math.abs(rate1 - rate2);
  const rateScore = Math.max(0, 20 - rateDiff / 5);
  score += rateScore;

  // Profile similarity (10 points) - similar focus levels
  const level1 = user1.totalFocusHours || 0;
  const level2 = user2.totalFocusHours || 0;
  const levelDiff = Math.abs(level1 - level2);
  const profileScore = Math.max(0, 10 - levelDiff / 10);
  score += profileScore;

  return Math.min(100, Math.round(score));
}

/**
 * Calculate exit penalty based on remaining time
 */
function calculateExitPenalty(remainingMinutes) {
  if (remainingMinutes <= 5) {
    return 0; // No penalty for last 5 minutes
  } else if (remainingMinutes <= 15) {
    return 5; // 5 minutes penalty
  } else if (remainingMinutes <= 30) {
    return 15; // 15 minutes penalty
  } else {
    return 30; // 30 minutes penalty
  }
}

/**
 * Get all study rooms
 */
const getStudyRooms = asyncHandler(async (req, res) => {
  const { status, roomType, limit = 20, offset = 0 } = req.query;

  let queryText = `
    SELECT sr.*,
           u.username as creator_username,
           u.nickname as creator_nickname,
           (SELECT COUNT(*) FROM study_room_participants WHERE room_id = sr.id) as participant_count
    FROM study_rooms sr
    JOIN users u ON sr.creator_id = u.id
    WHERE 1=1
  `;

  const params = [];
  let paramCount = 1;

  if (status) {
    queryText += ` AND sr.status = $${paramCount++}`;
    params.push(status);
  }

  if (roomType) {
    queryText += ` AND sr.room_type = $${paramCount++}`;
    params.push(roomType);
  }

  queryText += ` ORDER BY sr.created_at DESC LIMIT $${paramCount++} OFFSET $${paramCount}`;
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
 * Get single study room
 */
const getStudyRoom = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const roomResult = await query(
    `SELECT sr.*,
            u.username as creator_username,
            u.nickname as creator_nickname,
            u.avatar_url as creator_avatar
     FROM study_rooms sr
     JOIN users u ON sr.creator_id = u.id
     WHERE sr.id = $1`,
    [id]
  );

  if (roomResult.rows.length === 0) {
    throw new APIError(404, 'Study room not found');
  }

  const room = roomResult.rows[0];

  // Get participants
  const participantsResult = await query(
    `SELECT srp.*,
            u.username,
            u.nickname,
            u.avatar_url,
            u.total_focus_minutes,
            u.current_streak
     FROM study_room_participants srp
     JOIN users u ON srp.user_id = u.id
     WHERE srp.room_id = $1
     ORDER BY srp.joined_at ASC`,
    [id]
  );

  room.participants = participantsResult.rows;

  res.json({
    success: true,
    data: room,
  });
});

/**
 * Create study room
 */
const createStudyRoom = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const {
    name,
    description,
    durationMinutes,
    scheduledStartTime,
    maxParticipants = 4,
    taskCategory,
  } = req.body;

  // Validation
  if (!durationMinutes || durationMinutes < 15) {
    throw new APIError(400, 'Duration must be at least 15 minutes');
  }

  if (maxParticipants < 2 || maxParticipants > 10) {
    throw new APIError(400, 'Max participants must be between 2 and 10');
  }

  if (!scheduledStartTime) {
    throw new APIError(400, 'Scheduled start time is required');
  }

  const startTime = new Date(scheduledStartTime);
  const endTime = new Date(startTime.getTime() + durationMinutes * 60000);

  // Generate unique room code
  let roomCode;
  let codeExists = true;
  let attempts = 0;

  while (codeExists && attempts < 10) {
    roomCode = generateRoomCode();
    const existing = await query('SELECT id FROM study_rooms WHERE room_code = $1', [roomCode]);
    codeExists = existing.rows.length > 0;
    attempts++;
  }

  if (codeExists) {
    throw new APIError(500, 'Failed to generate unique room code');
  }

  const client = await getClient();

  try {
    await client.query('BEGIN');

    // Get user stats for matching criteria
    const userStats = await client.query(
      `SELECT total_completed_tasks, total_study_sessions, total_focus_hours
       FROM users WHERE id = $1`,
      [userId]
    );

    const stats = userStats.rows[0];
    const completionRate = stats.total_study_sessions > 0
      ? (stats.total_completed_tasks / stats.total_study_sessions) * 100
      : 0;

    const matchingCriteria = {
      taskCategory,
      completionRate: completionRate.toFixed(2),
      totalFocusHours: parseFloat(stats.total_focus_hours),
      scheduledStartTime: startTime.toISOString(),
      scheduledEndTime: endTime.toISOString(),
    };

    // Create study room
    const roomResult = await client.query(
      `INSERT INTO study_rooms
        (room_code, creator_id, name, description, room_type, max_participants,
         duration_minutes, scheduled_start_time, scheduled_end_time, matching_criteria)
       VALUES ($1, $2, $3, $4, 'created', $5, $6, $7, $8, $9)
       RETURNING *`,
      [roomCode, userId, name, description, maxParticipants, durationMinutes, startTime, endTime, matchingCriteria]
    );

    const room = roomResult.rows[0];

    // Add creator as participant
    await client.query(
      `INSERT INTO study_room_participants (room_id, user_id, role, status)
       VALUES ($1, $2, 'creator', 'joined')`,
      [room.id, userId]
    );

    await client.query('COMMIT');

    // Cache room state in Redis
    await setStudyRoomState(room.id, {
      status: 'waiting',
      participants: [userId],
      createdAt: new Date().toISOString(),
    });

    logger.info(`Study room created: ${roomCode} (creator: ${req.user.username})`);

    res.status(201).json({
      success: true,
      data: room,
      message: 'Study room created successfully',
    });
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
});

/**
 * Join study room
 */
const joinStudyRoom = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  const client = await getClient();

  try {
    await client.query('BEGIN');

    // Get study room
    const roomResult = await client.query(
      `SELECT * FROM study_rooms WHERE id = $1`,
      [id]
    );

    if (roomResult.rows.length === 0) {
      throw new APIError(404, 'Study room not found');
    }

    const room = roomResult.rows[0];

    // Check if room is joinable
    if (room.status !== 'waiting') {
      throw new APIError(400, 'Study room is not accepting new participants');
    }

    if (room.current_participants >= room.max_participants) {
      throw new APIError(400, 'Study room is full');
    }

    // Check if user already in room
    const existingParticipant = await client.query(
      'SELECT id FROM study_room_participants WHERE room_id = $1 AND user_id = $2',
      [id, userId]
    );

    if (existingParticipant.rows.length > 0) {
      throw new APIError(400, 'You are already in this study room');
    }

    // Add participant
    await client.query(
      `INSERT INTO study_room_participants (room_id, user_id, status)
       VALUES ($1, $2, 'joined')`,
      [id, userId]
    );

    // Update room participant count
    await client.query(
      `UPDATE study_rooms
       SET current_participants = current_participants + 1
       WHERE id = $1`,
      [id]
    );

    // Create join event
    await client.query(
      `INSERT INTO study_room_events (room_id, user_id, event_type, event_data)
       VALUES ($1, $2, 'user_joined', $3)`,
      [id, userId, JSON.stringify({ username: req.user.username, timestamp: new Date().toISOString() })]
    );

    await client.query('COMMIT');

    logger.info(`User joined study room: ${room.room_code} (user: ${req.user.username})`);

    res.json({
      success: true,
      message: 'Successfully joined study room',
    });
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
});

/**
 * Leave study room
 */
const leaveStudyRoom = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;
  const { reason = 'left' } = req.body;

  const client = await getClient();

  try {
    await client.query('BEGIN');

    // Get study room
    const roomResult = await client.query(
      `SELECT * FROM study_rooms WHERE id = $1`,
      [id]
    );

    if (roomResult.rows.length === 0) {
      throw new APIError(404, 'Study room not found');
    }

    const room = roomResult.rows[0];

    // Get participant
    const participantResult = await client.query(
      `SELECT * FROM study_room_participants
       WHERE room_id = $1 AND user_id = $2 AND status != 'left'`,
      [id, userId]
    );

    if (participantResult.rows.length === 0) {
      throw new APIError(404, 'You are not in this study room');
    }

    const participant = participantResult.rows[0];

    // Calculate penalty if leaving early
    let penalty = 0;
    let leftEarly = false;

    if (room.status === 'active') {
      const now = new Date();
      const endTime = new Date(room.scheduled_end_time);
      const remainingMinutes = Math.max(0, (endTime.getTime() - now.getTime()) / (1000 * 60));

      penalty = calculateExitPenalty(remainingMinutes);
      leftEarly = remainingMinutes > 5;
    }

    // Update participant status
    await client.query(
      `UPDATE study_room_participants
       SET status = 'left',
           left_at = CURRENT_TIMESTAMP,
           left_early = $1,
           penalty_minutes = $2
       WHERE id = $3`,
      [leftEarly, penalty, participant.id]
    );

    // Update room participant count
    await client.query(
      `UPDATE study_rooms
       SET current_participants = GREATEST(0, current_participants - 1)
       WHERE id = $1`,
      [id]
    );

    // Create leave event
    await client.query(
      `INSERT INTO study_room_events (room_id, user_id, event_type, event_data)
       VALUES ($1, $2, 'user_left', $3)`,
      [
        id,
        userId,
        JSON.stringify({
          username: req.user.username,
          reason,
          leftEarly,
          penalty,
          timestamp: new Date().toISOString(),
        }),
      ]
    );

    await client.query('COMMIT');

    logger.info(`User left study room: ${room.room_code} (user: ${req.user.username}, penalty: ${penalty}min)`);

    res.json({
      success: true,
      data: {
        leftEarly,
        penaltyMinutes: penalty,
      },
      message: leftEarly
        ? `You left early. Penalty: ${penalty} minutes`
        : 'Successfully left study room',
    });
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
});

/**
 * Update participant energy level
 */
const updateEnergyLevel = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;
  const { energyLevel, focusState } = req.body;

  // Validation
  if (energyLevel !== undefined && (energyLevel < 0 || energyLevel > 100)) {
    throw new APIError(400, 'Energy level must be between 0 and 100');
  }

  const validFocusStates = ['focused', 'break', 'distracted'];
  if (focusState && !validFocusStates.includes(focusState)) {
    throw new APIError(400, `Focus state must be one of: ${validFocusStates.join(', ')}`);
  }

  const updates = [];
  const values = [];
  let paramCount = 1;

  if (energyLevel !== undefined) {
    updates.push(`energy_level = $${paramCount++}`);
    values.push(energyLevel);
  }

  if (focusState) {
    updates.push(`focus_state = $${paramCount++}`);
    values.push(focusState);
  }

  if (updates.length === 0) {
    throw new APIError(400, 'No fields to update');
  }

  values.push(id, userId);

  const result = await query(
    `UPDATE study_room_participants
     SET ${updates.join(', ')}
     WHERE room_id = $${paramCount++} AND user_id = $${paramCount}
     RETURNING *`,
    values
  );

  if (result.rows.length === 0) {
    throw new APIError(404, 'Participant not found in study room');
  }

  // Create energy update event
  await query(
    `INSERT INTO study_room_events (room_id, user_id, event_type, event_data)
     VALUES ($1, $2, 'energy_updated', $3)`,
    [id, userId, JSON.stringify({ energyLevel, focusState, timestamp: new Date().toISOString() })]
  );

  res.json({
    success: true,
    data: result.rows[0],
    message: 'Energy level updated successfully',
  });
});

/**
 * Start study room session
 */
const startStudyRoom = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.user.id;

  const client = await getClient();

  try {
    await client.query('BEGIN');

    // Get study room
    const roomResult = await client.query(
      'SELECT * FROM study_rooms WHERE id = $1 AND creator_id = $2',
      [id, userId]
    );

    if (roomResult.rows.length === 0) {
      throw new APIError(404, 'Study room not found or you are not the creator');
    }

    const room = roomResult.rows[0];

    if (room.status !== 'waiting') {
      throw new APIError(400, 'Study room has already started or completed');
    }

    // Update room status
    await client.query(
      `UPDATE study_rooms
       SET status = 'active',
           started_at = CURRENT_TIMESTAMP
       WHERE id = $1`,
      [id]
    );

    // Update all participants to active
    await client.query(
      `UPDATE study_room_participants
       SET status = 'active'
       WHERE room_id = $1 AND status = 'joined'`,
      [id]
    );

    await client.query('COMMIT');

    logger.info(`Study room started: ${room.room_code} (creator: ${req.user.username})`);

    res.json({
      success: true,
      message: 'Study room session started',
    });
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
});

/**
 * Get user's study rooms
 */
const getMyStudyRooms = asyncHandler(async (req, res) => {
  const userId = req.user.id;
  const { status } = req.query;

  let queryText = `
    SELECT DISTINCT sr.*,
           u.username as creator_username,
           u.nickname as creator_nickname,
           srp.role,
           srp.status as participant_status,
           srp.joined_at
    FROM study_rooms sr
    JOIN users u ON sr.creator_id = u.id
    JOIN study_room_participants srp ON sr.id = srp.room_id
    WHERE srp.user_id = $1
  `;

  const params = [userId];
  let paramCount = 2;

  if (status) {
    queryText += ` AND sr.status = $${paramCount++}`;
    params.push(status);
  }

  queryText += ` ORDER BY sr.created_at DESC`;

  const result = await query(queryText, params);

  res.json({
    success: true,
    data: result.rows,
  });
});

module.exports = {
  getStudyRooms,
  getStudyRoom,
  createStudyRoom,
  joinStudyRoom,
  leaveStudyRoom,
  updateEnergyLevel,
  startStudyRoom,
  getMyStudyRooms,
};
