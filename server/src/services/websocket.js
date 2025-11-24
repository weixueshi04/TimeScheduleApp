const jwt = require('jsonwebtoken');
const { JWT_SECRET } = require('../middleware/auth');
const { query } = require('../config/postgres');
const {
  setUserOnline,
  setUserOffline,
  getUserOnlineStatus,
  getStudyRoomState,
  setStudyRoomState,
} = require('../config/redis');
const logger = require('../utils/logger');

/**
 * WebSocket event types
 */
const EVENT_TYPES = {
  // Connection events
  CONNECT: 'connect',
  DISCONNECT: 'disconnect',
  AUTHENTICATE: 'authenticate',
  AUTHENTICATED: 'authenticated',
  ERROR: 'error',

  // Study room events
  JOIN_ROOM: 'join_room',
  LEAVE_ROOM: 'leave_room',
  ROOM_JOINED: 'room_joined',
  ROOM_LEFT: 'room_left',
  USER_JOINED: 'user_joined',
  USER_LEFT: 'user_left',

  // Real-time updates
  ENERGY_UPDATE: 'energy_update',
  FOCUS_STATE_CHANGE: 'focus_state_change',
  ROOM_STATE_UPDATE: 'room_state_update',
  PARTICIPANT_UPDATE: 'participant_update',

  // Study session events
  SESSION_STARTED: 'session_started',
  SESSION_ENDED: 'session_ended',
  BREAK_STARTED: 'break_started',
  BREAK_ENDED: 'break_ended',

  // Chat events (for temporary rest room)
  CHAT_MESSAGE: 'chat_message',
  CHAT_HISTORY: 'chat_history',

  // Notifications
  NOTIFICATION: 'notification',
};

/**
 * Initialize WebSocket service
 */
