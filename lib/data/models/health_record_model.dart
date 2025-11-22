import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'health_record_model.g.dart';

/// 用餐类型枚举
@HiveType(typeId: 22)
enum MealType {
  @HiveField(0)
  breakfast, // 早餐

  @HiveField(1)
  lunch, // 午餐

  @HiveField(2)
  dinner, // 晚餐

  @HiveField(3)
  snack, // 加餐
}

/// 用餐类型扩展方法
extension MealTypeExtension on MealType {
  /// 获取显示名称
  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return '早餐';
      case MealType.lunch:
        return '午餐';
      case MealType.dinner:
        return '晚餐';
      case MealType.snack:
        return '加餐';
    }
  }

  /// 获取推荐用餐时间
  DateTime get recommendedTime {
    final now = DateTime.now();
    switch (this) {
      case MealType.breakfast:
        return DateTime(now.year, now.month, now.day, 7, 0);
      case MealType.lunch:
        return DateTime(now.year, now.month, now.day, 12, 0);
      case MealType.dinner:
        return DateTime(now.year, now.month, now.day, 18, 0);
      case MealType.snack:
        return DateTime(now.year, now.month, now.day, 15, 0);
    }
  }
}

/// 用餐记录模型
@HiveType(typeId: 21)
class MealRecord extends HiveObject {
  @HiveField(0)
  MealType type;

  @HiveField(1)
  DateTime time;

  @HiveField(2)
  String? notes;

  MealRecord({
    required this.type,
    required this.time,
    this.notes,
  });
}

/// 健康记录模型 - 记录每日的健康数据
@HiveType(typeId: 20)
class HealthRecord extends HiveObject {
  /// 记录ID
  @HiveField(0)
  final String id;

  /// 日期（仅日期，不含时间）
  @HiveField(1)
  DateTime date;

  /// 睡眠时长（分钟）
  @HiveField(2)
  int sleepMinutes;

  /// 入睡时间
  @HiveField(3)
  DateTime? bedTime;

  /// 起床时间
  @HiveField(4)
  DateTime? wakeTime;

  /// 饮水次数
  @HiveField(5)
  int waterCount;

  /// 饮水记录时间列表
  @HiveField(6)
  List<DateTime> waterTimes;

  /// 久坐时长（分钟）
  @HiveField(7)
  int sitMinutes;

  /// 运动时长（分钟）
  @HiveField(8)
  int exerciseMinutes;

  /// 用餐记录
  @HiveField(9)
  List<MealRecord> mealRecords;

  /// 步数
  @HiveField(10)
  int steps;

  /// 备注
  @HiveField(11)
  String? notes;

  HealthRecord({
    String? id,
    DateTime? date,
    this.sleepMinutes = 0,
    this.bedTime,
    this.wakeTime,
    this.waterCount = 0,
    List<DateTime>? waterTimes,
    this.sitMinutes = 0,
    this.exerciseMinutes = 0,
    List<MealRecord>? mealRecords,
    this.steps = 0,
    this.notes,
  })  : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now(),
        waterTimes = waterTimes ?? [],
        mealRecords = mealRecords ?? [];

  /// 添加饮水记录
  void addWater() {
    waterCount++;
    waterTimes.add(DateTime.now());
    save();
  }

  /// 添加用餐记录
  void addMeal(MealType type, {String? notes}) {
    mealRecords.add(MealRecord(
      type: type,
      time: DateTime.now(),
      notes: notes,
    ));
    save();
  }

  /// 更新睡眠时长
  void updateSleep(DateTime bedTime, DateTime wakeTime) {
    this.bedTime = bedTime;
    this.wakeTime = wakeTime;
    sleepMinutes = wakeTime.difference(bedTime).inMinutes;
    save();
  }

  /// 添加运动时长
  void addExercise(int minutes) {
    exerciseMinutes += minutes;
    save();
  }

  /// 添加步数
  void addSteps(int count) {
    steps += count;
    save();
  }

  /// 是否达到睡眠目标（8小时 = 480分钟）
  bool get isSleepGoalMet => sleepMinutes >= 480;

  /// 是否达到饮水目标（8杯）
  bool get isWaterGoalMet => waterCount >= 8;

  /// 是否达到运动目标（30分钟）
  bool get isExerciseGoalMet => exerciseMinutes >= 30;

  /// 是否达到步数目标（8000步）
  bool get isStepsGoalMet => steps >= 8000;

  /// 获取睡眠时长（小时，保留1位小数）
  double get sleepHours => sleepMinutes / 60.0;

  /// 获取运动时长（小时，保留1位小数）
  double get exerciseHours => exerciseMinutes / 60.0;

  /// 健康评分（0-100分）
  int get healthScore {
    int score = 0;

    // 睡眠得分（40分）
    if (sleepMinutes >= 480) {
      score += 40;
    } else if (sleepMinutes > 0) {
      score += (sleepMinutes / 480 * 40).round();
    }

    // 饮水得分（20分）
    if (waterCount >= 8) {
      score += 20;
    } else if (waterCount > 0) {
      score += (waterCount / 8 * 20).round();
    }

    // 运动得分（30分）
    if (exerciseMinutes >= 30) {
      score += 30;
    } else if (exerciseMinutes > 0) {
      score += (exerciseMinutes / 30 * 30).round();
    }

    // 用餐得分（10分）
    if (mealRecords.length >= 3) {
      score += 10;
    } else if (mealRecords.isNotEmpty) {
      score += (mealRecords.length / 3 * 10).round();
    }

    return score.clamp(0, 100);
  }

  /// 获取健康评级
  String get healthRating {
    final score = healthScore;
    if (score >= 90) return '优秀';
    if (score >= 75) return '良好';
    if (score >= 60) return '中等';
    if (score >= 40) return '一般';
    return '较差';
  }

  /// 获取健康评级颜色
  Color get healthRatingColor {
    final score = healthScore;
    if (score >= 90) return CupertinoColors.systemGreen;
    if (score >= 75) return CupertinoColors.systemBlue;
    if (score >= 60) return CupertinoColors.systemOrange;
    return CupertinoColors.systemRed;
  }

  /// 获取未达标项目列表
  List<String> get unmetGoals {
    List<String> goals = [];
    if (!isSleepGoalMet) goals.add('睡眠不足');
    if (!isWaterGoalMet) goals.add('饮水不足');
    if (!isExerciseGoalMet) goals.add('运动不足');
    if (mealRecords.length < 3) goals.add('用餐次数不足');
    return goals;
  }

  /// 复制记录
  HealthRecord copyWith({
    DateTime? date,
    int? sleepMinutes,
    DateTime? bedTime,
    DateTime? wakeTime,
    int? waterCount,
    List<DateTime>? waterTimes,
    int? sitMinutes,
    int? exerciseMinutes,
    List<MealRecord>? mealRecords,
    int? steps,
    String? notes,
  }) {
    return HealthRecord(
      id: id,
      date: date ?? this.date,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
      bedTime: bedTime ?? this.bedTime,
      wakeTime: wakeTime ?? this.wakeTime,
      waterCount: waterCount ?? this.waterCount,
      waterTimes: waterTimes ?? this.waterTimes,
      sitMinutes: sitMinutes ?? this.sitMinutes,
      exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
      mealRecords: mealRecords ?? this.mealRecords,
      steps: steps ?? this.steps,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'HealthRecord{date: ${date.toString().substring(0, 10)}, score: $healthScore, rating: $healthRating}';
  }
}
