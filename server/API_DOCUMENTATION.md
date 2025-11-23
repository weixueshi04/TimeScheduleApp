# TimeScheduleApp Backend API Documentation

Version: 2.0.0
Base URL: `http://localhost:3000/api/v1`

## Table of Contents

1. [Authentication](#authentication)
2. [Tasks](#tasks)
3. [Focus Sessions](#focus-sessions)
4. [Health Records](#health-records)
5. [Study Rooms](#study-rooms)
6. [WebSocket Events](#websocket-events)

---

## Authentication

### Register

Register a new user account.

**Endpoint:** `POST /auth/register`

**Request Body:**
```json
{
  "username": "johndoe",
  "email": "john@example.com",
  "password": "password123",
  "nickname": "John" // optional
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "username": "johndoe",
      "email": "john@example.com",
      "nickname": "John",
      "createdAt": "2025-11-23T10:00:00.000Z"
    },
    "tokens": {
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    }
  },
  "message": "User registered successfully"
}
```

### Login

Login to an existing account.

**Endpoint:** `POST /auth/login`

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "username": "johndoe",
      "email": "john@example.com",
      "nickname": "John",
      "avatarUrl": null,
      "isVerified": false,
      "stats": {
        "totalFocusMinutes": 120,
        "totalCompletedTasks": 5,
        "currentStreak": 3
      }
    },
    "tokens": {
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    }
  },
  "message": "Login successful"
}
```

### Get Current User

Get the current authenticated user's profile.

**Endpoint:** `GET /auth/me`

**Headers:**
```
Authorization: Bearer <accessToken>
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "id": 1,
    "username": "johndoe",
    "email": "john@example.com",
    "nickname": "John",
    "avatarUrl": null,
    "bio": null,
    "isVerified": false,
    "stats": {
      "totalFocusMinutes": 120,
      "totalCompletedTasks": 5,
      "totalStudySessions": 3,
      "currentStreak": 3,
      "longestStreak": 7
    },
    "studyRoomEligibility": {
      "daysSinceRegistration": 5,
      "totalFocusSessions": 6,
      "totalFocusHours": 2.5,
      "canCreateStudyRoom": false
    },
    "createdAt": "2025-11-18T10:00:00.000Z",
    "lastLoginAt": "2025-11-23T10:00:00.000Z"
  }
}
```

### Refresh Token

Refresh the access token using a refresh token.

**Endpoint:** `POST /auth/refresh`

**Request Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  },
  "message": "Access token refreshed successfully"
}
```

---

## Tasks

### Get All Tasks

Get all tasks for the current user with optional filters.

**Endpoint:** `GET /tasks`

**Headers:**
```
Authorization: Bearer <accessToken>
```

**Query Parameters:**
- `status` (optional): `pending`, `in_progress`, `completed`, `cancelled`
- `category` (optional): `work`, `study`, `life`, `health`, `other`
- `priority` (optional): `low`, `medium`, `high`, `urgent`
- `dueDate` (optional): `YYYY-MM-DD`
- `limit` (optional): Default 100
- `offset` (optional): Default 0

**Response:** `200 OK`
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "user_id": 1,
      "title": "Complete project proposal",
      "description": "Write and submit the Q4 project proposal",
      "category": "work",
      "priority": "high",
      "status": "in_progress",
      "is_completed": false,
      "due_date": "2025-11-25",
      "completed_at": null,
      "estimated_pomodoros": 3,
      "actual_pomodoros": 1,
      "created_at": "2025-11-23T09:00:00.000Z",
      "updated_at": "2025-11-23T09:30:00.000Z"
    }
  ],
  "pagination": {
    "limit": 100,
    "offset": 0,
    "total": 1
  }
}
```

### Create Task

Create a new task.

**Endpoint:** `POST /tasks`

**Headers:**
```
Authorization: Bearer <accessToken>
```

**Request Body:**
```json
{
  "title": "Complete project proposal",
  "description": "Write and submit the Q4 project proposal",
  "category": "work",
  "priority": "high",
  "dueDate": "2025-11-25",
  "estimatedPomodoros": 3
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "data": {
    "id": 1,
    "user_id": 1,
    "title": "Complete project proposal",
    "description": "Write and submit the Q4 project proposal",
    "category": "work",
    "priority": "high",
    "status": "pending",
    "is_completed": false,
    "due_date": "2025-11-25",
    "completed_at": null,
    "estimated_pomodoros": 3,
    "actual_pomodoros": 0,
    "created_at": "2025-11-23T10:00:00.000Z",
    "updated_at": "2025-11-23T10:00:00.000Z",
    "deleted_at": null
  },
  "message": "Task created successfully"
}
```

### Complete Task

Mark a task as completed.

**Endpoint:** `PUT /tasks/:id/complete`

**Headers:**
```
Authorization: Bearer <accessToken>
```

**Request Body:**
```json
{
  "actualPomodoros": 2
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "id": 1,
    "status": "completed",
    "is_completed": true,
    "completed_at": "2025-11-23T12:00:00.000Z",
    "actual_pomodoros": 2
  },
  "message": "Task completed successfully"
}
```

---

## Focus Sessions

### Start Focus Session

Start a new focus session.

**Endpoint:** `POST /focus`

**Headers:**
```
Authorization: Bearer <accessToken>
```

**Request Body:**
```json
{
  "taskId": 1,
  "durationMinutes": 25,
  "focusMode": "pomodoro"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "data": {
    "id": 1,
    "user_id": 1,
    "task_id": 1,
    "study_room_id": null,
    "duration_minutes": 25,
    "actual_duration_minutes": null,
    "focus_mode": "pomodoro",
    "status": "active",
    "is_completed": false,
    "interruption_count": 0,
    "started_at": "2025-11-23T10:00:00.000Z",
    "completed_at": null,
    "paused_at": null,
    "created_at": "2025-11-23T10:00:00.000Z"
  },
  "message": "Focus session started successfully"
}
```

### Complete Focus Session

Complete an active focus session.

**Endpoint:** `PUT /focus/:id/complete`

**Headers:**
```
Authorization: Bearer <accessToken>
```

**Request Body:**
```json
{
  "actualDurationMinutes": 25,
  "interruptionCount": 0
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "id": 1,
    "status": "completed",
    "is_completed": true,
    "actual_duration_minutes": 25,
    "interruption_count": 0,
    "completed_at": "2025-11-23T10:25:00.000Z"
  },
  "message": "Focus session completed successfully"
}
```

### Get Today's Focus Sessions

Get today's focus sessions with statistics.

**Endpoint:** `GET /focus/today`

**Headers:**
```
Authorization: Bearer <accessToken>
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "sessions": [
      {
        "id": 1,
        "duration_minutes": 25,
        "actual_duration_minutes": 25,
        "focus_mode": "pomodoro",
        "status": "completed",
        "is_completed": true,
        "started_at": "2025-11-23T10:00:00.000Z",
        "completed_at": "2025-11-23T10:25:00.000Z",
        "task_title": "Complete project proposal"
      }
    ],
    "totalFocusMinutes": 25,
    "completedSessions": 1,
    "totalSessions": 1
  }
}
```

---

## Health Records

### Create/Update Health Record

Create or update a health record for a specific date.

**Endpoint:** `POST /health`

**Headers:**
```
Authorization: Bearer <accessToken>
```

**Request Body:**
```json
{
  "recordDate": "2025-11-23",
  "sleepHours": 7.5,
  "waterIntakeMl": 2000,
  "exerciseMinutes": 30,
  "mood": "good",
  "notes": "Felt productive today"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "id": 1,
    "user_id": 1,
    "record_date": "2025-11-23",
    "sleep_hours": 7.5,
    "water_intake_ml": 2000,
    "exercise_minutes": 30,
    "mood": "good",
    "notes": "Felt productive today",
    "health_score": 85,
    "created_at": "2025-11-23T10:00:00.000Z",
    "updated_at": "2025-11-23T10:00:00.000Z"
  },
  "message": "Health record saved successfully"
}
```

### Get Health Statistics

Get health statistics for a specific period.

**Endpoint:** `GET /health/statistics`

**Headers:**
```
Authorization: Bearer <accessToken>
```

**Query Parameters:**
- `period` (optional): `day`, `week`, `month`, `year` (default: `week`)

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "period": "week",
    "statistics": {
      "total_records": 7,
      "avg_health_score": 82.5,
      "avg_sleep_hours": 7.3,
      "avg_water_intake": 1850,
      "avg_exercise_minutes": 25,
      "great_mood_days": 2,
      "good_mood_days": 4,
      "normal_mood_days": 1,
      "bad_mood_days": 0,
      "terrible_mood_days": 0
    }
  }
}
```

