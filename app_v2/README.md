# TimeScheduleApp Flutter v2.0

Flutter前端应用 - 网络自习室核心功能

## 🚀 项目概述

TimeScheduleApp v2.0 Flutter客户端，实现：
- 用户认证（注册/登录）
- WebSocket实时通信
- 网络自习室核心功能
- 与后端API完整集成

## 📁 项目结构

```
lib/
├── core/
│   ├── constants/         # 常量配置
│   │   └── api_constants.dart  # API端点和配置
│   └── utils/            # 工具类
├── data/
│   ├── models/           # 数据模型
│   │   ├── user.dart           # 用户模型
│   │   └── study_room.dart     # 自习室模型
│   ├── repositories/     # 数据仓库（API调用）
│   │   ├── auth_repository.dart       # 认证仓库
│   │   └── study_room_repository.dart # 自习室仓库
│   └── services/         # 服务层
│       ├── api_client.dart         # API客户端（Dio）
│       ├── token_service.dart      # Token管理
│       └── websocket_service.dart  # WebSocket服务
├── business/
│   ├── providers/        # 状态管理（Provider）
│   │   └── auth_provider.dart  # 认证Provider
│   └── use_cases/        # 业务用例
└── presentation/
    ├── screens/          # 页面
    ├── widgets/          # 组件
    └── themes/           # 主题
```

## 🛠️ 技术栈

- **Flutter**: 3.0+
- **状态管理**: Provider
- **网络请求**: Dio
- **WebSocket**: socket_io_client
- **安全存储**: flutter_secure_storage
- **数据模型**: json_serializable
- **日志**: logger

## 📦 依赖安装

```bash
# 克隆代码后，安装依赖
flutter pub get

# 生成模型代码（.g.dart文件）
flutter packages pub run build_runner build
```

## ⚙️ 配置后端地址

编辑 `lib/core/constants/api_constants.dart`:

```dart
class ApiConstants {
  // 修改为你的后端服务器地址
  static const String baseUrl = 'http://localhost:3000';  // 本地开发
  // static const String baseUrl = 'http://192.168.1.100:3000';  // 局域网
  // static const String baseUrl = 'https://api.yourapp.com';  // 生产环境

  static const String wsUrl = 'http://localhost:3000';  // WebSocket地址
}
```

## 🚀 运行应用

### 1. 确保后端服务器正在运行

```bash
cd server
npm start
```

### 2. 运行Flutter应用

```bash
cd app_v2

# iOS模拟器
flutter run -d ios

# Android模拟器
flutter run -d android

# Chrome浏览器（调试）
flutter run -d chrome

# 所有可用设备
flutter devices
```

## 📱 功能说明

### 已实现功能

#### 1. 用户认证
- ✅ 用户注册
- ✅ 用户登录
- ✅ 自动Token刷新
- ✅ 登出功能
- ✅ 认证状态管理

#### 2. API集成
- ✅ Dio HTTP客户端
- ✅ 请求/响应拦截器
- ✅ 自动Token注入
- ✅ 401错误自动刷新Token
- ✅ 错误处理

#### 3. WebSocket通信
- ✅ WebSocket连接管理
- ✅ JWT认证集成
- ✅ 事件发送/监听
- ✅ 自习室实时事件支持

#### 4. 数据模型
- ✅ User模型（用户信息、统计、准入资格）
- ✅ StudyRoom模型（自习室、参与者）
- ✅ JSON序列化/反序列化

#### 5. 安全存储
- ✅ 加密存储AccessToken
- ✅ 加密存储RefreshToken
- ✅ 安全清除令牌

### 待实现功能

- [ ] 自习室列表页面
- [ ] 创建自习室页面
- [ ] 自习室详情页（能量条、实时状态）
- [ ] 任务管理页面
- [ ] 专注计时页面
- [ ] 健康管理页面
- [ ] 统计图表
- [ ] 用户设置

## 🎨 UI界面

### 当前界面

#### 1. 启动页 (SplashScreen)
- 显示Logo和加载动画
- 检查登录状态

#### 2. 登录/注册页 (LoginScreen)
- 邮箱密码登录
- 用户注册
- 表单验证
- 错误提示

#### 3. 主页 (HomeScreen)
- 用户信息卡片
- 学习统计显示
- 自习室准入资格进度
- 功能菜单网格
- 创建自习室按钮（满足条件时显示）

## 🔌 API使用示例

### 认证

