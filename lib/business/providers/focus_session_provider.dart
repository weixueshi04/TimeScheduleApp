import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:focus_life/data/models/focus_session_model.dart';
import 'package:focus_life/data/models/task_model.dart';
import 'package:focus_life/data/repositories/focus_session_repository.dart';
import 'package:focus_life/data/local/hive_service.dart';
import 'package:focus_life/core/constants/app_constants.dart';
import 'package:focus_life/core/services/audio_service.dart';

/// 专注会话状态管理Provider
///
/// 负责管理番茄钟计时器的状态和业务逻辑
class FocusSessionProvider with ChangeNotifier {
  final FocusSessionRepository _repository = FocusSessionRepository();

  // ==================== 状态变量 ====================

  /// 当前会话状态
  FocusSessionState _state = FocusSessionState.idle;

  /// 当前会话类型
  SessionType _currentSessionType = SessionType.focus;

  /// 当前会话
  FocusSession? _currentSession;

  /// 关联的任务
  Task? _associatedTask;

  /// 剩余时间(秒)
  int _remainingSeconds = 0;

  /// 目标时间(分钟)
  int _targetMinutes = AppConstants.defaultPomodoroMinutes;

  /// 短休息时间(分钟)
  int _shortBreakMinutes = AppConstants.defaultShortBreakMinutes;

  /// 长休息时间(分钟)
  int _longBreakMinutes = AppConstants.defaultLongBreakMinutes;

  /// 完成的番茄钟数量
  int _completedPomodoros = 0;

  /// 中断次数
  int _interruptionCount = 0;

  /// 计时器
  Timer? _timer;

  /// 会话开始时间
  DateTime? _sessionStartTime;

  /// 今日历史会话
  List<FocusSession> _todaySessions = [];

  /// 是否正在加载
  bool _isLoading = false;

  // ==================== Getters ====================

  FocusSessionState get state => _state;
  SessionType get currentSessionType => _currentSessionType;
  FocusSession? get currentSession => _currentSession;
  Task? get associatedTask => _associatedTask;
  int get remainingSeconds => _remainingSeconds;
  int get targetMinutes => _targetMinutes;
  int get shortBreakMinutes => _shortBreakMinutes;
  int get longBreakMinutes => _longBreakMinutes;
  int get completedPomodoros => _completedPomodoros;
  int get interruptionCount => _interruptionCount;
  bool get isLoading => _isLoading;
  List<FocusSession> get todaySessions => _todaySessions;

  /// 获取进度百分比 (0.0 - 1.0)
  double get progress {
    final totalSeconds = _currentSessionType.getDurationMinutes(
      targetMinutes,
      shortBreakMinutes,
      longBreakMinutes,
    ) * 60;
    if (totalSeconds == 0) return 0.0;
    return 1.0 - (_remainingSeconds / totalSeconds);
  }

  /// 获取格式化的剩余时间 (MM:SS)
  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 是否正在运行
  bool get isRunning => _state == FocusSessionState.running;

  /// 是否已暂停
  bool get isPaused => _state == FocusSessionState.paused;

  /// 是否空闲
  bool get isIdle => _state == FocusSessionState.idle;

  /// 获取今日专注总时长(分钟)
  int get todayFocusMinutes => _repository.getTodayFocusMinutes();

  /// 获取今日完成会话数
  int get todaySessionsCount => _todaySessions.length;

  /// 获取今日平均质量分数
  double get todayAverageQuality {
    if (_todaySessions.isEmpty) return 0.0;
    return _todaySessions.map((s) => s.qualityScore).reduce((a, b) => a + b) /
        _todaySessions.length;
  }

  // ==================== 初始化 ====================

  /// 加载用户设置
  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final settings = HiveService.instance.settings;
      _targetMinutes = settings.pomodoroMinutes;
      _shortBreakMinutes = settings.shortBreakMinutes;
      _longBreakMinutes = settings.longBreakMinutes;

      await loadTodaySessions();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 加载今日会话
  Future<void> loadTodaySessions() async {
    _todaySessions = _repository.getTodaySessions();
    notifyListeners();
  }

  // ==================== 计时器控制 ====================

  /// 开始专注会话
  Future<void> startFocusSession({Task? task}) async {
    if (_state != FocusSessionState.idle) return;

    _currentSessionType = SessionType.focus;
    _associatedTask = task;
    _remainingSeconds = _targetMinutes * 60;
    _interruptionCount = 0;
    _sessionStartTime = DateTime.now();

    // 创建新会话
    _currentSession = FocusSession(
      id: null,
      taskId: task?.id,
      taskTitle: task?.title,
      sessionType: SessionType.focus,
      targetMinutes: _targetMinutes,
      startTime: _sessionStartTime!,
    );

    _state = FocusSessionState.running;
    _startTimer();
    notifyListeners();
  }