function initializeWebSocket(io) {
  // Middleware for authentication
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.split(' ')[1];

      if (!token) {
        return next(new Error('Authentication token required'));
      }

      // Verify JWT token
      const decoded = jwt.verify(token, JWT_SECRET);

      if (decoded.type !== 'access') {
        return next(new Error('Invalid token type'));
      }

      // Get user from database
      const result = await query(
        'SELECT id, username, email, nickname, avatar_url, status FROM users WHERE id = $1',
        [decoded.id]
      );

      if (result.rows.length === 0) {
        return next(new Error('User not found'));
      }

      const user = result.rows[0];

      if (user.status !== 'active') {
        return next(new Error('User account is not active'));
      }

      // Attach user to socket
      socket.user = user;
      next();
    } catch (error) {
      logger.error('WebSocket authentication error:', error);
      next(new Error('Authentication failed'));
    }
  });

  // Handle connections
  io.on(EVENT_TYPES.CONNECT, (socket) => {
    const user = socket.user;
    logger.info(`WebSocket connected: ${user.username} (${socket.id})`);

    // Mark user as online
    setUserOnline(user.id, socket.id).catch(error => {
      logger.error('Error setting user online:', error);
    });

    // Send authenticated event
    socket.emit(EVENT_TYPES.AUTHENTICATED, {
      success: true,
      user: {
        id: user.id,
        username: user.username,
        nickname: user.nickname,
        avatarUrl: user.avatar_url,
      },
    });

    /**
     * Join study room
     */
    socket.on(EVENT_TYPES.JOIN_ROOM, async (data) => {
      try {
        const { roomId } = data;

        // Verify user is participant
        const participantResult = await query(
          `SELECT srp.*, sr.room_code, sr.status as room_status
           FROM study_room_participants srp
           JOIN study_rooms sr ON srp.room_id = sr.id
           WHERE srp.room_id = $1 AND srp.user_id = $2 AND srp.status != 'left'`,
          [roomId, user.id]
        );

        if (participantResult.rows.length === 0) {
          socket.emit(EVENT_TYPES.ERROR, {
            message: 'You are not a participant of this study room',
          });
          return;
        }

        const participant = participantResult.rows[0];

        // Join socket room
        socket.join(`room:${roomId}`);

        // Get current room state
        const roomState = await getStudyRoomState(roomId);

        // Notify user
        socket.emit(EVENT_TYPES.ROOM_JOINED, {
          success: true,
          roomId,
          roomCode: participant.room_code,
          participant,
          roomState,
        });

        // Notify other participants
        socket.to(`room:${roomId}`).emit(EVENT_TYPES.USER_JOINED, {
          userId: user.id,
          username: user.username,
          nickname: user.nickname,
          avatarUrl: user.avatar_url,
          timestamp: new Date().toISOString(),
        });

        logger.info(`User ${user.username} joined study room ${roomId} via WebSocket`);
      } catch (error) {
        logger.error('Error joining room:', error);
        socket.emit(EVENT_TYPES.ERROR, {
          message: 'Failed to join study room',
          error: error.message,
        });
      }
    });

    /**
     * Leave study room
     */
    socket.on(EVENT_TYPES.LEAVE_ROOM, async (data) => {
      try {
        const { roomId } = data;

        // Leave socket room
        socket.leave(`room:${roomId}`);

        // Notify user
        socket.emit(EVENT_TYPES.ROOM_LEFT, {
          success: true,
          roomId,
        });

        // Notify other participants
        socket.to(`room:${roomId}`).emit(EVENT_TYPES.USER_LEFT, {
          userId: user.id,
          username: user.username,
          timestamp: new Date().toISOString(),
        });

        logger.info(`User ${user.username} left study room ${roomId} via WebSocket`);
      } catch (error) {
        logger.error('Error leaving room:', error);
        socket.emit(EVENT_TYPES.ERROR, {
          message: 'Failed to leave study room',
          error: error.message,
        });
      }
    });

    /**
     * Update energy level
     */
    socket.on(EVENT_TYPES.ENERGY_UPDATE, async (data) => {
      try {
        const { roomId, energyLevel, focusState } = data;

        // Update in database
        await query(
          `UPDATE study_room_participants
           SET energy_level = $1,
               focus_state = $2
           WHERE room_id = $3 AND user_id = $4`,
          [energyLevel, focusState, roomId, user.id]
        );

        // Broadcast to room
        io.to(`room:${roomId}`).emit(EVENT_TYPES.ENERGY_UPDATE, {
          userId: user.id,
          username: user.username,
          energyLevel,
          focusState,
          timestamp: new Date().toISOString(),
        });

        // Log event
        await query(
          `INSERT INTO study_room_events (room_id, user_id, event_type, event_data)
           VALUES ($1, $2, 'energy_updated', $3)`,
          [roomId, user.id, JSON.stringify({ energyLevel, focusState })]
        );

        logger.debug(`Energy updated: user ${user.username}, room ${roomId}, energy ${energyLevel}`);
      } catch (error) {
        logger.error('Error updating energy:', error);
        socket.emit(EVENT_TYPES.ERROR, {
          message: 'Failed to update energy level',
          error: error.message,
        });
      }
    });

    /**
     * Focus state change
     */
    socket.on(EVENT_TYPES.FOCUS_STATE_CHANGE, async (data) => {
      try {
        const { roomId, focusState } = data;

        // Update in database
        await query(
          `UPDATE study_room_participants
           SET focus_state = $1
           WHERE room_id = $2 AND user_id = $3`,
          [focusState, roomId, user.id]
        );

        // Broadcast to room
        io.to(`room:${roomId}`).emit(EVENT_TYPES.FOCUS_STATE_CHANGE, {
          userId: user.id,
          username: user.username,
          focusState,
          timestamp: new Date().toISOString(),
        });

        logger.debug(`Focus state changed: user ${user.username}, room ${roomId}, state ${focusState}`);
      } catch (error) {
        logger.error('Error changing focus state:', error);
        socket.emit(EVENT_TYPES.ERROR, {
          message: 'Failed to change focus state',
          error: error.message,
        });
      }
    });

    /**
     * Start break
     */
    socket.on(EVENT_TYPES.BREAK_STARTED, async (data) => {
      try {
        const { roomId, duration } = data;

        // Broadcast to room
        io.to(`room:${roomId}`).emit(EVENT_TYPES.BREAK_STARTED, {
          userId: user.id,
          username: user.username,
          duration,
          timestamp: new Date().toISOString(),
        });

        // Log event
        await query(
          `INSERT INTO study_room_events (room_id, user_id, event_type, event_data)
           VALUES ($1, $2, 'break_started', $3)`,
          [roomId, user.id, JSON.stringify({ duration })]
        );

        logger.info(`Break started: user ${user.username}, room ${roomId}, duration ${duration}min`);
      } catch (error) {
        logger.error('Error starting break:', error);
        socket.emit(EVENT_TYPES.ERROR, {
          message: 'Failed to start break',
          error: error.message,
        });
      }
    });

    /**
     * End break
     */
    socket.on(EVENT_TYPES.BREAK_ENDED, async (data) => {
      try {
        const { roomId } = data;

        // Broadcast to room
        io.to(`room:${roomId}`).emit(EVENT_TYPES.BREAK_ENDED, {
          userId: user.id,
          username: user.username,
          timestamp: new Date().toISOString(),
        });

        // Log event
        await query(
          `INSERT INTO study_room_events (room_id, user_id, event_type, event_data)
           VALUES ($1, $2, 'break_ended', $3)`,
          [roomId, user.id, JSON.stringify({})]
        );

        logger.info(`Break ended: user ${user.username}, room ${roomId}`);
      } catch (error) {
        logger.error('Error ending break:', error);
        socket.emit(EVENT_TYPES.ERROR, {
          message: 'Failed to end break',
          error: error.message,
        });
      }
    });

    /**
     * Chat message (for temporary rest room)
     */
    socket.on(EVENT_TYPES.CHAT_MESSAGE, async (data) => {
      try {
        const { roomId, message } = data;

        if (!message || message.trim().length === 0) {
          socket.emit(EVENT_TYPES.ERROR, {
            message: 'Message cannot be empty',
          });
          return;
        }

        const chatMessage = {
          id: `${Date.now()}-${user.id}`,
          roomId,
          userId: user.id,
          username: user.username,
          nickname: user.nickname,
          avatarUrl: user.avatar_url,
          message: message.trim(),
          timestamp: new Date().toISOString(),
        };

        // Broadcast to room
        io.to(`room:${roomId}`).emit(EVENT_TYPES.CHAT_MESSAGE, chatMessage);

        logger.debug(`Chat message: user ${user.username}, room ${roomId}`);
      } catch (error) {
        logger.error('Error sending chat message:', error);
        socket.emit(EVENT_TYPES.ERROR, {
          message: 'Failed to send chat message',
          error: error.message,
        });
      }
    });

    /**
     * Disconnect
     */
    socket.on(EVENT_TYPES.DISCONNECT, async () => {
      logger.info(`WebSocket disconnected: ${user.username} (${socket.id})`);

      // Mark user as offline
      setUserOffline(user.id).catch(error => {
        logger.error('Error setting user offline:', error);
      });

      // Get all rooms user was in and notify
      const rooms = Array.from(socket.rooms).filter(room => room.startsWith('room:'));

      for (const room of rooms) {
        const roomId = room.split(':')[1];
        socket.to(room).emit(EVENT_TYPES.USER_LEFT, {
          userId: user.id,
          username: user.username,
          reason: 'disconnect',
          timestamp: new Date().toISOString(),
        });
      }
    });
  });

  logger.info('WebSocket service initialized');
}

/**
 * Broadcast notification to user
 */
function sendNotificationToUser(io, userId, notification) {
  getUserOnlineStatus(userId)
    .then(status => {
      if (status && status.socketId) {
        io.to(status.socketId).emit(EVENT_TYPES.NOTIFICATION, notification);
        logger.debug(`Notification sent to user ${userId}`);
      }
    })
    .catch(error => {
      logger.error(`Error sending notification to user ${userId}:`, error);
    });
}

/**
 * Broadcast update to study room
 */
function broadcastToRoom(io, roomId, event, data) {
  io.to(`room:${roomId}`).emit(event, data);
  logger.debug(`Broadcast to room ${roomId}: ${event}`);
}

module.exports = {
  initializeWebSocket,
  sendNotificationToUser,
  broadcastToRoom,
  EVENT_TYPES,
};
