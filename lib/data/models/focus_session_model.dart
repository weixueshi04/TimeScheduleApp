import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'focus_session_model.g.dart';

/// 专注类型枚举
@HiveType(typeId: 11)
enum FocusType {
  @HiveField(0)
  pomodoro, // 番茄钟（25分钟）

  @HiveField(1)
  shortBreak, // 短休息（5分钟）

  @HiveField(2)
  longBreak, // 长休息（15分钟）

  @HiveField(3)
  custom, // 自定义时长
}

/// 专注类型扩展方法
extension FocusTypeExtension on FocusType {
  /// 获取显示名称
  String get displayName {
    switch (this) {
      case FocusType.pomodoro:
        return '番茄钟';
      case FocusType.shortBreak:
        return '短休息';
      case FocusType.longBreak:
        return '长休息';
      case FocusType.custom:
        return '自定义';
    }
  }

  /// 获取默认时长（分钟）
  int get defaultMinutes {
    switch (this) {
      case FocusType.pomodoro:
        return 25;
      case FocusType.shortBreak:
        return 5;
      case FocusType.longBreak:
        return 15;
      case FocusType.custom:
        return 30;
    }
  }
}

/// 专注会话模型 - 记录每次专注/休息的详细信息
@HiveType(typeId: 10)
class FocusSession extends HiveObject {
  /// 会话ID
  @HiveField(0)
  final String id;

  /// 关联的任务ID（可选）
  @HiveField(1)
  String? taskId;

  /// 开始时间
  @HiveField(2)
  DateTime startTime;

  /// 结束时间（可选，进行中时为null）
  @HiveField(3)
  DateTime? endTime;

  /// 持续时长（分钟）
  @HiveField(4)
  int durationMinutes;

  /// 设定目标时长（分钟）
  @HiveField(5)
  int targetMinutes;

  /// 中断次数（切换应用或离开的次数）
  @HiveField(6)
  int interruptionCount;

  /// 是否完整完成（达到目标时长）
  @HiveField(7)
  bool isCompleted;

  /// 专注类型
  @HiveField(8)
  FocusType focusType;

  /// 备注
  @HiveField(9)
  String? notes;

  /// 使用的白噪音类型
  @HiveField(10)
  String? soundType;

  FocusSession({
    String? id,
    this.taskId,
    DateTime? startTime,
    this.endTime,
    this.durationMinutes = 0,
    required this.targetMinutes,
    this.interruptionCount = 0,
    this.isCompleted = false,
    this.focusType = FocusType.pomodoro,
    this.notes,
    this.soundType,
  })  : id = id ?? const Uuid().v4(),
        startTime = startTime ?? DateTime.now();

  /// 结束会话
  void complete() {
    endTime = DateTime.now();
    durationMinutes = endTime!.difference(startTime).inMinutes;
    isCompleted = durationMinutes >= targetMinutes;
    save();
  }

  /// 记录中断
  void interrupt() {
    interruptionCount++;
    save();
  }

  /// 是否正在进行
  bool get isActive => endTime == null;

  /// 完成率（0.0-1.0）
  double get completionRate {
    if (targetMinutes == 0) return 0;
    return (durationMinutes / targetMinutes).clamp(0.0, 1.0);
  }

  /// 完成率百分比
  int get completionPercentage {
    return (completionRate * 100).round();
  }

  /// 专注质量评分（0-100）
  /// 根据完成率和中断次数计算
  int get qualityScore {
    // 基础分：完成率 * 70分
    int baseScore = (completionRate * 70).round();

    // 扣除中断分数：每次中断扣5分，最多扣30分
    int interruptionPenalty = (interruptionCount * 5).clamp(0, 30);

    return (baseScore - interruptionPenalty).clamp(0, 100);
  }

  /// 获取质量评级
  String get qualityRating {
    final score = qualityScore;
    if (score >= 90) return '优秀';
    if (score >= 75) return '良好';
    if (score >= 60) return '中等';
    if (score >= 40) return '一般';
    return '较差';
  }

  /// 复制会话
  FocusSession copyWith({
    String? taskId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    int? targetMinutes,
    int? interruptionCount,
    bool? isCompleted,
    FocusType? focusType,
    String? notes,
    String? soundType,
  }) {
    return FocusSession(
      id: id,
      taskId: taskId ?? this.taskId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      interruptionCount: interruptionCount ?? this.interruptionCount,
      isCompleted: isCompleted ?? this.isCompleted,
      focusType: focusType ?? this.focusType,
      notes: notes ?? this.notes,
      soundType: soundType ?? this.soundType,
    );
  }

  @override
  String toString() {
    return 'FocusSession{id: $id, type: $focusType, duration: $durationMinutes/$targetMinutes分钟, quality: $qualityRating}';
  }
}
