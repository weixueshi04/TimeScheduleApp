import 'package:hive_flutter/hive_flutter.dart';
import 'package:focus_life/data/models/task_model.dart';
import 'package:focus_life/data/models/focus_session_model.dart';
import 'package:focus_life/data/models/health_record_model.dart';
import 'package:focus_life/data/models/user_settings_model.dart';
import 'package:focus_life/core/constants/app_constants.dart';

/// Hive数据库服务 - 负责数据库的初始化、管理和访问
class HiveService {
  /// 私有构造函数（单例模式）
  HiveService._();

  /// 单例实例
  static final HiveService instance = HiveService._();

  /// 是否已初始化
  bool _isInitialized = false;

  /// 初始化Hive数据库
  ///
  /// 步骤：
  /// 1. 初始化Hive Flutter
  /// 2. 注册所有TypeAdapter
  /// 3. 打开所有Box
  /// 4. 初始化默认设置（如果不存在）
  Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    try {
      // 1. 初始化Hive Flutter
      await Hive.initFlutter();

      // 2. 注册TypeAdapter
      _registerAdapters();

      // 3. 打开所有Box
      await _openBoxes();

      // 4. 初始化默认设置
      await _initializeDefaultSettings();

      _isInitialized = true;
      print('✅ Hive数据库初始化成功');
    } catch (e) {
      print('❌ Hive数据库初始化失败: $e');
      rethrow;
    }
  }

  /// 注册所有TypeAdapter
  void _registerAdapters() {
    // 任务相关
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(TaskCategoryAdapter());
    Hive.registerAdapter(TaskPriorityAdapter());
    Hive.registerAdapter(SubTaskAdapter());
    Hive.registerAdapter(RecurringRuleAdapter());
    Hive.registerAdapter(RecurringTypeAdapter());

    // 专注会话相关
    Hive.registerAdapter(FocusSessionAdapter());
    Hive.registerAdapter(FocusTypeAdapter());

    // 健康记录相关
    Hive.registerAdapter(HealthRecordAdapter());
    Hive.registerAdapter(MealRecordAdapter());
    Hive.registerAdapter(MealTypeAdapter());

    // 用户设置
    Hive.registerAdapter(UserSettingsAdapter());

    print('✅ TypeAdapter注册完成');
  }

  /// 打开所有Box
  Future<void> _openBoxes() async {
    await Future.wait([
      Hive.openBox<Task>(AppConstants.tasksBoxName),
      Hive.openBox<FocusSession>(AppConstants.focusSessionsBoxName),
      Hive.openBox<HealthRecord>(AppConstants.healthRecordsBoxName),
      Hive.openBox<UserSettings>(AppConstants.settingsBoxName),
    ]);

    print('✅ 所有Box打开完成');
  }

  /// 初始化默认设置
  Future<void> _initializeDefaultSettings() async {
    final settingsBox = Hive.box<UserSettings>(AppConstants.settingsBoxName);

    if (settingsBox.isEmpty) {
      // 创建默认设置
      final defaultSettings = UserSettings();
      await settingsBox.put('default', defaultSettings);
      print('✅ 默认设置初始化完成');
    }
  }

  // ==================== Box访问器 ====================

  /// 获取任务Box
  Box<Task> get tasksBox {
    _ensureInitialized();
    return Hive.box<Task>(AppConstants.tasksBoxName);
  }

  /// 获取专注会话Box
  Box<FocusSession> get focusSessionsBox {
    _ensureInitialized();
    return Hive.box<FocusSession>(AppConstants.focusSessionsBoxName);
  }

  /// 获取健康记录Box
  Box<HealthRecord> get healthRecordsBox {
    _ensureInitialized();
    return Hive.box<HealthRecord>(AppConstants.healthRecordsBoxName);
  }

  /// 获取设置Box
  Box<UserSettings> get settingsBox {
    _ensureInitialized();
    return Hive.box<UserSettings>(AppConstants.settingsBoxName);
  }

  /// 获取用户设置
  UserSettings get settings {
    final box = settingsBox;
    return box.get('default', defaultValue: UserSettings())!;
  }

  /// 更新用户设置
  Future<void> updateSettings(UserSettings settings) async {
    final box = settingsBox;
    await box.put('default', settings);
  }

  // ==================== 数据统计 ====================

  /// 获取所有任务总数
  int get totalTasksCount => tasksBox.length;

  /// 获取已完成任务数
  int get completedTasksCount {
    return tasksBox.values.where((task) => task.isCompleted).length;
  }

  /// 获取未完成任务数
  int get pendingTasksCount {
    return tasksBox.values.where((task) => !task.isCompleted).length;
  }

  /// 获取今日专注时长（分钟）
  int get todayFocusMinutes {
    final today = DateTime.now();
    return focusSessionsBox.values
        .where((session) =>
            session.startTime.year == today.year &&
            session.startTime.month == today.month &&
            session.startTime.day == today.day)
        .fold(0, (sum, session) => sum + session.durationMinutes);
  }

  /// 获取今日健康记录
  HealthRecord? get todayHealthRecord {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';

    // 首先尝试直接获取
    final record = healthRecordsBox.get(todayKey);
    if (record != null) return record;

    // 如果不存在，遍历查找
    for (var record in healthRecordsBox.values) {
      if (record.date.year == today.year &&
          record.date.month == today.month &&
          record.date.day == today.day) {
        return record;
      }
    }

    return null;
  }

  /// 获取或创建今日健康记录
  Future<HealthRecord> getOrCreateTodayHealthRecord() async {
    var record = todayHealthRecord;
    if (record == null) {
      final today = DateTime.now();
      final todayKey = '${today.year}-${today.month}-${today.day}';
      record = HealthRecord(date: today);
      await healthRecordsBox.put(todayKey, record);
    }
    return record;
  }

  // ==================== 数据清理 ====================

  /// 清除所有数据（仅用于调试）
  Future<void> clearAllData() async {
    await Future.wait([
      tasksBox.clear(),
      focusSessionsBox.clear(),
      healthRecordsBox.clear(),
      // 不清除设置
    ]);
    print('⚠️ 所有数据已清除');
  }

  /// 清除已完成的任务
  Future<void> clearCompletedTasks() async {
    final completedKeys = tasksBox.keys.where((key) {
      final task = tasksBox.get(key);
      return task != null && task.isCompleted;
    }).toList();

    await tasksBox.deleteAll(completedKeys);
    print('✅ 已清除${completedKeys.length}个已完成任务');
  }

  /// 清除过期的专注会话（超过30天）
  Future<void> clearOldFocusSessions({int daysToKeep = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    final oldKeys = focusSessionsBox.keys.where((key) {
      final session = focusSessionsBox.get(key);
      return session != null && session.startTime.isBefore(cutoffDate);
    }).toList();

    await focusSessionsBox.deleteAll(oldKeys);
    print('✅ 已清除${oldKeys.length}个过期专注会话');
  }

  // ==================== 其他方法 ====================

  /// 确保已初始化
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('HiveService未初始化，请先调用init()方法');
    }
  }

  /// 关闭所有Box
  Future<void> close() async {
    if (!_isInitialized) return;

    await Hive.close();
    _isInitialized = false;
    print('✅ Hive数据库已关闭');
  }

  /// 压缩所有Box（优化存储空间）
  Future<void> compactAll() async {
    await Future.wait([
      tasksBox.compact(),
      focusSessionsBox.compact(),
      healthRecordsBox.compact(),
      settingsBox.compact(),
    ]);
    print('✅ 所有Box已压缩');
  }
}
