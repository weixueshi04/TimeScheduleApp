# TimeScheduleApp 项目改进计划 (2025)

## 执行摘要

基于对您项目的分析，本文档提供了针对当前代码的具体改进建议，重点关注：
1. 代码重复率高 (V1和V2各自维护)
2. 认证系统需要加强
3. WebSocket连接稳定性
4. 性能优化空间

---

## 一、项目现状分析

### 1.1 当前项目结构
```
TimeScheduleApp/
├── lib/                 # V1.0 本地应用 (1000+ 行)
├── app_v2/             # V2.0 网络应用 (1500+ 行)
├── server/             # Node.js后端服务
└── 文档/               # 各类文档
```

### 1.2 发现的问题

#### 问题1: 代码重复 (严重)
- **V1.0和V2.0中的models重复**: TaskModel, HealthModel等
- **repositories重复**: 两个版本都有TaskRepository, HealthRepository
- **UI组件重复**: 列表页面、详情页面逻辑重复
- **成本**: 每次修复bug需要在两个地方改动
- **风险**: 版本间不一致

#### 问题2: 认证系统不完整 (中等)
✓ 已有基础: TokenService, ApiClient拦截器
✗ 缺失功能:
- Token过期前5分钟的主动刷新
- 多个并发请求时的Token刷新竞态条件处理
- 登出后的自动导航到登录页
- 网络恢复后的自动重连

#### 问题3: WebSocket不稳定 (中等)
✓ 已有: 基础连接
✗ 缺失:
- 心跳检测 (ping/pong)
- 自动重连机制
- 连接失败的重试策略
- 断网时的缓存消息

#### 问题4: 性能瓶颈 (低)
- Provider使用不够精细，可能导致过度重建
- 图片缓存策略未优化
- 列表滚动性能未测试

---

## 二、分阶段改进方案

### Phase 1: 代码整合 (2-3周)

#### 目标: 消除V1/V2代码重复

**Step 1.1: 创建共享库结构**

```bash
mkdir -p lib_shared
mkdir -p lib_shared/data/models
mkdir -p lib_shared/data/repositories
mkdir -p lib_shared/presentation/widgets
mkdir -p lib_shared/presentation/screens
mkdir -p lib_shared/core
```

**Step 1.2: 迁移共享代码**

```dart
// lib_shared/data/models/task_model.dart
// 合并V1和V2的TaskModel

class TaskModel {
  final int id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskStatus status;
  final int? remoteId;  // 用于区分本地/远程

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    this.remoteId,
  });

  // V1本地方法
  Map<String, dynamic> toHiveMap() => {
    'id': id,
    'title': title,
    'description': description,
    'dueDate': dueDate.toIso8601String(),
    'status': status.toString(),
  };

  // V2远程方法
  Map<String, dynamic> toJson() => {
    'id': remoteId ?? id,
    'title': title,
    'description': description,
    'dueDate': dueDate.toIso8601String(),
    'status': status.toString(),
  };
}
```

**Step 1.3: 统一Repository接口**

```dart
// lib_shared/data/repositories/task_repository_base.dart
abstract class ITaskRepository {
  Future<List<TaskModel>> getTasks();
  Future<TaskModel> createTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(int id);
}

// lib_v1/data/repositories/local_task_repository.dart
class LocalTaskRepository implements ITaskRepository {
  @override
  Future<List<TaskModel>> getTasks() async {
    // Hive实现
  }
}

// lib_v2/data/repositories/remote_task_repository.dart
class RemoteTaskRepository implements ITaskRepository {
  @override
  Future<List<TaskModel>> getTasks() async {
    // API实现
  }
}
```

**Step 1.4: 项目重组后的新结构**

```
TimeScheduleApp/
├── lib_shared/              # 共享代码 (新)
│   ├── core/
│   │   ├── constants/
│   │   ├── utils/
│   │   └── themes/
│   ├── data/
│   │   ├── models/          # 共享的数据模型
│   │   └── repositories/    # 抽象的repository接口
│   └── presentation/
│       ├── widgets/         # 可复用的UI组件
│       └── screens/         # 通用的屏幕

├── lib/                      # V1.0 本地应用
│   ├── main.dart
│   └── data/
│       └── local/           # Hive存储实现

├── lib_v2/                   # V2.0 网络应用
│   ├── main.dart
│   └── data/
│       ├── remote/          # API实现
│       └── services/        # API客户端、WebSocket

└── pubspec.yaml
```

**预期收益**:
- 减少代码重复 50%
- 新特性只需实现一次
- Bug修复的风险大幅降低

