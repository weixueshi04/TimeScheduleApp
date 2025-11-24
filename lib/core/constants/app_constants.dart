/// FocusLife APP 全局常量定义
class AppConstants {
  // ==================== 应用信息 ====================

  /// 应用名称
  static const String appName = 'FocusLife';

  /// 应用中文名
  static const String appNameCN = '专注生活';

  /// 应用版本
  static const String appVersion = '1.0.0';

  // ==================== 番茄钟默认配置 ====================

  /// 默认番茄钟时长（分钟）
  static const int defaultPomodoroMinutes = 25;

  /// 默认短休息时长（分钟）
  static const int defaultShortBreakMinutes = 5;

  /// 默认长休息时长（分钟）
  static const int defaultLongBreakMinutes = 15;

  /// 长休息前的番茄钟数量
  static const int pomodorosBeforeLongBreak = 4;

  // ==================== 健康提醒默认配置 ====================

  /// 默认久坐提醒间隔（分钟）
  static const int defaultSitReminderMinutes = 60;

  /// 默认饮水提醒间隔（分钟）
  static const int defaultWaterReminderMinutes = 120;

  /// 默认睡眠提醒提前时间（分钟）
  static const int defaultSleepReminderMinutesBefore = 30;

  // ==================== 健康目标默认值 ====================

  /// 每日睡眠目标（分钟）- 8小时
  static const int dailySleepGoalMinutes = 480;

  /// 每日饮水目标（杯）
  static const int dailyWaterGoal = 8;

  /// 每日运动目标（分钟）
  static const int dailyExerciseGoalMinutes = 30;

  /// 每日步数目标
  static const int dailyStepsGoal = 8000;

  // ==================== 数据库相关 ====================

  /// Hive Box名称
  static const String tasksBoxName = 'tasks';
  static const String focusSessionsBoxName = 'focus_sessions';
  static const String healthRecordsBoxName = 'health_records';
  static const String statisticsBoxName = 'statistics';
  static const String settingsBoxName = 'settings';

  // ==================== 通知ID ====================

  /// 任务提醒通知ID起始值
  static const int taskReminderNotificationIdStart = 1000;

  /// 久坐提醒通知ID
  static const int sitReminderNotificationId = 100;

  /// 饮水提醒通知ID
  static const int waterReminderNotificationId = 101;

  /// 睡眠提醒通知ID
  static const int sleepReminderNotificationId = 102;

  /// 用餐提醒通知ID起始值
  static const int mealReminderNotificationIdStart = 200;

  // ==================== 时间格式 ====================

  /// 日期格式
  static const String dateFormat = 'yyyy-MM-dd';

  /// 时间格式
  static const String timeFormat = 'HH:mm';

  /// 日期时间格式
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';

  /// 显示用日期格式（中文）
  static const String displayDateFormat = 'yyyy年MM月dd日';

  /// 显示用时间格式
  static const String displayTimeFormat = 'HH:mm';

  // ==================== 动画时长 ====================

  /// 短动画时长（毫秒）
  static const int shortAnimationDuration = 200;

  /// 中等动画时长（毫秒）
  static const int mediumAnimationDuration = 300;

  /// 长动画时长（毫秒）
  static const int longAnimationDuration = 500;

  // ==================== 其他配置 ====================

  /// 任务标题最大长度
  static const int maxTaskTitleLength = 100;

  /// 任务描述最大长度
  static const int maxTaskDescriptionLength = 500;

  /// 备注最大长度
  static const int maxNotesLength = 1000;
}
