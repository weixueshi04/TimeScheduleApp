-- TimeScheduleApp v2.0 Database Schema
-- PostgreSQL Database Schema for Network Study Room Application

-- ==================== 用户系统 (User System) ====================

-- 用户表
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  nickname VARCHAR(100),
  avatar_url VARCHAR(500),
  bio TEXT,
  phone VARCHAR(20),

  -- 用户统计
  total_focus_minutes INTEGER DEFAULT 0,
  total_completed_tasks INTEGER DEFAULT 0,
  total_study_sessions INTEGER DEFAULT 0,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,

  -- 用户状态
  status VARCHAR(20) DEFAULT 'active', -- active, suspended, deleted
  is_verified BOOLEAN DEFAULT false,
  verification_token VARCHAR(255),

  -- 准入机制相关
  days_since_registration INTEGER DEFAULT 0,
  total_focus_sessions INTEGER DEFAULT 0,
  total_focus_hours DECIMAL(10, 2) DEFAULT 0,
  can_create_study_room BOOLEAN DEFAULT false,

  -- 时间戳
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  last_login_at TIMESTAMP WITH TIME ZONE,
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- 用户刷新令牌表 (用于JWT刷新)
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token VARCHAR(500) UNIQUE NOT NULL,
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  revoked BOOLEAN DEFAULT false
);

-- ==================== 任务管理 (Task Management) ====================