---

### Phase 2: 认证系统加强 (1-2周)

#### 目标: 完整的JWT认证系统

**Step 2.1: 增强TokenService**

```dart
// lib_v2/data/services/token_service.dart (改进版)

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:async';

class TokenService extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage;
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const int _refreshThresholdMinutes = 5;

  Timer? _refreshTimer;

  TokenService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// 检查Token是否即将过期
  Future<bool> shouldRefreshToken() async {
    final expiryStr = await _secureStorage.read(key: _tokenExpiryKey);
    if (expiryStr == null) return false;

    final expiry = DateTime.parse(expiryStr);
    final threshold = DateTime.now().add(Duration(minutes: _refreshThresholdMinutes));
    return expiry.isBefore(threshold);
  }

  /// 保存Token并启动自动刷新
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    final expiryDate = DateTime.now().add(Duration(seconds: expiresIn));

    await Future.wait([
      _secureStorage.write(key: _accessTokenKey, value: accessToken),
      _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
      _secureStorage.write(key: _tokenExpiryKey, value: expiryDate.toIso8601String()),
    ]);

    // 启动自动刷新定时器
    _startAutoRefreshTimer(expiresIn);
  }

  /// 启动自动刷新定时器
  void _startAutoRefreshTimer(int expiresIn) {
    _refreshTimer?.cancel();

    // 在Token过期前5分钟刷新
    final refreshAfter = Duration(seconds: expiresIn - 300);

    _refreshTimer = Timer(refreshAfter, () {
      _logger.i('Auto-refreshing token...');
      notifyListeners();  // 通知UI执行刷新
    });
  }

  /// 清除所有Token（登出）
  Future<void> clearTokens() async {
    _refreshTimer?.cancel();

    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
      _secureStorage.delete(key: _tokenExpiryKey),
    ]);

    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
```

**Step 2.2: 改进ApiClient拦截器**

```dart
// lib_v2/data/services/api_client.dart (改进版)

class ApiClient {
  late final Dio _dio;
  final TokenService _tokenService;
  final VoidCallback? _onUnauthorized;  // 登出回调

  bool _isRefreshing = false;
  final List<RequestOptions> _pendingRequests = [];

  ApiClient(
    this._tokenService, {
    VoidCallback? onUnauthorized,
  }) : _onUnauthorized = onUnauthorized {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.addAll([
      _createAuthInterceptor(),
      _createRetryInterceptor(),
      _createLogInterceptor(),
    ]);
  }

  /// 认证拦截器 (处理Token刷新)
  Interceptor _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _tokenService.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          return _handle401Error(error, handler);
        }
        return handler.next(error);
      },
    );
  }

  /// 处理401错误 (Token过期)
  Future<void> _handle401Error(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (_isRefreshing) {
      // 已有刷新任务进行中，等待其完成
      _pendingRequests.add(error.requestOptions);
      return;
    }

    _isRefreshing = true;

    try {
      final newToken = await _refreshAccessToken();

      if (newToken != null) {
        // 更新当前请求的Token
        error.requestOptions.headers['Authorization'] = 'Bearer $newToken';

        // 重试当前请求
        final response = await _dio.fetch(error.requestOptions);
        handler.resolve(response);

        // 重试所有等待的请求
        for (final request in _pendingRequests) {
          request.headers['Authorization'] = 'Bearer $newToken';
        }
        _pendingRequests.clear();
      } else {
        // Token刷新失败，执行登出
        await _tokenService.clearTokens();
        _onUnauthorized?.call();
        handler.next(error);
      }
    } catch (e) {
      _logger.e('Token refresh error: $e');
      await _tokenService.clearTokens();
      _onUnauthorized?.call();
      handler.next(error);
    } finally {
      _isRefreshing = false;
    }
  }

  /// 刷新Access Token
  Future<String?> _refreshAccessToken() async {
    try {
      final refreshToken = await _tokenService.getRefreshToken();
      if (refreshToken == null) return null;

      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {'Authorization': null},  // 不使用Bearer Token
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final newAccessToken = response.data['data']['accessToken'] as String;
        final expiresIn = response.data['data']['expiresIn'] as int;

        await _tokenService.saveAccessToken(newAccessToken);

        // 重新启动自动刷新定时器
        _tokenService._startAutoRefreshTimer(expiresIn);

        return newAccessToken;
      }

      return null;
    } catch (e) {
      _logger.e('Refresh token error: $e');
      return null;
    }
  }

  /// 重试拦截器 (处理网络超时)
  Interceptor _createRetryInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (_isNetworkError(error) && !_isRefreshing) {
          for (int i = 0; i < 3; i++) {
            await Future.delayed(Duration(milliseconds: 100 * (i + 1)));
            try {
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              continue;
            }
          }
        }
        return handler.next(error);
      },
    );
  }

  bool _isNetworkError(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.unknown;
  }

  Interceptor _createLogInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        _logger.d('''
          → ${options.method} ${options.path}
          Headers: ${options.headers}
          Data: ${options.data}
        ''');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.d('''
          ← ${response.statusCode} ${response.requestOptions.path}
          Data: ${response.data}
        ''');
        return handler.next(response);
      },
      onError: (error, handler) {
        _logger.e('''
          ⚠ ${error.response?.statusCode} ${error.requestOptions.path}
          Message: ${error.message}
          Data: ${error.response?.data}
        ''');
        return handler.next(error);
      },
    );
  }
}
```

