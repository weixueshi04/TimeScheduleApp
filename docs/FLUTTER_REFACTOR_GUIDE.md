# Flutter时间管理应用 - 重构技术建议指南 (2025)

## 项目概况分析
根据您当前的项目结构，您已经有两个版本：
- **v1.0**: 本地应用（Hive存储，无网络）
- **v2.0**: 网络应用（Dio+Provider+JWT认证）

## 一、单项目多版本代码组织结构最佳实践

### 1.1 当前项目结构评估
您的多版本管理方案（主项目vs app_v2）存在代码重复。建议升级为以下结构：

```
TimeScheduleApp/
├── lib/                          # 共享代码
│   ├── common/
│   │   ├── constants/           # 应用常量
│   │   ├── utils/               # 工具函数
│   │   └── themes/              # UI主题
│   ├── data/
│   │   ├── models/              # 数据模型
│   │   ├── repositories/        # 数据仓储层
│   │   └── local/               # 本地存储（可选）
│   ├── domain/                  # 业务逻辑层
│   └── presentation/            # UI层
│
├── lib_v1/                       # v1.0专用代码（仅本地差异）
│   ├── data/
│   │   └── local/hive_service/  # Hive本地存储
│   └── main_v1.dart
│
├── lib_v2/                       # v2.0专用代码（网络功能）
│   ├── data/
│   │   ├── services/            # API和WebSocket服务
│   │   └── remote/              # 远程数据源
│   ├── business/
│   │   └── providers/           # Provider状态管理
│   └── main_v2.dart
│
└── pubspec.yaml                 # 统一依赖管理
```

### 1.2 使用Flutter Flavor实现多环境配置

```yaml
# android/app/build.gradle
flavorDimensions "env"
productFlavors {
    v1 {
        dimension "env"
        applicationIdSuffix ".v1"
    }
    v2 {
        dimension "env"
        applicationIdSuffix ".v2"
    }
}
```

### 1.3 版本管理工具 - FVM (Flutter Version Manager)

推荐使用FVM管理Flutter SDK版本：

```bash
# 安装FVM
brew tap leoafarias/fvm
brew install fvm

# 为项目指定Flutter版本
fvm install 3.24.0
fvm use 3.24.0

# 创建.fvmrc文件
echo '{"flutterSdkVersion": "3.24.0"}' > .fvmrc
```

---

## 二、网络库最新版本与最佳实践

### 2.1 Dio网络库（最新版本: 5.4.3）

**您当前使用的版本**: `dio: ^5.4.0` ✓ 最新稳定版

**优势**:
- 强大的拦截器系统
- 支持自动token刷新
- 超时管理完善
- 请求/响应转换

**推荐配置**:

```dart
class ApiClient {
  late final Dio _dio;
  final TokenService _tokenService;

  ApiClient(this._tokenService) {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.example.com',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // 拦截器优化
    _dio.interceptors.addAll([
      _createAuthInterceptor(),
      _createLogInterceptor(),
      _createErrorInterceptor(),
    ]);
  }

  // 超时重试拦截器
  Interceptor _createRetryInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.type == DioExceptionType.connectionTimeout) {
          // 实现指数退避重试
          for (int i = 0; i < 3; i++) {
            await Future.delayed(Duration(seconds: 2 ^ i));
            try {
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              continue;
            }
          }
        }
        handler.next(error);
      },
    );
  }
}
```

### 2.2 Socket.IO Client（最新版本: 2.0.3+1）

**您当前使用的版本**: `socket_io_client: ^2.0.3+1` ✓ 最新稳定版

**WebSocket服务最佳实现**:

