import 'package:focus_life/data/models/focus_session_model.dart';
import 'package:focus_life/data/local/hive_service.dart';

/// 专注会话数据仓库 - 负责专注会话数据的CRUD操作
class FocusSessionRepository {
  final HiveService _hiveService = HiveService.instance;

  // ==================== 创建 Create ====================

  /// 添加新的专注会话
  Future<void> addSession(FocusSession session) async {
    final box = _hiveService.focusSessionsBox;
    await box.put(session.id, session);
  }

  /// 批量添加专注会话
  Future<void> addSessions(List<FocusSession> sessions) async {
    final box = _hiveService.focusSessionsBox;
    final map = {for (var session in sessions) session.id: session};
    await box.putAll(map);
  }

  // ==================== 读取 Read ====================

  /// 获取所有专注会话
  List<FocusSession> getAllSessions() {
    return _hiveService.focusSessionsBox.values.toList();
  }

  /// 根据ID获取专注会话
  FocusSession? getSessionById(String id) {
    return _hiveService.focusSessionsBox.get(id);
  }

  /// 获取今天的专注会话
  List<FocusSession> getTodaySessions() {
    final today = DateTime.now();
    return getAllSessions().where((session) {
      return session.startTime.year == today.year &&
          session.startTime.month == today.month &&
          session.startTime.day == today.day;
    }).toList();
  }