**Step 2.3: 在App中集成认证错误处理**

```dart
// lib_v2/main.dart (改进版)

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TokenService>(
          create: (_) => TokenService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<ApiClient>(
          create: (context) => ApiClient(
            context.read<TokenService>(),
            onUnauthorized: () {
              // Token失效，跳转到登录页
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ),
        Provider<WebSocketService>(
          create: (context) => WebSocketService(context.read<TokenService>()),
        ),
      ],
      child: MaterialApp(
        title: 'Time Schedule',
        home: Consumer<TokenService>(
          builder: (context, tokenService, _) {
            return FutureBuilder<bool>(
              future: tokenService.isLoggedIn(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.data == true) {
                  return const HomeScreen();
                } else {
                  return const LoginScreen();
                }
              },
            );
          },
        ),
      ),
    );
  }
}
```

**预期收益**:
- Token自动刷新，用户无感
- 多个并发请求的安全处理
- Token失效自动登出
- 网络错误自动重试

---

### Phase 3: WebSocket稳定性 (1周)

#### 目标: 可靠的实时连接

**Step 3.1: 完整的WebSocketService实现**

```dart
// lib_v2/data/services/websocket_service.dart (完整版)

import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

class WebSocketService extends ChangeNotifier {
  late IO.Socket socket;
  bool _isConnected = false;
  bool _isConnecting = false;
  StreamSubscription? _heartbeatTimer;
  StreamSubscription? _reconnectTimer;
  static const int _heartbeatInterval = 30;  // 秒
  static const int _maxReconnectAttempts = 5;
  int _reconnectAttempts = 0;

  final TokenService _tokenService;
  final Function(String, dynamic)? onEvent;
  final Function()? onConnected;
  final Function()? onDisconnected;

  WebSocketService(
    this._tokenService, {
    this.onEvent,
    this.onConnected,
    this.onDisconnected,
  }) {
    _initSocket();
  }

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;

  void _initSocket() {
    final token = _tokenService.getAccessToken();

    socket = IO.io(
      ApiConstants.wsBaseUrl,
      OptionBuilder()
        .setTransports(['websocket'])      // 必须！
        .disableAutoConnect()              // 必须！
        .setExtraHeaders({
          'Authorization': 'Bearer $token',
        })
        .build(),
    );

    _setupListeners();
  }

  void _setupListeners() {
    socket.on('connect', (_) {
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      _logger.i('WebSocket connected');
      _startHeartbeat();
      onConnected?.call();
      notifyListeners();
    });

    socket.on('disconnect', (_) {
      _isConnected = false;
      _logger.w('WebSocket disconnected');
      _stopHeartbeat();
      onDisconnected?.call();
      notifyListeners();
      _attemptReconnect();
    });

    socket.on('pong', (_) {
      _logger.d('Heartbeat pong received');
    });

    socket.on('error', (error) {
      _logger.e('WebSocket error: $error');
      _reconnectIfNeeded();
    });

    // 业务事件监听
    socket.on('study_room:update', (data) {
      onEvent?.call('study_room:update', data);
    });

    socket.on('task:create', (data) {
      onEvent?.call('task:create', data);
    });

    socket.on('task:update', (data) {
      onEvent?.call('task:update', data);
    });

    socket.on('task:delete', (data) {
      onEvent?.call('task:delete', data);
    });
  }

  /// 启动心跳检测
  void _startHeartbeat() {
    _stopHeartbeat();

    _heartbeatTimer = Stream.periodic(
      Duration(seconds: _heartbeatInterval),
      (_) => null,
    ).listen((_) {
      if (_isConnected) {
        socket.emit('ping');
        _logger.d('Heartbeat ping sent');
      }
    });
  }

  /// 停止心跳检测
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// 尝试重新连接
  void _attemptReconnect() {
    if (_isConnecting) return;

    _isConnecting = true;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.e('Max reconnect attempts reached');
      _isConnecting = false;
      return;
    }

    // 指数退避算法
    final delaySeconds = _getExponentialBackoffDelay(_reconnectAttempts);
    _logger.i('Attempting reconnect in ${delaySeconds}s (attempt ${_reconnectAttempts + 1}/$_maxReconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Future.delayed(Duration(seconds: delaySeconds)).asStream().listen((_) {
      if (!_isConnected && _reconnectAttempts < _maxReconnectAttempts) {
        _reconnectAttempts++;
        socket.connect();
      }
      _isConnecting = false;
    });
  }

  /// 计算指数退避延迟
  int _getExponentialBackoffDelay(int attempt) {
    // 1s, 2s, 4s, 8s, 16s
    final delay = 1 << attempt;  // 2^attempt
    return delay.clamp(1, 60);   // 最多60秒
  }

  /// 检查连接是否需要重连
  void _reconnectIfNeeded() {
    if (!_isConnected && _reconnectAttempts < _maxReconnectAttempts) {
      _attemptReconnect();
    }
  }

  /// 手动连接
  void connect() {
    if (!_isConnected && !_isConnecting) {
      _reconnectAttempts = 0;
      socket.connect();
    }
  }

  /// 手动断开连接
  void disconnect() {
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    socket.disconnect();
  }

  /// 发送事件
  void emit(String event, [dynamic data]) {
    if (_isConnected) {
      socket.emit(event, data);
      _logger.d('Event sent: $event');
    } else {
      _logger.w('Cannot emit event: WebSocket not connected');
    }
  }

  @override
  void dispose() {
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    disconnect();
    super.dispose();
  }
}
```

