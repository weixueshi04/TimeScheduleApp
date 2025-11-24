import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'study_room.g.dart';

/// 自习室模型
@JsonSerializable()
class StudyRoom extends Equatable {
  final int id;
  final String roomCode;
  final int creatorId;
  final String? name;
  final String? description;
  final String roomType; // matched, created, temporary_rest
  final int maxParticipants;
  final int durationMinutes;
  final DateTime scheduledStartTime;
  final DateTime scheduledEndTime;
  final String status; // waiting, active, completed, cancelled
  final int currentParticipants;
  final Map<String, dynamic>? matchingCriteria;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? creatorUsername;
  final String? creatorNickname;
  final String? creatorAvatar;
  final List<Participant>? participants;

  const StudyRoom({
    required this.id,
    required this.roomCode,
    required this.creatorId,
    this.name,
    this.description,
    required this.roomType,
    required this.maxParticipants,
    required this.durationMinutes,
    required this.scheduledStartTime,
    required this.scheduledEndTime,
    required this.status,
    required this.currentParticipants,
    this.matchingCriteria,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.creatorUsername,
    this.creatorNickname,
    this.creatorAvatar,
    this.participants,
  });

  factory StudyRoom.fromJson(Map<String, dynamic> json) =>
      _$StudyRoomFromJson(json);
  Map<String, dynamic> toJson() => _$StudyRoomToJson(this);

  /// 是否可以加入
  bool get canJoin => status == 'waiting' && currentParticipants < maxParticipants;

  /// 是否已开始
  bool get isActive => status == 'active';

  /// 是否已结束
  bool get isEnded => status == 'completed' || status == 'cancelled';

  /// 剩余时间（分钟）
  int? get remainingMinutes {
    if (!isActive) return null;
    final now = DateTime.now();
    final diff = scheduledEndTime.difference(now);
    return diff.inMinutes;
  }

  /// 复制并修改部分属性
  StudyRoom copyWith({
    int? id,
    String? roomCode,
    int? creatorId,
    String? name,
    String? description,
    String? roomType,
    int? maxParticipants,
    int? durationMinutes,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
    String? status,
    int? currentParticipants,
    Map<String, dynamic>? matchingCriteria,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
    String? creatorUsername,
    String? creatorNickname,
    String? creatorAvatar,
    List<Participant>? participants,
  }) {
    return StudyRoom(
      id: id ?? this.id,
      roomCode: roomCode ?? this.roomCode,
      creatorId: creatorId ?? this.creatorId,
      name: name ?? this.name,
      description: description ?? this.description,
      roomType: roomType ?? this.roomType,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      scheduledEndTime: scheduledEndTime ?? this.scheduledEndTime,
      status: status ?? this.status,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      matchingCriteria: matchingCriteria ?? this.matchingCriteria,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      creatorUsername: creatorUsername ?? this.creatorUsername,
      creatorNickname: creatorNickname ?? this.creatorNickname,
      creatorAvatar: creatorAvatar ?? this.creatorAvatar,
      participants: participants ?? this.participants,
    );
  }

  @override
  List<Object?> get props => [
        id,
        roomCode,
        creatorId,
        name,
        description,
        roomType,
        maxParticipants,
        durationMinutes,
        scheduledStartTime,
        scheduledEndTime,
        status,
        currentParticipants,
        matchingCriteria,
        createdAt,
        startedAt,
        endedAt,
        creatorUsername,
        creatorNickname,
        creatorAvatar,
        participants,
      ];
}

/// 自习室参与者
@JsonSerializable()
class Participant extends Equatable {
  final int id;
  final int roomId;
  final int userId;
  final String status; // joined, active, left, kicked, completed
  final String role; // creator, member
  final int energyLevel; // 0-100
  final String focusState; // focused, break, distracted
  final bool leftEarly;
  final int penaltyMinutes;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final String? username;
  final String? nickname;
  final String? avatarUrl;
  final int? totalFocusMinutes;
  final int? currentStreak;

  const Participant({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.status,
    required this.role,
    required this.energyLevel,
    required this.focusState,
    required this.leftEarly,
    required this.penaltyMinutes,
    required this.joinedAt,
    this.leftAt,
    this.username,
    this.nickname,
    this.avatarUrl,
    this.totalFocusMinutes,
    this.currentStreak,
  });

  factory Participant.fromJson(Map<String, dynamic> json) =>
      _$ParticipantFromJson(json);
  Map<String, dynamic> toJson() => _$ParticipantToJson(this);

  /// 是否在线
  bool get isOnline => status == 'active' || status == 'joined';

  /// 是否创建者
  bool get isCreator => role == 'creator';

  @override
  List<Object?> get props => [
        id,
        roomId,
        userId,
        status,
        role,
        energyLevel,
        focusState,
        leftEarly,
        penaltyMinutes,
        joinedAt,
        leftAt,
        username,
        nickname,
        avatarUrl,
        totalFocusMinutes,
        currentStreak,
      ];
}

/// 创建自习室请求
@JsonSerializable()
class CreateStudyRoomRequest {
  final String? name;
  final String? description;
  final int durationMinutes;
  final String scheduledStartTime; // ISO 8601
  final int maxParticipants;
  final String? taskCategory;

  const CreateStudyRoomRequest({
    this.name,
    this.description,
    required this.durationMinutes,
    required this.scheduledStartTime,
    required this.maxParticipants,
    this.taskCategory,
  });

  factory CreateStudyRoomRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateStudyRoomRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateStudyRoomRequestToJson(this);
}

/// 更新能量请求
@JsonSerializable()
class UpdateEnergyRequest {
  final int? energyLevel;
  final String? focusState;

  const UpdateEnergyRequest({
    this.energyLevel,
    this.focusState,
  });

  factory UpdateEnergyRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateEnergyRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateEnergyRequestToJson(this);
}