```dart
class WebSocketService extends ChangeNotifier {
  late IO.Socket socket;
  bool _isConnected = false;

  WebSocketService(this._tokenService) {
    _initSocket();
  }

  void _initSocket() {
    socket = IO.io(
      'https://api.example.com',
      OptionBuilder()
        .setTransports(['websocket']) // Flutter强制使用WebSocket
        .disableAutoConnect()
        .setExtraHeaders({
          'Authorization': 'Bearer ${_tokenService.getAccessToken()}',
        })
        .setAuth({
          'token': _tokenService.getAccessToken(),
        })
        .build(),
    );

    _setupListeners();
  }

  void _setupListeners() {
    socket.on('connect', (_) {
      _isConnected = true;
      _logger.i('WebSocket connected');
      notifyListeners();
    });

    socket.on('disconnect', (_) {
      _isConnected = false;
      _logger.w('WebSocket disconnected');
      notifyListeners();
    });

    socket.on('study_room:update', (data) {
      // 实时更新处理
      _handleStudyRoomUpdate(data);
    });

    socket.on('error', (error) {
      _logger.e('WebSocket error: $error');
    });
  }

  // 重连机制
  void reconnect() {
    if (!_isConnected) {
      socket.connect();
    }
  }
}
```

**重要注意事项**:
- Flutter App中必须使用`.setTransports(['websocket'])` 避免双重事件触发
- 如果autoConnect: true，不要再调用.connect()
- 实现心跳检测防止连接断开：

```dart
void _startHeartbeat() {
  Timer.periodic(const Duration(seconds: 30), (timer) {
    if (_isConnected) {
      socket.emit('ping');
    }
  });
}
```

---

## 三、Provider状态管理最佳实践（v6.1.1）

### 3.1 推荐使用的Provider模式

**当前使用**: `provider: ^6.1.1` ✓ 最新稳定版

**最佳实践方案 - MVVM架构**:

```dart
// 1. 模型层 (Model)
class TaskModel {
  final int id;
  final String title;
  final DateTime dueDate;

  TaskModel({
    required this.id,
    required this.title,
    required this.dueDate,
  });
}

// 2. 视图模型层 (ViewModel/Provider)
class TaskProvider extends ChangeNotifier {
  final TaskRepository _repository;
  List<TaskModel> _tasks = [];
  bool _isLoading = false;

  TaskProvider(this._repository);

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    try {
      _tasks = await _repository.getTasks();
    } catch (e) {
      _logger.e('Error loading tasks: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createTask(String title, DateTime dueDate) async {
    try {
      final newTask = await _repository.createTask(title, dueDate);
      _tasks.add(newTask);
      notifyListeners();
    } catch (e) {
      _logger.e('Error creating task: $e');
      rethrow;
    }
  }
}

// 3. UI层
class TaskScreen extends ConsumerWidget {
  const TaskScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: provider.tasks.length,
          itemBuilder: (context, index) {
            final task = provider.tasks[index];
            return TaskTile(task: task);
          },
        );
      },
    );
  }
}
```

### 3.2 优化选择器以提高性能

```dart
// 使用Selector避免不必要的重建
class TaskCount extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Selector<TaskProvider, int>(
      selector: (context, provider) => provider.tasks.length,
      builder: (context, count, _) {
        return Text('Tasks: $count');
      },
    );
  }
}
```

### 3.3 Provider依赖注入和组织

```dart
// main.dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        // 服务层
        Provider<TokenService>(
          create: (_) => TokenService(),
        ),
        Provider<ApiClient>(
          create: (context) => ApiClient(context.read<TokenService>()),
        ),
        Provider<WebSocketService>(
          create: (context) => WebSocketService(context.read<TokenService>()),
        ),

        // 仓储层
        Provider<TaskRepository>(
          create: (context) => TaskRepository(context.read<ApiClient>()),
        ),

        // 状态管理层
        ChangeNotifierProvider(
          create: (context) => AuthProvider(context.read<ApiClient>()),
        ),
        ChangeNotifierProvider(
          create: (context) => TaskProvider(context.read<TaskRepository>()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
```

---

## 四、JWT Token认证最佳实践

### 4.1 安全存储方案

**您当前实现**: 使用`flutter_secure_storage: ^9.0.0` ✓ 正确做法

**改进建议**：