---

## Study Rooms

### Create Study Room

Create a new study room (requires eligibility: 3 days registration + 5 focus sessions OR 3 hours total).

**Endpoint:** `POST /study-rooms`

**Headers:**
```
Authorization: Bearer <accessToken>
```

**Request Body:**
```json
{
  "name": "Morning Study Session",
  "description": "Let's study together!",
  "durationMinutes": 90,
  "scheduledStartTime": "2025-11-23T09:00:00.000Z",
  "maxParticipants": 4,
  "taskCategory": "study"
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "data": {
    "id": 1,
    "room_code": "ABCD1234",
    "creator_id": 1,
    "name": "Morning Study Session",
    "description": "Let's study together!",
    "room_type": "created",
    "max_participants": 4,
    "duration_minutes": 90,
    "scheduled_start_time": "2025-11-23T09:00:00.000Z",
    "scheduled_end_time": "2025-11-23T10:30:00.000Z",
    "status": "waiting",
    "current_participants": 1,
    "matching_criteria": {
      "taskCategory": "study",
      "completionRate": "75.50",
      "totalFocusHours": 15.5,
      "scheduledStartTime": "2025-11-23T09:00:00.000Z",
      "scheduledEndTime": "2025-11-23T10:30:00.000Z"
    },
    "created_at": "2025-11-23T08:00:00.000Z",
    "started_at": null,
    "ended_at": null
  },
  "message": "Study room created successfully"
}
```

