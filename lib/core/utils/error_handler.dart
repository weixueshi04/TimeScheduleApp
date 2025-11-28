import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// 错误类型
enum ErrorType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  unknown,
}

/// 应用错误
class AppError {
  final ErrorType type;
  final String message;
  final String? detail;
  final int? statusCode;
  final dynamic originalError;

  const AppError({
    required this.type,
    required this.message,
    this.detail,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() {
    return 'AppError(type: $type, message: $message, statusCode: $statusCode)';
  }
}

/// 统一错误处理器
class ErrorHandler {
  static final Logger _logger = Logger();

  /// 处理错误并返回AppError
  static AppError handleError(dynamic error) {
    _logger.e('Handling error: $error');

    if (error is DioException) {
      return _handleDioError(error);
    }

    if (error is AppError) {
      return error;
    }

    // 未知错误
    return AppError(
      type: ErrorType.unknown,
      message: '发生未知错误',
      detail: error.toString(),
      originalError: error,
    );
  }

  /// 处理Dio网络错误
  static AppError _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppError(
          type: ErrorType.timeout,
          message: '请求超时，请检查网络连接',
          detail: '连接服务器超时',
          originalError: error,
        );

      case DioExceptionType.badResponse:
        return _handleHttpError(error);

      case DioExceptionType.cancel:
        return AppError(
          type: ErrorType.unknown,
          message: '请求已取消',
          originalError: error,
        );

      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
      default:
        return AppError(
          type: ErrorType.network,
          message: '网络连接失败，请检查网络设置',
          detail: error.message,
          originalError: error,
        );
    }
  }

  /// 处理HTTP错误
  static AppError _handleHttpError(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    // 尝试从响应中提取错误消息
    String? serverMessage;
    if (responseData is Map<String, dynamic>) {
      serverMessage = responseData['message'] as String? ??
          responseData['error'] as String?;
    }

    switch (statusCode) {
      case 400:
        return AppError(
          type: ErrorType.unknown,
          message: serverMessage ?? '请求参数错误',
          statusCode: 400,
          originalError: error,
        );

      case 401:
        return AppError(
          type: ErrorType.unauthorized,
          message: serverMessage ?? '登录已过期，请重新登录',
          statusCode: 401,
          originalError: error,
        );

      case 403:
        return AppError(
          type: ErrorType.forbidden,
          message: serverMessage ?? '没有权限访问',
          statusCode: 403,
          originalError: error,
        );

      case 404:
        return AppError(
          type: ErrorType.notFound,
          message: serverMessage ?? '请求的资源不存在',
          statusCode: 404,
          originalError: error,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        return AppError(
          type: ErrorType.serverError,
          message: serverMessage ?? '服务器错误，请稍后重试',
          statusCode: statusCode,
          originalError: error,
        );

      default:
        return AppError(
          type: ErrorType.unknown,
          message: serverMessage ?? '请求失败（$statusCode）',
          statusCode: statusCode,
          originalError: error,
        );
    }
  }

  /// 获取错误提示消息
  static String getErrorMessage(dynamic error) {
    final appError = handleError(error);
    return appError.message;
  }

  /// 判断错误是否需要重试
  static bool shouldRetry(AppError error) {
    return error.type == ErrorType.network ||
        error.type == ErrorType.timeout ||
        (error.type == ErrorType.serverError &&
            error.statusCode != null &&
            error.statusCode! >= 500);
  }

  /// 判断错误是否需要登出
  static bool shouldLogout(AppError error) {
    return error.type == ErrorType.unauthorized;
  }

  /// 记录错误日志
  static void logError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    final appError = handleError(error);

    if (context != null) {
      _logger.e('[$context] ${appError.message}', error, stackTrace);
    } else {
      _logger.e(appError.message, error, stackTrace);
    }
  }
}
