import 'package:logger/logger.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/token_service.dart';
import '../../core/constants/api_constants.dart';

/// 认证仓库 - 处理用户认证相关的API调用
class AuthRepository {
  final ApiClient _apiClient;
  final TokenService _tokenService;
  final Logger _logger = Logger();

  AuthRepository({
    required ApiClient apiClient,
    required TokenService tokenService,
  })  : _apiClient = apiClient,
        _tokenService = tokenService;

  /// 注册
  Future<AuthResponse> register({
    required String username,
    required String email,
    required String password,
    String? nickname,
  }) async {
    try {
      _logger.i('Registering user: $username');

      final response = await _apiClient.post(
        ApiConstants.authRegister,
        data: {
          'username': username,
          'email': email,
          'password': password,
          if (nickname != null) 'nickname': nickname,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error']?['message'] ?? 'Registration failed');
      }

      final authResponse = AuthResponse.fromJson(response.data['data']);

      // 保存令牌
      await _tokenService.saveTokens(
        accessToken: authResponse.tokens.accessToken,
        refreshToken: authResponse.tokens.refreshToken,
        userId: authResponse.user.id,
      );

      _logger.i('User registered successfully: ${authResponse.user.id}');
      return authResponse;
    } catch (e) {
      _logger.e('Registration error: $e');
      rethrow;
    }
  }

  /// 登录
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('Logging in: $email');

      final response = await _apiClient.post(
        ApiConstants.authLogin,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error']?['message'] ?? 'Login failed');
      }

      final authResponse = AuthResponse.fromJson(response.data['data']);

      // 保存令牌
      await _tokenService.saveTokens(
        accessToken: authResponse.tokens.accessToken,
        refreshToken: authResponse.tokens.refreshToken,
        userId: authResponse.user.id,
      );

      _logger.i('User logged in successfully: ${authResponse.user.id}');
      return authResponse;
    } catch (e) {
      _logger.e('Login error: $e');
      rethrow;
    }
  }

  /// 登出
  Future<void> logout() async {
    try {
      _logger.i('Logging out');

      final refreshToken = await _tokenService.getRefreshToken();

      if (refreshToken != null) {
        await _apiClient.post(
          ApiConstants.authLogout,
          data: {'refreshToken': refreshToken},
        );
      }

      // 清除本地令牌
      await _tokenService.clearTokens();

      _logger.i('User logged out successfully');
    } catch (e) {
      _logger.e('Logout error: $e');
      // 即使API调用失败，也要清除本地令牌
      await _tokenService.clearTokens();
    }
  }

  /// 获取当前用户信息
  Future<User> getCurrentUser() async {
    try {
      _logger.d('Fetching current user');

      final response = await _apiClient.get(ApiConstants.authMe);

      if (response.data['success'] != true) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to get user');
      }

      final user = User.fromJson(response.data['data']);
      _logger.d('Current user fetched: ${user.id}');
      return user;
    } catch (e) {
      _logger.e('Error fetching current user: $e');
      rethrow;
    }
  }

  /// 更新用户资料
  Future<User> updateProfile({
    String? nickname,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      _logger.i('Updating user profile');

      final response = await _apiClient.put(
        ApiConstants.authProfile,
        data: {
          if (nickname != null) 'nickname': nickname,
          if (bio != null) 'bio': bio,
          if (avatarUrl != null) 'avatarUrl': avatarUrl,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error']?['message'] ?? 'Update failed');
      }

      final user = User.fromJson(response.data['data']);
      _logger.i('Profile updated successfully');
      return user;
    } catch (e) {
      _logger.e('Profile update error: $e');
      rethrow;
    }
  }

  /// 修改密码
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _logger.i('Changing password');

      final response = await _apiClient.put(
        ApiConstants.authPassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error']?['message'] ?? 'Password change failed');
      }

      // 密码修改成功后需要重新登录
      await _tokenService.clearTokens();

      _logger.i('Password changed successfully');
    } catch (e) {
      _logger.e('Password change error: $e');
      rethrow;
    }
  }

  /// 检查是否已登录
  Future<bool> isLoggedIn() async {
    return await _tokenService.isLoggedIn();
  }
}
