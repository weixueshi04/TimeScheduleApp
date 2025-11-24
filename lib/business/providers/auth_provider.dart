import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/websocket_service.dart';

/// 认证状态
enum AuthStatus {
  initial,      // 初始状态
  authenticated, // 已认证
  unauthenticated, // 未认证
  loading,      // 加载中
}

/// 认证Provider - 管理用户认证状态
class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository;
  final WebSocketService _wsService;
  final Logger _logger = Logger();

  AuthStatus _status = AuthStatus.initial;
  User? _currentUser;
  String? _errorMessage;

  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  AuthProvider({
    required AuthRepository authRepository,
    required WebSocketService wsService,
  })  : _authRepository = authRepository,
        _wsService = wsService;

  /// 初始化 - 检查登录状态
  Future<void> initialize() async {
    try {
      _logger.i('Initializing AuthProvider');

      final isLoggedIn = await _authRepository.isLoggedIn();

      if (isLoggedIn) {
        _logger.i('User is logged in, fetching user info');
        await _fetchCurrentUser();

        // 连接WebSocket
        await _connectWebSocket();
      } else {
        _logger.i('User is not logged in');
        _setStatus(AuthStatus.unauthenticated);
      }
    } catch (e) {
      _logger.e('Initialization error: $e');
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  /// 注册
  Future<void> register({
    required String username,
    required String email,
    required String password,
    String? nickname,
  }) async {
    try {
      _setStatus(AuthStatus.loading);
      _clearError();

      final authResponse = await _authRepository.register(
        username: username,
        email: email,
        password: password,
        nickname: nickname,
      );

      _currentUser = authResponse.user;
      _setStatus(AuthStatus.authenticated);

      // 连接WebSocket
      await _connectWebSocket();

      _logger.i('Registration successful');
    } catch (e) {
      _logger.e('Registration failed: $e');
      _setError(e.toString());
      _setStatus(AuthStatus.unauthenticated);
      rethrow;
    }
  }

  /// 登录
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      _setStatus(AuthStatus.loading);
      _clearError();

      final authResponse = await _authRepository.login(
        email: email,
        password: password,
      );

      _currentUser = authResponse.user;
      _setStatus(AuthStatus.authenticated);

      // 连接WebSocket
      await _connectWebSocket();

      _logger.i('Login successful');
    } catch (e) {
      _logger.e('Login failed: $e');
      _setError(e.toString());
      _setStatus(AuthStatus.unauthenticated);
      rethrow;
    }
  }

  /// 登出
  Future<void> logout() async {
    try {
      _setStatus(AuthStatus.loading);

      // 断开WebSocket
      _wsService.disconnect();

      await _authRepository.logout();

      _currentUser = null;
      _setStatus(AuthStatus.unauthenticated);

      _logger.i('Logout successful');
    } catch (e) {
      _logger.e('Logout failed: $e');
      _setError(e.toString());
      // 即使失败也要清除本地状态
      _currentUser = null;
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  /// 获取当前用户信息
  Future<void> _fetchCurrentUser() async {
    try {
      _currentUser = await _authRepository.getCurrentUser();
      _setStatus(AuthStatus.authenticated);
    } catch (e) {
      _logger.e('Failed to fetch current user: $e');
      _setStatus(AuthStatus.unauthenticated);
      rethrow;
    }
  }

  /// 刷新用户信息
  Future<void> refreshUser() async {
    try {
      if (_status != AuthStatus.authenticated) {
        _logger.w('Cannot refresh user: not authenticated');
        return;
      }

      _currentUser = await _authRepository.getCurrentUser();
      notifyListeners();
      _logger.d('User info refreshed');
    } catch (e) {
      _logger.e('Failed to refresh user: $e');
    }
  }

  /// 更新用户资料
  Future<void> updateProfile({
    String? nickname,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final updatedUser = await _authRepository.updateProfile(
        nickname: nickname,
        bio: bio,
        avatarUrl: avatarUrl,
      );

      _currentUser = updatedUser;
      notifyListeners();

      _logger.i('Profile updated');
    } catch (e) {
      _logger.e('Profile update failed: $e');
      rethrow;
    }
  }

  /// 修改密码
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      // 密码修改后需要重新登录
      _currentUser = null;
      _setStatus(AuthStatus.unauthenticated);

      _logger.i('Password changed, please login again');
    } catch (e) {
      _logger.e('Password change failed: $e');
      rethrow;
    }
  }

  /// 连接WebSocket
  Future<void> _connectWebSocket() async {
    try {
      await _wsService.connect();
      _logger.i('WebSocket connected');
    } catch (e) {
      _logger.e('WebSocket connection failed: $e');
      // WebSocket连接失败不影响认证状态
    }
  }

  /// 设置状态
  void _setStatus(AuthStatus status) {
    if (_status != status) {
      _status = status;
      notifyListeners();
    }
  }

  /// 设置错误
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// 清除错误
  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _wsService.disconnect();
    super.dispose();
  }
}
