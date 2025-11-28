import 'dart:async';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../../core/constants/api_constants.dart';
import 'token_service.dart';

/// API客户端 - 封装Dio网络请求
class ApiClient {
  late final Dio _dio;
  final TokenService _tokenService;
  final Logger _logger = Logger();

  // Token刷新锁，防止并发请求重复刷新
  bool _isRefreshing = false;
  final List<void Function(String?)> _refreshCallbacks = [];

  ApiClient(this._tokenService) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.apiBaseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      headers: {
        ApiConstants.contentTypeHeader: ApiConstants.contentTypeJson,
      },
    ));

    // 添加拦截器
    _dio.interceptors.add(_createAuthInterceptor());
    _dio.interceptors.add(_createLogInterceptor());
  }

  /// 认证拦截器
  Interceptor _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 跳过刷新token的请求
        if (options.path.contains(ApiConstants.authRefresh)) {
          return handler.next(options);
        }

        // 主动检查token是否需要刷新
        final shouldRefresh = await _tokenService.shouldRefreshToken();
        if (shouldRefresh) {
          _logger.i('Token needs refresh before request');

          // 如果正在刷新，等待刷新完成
          if (_isRefreshing) {
            _logger.d('Token refresh in progress, waiting...');
            final newToken = await _waitForTokenRefresh();
            if (newToken != null) {
              options.headers[ApiConstants.authorizationHeader] =
                  'Bearer $newToken';
            }
          } else {
            // 执行token刷新
            final newToken = await _performTokenRefresh();
            if (newToken != null) {
              options.headers[ApiConstants.authorizationHeader] =
                  'Bearer $newToken';
            } else {
              // 刷新失败，清除token并返回错误
              await _tokenService.clearTokens();
              return handler.reject(
                DioException(
                  requestOptions: options,
                  error: 'Token refresh failed',
                  type: DioExceptionType.badResponse,
                ),
              );
            }
          }
        } else {
          // Token不需要刷新，正常添加token
          final token = await _tokenService.getAccessToken();
          if (token != null) {
            options.headers[ApiConstants.authorizationHeader] =
                'Bearer $token';
          }
        }

        handler.next(options);
      },
      onError: (error, handler) async {
        // 401错误，尝试刷新token
        if (error.response?.statusCode == 401) {
          _logger.w('Got 401 error, attempting to refresh token...');

          // 如果正在刷新，等待刷新完成
          if (_isRefreshing) {
            _logger.d('Token refresh in progress, waiting...');
            final newToken = await _waitForTokenRefresh();

            if (newToken != null) {
              // 重试原请求
              final options = error.requestOptions;
              options.headers[ApiConstants.authorizationHeader] =
                  'Bearer $newToken';

              try {
                final response = await _dio.fetch(options);
                return handler.resolve(response);
              } catch (e) {
                _logger.e('Retry request failed: $e');
              }
            }
          } else {
            // 执行token刷新
            final newToken = await _performTokenRefresh();

            if (newToken != null) {
              // 重试原请求
              final options = error.requestOptions;
              options.headers[ApiConstants.authorizationHeader] =
                  'Bearer $newToken';

              try {
                final response = await _dio.fetch(options);
                return handler.resolve(response);
              } catch (e) {
                _logger.e('Retry request failed: $e');
              }
            } else {
              // 刷新失败，清除token
              await _tokenService.clearTokens();
            }
          }
        }

        handler.next(error);
      },
    );
  }

  /// 日志拦截器
  Interceptor _createLogInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        _logger.d(
            '→ ${options.method} ${options.path}\n'
            'Headers: ${options.headers}\n'
            'Data: ${options.data}',
        );
        handler.next(options);
      },
      onResponse: (response, handler) {
        _logger.d(
            '← ${response.statusCode} ${response.requestOptions.path}\n'
            'Data: ${response.data}',
        );
        handler.next(response);
      },
      onError: (error, handler) {
        _logger.e(
            '⚠ ${error.response?.statusCode} ${error.requestOptions.path}\n'
            'Message: ${error.message}\n'
            'Data: ${error.response?.data}',
        );
        handler.next(error);
      },
    );
  }

  /// 刷新访问令牌（原有方法）
  Future<String?> _refreshToken() async {
    try {
      final refreshToken = await _tokenService.getRefreshToken();
      if (refreshToken == null) {
        _logger.w('No refresh token available');
        return null;
      }

      final response = await _dio.post(
        ApiConstants.authRefresh,
        data: {'refreshToken': refreshToken},
        options: Options(
          headers: {
            ApiConstants.authorizationHeader: null, // 不使用access token
          },
        ),
      );

      if (response.statusCode == 200 &&
          response.data['success'] == true) {
        final newAccessToken = response.data['data']['accessToken'] as String;
        await _tokenService.saveAccessToken(newAccessToken);
        _logger.i('Access token refreshed successfully');
        return newAccessToken;
      }

      return null;
    } catch (e) {
      _logger.e('Error refreshing token: $e');
      return null;
    }
  }

  /// 执行Token刷新（带锁，防止并发）
  Future<String?> _performTokenRefresh() async {
    if (_isRefreshing) {
      _logger.w('Token refresh already in progress');
      return _waitForTokenRefresh();
    }

    _isRefreshing = true;
    _logger.i('Starting token refresh...');

    try {
      final newToken = await _refreshToken();

      // 通知所有等待的回调
      for (final callback in _refreshCallbacks) {
        callback(newToken);
      }
      _refreshCallbacks.clear();

      return newToken;
    } finally {
      _isRefreshing = false;
    }
  }

  /// 等待Token刷新完成
  Future<String?> _waitForTokenRefresh() async {
    if (!_isRefreshing) {
      _logger.w('No token refresh in progress');
      return await _tokenService.getAccessToken();
    }

    // 创建一个Future，等待刷新完成
    final completer = Completer<String?>();

    _refreshCallbacks.add((newToken) {
      if (!completer.isCompleted) {
        completer.complete(newToken);
      }
    });

    // 设置超时（30秒）
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _logger.e('Token refresh wait timeout');
        return null;
      },
    );
  }

  /// GET请求
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// POST请求
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PUT请求
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// DELETE请求
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
