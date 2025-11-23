# TimeScheduleApp Backend Server v2.0

Backend server for TimeScheduleApp - 从自律到他律的网络自习室应用

## 🚀 Overview

This is the backend API server for TimeScheduleApp v2.0, featuring:

- **RESTful API** for task management, focus sessions, and health tracking
- **WebSocket** real-time communication for network study rooms
- **JWT Authentication** with access and refresh tokens
- **PostgreSQL** for relational data (users, tasks, study rooms)
- **Redis** for caching and real-time state management
- **MongoDB** for chat history and sharing content

## 🎯 Core Features

### Network Study Rooms (网络自习室)
- Real-time multi-user study sessions
- Smart matching algorithm based on time overlap, task similarity, and user stats
- Energy bar system for visual focus indicators
- Exit penalty system to encourage commitment
- Temporary rest rooms with voice chat support

### User Management
- Registration and authentication with JWT
- User profile and statistics
- Study room eligibility system (3 days + 5 sessions or 3 hours)

### Task Management
- CRUD operations for tasks
- Task categorization (work, study, life, health, other)
- Priority levels (low, medium, high, urgent)
- Today's tasks and statistics

### Focus Sessions
- Pomodoro timer and custom focus modes
- Session tracking with interruption counting
- Integration with tasks and study rooms
- Daily and period statistics

### Health Management
- Daily health records (sleep, water, exercise, mood)
- Automatic health score calculation
- Trends and statistics visualization

## 📁 Project Structure

```
server/
├── src/
│   ├── config/           # Database configurations
│   │   ├── postgres.js   # PostgreSQL connection pool
│   │   ├── redis.js      # Redis client and helpers
│   │   └── mongodb.js    # MongoDB connection
│   ├── controllers/      # Request handlers
│   │   ├── authController.js       # Authentication logic
│   │   ├── taskController.js       # Task management
│   │   ├── focusController.js      # Focus sessions
│   │   ├── healthController.js     # Health records
│   │   └── studyRoomController.js  # Study rooms
│   ├── database/         # Database schema and migrations
│   │   ├── schema.sql    # PostgreSQL table definitions
│   │   └── migrations.js # Migration runner
│   ├── middleware/       # Express middleware
│   │   ├── auth.js       # JWT authentication
│   │   └── errorHandler.js # Error handling
│   ├── routes/           # API routes
│   │   ├── authRoutes.js
│   │   ├── taskRoutes.js
│   │   ├── focusRoutes.js
│   │   ├── healthRoutes.js
│   │   └── studyRoomRoutes.js
│   ├── services/         # Business logic services
│   │   └── websocket.js  # WebSocket real-time communication
│   ├── utils/            # Utility functions
│   │   └── logger.js     # Winston logger
│   └── server.js         # Main application entry point
├── scripts/              # Utility scripts
│   ├── init-db.js        # Database initialization
│   └── update-user-days.js # Daily user stats update
├── logs/                 # Application logs (gitignored)
├── package.json
├── .env.example          # Environment variables template
├── README.md             # This file
└── API_DOCUMENTATION.md  # Complete API documentation

```

## 🛠️ Technology Stack

- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **WebSocket**: Socket.io
- **Databases**:
  - PostgreSQL 14+ (main database)
  - Redis 7+ (caching, real-time state)
  - MongoDB 6+ (chat, sharing content)
- **Authentication**: JWT (jsonwebtoken)
- **Security**:
  - Helmet (security headers)
  - bcryptjs (password hashing)
  - CORS
  - Rate limiting (express-rate-limit)
- **Logging**: Winston
- **Process Management**: PM2 (recommended for production)

## 📦 Installation

### Prerequisites

Make sure you have the following installed:
- Node.js 18+ and npm
- PostgreSQL 14+
- Redis 7+
- MongoDB 6+

### 1. Clone and Install Dependencies

```bash
cd server
npm install
```

### 2. Configure Environment Variables

Copy the example environment file and configure it:

```bash
cp .env.example .env
```

Edit `.env` and set your configuration:

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

# JWT Secrets (CHANGE THESE IN PRODUCTION!)
JWT_SECRET=your-secret-key-change-this-in-production
JWT_EXPIRES_IN=7d
JWT_REFRESH_SECRET=your-refresh-secret-change-this
JWT_REFRESH_EXPIRES_IN=30d

# WebSocket
SOCKET_CORS_ORIGIN=*

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Logging
LOG_LEVEL=info
```

### 3. Initialize Database

Run the database initialization script to create all tables:

```bash
# Run migrations only
node scripts/init-db.js

# Run migrations and seed sample data (for development)
node scripts/init-db.js --seed

# Drop all tables, then migrate and seed (WARNING: destructive!)
node scripts/init-db.js --drop --seed
```

### 4. Start the Server

**Development mode** (with auto-reload):
```bash
npm run dev
```

**Production mode**:
```bash
npm start
```

The server will start on `http://localhost:3000` by default.

## 🧪 Testing

### Manual Testing

Test the health endpoint:
```bash
curl http://localhost:3000/health
```

Test authentication:
```bash
# Register
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123"
  }'

# Login
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

### WebSocket Testing

Use a WebSocket client to test real-time features:

```javascript
const io = require('socket.io-client');

const socket = io('http://localhost:3000', {
  auth: {
    token: 'your-jwt-access-token'
  }
});