**Step 3.2: 在Provider中使用WebSocket**

```dart
// lib_v2/business/providers/study_room_provider.dart

class StudyRoomProvider extends ChangeNotifier {
  final WebSocketService _webSocketService;
  List<StudyRoom> _rooms = [];
  bool _isLoading = false;

  StudyRoomProvider(this._webSocketService) {
    _setupWebSocketListeners();
  }

  void _setupWebSocketListeners() {
    _webSocketService.onEvent = (event, data) {
      switch (event) {
        case 'study_room:update':
          _handleRoomUpdate(data);
          break;
        case 'room:user_joined':
          _handleUserJoined(data);
          break;
        case 'room:user_left':
          _handleUserLeft(data);
          break;
      }
    };
  }

  void _handleRoomUpdate(dynamic data) {
    final index = _rooms.indexWhere((r) => r.id == data['id']);
    if (index >= 0) {
      _rooms[index] = StudyRoom.fromJson(data);
    }
    notifyListeners();
  }

  // 其他处理方法...
}
```

**预期收益**:
- 自动重连机制
- 心跳保活
- 指数退避避免服务器压力
- 断网自动恢复

---

### Phase 4: 性能优化 (1周)

#### 目标: 更流畅的UI体验

**Step 4.1: 使用Selector优化Provider重建**

```dart
// 不好的做法：整个Provider变化导致重建
Consumer<TaskProvider>(
  builder: (context, provider, _) {
    return Column(
      children: [
        Text('总任务数: ${provider.tasks.length}'),  // 只需要这个
        ListView.builder(
          itemCount: provider.tasks.length,  // 不需要这个变化
          itemBuilder: (context, index) => TaskTile(task: provider.tasks[index]),
        ),
      ],
    );
  },
);

// 好的做法：使用Selector精准监听
class TaskListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 只监听任务数量
        Selector<TaskProvider, int>(
          selector: (context, provider) => provider.tasks.length,
          builder: (context, count, _) => Text('总任务数: $count'),
        ),
        // 只监听任务列表
        Selector<TaskProvider, List<TaskModel>>(
          selector: (context, provider) => provider.tasks,
          builder: (context, tasks, _) {
            return ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) => TaskTile(task: tasks[index]),
            );
          },
        ),
      ],
    );
  }
}
```

**Step 4.2: 使用const优化Widget重建**

```dart
// 不好的做法
class TaskTile extends StatelessWidget {
  final TaskModel task;
  TaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(task.title),
        trailing: Icon(Icons.check),  // 每次都创建新Icon
      ),
    );
  }
}

// 好的做法
class TaskTile extends StatelessWidget {
  final TaskModel task;

  const TaskTile({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(task.title),
        trailing: const Icon(Icons.check),  // const优化
      ),
    );
  }
}

// 使用const构造函数
const checkIcon = Icon(Icons.check);

class TaskTile extends StatelessWidget {
  final TaskModel task;

  const TaskTile({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(task.title),
        trailing: checkIcon,  // 复用const实例
      ),
    );
  }
}
```

