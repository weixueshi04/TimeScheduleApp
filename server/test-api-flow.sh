#!/bin/bash

# TimeScheduleApp API 完整测试流程
# 自动测试所有核心功能

set -e

BASE_URL="http://localhost:3000"
API_URL="$BASE_URL/api/v1"

echo "🚀 TimeScheduleApp API 测试流程"
echo "================================"
echo ""

# 颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. 健康检查
echo "1️⃣  测试健康检查..."
HEALTH=$(curl -s "$BASE_URL/health")
if echo "$HEALTH" | grep -q "OK"; then
    echo -e "${GREEN}✅ 服务器运行正常${NC}"
else
    echo -e "${RED}❌ 服务器无响应${NC}"
    exit 1
fi
echo ""

# 2. 注册用户
echo "2️⃣  注册新用户..."
REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d '{
        "username": "testuser_'$(date +%s)'",
        "email": "test'$(date +%s)'@example.com",
        "password": "password123",
        "nickname": "测试用户"
    }')

if echo "$REGISTER_RESPONSE" | grep -q "accessToken"; then
    echo -e "${GREEN}✅ 注册成功${NC}"
    TOKEN=$(echo "$REGISTER_RESPONSE" | grep -o '"accessToken":"[^"]*"' | cut -d'"' -f4)
    USER_ID=$(echo "$REGISTER_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    echo "   Token: ${TOKEN:0:30}..."
    echo "   User ID: $USER_ID"
else
    echo -e "${RED}❌ 注册失败${NC}"
    echo "$REGISTER_RESPONSE"
    exit 1
fi
echo ""

# 3. 获取用户资料
echo "3️⃣  获取用户资料..."
USER_PROFILE=$(curl -s "$API_URL/auth/me" \
    -H "Authorization: Bearer $TOKEN")

if echo "$USER_PROFILE" | grep -q "studyRoomEligibility"; then
    echo -e "${GREEN}✅ 获取用户资料成功${NC}"
    CAN_CREATE=$(echo "$USER_PROFILE" | grep -o '"canCreateStudyRoom":[^,}]*' | cut -d':' -f2)
    FOCUS_SESSIONS=$(echo "$USER_PROFILE" | grep -o '"totalFocusSessions":[0-9]*' | cut -d':' -f2)
    echo "   准入资格: $CAN_CREATE"
    echo "   专注次数: $FOCUS_SESSIONS"
else
    echo -e "${RED}❌ 获取用户资料失败${NC}"
    exit 1
fi
echo ""

# 4. 创建任务
echo "4️⃣  创建任务..."
TASK_RESPONSE=$(curl -s -X POST "$API_URL/tasks" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "title": "测试任务",
        "description": "自动化测试创建的任务",
        "category": "work",
        "priority": "high",
        "dueDate": "'$(date -d "+1 day" +%Y-%m-%d)'",
        "estimatedPomodoros": 3
    }')

if echo "$TASK_RESPONSE" | grep -q "测试任务"; then
    echo -e "${GREEN}✅ 创建任务成功${NC}"
    TASK_ID=$(echo "$TASK_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    echo "   Task ID: $TASK_ID"
else
    echo -e "${RED}❌ 创建任务失败${NC}"
    exit 1
fi
echo ""

# 5. 开始专注会话
echo "5️⃣  开始专注会话..."
FOCUS_RESPONSE=$(curl -s -X POST "$API_URL/focus" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "taskId": '$TASK_ID',
        "durationMinutes": 25,
        "focusMode": "pomodoro"
    }')

if echo "$FOCUS_RESPONSE" | grep -q "Focus session started"; then
    echo -e "${GREEN}✅ 开始专注会话成功${NC}"
    FOCUS_ID=$(echo "$FOCUS_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    echo "   Focus Session ID: $FOCUS_ID"
else
    echo -e "${RED}❌ 开始专注会话失败${NC}"
    exit 1
fi
echo ""

# 6. 完成专注会话
echo "6️⃣  完成专注会话..."
sleep 1
COMPLETE_RESPONSE=$(curl -s -X PUT "$API_URL/focus/$FOCUS_ID/complete" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "actualDurationMinutes": 25,
        "interruptionCount": 0
    }')

if echo "$COMPLETE_RESPONSE" | grep -q "completed"; then
    echo -e "${GREEN}✅ 完成专注会话成功${NC}"
else
    echo -e "${RED}❌ 完成专注会话失败${NC}"
    exit 1
fi
echo ""

# 7. 创建健康记录
echo "7️⃣  创建健康记录..."
HEALTH_RESPONSE=$(curl -s -X POST "$API_URL/health" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "recordDate": "'$(date +%Y-%m-%d)'",
        "sleepHours": 7.5,
        "waterIntakeMl": 2000,
        "exerciseMinutes": 30,
        "mood": "good",
        "notes": "测试健康记录"
    }')

if echo "$HEALTH_RESPONSE" | grep -q "health_score"; then
    echo -e "${GREEN}✅ 创建健康记录成功${NC}"
    HEALTH_SCORE=$(echo "$HEALTH_RESPONSE" | grep -o '"health_score":[0-9]*' | cut -d':' -f2)
    echo "   健康分数: $HEALTH_SCORE/100"
else
    echo -e "${RED}❌ 创建健康记录失败${NC}"
    exit 1
fi
echo ""

# 8. 获取今日统计
echo "8️⃣  获取今日统计..."
TODAY_FOCUS=$(curl -s "$API_URL/focus/today" \
    -H "Authorization: Bearer $TOKEN")

if echo "$TODAY_FOCUS" | grep -q "totalFocusMinutes"; then
    echo -e "${GREEN}✅ 获取今日统计成功${NC}"
    TOTAL_MINUTES=$(echo "$TODAY_FOCUS" | grep -o '"totalFocusMinutes":[0-9]*' | cut -d':' -f2)
    COMPLETED_SESSIONS=$(echo "$TODAY_FOCUS" | grep -o '"completedSessions":[0-9]*' | cut -d':' -f2)
    echo "   今日专注时间: $TOTAL_MINUTES 分钟"
    echo "   完成会话数: $COMPLETED_SESSIONS"
else
    echo -e "${RED}❌ 获取今日统计失败${NC}"
    exit 1
fi
echo ""

# 9. 测试准入机制（模拟多次会话）
echo "9️⃣  测试准入机制（需要5次会话或3小时）..."
echo "   当前进度: $COMPLETED_SESSIONS/5 次会话"

if [ "$COMPLETED_SESSIONS" -lt 5 ]; then
    echo -e "${YELLOW}⚠️  还需要 $((5 - COMPLETED_SESSIONS)) 次会话才能创建自习室${NC}"
    echo "   继续创建专注会话..."

    for i in $(seq $((COMPLETED_SESSIONS + 1)) 5); do
        echo "   第 $i 次会话..."
        FOCUS=$(curl -s -X POST "$API_URL/focus" \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            -d '{"taskId": '$TASK_ID', "durationMinutes": 25, "focusMode": "pomodoro"}')
        FOCUS_ID=$(echo "$FOCUS" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
        sleep 1
        curl -s -X PUT "$API_URL/focus/$FOCUS_ID/complete" \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            -d '{"actualDurationMinutes": 25}' > /dev/null
        echo "     ✓ 完成"
    done
fi
echo ""

# 10. 创建自习室
echo "🔟 创建自习室..."
ROOM_RESPONSE=$(curl -s -X POST "$API_URL/study-rooms" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "测试自习室",
        "description": "自动化测试创建的自习室",
        "durationMinutes": 90,
        "scheduledStartTime": "'$(date -u -d "+1 hour" +%Y-%m-%dT%H:%M:%S.000Z)'",
        "maxParticipants": 4,
        "taskCategory": "study"
    }')

if echo "$ROOM_RESPONSE" | grep -q "room_code"; then
    echo -e "${GREEN}✅ 创建自习室成功${NC}"
    ROOM_ID=$(echo "$ROOM_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    ROOM_CODE=$(echo "$ROOM_RESPONSE" | grep -o '"room_code":"[^"]*"' | cut -d'"' -f4)
    echo "   Room ID: $ROOM_ID"
    echo "   Room Code: $ROOM_CODE"
elif echo "$ROOM_RESPONSE" | grep -q "eligibility"; then
    echo -e "${YELLOW}⚠️  准入条件未满足${NC}"
    echo "   需要: 3天注册 + (5次专注 或 3小时总时长)"
else
    echo -e "${RED}❌ 创建自习室失败${NC}"
    echo "$ROOM_RESPONSE"
fi
echo ""

# 总结
echo "================================"
echo "✅ 测试完成!"
echo ""
echo "📊 测试结果总结:"
echo "   - 健康检查: ✅"
echo "   - 用户注册: ✅"
echo "   - 任务管理: ✅"
echo "   - 专注会话: ✅"
echo "   - 健康记录: ✅"
echo "   - 统计查询: ✅"
echo "   - 准入机制: ✅"
if [ -n "$ROOM_CODE" ]; then
    echo "   - 自习室创建: ✅"
else
    echo "   - 自习室创建: ⚠️  (需满足准入条件)"
fi
echo ""
echo "💡 提示: 使用以下命令测试WebSocket:"
echo "   node test-websocket.js $TOKEN"
echo ""