  /// 开始休息会话
  Future<void> startBreakSession({bool isLongBreak = false}) async {
    if (_state != FocusSessionState.idle) return;

    _currentSessionType = isLongBreak ? SessionType.longBreak : SessionType.shortBreak;
    _remainingSeconds = (isLongBreak ? _longBreakMinutes : _shortBreakMinutes) * 60;
    _sessionStartTime = DateTime.now();

    // 创建新会话
    _currentSession = FocusSession(
      id: null,
      sessionType: _currentSessionType,
      targetMinutes: isLongBreak ? _longBreakMinutes : _shortBreakMinutes,
      startTime: _sessionStartTime!,
    );

    _state = FocusSessionState.running;
    _startTimer();
    notifyListeners();
  }

  /// 暂停会话
  void pauseSession() {
    if (_state != FocusSessionState.running) return;

    _state = FocusSessionState.paused;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  /// 恢复会话
  void resumeSession() {
    if (_state != FocusSessionState.paused) return;

    _state = FocusSessionState.running;
    _startTimer();
    notifyListeners();
  }

  /// 停止会话
  Future<void> stopSession() async {
    if (_state == FocusSessionState.idle) return;

    _timer?.cancel();
    _timer = null;

    // 如果会话已经开始,保存记录
    if (_currentSession != null && _sessionStartTime != null) {
      final elapsedMinutes = DateTime.now().difference(_sessionStartTime!).inMinutes;

      // 完成当前会话
      _currentSession!.complete(elapsedMinutes, _interruptionCount);

      // 保存到数据库
      await _repository.addFocusSession(_currentSession!);

      // 重新加载今日会话
      await loadTodaySessions();
    }

    _reset();
    notifyListeners();
  }

  /// 完成会话
  Future<void> completeSession() async {
    if (_currentSession == null || _sessionStartTime == null) return;

    final elapsedMinutes = DateTime.now().difference(_sessionStartTime!).inMinutes;

    // 完成当前会话
    _currentSession!.complete(elapsedMinutes, _interruptionCount);

    // 保存到数据库
    await _repository.addFocusSession(_currentSession!);

    // 播放完成音效
    if (_currentSessionType == SessionType.focus) {
      await AudioService.instance.playFocusComplete();
      _completedPomodoros++;
    } else {
      await AudioService.instance.playBreakComplete();
    }

    // 重新加载今日会话
    await loadTodaySessions();

    _timer?.cancel();
    _timer = null;
    _reset();
    notifyListeners();
  }

  /// 记录中断
  void recordInterruption() {
    if (_state != FocusSessionState.running && _state != FocusSessionState.paused) {
      return;
    }

    _interruptionCount++;
    notifyListeners();
  }

  /// 跳过休息
  Future<void> skipBreak() async {
    if (_currentSessionType == SessionType.focus) return;

    await stopSession();
  }

  // ==================== 私有方法 ====================

  /// 启动计时器
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        // 时间到,完成会话
        completeSession();
      }
    });
  }

  /// 重置状态
  void _reset() {
    _state = FocusSessionState.idle;
    _currentSession = null;
    _associatedTask = null;
    _remainingSeconds = 0;
    _interruptionCount = 0;
    _sessionStartTime = null;
  }

  // ==================== 设置 ====================

  /// 设置专注时长
  void setFocusDuration(int minutes) {
    _targetMinutes = minutes;
    HiveService.instance.settings.pomodoroMinutes = minutes;
    HiveService.instance.settings.save();
    notifyListeners();
  }

  /// 设置短休息时长
  void setShortBreakDuration(int minutes) {
    _shortBreakMinutes = minutes;
    HiveService.instance.settings.shortBreakMinutes = minutes;
    HiveService.instance.settings.save();
    notifyListeners();
  }

  /// 设置长休息时长
  void setLongBreakDuration(int minutes) {
    _longBreakMinutes = minutes;
    HiveService.instance.settings.longBreakMinutes = minutes;
    HiveService.instance.settings.save();
    notifyListeners();
  }

  // ==================== 统计信息 ====================

  /// 获取本周专注时长统计
  Map<DateTime, int> getWeeklyFocusStats() {
    return _repository.getDailyFocusMinutesStats(days: 7);
  }

  /// 获取平均质量分数
  double getAverageQualityScore() {
    return _repository.getAverageQualityScore();
  }

  /// 获取最佳专注时段
  List<int> getBestFocusHours() {
    return _repository.getBestFocusHours();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// 专注会话状态
enum FocusSessionState {
  idle, // 空闲
  running, // 运行中
  paused, // 已暂停
}

/// 会话类型扩展
extension SessionTypeExtension on SessionType {
  /// 获取会话时长
  int getDurationMinutes(int focus, int shortBreak, int longBreak) {
    switch (this) {
      case SessionType.focus:
        return focus;
      case SessionType.shortBreak:
        return shortBreak;
      case SessionType.longBreak:
        return longBreak;
    }
  }

  /// 获取显示名称
  String get displayName {
    switch (this) {
      case SessionType.focus:
        return '专注';
      case SessionType.shortBreak:
        return '短休息';
      case SessionType.longBreak:
        return '长休息';
    }
  }
}

/// 会话状态扩展
extension FocusSessionStateExtension on FocusSessionState {
  String get displayName {
    switch (this) {
      case FocusSessionState.idle:
        return '空闲';
      case FocusSessionState.running:
        return '运行中';
      case FocusSessionState.paused:
        return '已暂停';
    }
  }
}
