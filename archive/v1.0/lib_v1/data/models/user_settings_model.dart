import 'package:hive/hive.dart';

part 'user_settings_model.g.dart';

/// 用户设置模型 - 存储APP的各项配置
@HiveType(typeId: 40)
class UserSettings extends HiveObject {
  // ==================== 番茄钟设置 ====================

  /// 番茄钟时长（分钟）
  @HiveField(0)
  int pomodoroMinutes;

  /// 短休息时长（分钟）
  @HiveField(1)
  int shortBreakMinutes;

  /// 长休息时长（分钟）
  @HiveField(2)
  int longBreakMinutes;

  /// 长休息前需要完成的番茄钟数量
  @HiveField(3)
  int pomodorosBeforeLongBreak;

  // ==================== 提醒设置 ====================

  /// 是否启用任务提醒
  @HiveField(4)
  bool enableTaskReminders;

  /// 是否启用健康提醒
  @HiveField(5)
  bool enableHealthReminders;

  // ==================== 久坐提醒 ====================

  /// 是否启用久坐提醒
  @HiveField(6)
  bool enableSitReminder;

  /// 久坐提醒间隔（分钟）
  @HiveField(7)
  int sitReminderMinutes;

  // ==================== 饮水提醒 ====================

  /// 是否启用饮水提醒
  @HiveField(8)
  bool enableWaterReminder;

  /// 饮水提醒间隔（分钟）
  @HiveField(9)
  int waterReminderMinutes;

  // ==================== 睡眠提醒 ====================

  /// 是否启用睡眠提醒
  @HiveField(10)
  bool enableSleepReminder;

  /// 就寝时间（小时）
  @HiveField(11)
  int bedTimeHour;

  /// 就寝时间（分钟）
  @HiveField(12)
  int bedTimeMinute;

  /// 睡眠提醒提前时间（分钟）
  @HiveField(13)
  int sleepReminderMinutesBefore;

  // ==================== 健康目标设置 ====================

  /// 每日睡眠目标（分钟）
  @HiveField(14)
  int dailySleepGoalMinutes;

  /// 每日饮水目标（杯）
  @HiveField(15)
  int dailyWaterGoal;

  /// 每日运动目标（分钟）
  @HiveField(16)
  int dailyExerciseGoalMinutes;

  /// 每日步数目标
  @HiveField(17)
  int dailyStepsGoal;

  // ==================== 界面设置 ====================

  /// 是否启用深色模式
  @HiveField(18)
  bool isDarkMode;

  /// 语言设置
  @HiveField(19)
  String language;

  // ==================== 专注设置 ====================

  /// 是否启用专注模式时的防打扰
  @HiveField(20)
  bool enableFocusDnd;

  /// 默认白噪音类型
  @HiveField(21)
  String? defaultSoundType;

  /// 是否自动开始下一个番茄钟
  @HiveField(22)
  bool autoStartNextPomodoro;

  UserSettings({
    // 番茄钟默认值
    this.pomodoroMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.pomodorosBeforeLongBreak = 4,

    // 提醒默认启用
    this.enableTaskReminders = true,
    this.enableHealthReminders = true,

    // 久坐提醒
    this.enableSitReminder = true,
    this.sitReminderMinutes = 60,

    // 饮水提醒
    this.enableWaterReminder = true,
    this.waterReminderMinutes = 120,

    // 睡眠提醒
    this.enableSleepReminder = true,
    this.bedTimeHour = 22,
    this.bedTimeMinute = 0,
    this.sleepReminderMinutesBefore = 30,

    // 健康目标
    this.dailySleepGoalMinutes = 480, // 8小时
    this.dailyWaterGoal = 8,
    this.dailyExerciseGoalMinutes = 30,
    this.dailyStepsGoal = 8000,

    // 界面设置
    this.isDarkMode = false,
    this.language = 'zh_CN',

    // 专注设置
    this.enableFocusDnd = false,
    this.defaultSoundType,
    this.autoStartNextPomodoro = false,
  });