  /// 获取本周的专注会话
  List<FocusSession> getThisWeekSessions() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return getAllSessions().where((session) {
      return session.startTime.isAfter(startOfWeek);
    }).toList();
  }

  /// 获取本月的专注会话
  List<FocusSession> getThisMonthSessions() {
    final now = DateTime.now();
    return getAllSessions().where((session) {
      return session.startTime.year == now.year &&
          session.startTime.month == now.month;
    }).toList();
  }

  /// 根据日期范围获取专注会话
  List<FocusSession> getSessionsByDateRange(DateTime start, DateTime end) {
    return getAllSessions().where((session) {
      return session.startTime.isAfter(start) &&
          session.startTime.isBefore(end);
    }).toList();
  }

  /// 根据任务ID获取专注会话
  List<FocusSession> getSessionsByTaskId(String taskId) {
    return getAllSessions()
        .where((session) => session.taskId == taskId)
        .toList();
  }

  /// 根据专注类型获取会话
  List<FocusSession> getSessionsByType(FocusType type) {
    return getAllSessions()
        .where((session) => session.focusType == type)
        .toList();
  }

  /// 获取已完成的会话
  List<FocusSession> getCompletedSessions() {
    return getAllSessions().where((session) => session.isCompleted).toList();
  }

  /// 获取正在进行的会话
  FocusSession? getActiveSession() {
    return getAllSessions().where((session) => session.isActive).firstOrNull;
  }

  // ==================== 更新 Update ====================

  /// 更新专注会话
  Future<void> updateSession(FocusSession session) async {
    await _hiveService.focusSessionsBox.put(session.id, session);
  }

  /// 完成会话
  Future<void> completeSession(String sessionId) async {
    final session = getSessionById(sessionId);
    if (session != null) {
      session.complete();
    }
  }

  /// 记录会话中断
  Future<void> recordInterruption(String sessionId) async {
    final session = getSessionById(sessionId);
    if (session != null) {
      session.interrupt();
    }
  }

  // ==================== 删除 Delete ====================

  /// 删除专注会话
  Future<void> deleteSession(String sessionId) async {
    await _hiveService.focusSessionsBox.delete(sessionId);
  }

  /// 批量删除会话
  Future<void> deleteSessions(List<String> sessionIds) async {
    await _hiveService.focusSessionsBox.deleteAll(sessionIds);
  }

  /// 删除过期会话（超过指定天数）
  Future<void> deleteOldSessions({int daysToKeep = 30}) async {
    await _hiveService.clearOldFocusSessions(daysToKeep: daysToKeep);
  }

  // ==================== 统计 Statistics ====================

  /// 获取总专注时长（分钟）
  int getTotalFocusMinutes() {
    return getAllSessions()
        .fold(0, (sum, session) => sum + session.durationMinutes);
  }

  /// 获取今日专注时长（分钟）
  int getTodayFocusMinutes() {
    return getTodaySessions()
        .fold(0, (sum, session) => sum + session.durationMinutes);
  }

  /// 获取本周专注时长（分钟）
  int getThisWeekFocusMinutes() {
    return getThisWeekSessions()
        .fold(0, (sum, session) => sum + session.durationMinutes);
  }

  /// 获取本月专注时长（分钟）
  int getThisMonthFocusMinutes() {
    return getThisMonthSessions()
        .fold(0, (sum, session) => sum + session.durationMinutes);
  }

  /// 获取今日完成的番茄钟数量
  int getTodayPomodoroCount() {
    return getTodaySessions()
        .where((session) =>
            session.focusType == FocusType.pomodoro && session.isCompleted)
        .length;
  }

  /// 获取平均专注质量评分
  double getAverageQualityScore() {
    final sessions = getAllSessions().where((s) => s.isCompleted);
    if (sessions.isEmpty) return 0;

    final totalScore = sessions.fold(0, (sum, session) => sum + session.qualityScore);
    return totalScore / sessions.length;
  }

  /// 获取平均完成率
  double getAverageCompletionRate() {
    final sessions = getAllSessions();
    if (sessions.isEmpty) return 0;

    final totalRate = sessions.fold(0.0, (sum, session) => sum + session.completionRate);
    return totalRate / sessions.length;
  }

  /// 获取总中断次数
  int getTotalInterruptions() {
    return getAllSessions()
        .fold(0, (sum, session) => sum + session.interruptionCount);
  }

  /// 获取今日中断次数
  int getTodayInterruptions() {
    return getTodaySessions()
        .fold(0, (sum, session) => sum + session.interruptionCount);
  }

  /// 获取每日专注时长统计（最近N天）
  Map<DateTime, int> getDailyFocusMinutesStats({int days = 7}) {
    final now = DateTime.now();
    final result = <DateTime, int>{};

    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final sessions = getAllSessions().where((session) {
        return session.startTime.year == date.year &&
            session.startTime.month == date.month &&
            session.startTime.day == date.day;
      });

      result[date] = sessions.fold(0, (sum, session) => sum + session.durationMinutes);
    }

    return result;
  }

  /// 获取每日番茄钟完成数量统计（最近N天）
  Map<DateTime, int> getDailyPomodoroCountStats({int days = 7}) {
    final now = DateTime.now();
    final result = <DateTime, int>{};

    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final sessions = getAllSessions().where((session) {
        return session.focusType == FocusType.pomodoro &&
            session.isCompleted &&
            session.startTime.year == date.year &&
            session.startTime.month == date.month &&
            session.startTime.day == date.day;
      });

      result[date] = sessions.length;
    }

    return result;
  }

  /// 获取各类型会话的数量统计
  Map<FocusType, int> getSessionsCountByType() {
    final sessions = getAllSessions();
    return {
      for (var type in FocusType.values)
        type: sessions.where((session) => session.focusType == type).length,
    };
  }

  // ==================== 排序 Sorting ====================

  /// 按开始时间排序（最新的在前）
  List<FocusSession> sortSessionsByStartTime(List<FocusSession> sessions) {
    return sessions..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  /// 按时长排序（最长的在前）
  List<FocusSession> sortSessionsByDuration(List<FocusSession> sessions) {
    return sessions
      ..sort((a, b) => b.durationMinutes.compareTo(a.durationMinutes));
  }

  /// 按质量评分排序（最高的在前）
  List<FocusSession> sortSessionsByQuality(List<FocusSession> sessions) {
    return sessions..sort((a, b) => b.qualityScore.compareTo(a.qualityScore));
  }
}