```dart
class TokenService {
  final FlutterSecureStorage _secureStorage;

  TokenService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage(
        aOptions: AndroidOptions(
          keyCipherAlgorithm: KeyCipherAlgorithm.AES_ECB_OAEPwithSHA_256andMGF1Padding,
          storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_this_device_this_app_only,
        ),
      );

  // 保存token时添加过期时间
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
  }) async {
    final expiryDate = DateTime.now().add(Duration(seconds: expiresIn));

    await Future.wait([
      _secureStorage.write(key: 'access_token', value: accessToken),
      _secureStorage.write(key: 'refresh_token', value: refreshToken),
      _secureStorage.write(key: 'token_expiry', value: expiryDate.toIso8601String()),
    ]);
  }

  // 检查token是否过期
  Future<bool> isTokenExpired() async {
    final expiryStr = await _secureStorage.read(key: 'token_expiry');
    if (expiryStr == null) return true;

    final expiry = DateTime.parse(expiryStr);
    return DateTime.now().isAfter(expiry.subtract(Duration(minutes: 5)));
  }
}
```

### 4.2 自动刷新Token实现

**您当前实现已经有基础**，改进版本：

```dart
class AuthInterceptor extends Interceptor {
  final TokenService _tokenService;
  bool _isRefreshing = false;
  List<RequestOptions> _requestsWaitingForRefresh = [];

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 在请求前检查并刷新过期的token
    if (await _tokenService.isTokenExpired()) {
      try {
        await _tokenService.refreshToken();
      } catch (e) {
        _logger.e('Token refresh failed, redirecting to login');
        // 清除token并导航到登录页
        await _tokenService.clearTokens();
        _navigateToLogin();
        return handler.reject(DioException(
          requestOptions: options,
          error: 'Token expired and refresh failed',
        ));
      }
    }

    // 添加token到请求头
    final token = await _tokenService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      if (!_isRefreshing) {
        _isRefreshing = true;

        try {
          await _tokenService.refreshToken();

          // 重试所有等待的请求
          for (var req in _requestsWaitingForRefresh) {
            final token = await _tokenService.getAccessToken();
            req.headers['Authorization'] = 'Bearer $token';
          }
          _requestsWaitingForRefresh.clear();
          _isRefreshing = false;

          // 重试当前请求
          return handler.resolve(
            await _dio.fetch(err.requestOptions),
          );
        } catch (e) {
          _isRefreshing = false;
          _requestsWaitingForRefresh.clear();
          return handler.reject(err);
        }
      } else {
        // 等待刷新完成后再重试
        _requestsWaitingForRefresh.add(err.requestOptions);
        return handler.next(err);
      }
    }

    return handler.next(err);
  }
}
```

### 4.3 Token存储策略对比

| 存储方式 | 安全性 | 推荐使用场景 |
|---------|--------|------------|
| SharedPreferences | 低 | 非敏感数据 |
| FlutterSecureStorage | 高 | JWT Token、密码 |
| Hive(加密) | 中-高 | 大量本地数据 |
| SQLCipher | 高 | 大型数据库 |

**推荐配置**：
- Access Token (短期): FlutterSecureStorage
- Refresh Token (长期): FlutterSecureStorage
- 用户信息: Hive加密存储
- 偏好设置: SharedPreferences

---

## 五、最新版本依赖建议表

```yaml
dependencies:
  flutter:
    sdk: flutter

  # 状态管理 (已是最新)
  provider: ^6.2.1        # 更新: 6.1.1 -> 6.2.1

  # 网络请求 (已是最新)
  dio: ^5.4.3             # 已是最新: 5.4.0
  socket_io_client: ^2.0.3+1  # 已是最新

  # 安全存储 (已是最新)
  flutter_secure_storage: ^9.2.2  # 更新: 9.0.0 -> 9.2.2

  # 本地存储
  shared_preferences: ^2.2.3  # 已是最新
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # UI组件
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.1
  table_calendar: ^3.0.9
  fl_chart: ^0.66.0

  # 日志和调试
  logger: ^2.4.0          # 更新: 2.0.2+1 -> 2.4.0

  # 工具
  intl: ^0.19.0           # 更新: 0.18.1 -> 0.19.0
  uuid: ^4.3.3
  equatable: ^2.0.5

  # JSON序列化
  json_annotation: ^4.9.0  # 更新: 4.8.1 -> 4.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  build_runner: ^2.4.8
  json_serializable: ^6.8.0  # 更新: 6.7.1 -> 6.8.0
  hive_generator: ^2.0.1
```

