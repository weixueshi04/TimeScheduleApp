/// API常量配置
class ApiConstants {
  // 基础URL
  static const String baseUrl = 'http://localhost:3000';
  static const String apiVersion = 'v1';
  static const String apiBaseUrl = '$baseUrl/api/$apiVersion';

  // WebSocket URL
  static const String wsUrl = 'http://localhost:3000';

  // API端点
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';
  static const String authProfile = '/auth/profile';
  static const String authPassword = '/auth/password';

  static const String tasks = '/tasks';
  static const String tasksToday = '/tasks/today';
  static const String tasksStatistics = '/tasks/statistics';

  static const String focus = '/focus';
  static const String focusToday = '/focus/today';
  static const String focusStatistics = '/focus/statistics';

  static const String health = '/health';
  static const String healthToday = '/health/today';
  static const String healthStatistics = '/health/statistics';
  static const String healthTrends = '/health/trends';

  static const String studyRooms = '/study-rooms';
  static const String studyRoomsMy = '/study-rooms/my';

  // HTTP Headers
  static const String authorizationHeader = 'Authorization';
  static const String contentTypeHeader = 'Content-Type';
  static const String contentTypeJson = 'application/json';

  // Token存储键
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';

  // 超时时间
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // 分页
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}