### Join Study Room

Join an existing study room.

**Endpoint:** `POST /study-rooms/:id/join`

**Headers:**
```
Authorization: Bearer <accessToken>
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Successfully joined study room"
}
```

### Leave Study Room

Leave a study room (may incur penalty if leaving early).

**Endpoint:** `POST /study-rooms/:id/leave`

**Headers:**
```
Authorization: Bearer <accessToken>
```

**Request Body:**
```json
{
  "reason": "Emergency"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "leftEarly": true,
    "penaltyMinutes": 15
  },
  "message": "You left early. Penalty: 15 minutes"
}
```

**Exit Penalty Rules:**
- Last 5 minutes: No penalty
- 6-15 minutes remaining: 5 minutes penalty
- 16-30 minutes remaining: 15 minutes penalty
- 30+ minutes remaining: 30 minutes penalty

### Update Energy Level

Update your energy level and focus state in a study room.

**Endpoint:** `PUT /study-rooms/:id/energy`

**Headers:**
```
Authorization: Bearer <accessToken>
```

**Request Body:**
```json
{
  "energyLevel": 75,
  "focusState": "focused"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "id": 1,
    "room_id": 1,
    "user_id": 1,
    "energy_level": 75,
    "focus_state": "focused",
    "status": "active",
    "joined_at": "2025-11-23T09:00:00.000Z"
  },
  "message": "Energy level updated successfully"
}
```

**Focus States:**
- `focused`: Actively working
- `break`: Taking a short break
- `distracted`: Lost focus temporarily

---

## WebSocket Events

Connect to WebSocket server at `ws://localhost:3000`

### Authentication

Send authentication token after connecting:

```javascript
socket.emit('authenticate', {
  token: 'your-jwt-access-token'
});

socket.on('authenticated', (data) => {
  console.log('Authenticated:', data.user);
});
```

### Join Study Room

```javascript
socket.emit('join_room', {
  roomId: 1
});

socket.on('room_joined', (data) => {
  console.log('Joined room:', data.roomCode);
});

socket.on('user_joined', (data) => {
  console.log(`${data.username} joined the room`);
});
```

### Energy Updates

```javascript
socket.emit('energy_update', {
  roomId: 1,
  energyLevel: 75,
  focusState: 'focused'
});

socket.on('energy_update', (data) => {
  console.log(`${data.username} energy: ${data.energyLevel}`);
});
```

### Break Management

```javascript
socket.emit('break_started', {
  roomId: 1,
  duration: 5 // minutes
});

socket.on('break_started', (data) => {
  console.log(`${data.username} started a ${data.duration}min break`);
});

socket.emit('break_ended', {
  roomId: 1
});

socket.on('break_ended', (data) => {
  console.log(`${data.username} ended break`);
});
```

### Chat Messages

```javascript
socket.emit('chat_message', {
  roomId: 1,
  message: 'Hello everyone!'
});

socket.on('chat_message', (data) => {
  console.log(`${data.username}: ${data.message}`);
});
```

---

## Error Responses

All error responses follow this format:

```json
{
  "success": false,
  "error": {
    "code": 400,
    "message": "Error description"
  }
}
```

**Common Status Codes:**
- `400`: Bad Request - Invalid input data
- `401`: Unauthorized - Missing or invalid authentication token
- `403`: Forbidden - Insufficient permissions
- `404`: Not Found - Resource not found
- `409`: Conflict - Resource already exists
- `500`: Internal Server Error - Server-side error

---

## Rate Limiting

API requests are rate-limited to **100 requests per 15 minutes** per IP address for `/api/*` endpoints.

If you exceed the rate limit, you'll receive a `429 Too Many Requests` response.

---

## Environment Variables

Required environment variables for the backend:

```bash
# Server
PORT=3000
NODE_ENV=development
API_VERSION=v1

# PostgreSQL
PG_HOST=localhost
PG_PORT=5432
PG_DATABASE=timeschedule_db
PG_USER=postgres
PG_PASSWORD=your_password

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_DB=0

# MongoDB
MONGO_HOST=localhost
MONGO_PORT=27017
MONGO_DATABASE=timeschedule_db

# JWT
JWT_SECRET=your-secret-key-change-this-in-production
JWT_EXPIRES_IN=7d
JWT_REFRESH_SECRET=your-refresh-secret-change-this
JWT_REFRESH_EXPIRES_IN=30d

# WebSocket
SOCKET_CORS_ORIGIN=*

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```
