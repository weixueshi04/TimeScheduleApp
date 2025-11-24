import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../../core/constants/api_constants.dart';
import 'token_service.dart';

/// API客户端 - 封装Dio网络请求
class ApiClient {
  late final Dio _dio;
  final TokenService _tokenService;
  final Logger _logger = Logger();

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
        // 获取访问令牌
        final token = await _tokenService.getAccessToken();
        if (token != null) {
          options.headers[ApiConstants.authorizationHeader] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // 401错误，尝试刷新token
        if (error.response?.statusCode == 401) {
          _logger.w('Access token expired, attempting to refresh...');

          try {
            // 刷新token
            final newToken = await _refreshToken();

            if (newToken != null) {
              // 重试原请求
              final options = error.requestOptions;
              options.headers[ApiConstants.authorizationHeader] =
                  'Bearer $newToken';

              final response = await _dio.fetch(options);
              return handler.resolve(response);
            }
          } catch (e) {
            _logger.e('Token refresh failed: $e');
            // 清除token，需要重新登录
            await _tokenService.clearTokens();
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

  /// 刷新访问令牌
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
