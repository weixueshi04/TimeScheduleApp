# v1.0 Hive TypeAdapter 修复指南

## 问题描述

v1.0 使用 Hive 本地数据库，需要为自定义类生成 TypeAdapter。
由于 Flutter 环境不可用，`build_runner` 无法执行，导致以下文件缺失：

```
lib/data/models/task.g.dart
lib/data/models/focus_session.g.dart
lib/data/models/health_record.g.dart
```

## 解决方案1: 手动创建 TypeAdapter

### 1. Task TypeAdapter

创建文件 `lib/data/models/task.g.dart`:

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 0;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      category: fields[3] as TaskCategory,
      priority: fields[4] as TaskPriority,
      status: fields[5] as TaskStatus,
      dueDate: fields[6] as DateTime?,
      estimatedPomodoros: fields[7] as int,
      actualPomodoros: fields[8] as int,
      isCompleted: fields[9] as bool,
      createdAt: fields[10] as DateTime,
      completedAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.priority)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.dueDate)
      ..writeByte(7)
      ..write(obj.estimatedPomodoros)
      ..writeByte(8)
      ..write(obj.actualPomodoros)
      ..writeByte(9)
      ..write(obj.isCompleted)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskCategoryAdapter extends TypeAdapter<TaskCategory> {
  @override
  final int typeId = 1;

  @override
  TaskCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskCategory.work;
      case 1:
        return TaskCategory.study;
      case 2:
        return TaskCategory.life;
      case 3:
        return TaskCategory.health;
      case 4:
        return TaskCategory.other;
      default:
        return TaskCategory.work;
    }
  }

  @override
  void write(BinaryWriter writer, TaskCategory obj) {
    switch (obj) {
      case TaskCategory.work:
        writer.writeByte(0);
        break;
      case TaskCategory.study:
        writer.writeByte(1);
        break;
      case TaskCategory.life:
        writer.writeByte(2);
        break;
      case TaskCategory.health:
        writer.writeByte(3);
        break;
      case TaskCategory.other:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskPriorityAdapter extends TypeAdapter<TaskPriority> {
  @override
  final int typeId = 2;

  @override
  TaskPriority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskPriority.low;
      case 1:
        return TaskPriority.medium;
      case 2:
        return TaskPriority.high;
      case 3:
        return TaskPriority.urgent;
      default:
        return TaskPriority.medium;
    }
  }

  @override
  void write(BinaryWriter writer, TaskPriority obj) {
    switch (obj) {
      case TaskPriority.low:
        writer.writeByte(0);
        break;
      case TaskPriority.medium:
        writer.writeByte(1);
        break;
      case TaskPriority.high:
        writer.writeByte(2);
        break;
      case TaskPriority.urgent:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskPriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskStatusAdapter extends TypeAdapter<TaskStatus> {
  @override
  final int typeId = 3;

  @override
  TaskStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskStatus.pending;
      case 1:
        return TaskStatus.inProgress;
      case 2:
        return TaskStatus.completed;
      case 3:
        return TaskStatus.cancelled;
      default:
        return TaskStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, TaskStatus obj) {
    switch (obj) {
      case TaskStatus.pending:
        writer.writeByte(0);
        break;
      case TaskStatus.inProgress:
        writer.writeByte(1);
        break;
      case TaskStatus.completed:
        writer.writeByte(2);
        break;
      case TaskStatus.cancelled:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
```

### 2. FocusSession TypeAdapter

创建文件 `lib/data/models/focus_session.g.dart`:

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FocusSessionAdapter extends TypeAdapter<FocusSession> {
  @override
  final int typeId = 4;

  @override
  FocusSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FocusSession(
      id: fields[0] as String,
      taskId: fields[1] as String?,
      duration: fields[2] as int,
      actualDuration: fields[3] as int?,
      mode: fields[4] as FocusMode,
      isCompleted: fields[5] as bool,
      interruptionCount: fields[6] as int,
      startTime: fields[7] as DateTime,
      endTime: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, FocusSession obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taskId)
      ..writeByte(2)
      ..write(obj.duration)
      ..writeByte(3)
      ..write(obj.actualDuration)
      ..writeByte(4)
      ..write(obj.mode)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.interruptionCount)
      ..writeByte(7)
      ..write(obj.startTime)
      ..writeByte(8)
      ..write(obj.endTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class FocusModeAdapter extends TypeAdapter<FocusMode> {
  @override
  final int typeId = 5;

  @override
  FocusMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FocusMode.pomodoro;
      case 1:
        return FocusMode.custom;
      case 2:
        return FocusMode.deepWork;
      default:
        return FocusMode.pomodoro;
    }
  }

  @override
  void write(BinaryWriter writer, FocusMode obj) {
    switch (obj) {
      case FocusMode.pomodoro:
        writer.writeByte(0);
        break;
      case FocusMode.custom:
        writer.writeByte(1);
        break;
      case FocusMode.deepWork:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
```

### 3. HealthRecord TypeAdapter

创建文件 `lib/data/models/health_record.g.dart`:

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HealthRecordAdapter extends TypeAdapter<HealthRecord> {
  @override
  final int typeId = 6;

  @override
  HealthRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HealthRecord(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      sleepHours: fields[2] as double?,
      waterIntake: fields[3] as int?,
      exerciseMinutes: fields[4] as int?,
      mood: fields[5] as Mood?,
      notes: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HealthRecord obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.sleepHours)
      ..writeByte(3)
      ..write(obj.waterIntake)
      ..writeByte(4)
      ..write(obj.exerciseMinutes)
      ..writeByte(5)
      ..write(obj.mood)
      ..writeByte(6)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MoodAdapter extends TypeAdapter<Mood> {
  @override
  final int typeId = 7;

  @override
  Mood read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Mood.great;
      case 1:
        return Mood.good;
      case 2:
        return Mood.normal;
      case 3:
        return Mood.bad;
      case 4:
        return Mood.terrible;
      default:
        return Mood.normal;
    }
  }

  @override
  void write(BinaryWriter writer, Mood obj) {
    switch (obj) {
      case Mood.great:
        writer.writeByte(0);
        break;
      case Mood.good:
        writer.writeByte(1);
        break;
      case Mood.normal:
        writer.writeByte(2);
        break;
      case Mood.bad:
        writer.writeByte(3);
        break;
      case Mood.terrible:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MoodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
```

## 解决方案2: 安装 Flutter SDK

参考 `install-flutter.sh` 脚本自动安装。

## 推荐方案

**如果继续开发v1.0**: 安装Flutter SDK（方案2）
**如果直接开发v2.0**: 跳过v1.0，专注于v2.0 Flutter前端 + 后端集成

## v1.0 vs v2.0 对比

| 特性 | v1.0 (单机版) | v2.0 (网络版) |
|------|--------------|--------------|
| 数据存储 | Hive本地 | PostgreSQL + Redis |
| 核心功能 | 任务+专注+健康 | 网络自习室 |
| 用户体验 | 个人使用 | 多人协作 |
| 开发进度 | 60% (阻塞) | 后端100% |
| 技术债务 | TypeAdapter缺失 | 无 |

## 建议

**直接开发v2.0前端**，理由：
1. ✅ 后端已100%完成并测试
2. ✅ 网络自习室是核心创新
3. ✅ v1.0的任务/专注/健康功能会在v2.0中保留
4. ✅ 避免技术债务（Hive → PostgreSQL）
5. ✅ 用户需要多人协作功能

v1.0可以作为**原型参考**，v2.0前端可以复用UI组件和交互逻辑。