-- 任务表
CREATE TABLE IF NOT EXISTS tasks (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  description TEXT,

  -- 任务分类
  category VARCHAR(50) NOT NULL, -- work, study, life, health, other
  priority VARCHAR(20) NOT NULL, -- low, medium, high, urgent

  -- 任务状态
  status VARCHAR(20) DEFAULT 'pending', -- pending, in_progress, completed, cancelled
  is_completed BOOLEAN DEFAULT false,

  -- 时间相关
  due_date DATE,
  completed_at TIMESTAMP WITH TIME ZONE,
  estimated_pomodoros INTEGER DEFAULT 1,
  actual_pomodoros INTEGER DEFAULT 0,

  -- 时间戳
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- ==================== 专注计时 (Focus Timer) ====================

-- 专注会话表
CREATE TABLE IF NOT EXISTS focus_sessions (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  task_id INTEGER REFERENCES tasks(id) ON DELETE SET NULL,
  study_room_id INTEGER REFERENCES study_rooms(id) ON DELETE SET NULL,

  -- 会话信息
  duration_minutes INTEGER NOT NULL, -- 预设时长
  actual_duration_minutes INTEGER, -- 实际完成时长
  focus_mode VARCHAR(20) DEFAULT 'pomodoro', -- pomodoro, custom, deep_work

  -- 会话状态
  status VARCHAR(20) DEFAULT 'active', -- active, completed, interrupted, cancelled
  is_completed BOOLEAN DEFAULT false,
  interruption_count INTEGER DEFAULT 0,

  -- 时间戳
  started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP WITH TIME ZONE,
  paused_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 健康管理 (Health Management) ====================

-- 健康记录表
CREATE TABLE IF NOT EXISTS health_records (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  record_date DATE NOT NULL,

  -- 健康指标
  sleep_hours DECIMAL(4, 2),
  water_intake_ml INTEGER,
  exercise_minutes INTEGER,

  -- 心情和笔记
  mood VARCHAR(20), -- great, good, normal, bad, terrible
  notes TEXT,

  -- 健康分数
  health_score INTEGER, -- 0-100

  -- 时间戳
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  UNIQUE(user_id, record_date)
);

-- ==================== 网络自习室 (Network Study Room) ====================

-- 自习室表
CREATE TABLE IF NOT EXISTS study_rooms (
  id SERIAL PRIMARY KEY,
  room_code VARCHAR(20) UNIQUE NOT NULL,
  creator_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- 自习室信息
  name VARCHAR(255),
  description TEXT,
  room_type VARCHAR(20) DEFAULT 'matched', -- matched, created, temporary_rest

  -- 自习室配置
  max_participants INTEGER DEFAULT 4,
  duration_minutes INTEGER NOT NULL,
  scheduled_start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  scheduled_end_time TIMESTAMP WITH TIME ZONE NOT NULL,

  -- 自习室状态
  status VARCHAR(20) DEFAULT 'waiting', -- waiting, active, completed, cancelled
  current_participants INTEGER DEFAULT 1,

  -- 匹配信息
  matching_criteria JSONB, -- 存储匹配算法使用的信息

  -- 时间戳
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  started_at TIMESTAMP WITH TIME ZONE,
  ended_at TIMESTAMP WITH TIME ZONE
);

-- 自习室参与者表
CREATE TABLE IF NOT EXISTS study_room_participants (
  id SERIAL PRIMARY KEY,
  room_id INTEGER NOT NULL REFERENCES study_rooms(id) ON DELETE CASCADE,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- 参与状态
  status VARCHAR(20) DEFAULT 'joined', -- joined, active, left, kicked, completed
  role VARCHAR(20) DEFAULT 'member', -- creator, member

  -- 参与信息
  energy_level INTEGER DEFAULT 100, -- 能量条 0-100
  focus_state VARCHAR(20) DEFAULT 'focused', -- focused, break, distracted

  -- 退出惩罚
  left_early BOOLEAN DEFAULT false,
  penalty_minutes INTEGER DEFAULT 0,

  -- 时间戳
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  left_at TIMESTAMP WITH TIME ZONE,

  UNIQUE(room_id, user_id)
);

-- 自习室事件表 (记录自习室内的重要事件)
CREATE TABLE IF NOT EXISTS study_room_events (
  id SERIAL PRIMARY KEY,
  room_id INTEGER NOT NULL REFERENCES study_rooms(id) ON DELETE CASCADE,
  user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,

  -- 事件信息
  event_type VARCHAR(50) NOT NULL, -- user_joined, user_left, break_started, break_ended, energy_updated, room_completed
  event_data JSONB,

  -- 时间戳
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ==================== 社交系统 (Social System) ====================

-- 默契度表
CREATE TABLE IF NOT EXISTS user_rapport (
  id SERIAL PRIMARY KEY,
  user_id_1 INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_id_2 INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- 默契度信息
  rapport_score INTEGER DEFAULT 0, -- 默契度分数
  total_sessions_together INTEGER DEFAULT 0, -- 共同参与的自习次数
  total_minutes_together INTEGER DEFAULT 0, -- 共同学习时长

  -- 社交状态
  relationship_status VARCHAR(20) DEFAULT 'acquaintance', -- stranger, acquaintance, friend, close_friend

  -- 时间戳
  first_met_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  last_interaction_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  UNIQUE(user_id_1, user_id_2),
  CHECK (user_id_1 < user_id_2) -- 确保user_id_1总是小于user_id_2，避免重复记录
);

-- 用户关注表
CREATE TABLE IF NOT EXISTS user_follows (
  id SERIAL PRIMARY KEY,
  follower_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  following_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- 时间戳
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

  UNIQUE(follower_id, following_id),
  CHECK (follower_id != following_id)
);

-- ==================== 通知系统 (Notification System) ====================

-- 通知表
CREATE TABLE IF NOT EXISTS notifications (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- 通知信息
  type VARCHAR(50) NOT NULL, -- study_room_invitation, rapport_milestone, friend_request, system_announcement
  title VARCHAR(255) NOT NULL,
  content TEXT,
  data JSONB,

  -- 通知状态
  is_read BOOLEAN DEFAULT false,
  read_at TIMESTAMP WITH TIME ZONE,

  -- 时间戳
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  expires_at TIMESTAMP WITH TIME ZONE
);

-- ==================== 索引 (Indexes) ====================

-- 用户索引
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_status ON users(status);
CREATE INDEX idx_users_created_at ON users(created_at);

-- 任务索引
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);
CREATE INDEX idx_tasks_category ON tasks(category);
CREATE INDEX idx_tasks_created_at ON tasks(created_at);

-- 专注会话索引
CREATE INDEX idx_focus_sessions_user_id ON focus_sessions(user_id);
CREATE INDEX idx_focus_sessions_task_id ON focus_sessions(task_id);
CREATE INDEX idx_focus_sessions_room_id ON focus_sessions(study_room_id);
CREATE INDEX idx_focus_sessions_started_at ON focus_sessions(started_at);

-- 健康记录索引
CREATE INDEX idx_health_records_user_id ON health_records(user_id);
CREATE INDEX idx_health_records_date ON health_records(record_date);

-- 自习室索引
CREATE INDEX idx_study_rooms_creator_id ON study_rooms(creator_id);
CREATE INDEX idx_study_rooms_status ON study_rooms(status);
CREATE INDEX idx_study_rooms_room_code ON study_rooms(room_code);
CREATE INDEX idx_study_rooms_scheduled_time ON study_rooms(scheduled_start_time, scheduled_end_time);

-- 自习室参与者索引
CREATE INDEX idx_room_participants_room_id ON study_room_participants(room_id);
CREATE INDEX idx_room_participants_user_id ON study_room_participants(user_id);
CREATE INDEX idx_room_participants_status ON study_room_participants(status);

-- 自习室事件索引
CREATE INDEX idx_room_events_room_id ON study_room_events(room_id);
CREATE INDEX idx_room_events_type ON study_room_events(event_type);
CREATE INDEX idx_room_events_created_at ON study_room_events(created_at);

-- 默契度索引
CREATE INDEX idx_rapport_user1 ON user_rapport(user_id_1);
CREATE INDEX idx_rapport_user2 ON user_rapport(user_id_2);
CREATE INDEX idx_rapport_score ON user_rapport(rapport_score);

-- 通知索引
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- ==================== 触发器 (Triggers) ====================

-- 更新 updated_at 字段的触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 应用触发器到各表
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_health_records_updated_at BEFORE UPDATE ON health_records
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