  /// 获取就寝时间字符串
  String get bedTimeString {
    final hour = bedTimeHour.toString().padLeft(2, '0');
    final minute = bedTimeMinute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// 获取睡眠目标（小时）
  double get dailySleepGoalHours => dailySleepGoalMinutes / 60.0;

  /// 获取运动目标（小时）
  double get dailyExerciseGoalHours => dailyExerciseGoalMinutes / 60.0;

  /// 重置为默认设置
  void resetToDefaults() {
    pomodoroMinutes = 25;
    shortBreakMinutes = 5;
    longBreakMinutes = 15;
    pomodorosBeforeLongBreak = 4;
    enableTaskReminders = true;
    enableHealthReminders = true;
    enableSitReminder = true;
    sitReminderMinutes = 60;
    enableWaterReminder = true;
    waterReminderMinutes = 120;
    enableSleepReminder = true;
    bedTimeHour = 22;
    bedTimeMinute = 0;
    sleepReminderMinutesBefore = 30;
    dailySleepGoalMinutes = 480;
    dailyWaterGoal = 8;
    dailyExerciseGoalMinutes = 30;
    dailyStepsGoal = 8000;
    isDarkMode = false;
    language = 'zh_CN';
    enableFocusDnd = false;
    defaultSoundType = null;
    autoStartNextPomodoro = false;
    save();
  }

  /// 更新番茄钟设置
  void updatePomodoroSettings({
    int? pomodoro,
    int? shortBreak,
    int? longBreak,
    int? beforeLongBreak,
  }) {
    if (pomodoro != null) pomodoroMinutes = pomodoro;
    if (shortBreak != null) shortBreakMinutes = shortBreak;
    if (longBreak != null) longBreakMinutes = longBreak;
    if (beforeLongBreak != null) pomodorosBeforeLongBreak = beforeLongBreak;
    save();
  }

  /// 更新健康目标
  void updateHealthGoals({
    int? sleep,
    int? water,
    int? exercise,
    int? steps,
  }) {
    if (sleep != null) dailySleepGoalMinutes = sleep;
    if (water != null) dailyWaterGoal = water;
    if (exercise != null) dailyExerciseGoalMinutes = exercise;
    if (steps != null) dailyStepsGoal = steps;
    save();
  }

  /// 更新就寝时间
  void updateBedTime(int hour, int minute) {
    bedTimeHour = hour;
    bedTimeMinute = minute;
    save();
  }

  /// 切换深色模式
  void toggleDarkMode() {
    isDarkMode = !isDarkMode;
    save();
  }

  /// 复制设置
  UserSettings copyWith({
    int? pomodoroMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? pomodorosBeforeLongBreak,
    bool? enableTaskReminders,
    bool? enableHealthReminders,
    bool? enableSitReminder,
    int? sitReminderMinutes,
    bool? enableWaterReminder,
    int? waterReminderMinutes,
    bool? enableSleepReminder,
    int? bedTimeHour,
    int? bedTimeMinute,
    int? sleepReminderMinutesBefore,
    int? dailySleepGoalMinutes,
    int? dailyWaterGoal,
    int? dailyExerciseGoalMinutes,
    int? dailyStepsGoal,
    bool? isDarkMode,
    String? language,
    bool? enableFocusDnd,
    String? defaultSoundType,
    bool? autoStartNextPomodoro,
  }) {
    return UserSettings(
      pomodoroMinutes: pomodoroMinutes ?? this.pomodoroMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      pomodorosBeforeLongBreak:
          pomodorosBeforeLongBreak ?? this.pomodorosBeforeLongBreak,
      enableTaskReminders: enableTaskReminders ?? this.enableTaskReminders,
      enableHealthReminders:
          enableHealthReminders ?? this.enableHealthReminders,
      enableSitReminder: enableSitReminder ?? this.enableSitReminder,
      sitReminderMinutes: sitReminderMinutes ?? this.sitReminderMinutes,
      enableWaterReminder: enableWaterReminder ?? this.enableWaterReminder,
      waterReminderMinutes: waterReminderMinutes ?? this.waterReminderMinutes,
      enableSleepReminder: enableSleepReminder ?? this.enableSleepReminder,
      bedTimeHour: bedTimeHour ?? this.bedTimeHour,
      bedTimeMinute: bedTimeMinute ?? this.bedTimeMinute,
      sleepReminderMinutesBefore:
          sleepReminderMinutesBefore ?? this.sleepReminderMinutesBefore,
      dailySleepGoalMinutes:
          dailySleepGoalMinutes ?? this.dailySleepGoalMinutes,
      dailyWaterGoal: dailyWaterGoal ?? this.dailyWaterGoal,
      dailyExerciseGoalMinutes:
          dailyExerciseGoalMinutes ?? this.dailyExerciseGoalMinutes,
      dailyStepsGoal: dailyStepsGoal ?? this.dailyStepsGoal,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      enableFocusDnd: enableFocusDnd ?? this.enableFocusDnd,
      defaultSoundType: defaultSoundType ?? this.defaultSoundType,
      autoStartNextPomodoro:
          autoStartNextPomodoro ?? this.autoStartNextPomodoro,
    );
  }

  @override
  String toString() {
    return 'UserSettings{pomodoro: ${pomodoroMinutes}min, sleep: ${dailySleepGoalMinutes}min, darkMode: $isDarkMode}';
  }
}
