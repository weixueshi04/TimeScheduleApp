import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../../core/constants/api_constants.dart';

/// Token服务 - 安全存储和管理JWT令牌
class TokenService {
  final FlutterSecureStorage _secureStorage;
  final Logger _logger = Logger();

  // Token过期时间的key
  static const String _tokenExpiryKey = 'token_expiry';

  // Token刷新的提前时间（5分钟）
  static const Duration _refreshBeforeExpiry = Duration(minutes: 5);

  TokenService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// 保存访问令牌
  Future<void> saveAccessToken(String token) async {
    try {
      await _secureStorage.write(
        key: ApiConstants.accessTokenKey,
        value: token,
      );

      // 解析并保存token过期时间
      final expiryTime = _parseTokenExpiry(token);
      if (expiryTime != null) {
        await _secureStorage.write(
          key: _tokenExpiryKey,
          value: expiryTime.toIso8601String(),
        );
        _logger.d('Access token saved with expiry: $expiryTime');
      } else {
        _logger.d('Access token saved (no expiry parsed)');
      }
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
        _secureStorage.delete(key: _tokenExpiryKey),
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

  /// 解析JWT Token的过期时间
  DateTime? _parseTokenExpiry(String token) {
    try {
      // JWT格式: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) {
        _logger.w('Invalid JWT token format');
        return null;
      }

      // 解码payload部分（base64）
      final payload = parts[1];
      // 添加padding（base64解码需要）
      final normalizedPayload = base64Url.normalize(payload);
      final payloadString = utf8.decode(base64Url.decode(normalizedPayload));
      final payloadMap = json.decode(payloadString) as Map<String, dynamic>;

      // 获取exp字段（Unix时间戳，秒）
      final exp = payloadMap['exp'];
      if (exp == null) {
        _logger.w('No exp field in token payload');
        return null;
      }

      // 转换为DateTime
      return DateTime.fromMillisecondsSinceEpoch(
        (exp as int) * 1000,
        isUtc: true,
      );
    } catch (e) {
      _logger.e('Error parsing token expiry: $e');
      return null;
    }
  }

  /// 获取Token过期时间
  Future<DateTime?> getTokenExpiry() async {
    try {
      final expiryStr = await _secureStorage.read(key: _tokenExpiryKey);
      if (expiryStr == null) {
        return null;
      }
      return DateTime.parse(expiryStr);
    } catch (e) {
      _logger.e('Error reading token expiry: $e');
      return null;
    }
  }

  /// 检查Token是否已过期
  Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) {
      // 无法确定过期时间，假设未过期
      return false;
    }

    return DateTime.now().toUtc().isAfter(expiry);
  }

  /// 检查Token是否需要刷新（即将在5分钟内过期）
  Future<bool> shouldRefreshToken() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) {
      // 无法确定过期时间，不需要刷新
      return false;
    }

    final now = DateTime.now().toUtc();
    final refreshTime = expiry.subtract(_refreshBeforeExpiry);

    // 如果当前时间在刷新时间之后，则需要刷新
    final shouldRefresh = now.isAfter(refreshTime);

    if (shouldRefresh) {
      _logger.i('Token should be refreshed (expires at: $expiry)');
    }

    return shouldRefresh;
  }

  /// 获取Token剩余有效时间
  Future<Duration?> getTokenRemainingTime() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) {
      return null;
    }

    final now = DateTime.now().toUtc();
    if (now.isAfter(expiry)) {
      return Duration.zero;
    }

    return expiry.difference(now);
  }
}