socket.on('authenticated', (data) => {
  console.log('Authenticated:', data);

  // Join a study room
  socket.emit('join_room', { roomId: 1 });
});

socket.on('room_joined', (data) => {
  console.log('Joined room:', data);
});

socket.on('user_joined', (data) => {
  console.log('User joined:', data);
});
```

## 📚 API Documentation

See [API_DOCUMENTATION.md](./API_DOCUMENTATION.md) for complete API reference.

### Quick Reference

**Base URL**: `http://localhost:3000/api/v1`

**Authentication**: Include JWT token in header:
```
Authorization: Bearer <your-access-token>
```

**Main Endpoints**:
- `/auth/*` - Authentication (register, login, profile)
- `/tasks/*` - Task management
- `/focus/*` - Focus session tracking
- `/health/*` - Health records
- `/study-rooms/*` - Network study rooms

**WebSocket**: Connect to `ws://localhost:3000` with JWT auth

## 🔧 Database Management

### PostgreSQL

**Connect to database**:
```bash
psql -U postgres -d timeschedule_db
```

**Useful queries**:
```sql
-- Check user count
SELECT COUNT(*) FROM users;

-- Check study rooms
SELECT * FROM study_rooms WHERE status = 'active';

-- Check today's focus sessions
SELECT * FROM focus_sessions WHERE started_at >= CURRENT_DATE;
```

### Redis

**Connect to Redis**:
```bash
redis-cli
```

**Useful commands**:
```bash
# Check online users
KEYS user:*:online

# Check study room state
GET room:1:state

# Check matching queue
ZRANGE matching:queue 0 -1
```

### MongoDB

**Connect to MongoDB**:
```bash
mongosh timeschedule_db
```

**Useful commands**:
```javascript
// Check collections
show collections

// Find chat messages
db.chat_messages.find({ roomId: 1 })
```

## 🔄 Scheduled Tasks

Some tasks should be run periodically (use cron or scheduled tasks):

### Update User Registration Days

Run daily to update user eligibility for study rooms:

```bash
# Add to cron (runs daily at 1 AM)
0 1 * * * cd /path/to/server && node scripts/update-user-days.js
```

### Clean Up Old Tokens

Run weekly to clean up expired refresh tokens:

```sql
-- Add to cron or scheduled task
DELETE FROM refresh_tokens WHERE expires_at < NOW();
```

## 🚀 Production Deployment

### Using PM2

Install PM2:
```bash
npm install -g pm2
```

Start with PM2:
```bash
pm2 start src/server.js --name timeschedule-api
pm2 save
pm2 startup
```

Monitor:
```bash
pm2 status
pm2 logs timeschedule-api
pm2 monit
```

### Environment Setup

1. Set `NODE_ENV=production` in your `.env`
2. Use strong, unique secrets for JWT tokens
3. Set up SSL/TLS certificates (use nginx reverse proxy)
4. Configure CORS with specific origins
5. Set up database backups
6. Configure log rotation
7. Set up monitoring (PM2 Plus, New Relic, etc.)

### Nginx Configuration Example

```nginx
server {
    listen 80;
    server_name api.yourapp.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # WebSocket support
    location /socket.io/ {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## 📊 Performance Considerations

### PostgreSQL Optimization

- Indexes are already created for common queries
- Use connection pooling (max 20 connections configured)
- Monitor slow queries with `pg_stat_statements`

### Redis Optimization

- Set appropriate TTL for cached data
- Use Redis pipelining for batch operations
- Monitor memory usage

### Rate Limiting

- Default: 100 requests per 15 minutes per IP
- Adjust in `.env` based on your needs
- Consider using Redis for distributed rate limiting

## 🐛 Troubleshooting

### Database Connection Issues

**Problem**: `ECONNREFUSED` when connecting to PostgreSQL/Redis/MongoDB

**Solutions**:
1. Check if databases are running
2. Verify connection credentials in `.env`
3. Check firewall settings
4. Ensure databases are configured to accept connections

### JWT Authentication Errors

**Problem**: `Invalid token` or `Token has expired`

**Solutions**:
1. Check if JWT secrets are set correctly
2. Verify token is sent in `Authorization: Bearer <token>` header
3. Use `/auth/refresh` endpoint to get new access token

### WebSocket Connection Issues

**Problem**: WebSocket fails to connect

**Solutions**:
1. Check CORS settings in `server.js`
2. Verify JWT token is sent during WebSocket handshake
3. Check firewall/proxy settings for WebSocket support

## 📝 Logging

Logs are stored in the `logs/` directory:

- `combined.log` - All logs
- `error.log` - Error logs only
- `exceptions.log` - Uncaught exceptions
- `rejections.log` - Unhandled promise rejections

**Log levels**: `error`, `warn`, `info`, `http`, `debug`

Set log level in `.env`:
```bash
LOG_LEVEL=debug  # For development
LOG_LEVEL=info   # For production
```

## 🤝 Contributing

When contributing to the backend:

1. Follow existing code structure
2. Add JSDoc comments for new functions
3. Update API documentation
4. Test all endpoints before submitting
5. Check logs for errors

## 📄 License

MIT License - See LICENSE file for details

## 📞 Support

For issues and questions:
- Create an issue on GitHub
- Check API documentation
- Review logs for error details

---

**Built with ❤️ for focused, collaborative studying**