---

## 六、GitHub优秀案例参考

### 推荐的迁移和重构案例：

1. **CarGuo/gsy_flutter_book**
   - 完整的Flutter APP开发教程
   - GSYGithubAppFlutter项目示例
   - 涵盖网络请求、状态管理、路由等
   - GitHub: https://github.com/CarGuo/gsy_flutter_book

2. **persilee/flutter_pro**
   - 跨平台iOS/Android应用
   - MVVM架构模式实现
   - Provider+Dio集成示例
   - GitHub: https://github.com/persilee/flutter_pro

3. **minhvuongrbs/Flutter-BoilerPlate**
   - Flutter项目模板
   - Provider + Dio最佳实践
   - 生产级代码组织结构
   - GitHub: https://github.com/minhvuongrbs/Flutter-BoilerPlate

4. **flutter/samples**
   - 官方示例代码库
   - 包含add-to-app、platform_design等高速用法
   - 参考最新的Flutter最佳实践
   - GitHub: https://github.com/flutter/samples

---

## 七、重构行动计划

### Phase 1: 项目结构优化 (1-2周)
- [ ] 提取共享代码到lib/
- [ ] 创建lib_v1和lib_v2目录
- [ ] 配置Flutter Flavor
- [ ] 设置.fvmrc文件

### Phase 2: 依赖升级 (1周)
- [ ] 升级所有依赖到最新版本
- [ ] 修复兼容性问题
- [ ] 运行测试确保功能正常

### Phase 3: 认证系统完善 (1-2周)
- [ ] 增强TokenService (过期检查、自动刷新)
- [ ] 完善错误处理和重试机制
- [ ] 添加自动登出和登录重定向

### Phase 4: WebSocket稳定性 (1周)
- [ ] 实现心跳检测
- [ ] 添加自动重连机制
- [ ] 处理异常断线场景

### Phase 5: 状态管理优化 (1-2周)
- [ ] 重构Provider为MVVM模式
- [ ] 添加Selector优化性能
- [ ] 完善错误状态管理

### Phase 6: 测试和文档 (1周)
- [ ] 单元测试覆盖关键功能
- [ ] 集成测试
- [ ] 编写迁移文档

---

## 八、常见坑点和解决方案

### 8.1 Socket.IO重复事件
**问题**: 事件被触发两次
**原因**: autoConnect和手动connect同时调用
**解决**: 使用`.disableAutoConnect()`，然后手动调用`.connect()`

### 8.2 Token刷新死循环
**问题**: Token刷新失败导致无限重试
**原因**: 刷新Token本身返回401
**解决**: 在刷新Token时不使用Auth拦截器

### 8.3 Provider性能下降
**问题**: UI重建过于频繁
**原因**: 使用Consumer或Provider.of导致全量重建
**解决**: 使用Selector或select()方法只监听特定属性

### 8.4 WebSocket连接不上
**问题**: Flutter中WebSocket连接失败
**原因**: 使用了多个transport导致错误
**解决**: 强制使用WebSocket: `.setTransports(['websocket'])`

---

## 附录：快速检查清单

- [ ] Flutter SDK版本使用FVM管理 (3.24.0或以上)
- [ ] Provider版本: 6.2.1或以上
- [ ] Dio版本: 5.4.3或以上
- [ ] flutter_secure_storage用于token存储
- [ ] 实现自动Token刷新机制
- [ ] WebSocket设置.setTransports(['websocket'])
- [ ] 实现心跳检测防止连接断开
- [ ] 使用Selector优化Provider性能
- [ ] 多版本代码通过Flavor区分
- [ ] 错误处理完善，有日志记录
