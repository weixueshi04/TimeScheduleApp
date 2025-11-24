import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'task.g.dart';

/// 任务模型
@JsonSerializable()
class Task extends Equatable {
  final int id;
  final int userId;
  final String title;
  final String? description;
  final String category; // work, study, reading, coding, exam_prep, life, health, other
  final String priority; // low, medium, high, urgent
  final String status; // pending, in_progress, completed, cancelled
  final DateTime? dueDate;
  final int estimatedPomodoros;
  final int actualPomodoros;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.dueDate,
    required this.estimatedPomodoros,
    required this.actualPomodoros,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
  Map<String, dynamic> toJson() => _$TaskToJson(this);

  /// 是否已完成
  bool get completed => isCompleted;

  /// 是否逾期
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  /// 是否今天到期
  bool get isDueToday {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  /// 剩余天数
  int? get remainingDays {
    if (dueDate == null || isCompleted) return null;
    final diff = dueDate!.difference(DateTime.now());
    return diff.inDays;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        category,
        priority,
        status,
        dueDate,
        estimatedPomodoros,
        actualPomodoros,
        isCompleted,
        createdAt,
        updatedAt,
        completedAt,
      ];
}

/// 创建任务请求
@JsonSerializable()
class CreateTaskRequest {
  final String title;
  final String? description;
  final String category;
  final String priority;
  final String? dueDate; // ISO 8601
  final int? estimatedPomodoros;

  const CreateTaskRequest({
    required this.title,
    this.description,
    required this.category,
    this.priority = 'medium',
    this.dueDate,
    this.estimatedPomodoros,
  });

  factory CreateTaskRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateTaskRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateTaskRequestToJson(this);
}

/// 更新任务请求
@JsonSerializable()
class UpdateTaskRequest {
  final String? title;
  final String? description;
  final String? category;
  final String? priority;
  final String? status;
  final String? dueDate;
  final int? estimatedPomodoros;

  const UpdateTaskRequest({
    this.title,
    this.description,
    this.category,
    this.priority,
    this.status,
    this.dueDate,
    this.estimatedPomodoros,
  });

  factory UpdateTaskRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateTaskRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateTaskRequestToJson(this);
}

/// 任务统计
@JsonSerializable()
class TaskStats {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int overdueTasks;
  final double completionRate;

  const TaskStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.overdueTasks,
    required this.completionRate,
  });

  factory TaskStats.fromJson(Map<String, dynamic> json) =>
      _$TaskStatsFromJson(json);
  Map<String, dynamic> toJson() => _$TaskStatsToJson(this);
}