```dart
final authProvider = context.read<AuthProvider>();

// 注册
await authProvider.register(
  username: 'testuser',
  email: 'test@example.com',
  password: 'password123',
  nickname: '测试用户',
);

// 登录
await authProvider.login(
  email: 'test@example.com',
  password: 'password123',
);

// 登出
await authProvider.logout();

// 获取当前用户
final user = authProvider.currentUser;
```

### 自习室

```dart
final studyRoomRepo = context.read<StudyRoomRepository>();

// 获取自习室列表
final rooms = await studyRoomRepo.getStudyRooms();

// 创建自习室
final room = await studyRoomRepo.createStudyRoom(
  CreateStudyRoomRequest(
    name: '早晨学习会',
    durationMinutes: 90,
    scheduledStartTime: DateTime.now().add(Duration(hours: 1)).toIso8601String(),
    maxParticipants: 4,
    taskCategory: 'study',
  ),
);

// 加入自习室
await studyRoomRepo.joinStudyRoom(roomId);
```

### WebSocket

```dart
final wsService = context.read<WebSocketService>();

// 连接WebSocket
await wsService.connect();

// 加入自习室
wsService.joinStudyRoom(roomId);

// 监听事件
wsService.onUserJoined((data) {
  print('User joined: ${data['username']}');
});

wsService.onEnergyUpdate((data) {
  print('Energy: ${data['energyLevel']}%');
});

// 发送事件
wsService.updateEnergy(
  roomId: roomId,
  energyLevel: 75,
  focusState: 'focused',
);
```

## 🧪 测试

### 测试流程

1. **启动后端服务器**
   ```bash
   cd server
   npm start
   ```

2. **运行Flutter应用**
   ```bash
   cd app_v2
   flutter run
   ```

3. **测试注册流程**
   - 点击"没有账号？去注册"
   - 填写用户名、邮箱、密码
   - 点击注册
   - 自动跳转到主页

4. **测试登录流程**
   - 填写邮箱和密码
   - 点击登录
   - 查看主页显示用户信息

5. **测试自动Token刷新**
   - 保持应用打开
   - 等待accessToken过期（7天，测试时可修改服务器配置缩短时间）
   - 发起任何API请求
   - 应自动刷新Token并重试

## 📝 开发规范

### 1. 代码风格
- 使用Dart官方lint规则
- 命名规范：类名PascalCase，变量名camelCase
- 单个文件不超过500行

### 2. 状态管理
- 使用Provider进行状态管理
- 业务逻辑放在Provider中
- UI只负责展示和用户交互

### 3. 错误处理
- 所有API调用使用try-catch
- 用户友好的错误提示
- 记录详细日志便于调试

### 4. 网络请求
- 统一使用ApiClient
- 不要直接使用Dio
- 所有请求都有超时设置

## 🐛 常见问题

### Q: 编译时提示 .g.dart 文件不存在

A: 运行代码生成命令
```bash
flutter packages pub run build_runner build
```

### Q: WebSocket连接失败

A: 检查：
1. 后端服务器是否正在运行
2. 后端URL配置是否正确
3. 是否已登录（WebSocket需要Token）
4. 查看日志了解具体错误

### Q: Token刷新失败

A:
1. 检查refreshToken是否过期
2. 查看服务器日志
3. 清除应用数据重新登录

### Q: iOS/Android真机测试连接不上后端

A:
1. 确保手机和电脑在同一局域网
2. 修改API地址为电脑的局域网IP
   ```dart
   static const String baseUrl = 'http://192.168.1.100:3000';
   ```
3. 后端需要监听0.0.0.0而不是localhost

## 📚 下一步开发计划

1. **自习室功能**
   - 自习室列表页面
   - 创建自习室表单
   - 自习室详情页
   - 能量条可视化
   - 实时参与者列表
   - 聊天功能

2. **任务管理**
   - 任务列表
   - 创建/编辑任务
   - 任务分类筛选
   - 今日任务视图

3. **专注计时**
   - 番茄钟计时器
   - 专注会话记录
   - 统计图表

4. **健康管理**
   - 健康记录表单
   - 健康趋势图表
   - 心情记录

## 🤝 贡献指南

欢迎提交Issue和Pull Request！

开发步骤：
1. Fork项目
2. 创建功能分支
3. 提交代码
4. 发起Pull Request

## 📄 许可证

MIT License

---

**开发者**: Claude
**时间**: 2025-11-23
**版本**: 2.0.0
