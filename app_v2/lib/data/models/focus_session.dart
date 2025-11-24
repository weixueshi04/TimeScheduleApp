import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'focus_session.g.dart';

/// 专注会话模型
@JsonSerializable()
class FocusSession extends Equatable {
  final int id;
  final int userId;
  final int? taskId;
  final int durationMinutes;
  final int? actualDurationMinutes;
  final String mode; // pomodoro, custom, deep_work
  final bool isCompleted;
  final int interruptionCount;
  final DateTime startTime;
  final DateTime? endTime;
  final DateTime createdAt;

  // Task info (joined from tasks table)
  final String? taskTitle;
  final String? taskCategory;

  const FocusSession({
    required this.id,
    required this.userId,
    this.taskId,
    required this.durationMinutes,
    this.actualDurationMinutes,
    required this.mode,
    required this.isCompleted,
    required this.interruptionCount,
    required this.startTime,
    this.endTime,
    required this.createdAt,
    this.taskTitle,
    this.taskCategory,
  });

  factory FocusSession.fromJson(Map<String, dynamic> json) =>
      _$FocusSessionFromJson(json);
  Map<String, dynamic> toJson() => _$FocusSessionToJson(this);

  /// 是否正在进行
  bool get isActive => !isCompleted && endTime == null;

  /// 剩余时间（分钟）
  int? get remainingMinutes {
    if (!isActive) return null;
    final now = DateTime.now();
    final plannedEnd = startTime.add(Duration(minutes: durationMinutes));
    final diff = plannedEnd.difference(now);
    return diff.inMinutes;
  }

  /// 已经过时间（分钟）
  int get elapsedMinutes {
    final now = DateTime.now();
    final end = endTime ?? now;
    final diff = end.difference(startTime);
    return diff.inMinutes;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        taskId,
        durationMinutes,
        actualDurationMinutes,
        mode,
        isCompleted,
        interruptionCount,
        startTime,
        endTime,
        createdAt,
        taskTitle,
        taskCategory,
      ];
}

/// 开始专注会话请求
@JsonSerializable()
class StartFocusRequest {
  final int? taskId;
  final int durationMinutes;
  final String? mode;

  const StartFocusRequest({
    this.taskId,
    required this.durationMinutes,
    this.mode,
  });

  factory StartFocusRequest.fromJson(Map<String, dynamic> json) =>
      _$StartFocusRequestFromJson(json);
  Map<String, dynamic> toJson() => _$StartFocusRequestToJson(this);
}

/// 完成专注会话请求
@JsonSerializable()
class CompleteFocusRequest {
  final int actualDurationMinutes;
  final int? interruptionCount;

  const CompleteFocusRequest({
    required this.actualDurationMinutes,
    this.interruptionCount,
  });

  factory CompleteFocusRequest.fromJson(Map<String, dynamic> json) =>
      _$CompleteFocusRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CompleteFocusRequestToJson(this);
}

/// 专注统计
@JsonSerializable()
class FocusStats {
  final int totalSessions;
  final int completedSessions;
  final int totalFocusMinutes;
  final int todayFocusMinutes;
  final double completionRate;

  const FocusStats({
    required this.totalSessions,
    required this.completedSessions,
    required this.totalFocusMinutes,
    required this.todayFocusMinutes,
    required this.completionRate,
  });

  factory FocusStats.fromJson(Map<String, dynamic> json) =>
      _$FocusStatsFromJson(json);
  Map<String, dynamic> toJson() => _$FocusStatsToJson(this);
}
