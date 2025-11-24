import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/cupertino.dart';

part 'task_model.g.dart';

/// 任务分类枚举
@HiveType(typeId: 1)
enum TaskCategory {
  @HiveField(0)
  work, // 工作

  @HiveField(1)
  study, // 学习

  @HiveField(2)
  life, // 生活

  @HiveField(3)
  health, // 健康
}

/// 任务分类扩展方法
extension TaskCategoryExtension on TaskCategory {
  /// 获取显示名称
  String get displayName {
    switch (this) {
      case TaskCategory.work:
        return '工作';
      case TaskCategory.study:
        return '学习';
      case TaskCategory.life:
        return '生活';
      case TaskCategory.health:
        return '健康';
    }
  }

  /// 获取分类颜色
  Color get color {
    switch (this) {
      case TaskCategory.work:
        return CupertinoColors.systemBlue;
      case TaskCategory.study:
        return CupertinoColors.systemPurple;
      case TaskCategory.life:
        return CupertinoColors.systemOrange;
      case TaskCategory.health:
        return CupertinoColors.systemGreen;
    }
  }

  /// 获取分类图标
  IconData get icon {
    switch (this) {
      case TaskCategory.work:
        return CupertinoIcons.briefcase;
      case TaskCategory.study:
        return CupertinoIcons.book;
      case TaskCategory.life:
        return CupertinoIcons.home;
      case TaskCategory.health:
        return CupertinoIcons.heart_fill;
    }
  }
}

/// 任务优先级枚举
@HiveType(typeId: 2)
enum TaskPriority {
  @HiveField(0)
  low, // 低优先级

  @HiveField(1)
  medium, // 中优先级

  @HiveField(2)
  high, // 高优先级

  @HiveField(3)
  urgent, // 紧急
}

/// 任务优先级扩展方法
extension TaskPriorityExtension on TaskPriority {
  /// 获取显示名称
  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return '低';
      case TaskPriority.medium:
        return '中';
      case TaskPriority.high:
        return '高';
      case TaskPriority.urgent:
        return '紧急';
    }
  }

  /// 获取优先级颜色
  Color get color {
    switch (this) {
      case TaskPriority.low:
        return CupertinoColors.systemGrey;
      case TaskPriority.medium:
        return CupertinoColors.systemYellow;
      case TaskPriority.high:
        return CupertinoColors.systemOrange;
      case TaskPriority.urgent:
        return CupertinoColors.systemRed;
    }
  }

  /// 获取排序优先级（数字越小优先级越高）
  int get sortOrder {
    switch (this) {
      case TaskPriority.urgent:
        return 0;
      case TaskPriority.high:
        return 1;
      case TaskPriority.medium:
        return 2;
      case TaskPriority.low:
        return 3;
    }
  }
}

/// 重复类型枚举
@HiveType(typeId: 5)
enum RecurringType {
  @HiveField(0)
  daily, // 每天

  @HiveField(1)
  weekly, // 每周

  @HiveField(2)
  monthly, // 每月

  @HiveField(3)
  custom, // 自定义
}

/// 重复规则模型
@HiveType(typeId: 4)
class RecurringRule extends HiveObject {
  /// 重复类型
  @HiveField(0)
  RecurringType type;

  /// 重复间隔（天数）
  @HiveField(1)
  int interval;

  /// 重复结束日期（可选）
  @HiveField(2)
  DateTime? endDate;

  /// 每周的哪几天（仅周重复时使用，1-7代表周一到周日）
  @HiveField(3)
  List<int>? weekdays;

  RecurringRule({
    required this.type,
    this.interval = 1,
    this.endDate,
    this.weekdays,
  });
}

/// 子任务模型
@HiveType(typeId: 3)
class SubTask extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isCompleted;

  @HiveField(3)
  DateTime createdAt;

  SubTask({
    String? id,
    required this.title,
    this.isCompleted = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// 切换完成状态
  void toggle() {
    isCompleted = !isCompleted;
  }
}

/// 任务模型 - 核心数据模型
@HiveType(typeId: 0)
class Task extends HiveObject {
  /// 任务唯一ID
  @HiveField(0)
  final String id;

  /// 任务标题
  @HiveField(1)
  String title;

  /// 任务描述（可选）
  @HiveField(2)
  String? description;

  /// 任务分类
  @HiveField(3)
  TaskCategory category;

  /// 任务优先级
  @HiveField(4)
  TaskPriority priority;

  /// 截止日期（可选）
  @HiveField(5)
  DateTime? dueDate;

  /// 预估完成时间（分钟）
  @HiveField(6)
  int estimatedMinutes;

  /// 实际完成时间（分钟）
  @HiveField(7)
  int actualMinutes;

  /// 是否已完成
  @HiveField(8)
  bool isCompleted;

  /// 创建时间
  @HiveField(9)
  DateTime createdAt;

  /// 更新时间
  @HiveField(10)
  DateTime updatedAt;

  /// 子任务ID列表
  @HiveField(11)
  List<String> subTaskIds;

  /// 是否重复任务
  @HiveField(12)
  bool isRecurring;

  /// 重复规则（可选）
  @HiveField(13)
  RecurringRule? recurringRule;

  /// 任务标签
  @HiveField(14)
  List<String> tags;

  /// 完成时间（可选）
  @HiveField(15)
  DateTime? completedAt;

  Task({
    String? id,
    required this.title,
    this.description,
    required this.category,
    required this.priority,
    this.dueDate,
    this.estimatedMinutes = 30,
    this.actualMinutes = 0,
    this.isCompleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? subTaskIds,
    this.isRecurring = false,
    this.recurringRule,
    List<String>? tags,
    this.completedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        subTaskIds = subTaskIds ?? [],
        tags = tags ?? [];

  /// 标记为完成
  void markAsCompleted() {
    isCompleted = true;
    completedAt = DateTime.now();
    updatedAt = DateTime.now();
    save();
  }

  /// 标记为未完成
  void markAsIncomplete() {
    isCompleted = false;
    completedAt = null;
    updatedAt = DateTime.now();
    save();
  }

  /// 更新实际用时
  void updateActualTime(int minutes) {
    actualMinutes += minutes;
    updatedAt = DateTime.now();
    save();
  }

  /// 是否超时（已过截止日期且未完成）
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  /// 时间偏差（实际-预估，正数表示超时）
  int get timeDeviation => actualMinutes - estimatedMinutes;

  /// 时间效率（预估/实际，百分比）
  double get timeEfficiency {
    if (actualMinutes == 0) return 100.0;
    return (estimatedMinutes / actualMinutes) * 100;
  }

  /// 剩余天数
  int? get daysRemaining {
    if (dueDate == null) return null;
    final now = DateTime.now();
    final difference = dueDate!.difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }

  /// 复制任务（用于创建副本或修改）
  Task copyWith({
    String? title,
    String? description,
    TaskCategory? category,
    TaskPriority? priority,
    DateTime? dueDate,
    int? estimatedMinutes,
    int? actualMinutes,
    bool? isCompleted,
    List<String>? subTaskIds,
    bool? isRecurring,
    RecurringRule? recurringRule,
    List<String>? tags,
    DateTime? completedAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      subTaskIds: subTaskIds ?? this.subTaskIds,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringRule: recurringRule ?? this.recurringRule,
      tags: tags ?? this.tags,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  String toString() {
    return 'Task{id: $id, title: $title, category: $category, priority: $priority, isCompleted: $isCompleted}';
  }
}
