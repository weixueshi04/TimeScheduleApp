import '../services/api_client.dart';
import '../models/focus_session.dart';

class FocusRepository {
  final ApiClient _apiClient;

  FocusRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// 获取专注会话列表
  Future<List<FocusSession>> getFocusSessions() async {
    final response = await _apiClient.get('/focus');
    final List data = response.data['data'];
    return data.map((json) => FocusSession.fromJson(json)).toList();
  }

  /// 获取当前活跃的专注会话
  Future<FocusSession?> getActiveSession() async {
    final response = await _apiClient.get('/focus/active');
    final data = response.data['data'];
    return data != null ? FocusSession.fromJson(data) : null;
  }

  /// 开始专注会话
  Future<FocusSession> startFocusSession(StartFocusRequest request) async {
    final response = await _apiClient.post(
      '/focus',
      data: request.toJson(),
    );
    return FocusSession.fromJson(response.data['data']);
  }

  /// 完成专注会话
  Future<FocusSession> completeFocusSession(
    int sessionId,
    CompleteFocusRequest request,
  ) async {
    final response = await _apiClient.put(
      '/focus/$sessionId/complete',
      data: request.toJson(),
    );
    return FocusSession.fromJson(response.data['data']);
  }

  /// 中断专注会话
  Future<FocusSession> interruptFocusSession(int sessionId) async {
    final response = await _apiClient.put('/focus/$sessionId/interrupt');
    return FocusSession.fromJson(response.data['data']);
  }

  /// 放弃专注会话
  Future<void> abandonFocusSession(int sessionId) async {
    await _apiClient.delete('/focus/$sessionId');
  }

  /// 获取今日专注会话
  Future<List<FocusSession>> getTodaySessions() async {
    final response = await _apiClient.get('/focus/today');
    final List data = response.data['data'];
    return data.map((json) => FocusSession.fromJson(json)).toList();
  }

  /// 获取专注统计
  Future<FocusStats> getFocusStats() async {
    final response = await _apiClient.get('/focus/stats');
    return FocusStats.fromJson(response.data['data']);
  }
}