**Step 4.3: 图片缓存优化**

```dart
// 使用cached_network_image优化网络图片加载
import 'package:cached_network_image/cached_network_image.dart';

class UserAvatar extends StatelessWidget {
  final String imageUrl;
  final double size;

  const UserAvatar({
    Key? key,
    required this.imageUrl,
    this.size = 48.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (context, url) {
        return Container(
          width: size,
          height: size,
          color: Colors.grey[300],
          child: const Center(child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )),
        );
      },
      errorWidget: (context, url, error) {
        return Container(
          width: size,
          height: size,
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        );
      },
      cacheManager: CacheManager(
        Config(
          'imageCache',
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 100,
        ),
      ),
    );
  }
}
```

**预期收益**:
- 列表滚动更流畅
- 内存占用减少
- 渲染性能提升30%

---

## 三、实施时间表

### Week 1-3: Phase 1 代码整合
- Week 1: 创建共享库结构，迁移models
- Week 2: 迁移repositories和widgets
- Week 3: 测试和bug修复

### Week 4-5: Phase 2 认证增强
- Week 4: 增强TokenService，改进拦截器
- Week 5: 集成和测试

### Week 6: Phase 3 WebSocket稳定性
- 实现完整的WebSocketService
- 集成心跳和重连机制
- 测试各种网络场景

### Week 7: Phase 4 性能优化
- 优化Provider使用
- 优化图片加载
- 性能测试和基准化

**总耗时**: 7周 (约2个月)

---

## 四、优先级排序

### 必须做 (P0)
1. ✓ 增强TokenService (自动刷新)
2. ✓ 完整的WebSocketService (心跳+重连)
3. ✓ 代码整合 (消除重复)

### 应该做 (P1)
1. 依赖升级到最新版本
2. Provider性能优化
3. 图片缓存优化

### 可以做 (P2)
1. 添加单元测试
2. 添加集成测试
3. 性能基准化

---

## 五、验收标准

### Phase 1 完成
- [ ] 共享库结构建立
- [ ] 代码重复率 < 20%
- [ ] 所有测试通过
- [ ] 两个版本功能一致

### Phase 2 完成
- [ ] Token自动刷新工作
- [ ] 401错误处理正确
- [ ] 并发请求无冲突
- [ ] 登出自动跳转登录

### Phase 3 完成
- [ ] WebSocket自动连接
- [ ] 心跳检测正常
- [ ] 断网自动重连
- [ ] 消息无丢失

### Phase 4 完成
- [ ] 列表滚动FPS > 50
- [ ] 内存占用减少20%
- [ ] 首屏加载时间 < 2s

---

## 六、监控指标

### 代码质量
- 代码行数
- 圈复杂度
- 测试覆盖率

### 性能指标
- 帧率 (FPS)
- 内存占用
- 网络请求时间
- 首屏加载时间

### 稳定性指标
- WebSocket连接成功率
- API错误率
- Token刷新失败率

---

## 七、相关文档

- `FLUTTER_REFACTOR_GUIDE.md` - 详细的重构指南
- `DEPENDENCY_UPGRADE_GUIDE.md` - 依赖升级指南
- `PROJECT_IMPROVEMENT_PLAN.md` - 本文档

---

## 附录：快速对标清单

完成度检查:

- [ ] Phase 1: 代码整合
  - [ ] lib_shared 创建
  - [ ] models 迁移
  - [ ] repositories 提取
  - [ ] UI components 共享
  - [ ] 测试通过

- [ ] Phase 2: 认证增强
  - [ ] Token自动刷新
  - [ ] 并发请求处理
  - [ ] 401错误处理
  - [ ] 自动登出

- [ ] Phase 3: WebSocket
  - [ ] 心跳检测
  - [ ] 自动重连
  - [ ] 指数退避
  - [ ] 事件监听

- [ ] Phase 4: 性能
  - [ ] Selector优化
  - [ ] Const优化
  - [ ] 图片缓存
  - [ ] 性能测试

---

## 问题反馈

如有任何问题，请参考：
- Flutter官方文档: https://docs.flutter.dev
- Provider包文档: https://pub.dev/packages/provider
- Dio包文档: https://pub.dev/packages/dio
- Socket.IO文档: https://pub.dev/packages/socket_io_client
