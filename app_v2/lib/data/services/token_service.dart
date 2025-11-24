import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../../core/constants/api_constants.dart';

/// Token服务 - 安全存储和管理JWT令牌
class TokenService {
  final FlutterSecureStorage _secureStorage;
  final Logger _logger = Logger();

  TokenService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// 保存访问令牌
  Future<void> saveAccessToken(String token) async {
    try {
      await _secureStorage.write(
        key: ApiConstants.accessTokenKey,
        value: token,
      );
      _logger.d('Access token saved');
    } catch (e) {
      _logger.e('Error saving access token: $e');
      rethrow;
    }
  }

  /// 获取访问令牌
  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: ApiConstants.accessTokenKey);
    } catch (e) {
      _logger.e('Error reading access token: $e');
      return null;
    }
  }

  /// 保存刷新令牌
  Future<void> saveRefreshToken(String token) async {
    try {
      await _secureStorage.write(
        key: ApiConstants.refreshTokenKey,
        value: token,
      );
      _logger.d('Refresh token saved');
    } catch (e) {
      _logger.e('Error saving refresh token: $e');
      rethrow;
    }
  }

  /// 获取刷新令牌
  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: ApiConstants.refreshTokenKey);
    } catch (e) {
      _logger.e('Error reading refresh token: $e');
      return null;
    }
  }

  /// 保存用户ID
  Future<void> saveUserId(int userId) async {
    try {
      await _secureStorage.write(
        key: ApiConstants.userIdKey,
        value: userId.toString(),
      );
      _logger.d('User ID saved: $userId');
    } catch (e) {
      _logger.e('Error saving user ID: $e');
      rethrow;
    }
  }

  /// 获取用户ID
  Future<int?> getUserId() async {
    try {
      final userIdStr = await _secureStorage.read(key: ApiConstants.userIdKey);
      return userIdStr != null ? int.tryParse(userIdStr) : null;
    } catch (e) {
      _logger.e('Error reading user ID: $e');
      return null;
    }
  }

  /// 保存所有令牌
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int userId,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      saveUserId(userId),
    ]);
    _logger.i('All tokens saved for user: $userId');
  }

  /// 清除所有令牌（登出）
  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _secureStorage.delete(key: ApiConstants.accessTokenKey),
        _secureStorage.delete(key: ApiConstants.refreshTokenKey),
        _secureStorage.delete(key: ApiConstants.userIdKey),
      ]);
      _logger.i('All tokens cleared');
    } catch (e) {
      _logger.e('Error clearing tokens: $e');
      rethrow;
    }
  }

  /// 检查是否已登录
  Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }
}
