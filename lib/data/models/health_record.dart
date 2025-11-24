import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'health_record.g.dart';

/// 健康记录模型
@JsonSerializable()
class HealthRecord extends Equatable {
  final int id;
  final int userId;
  final DateTime recordDate;
  final double? sleepHours;
  final int? waterIntake; // ml
  final int? exerciseMinutes;
  final String? mood; // great, good, normal, bad, terrible
  final String? notes;
  final int healthScore; // 0-100
  final DateTime createdAt;
  final DateTime updatedAt;

  const HealthRecord({
    required this.id,
    required this.userId,
    required this.recordDate,
    this.sleepHours,
    this.waterIntake,
    this.exerciseMinutes,
    this.mood,
    this.notes,
    required this.healthScore,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) =>
      _$HealthRecordFromJson(json);
  Map<String, dynamic> toJson() => _$HealthRecordToJson(this);

  /// 是否今天的记录
  bool get isToday {
    final now = DateTime.now();
    return recordDate.year == now.year &&
        recordDate.month == now.month &&
        recordDate.day == now.day;
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        recordDate,
        sleepHours,
        waterIntake,
        exerciseMinutes,
        mood,
        notes,
        healthScore,
        createdAt,
        updatedAt,
      ];
}

/// 创建/更新健康记录请求
@JsonSerializable()
class HealthRecordRequest {
  final String? recordDate; // ISO 8601 date
  final double? sleepHours;
  final int? waterIntake;
  final int? exerciseMinutes;
  final String? mood;
  final String? notes;

  const HealthRecordRequest({
    this.recordDate,
    this.sleepHours,
    this.waterIntake,
    this.exerciseMinutes,
    this.mood,
    this.notes,
  });

  factory HealthRecordRequest.fromJson(Map<String, dynamic> json) =>
      _$HealthRecordRequestFromJson(json);
  Map<String, dynamic> toJson() => _$HealthRecordRequestToJson(this);
}

/// 健康统计
@JsonSerializable()
class HealthStats {
  final double avgSleepHours;
  final int avgWaterIntake;
  final int avgExerciseMinutes;
  final double avgHealthScore;
  final int totalRecords;

  const HealthStats({
    required this.avgSleepHours,
    required this.avgWaterIntake,
    required this.avgExerciseMinutes,
    required this.avgHealthScore,
    required this.totalRecords,
  });

  factory HealthStats.fromJson(Map<String, dynamic> json) =>
      _$HealthStatsFromJson(json);
  Map<String, dynamic> toJson() => _$HealthStatsToJson(this);
}
