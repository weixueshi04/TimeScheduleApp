import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'user.g.dart';

/// 用户模型
@JsonSerializable()
class User extends Equatable {
  final int id;
  final String username;
  final String email;
  final String? nickname;
  final String? avatarUrl;
  final String? bio;
  final bool isVerified;
  final UserStats? stats;
  final StudyRoomEligibility? studyRoomEligibility;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    this.nickname,
    this.avatarUrl,
    this.bio,
    required this.isVerified,
    this.stats,
    this.studyRoomEligibility,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        nickname,
        avatarUrl,
        bio,
        isVerified,
        stats,
        studyRoomEligibility,
        createdAt,
        lastLoginAt,
      ];
}

/// 用户统计信息
@JsonSerializable()
class UserStats extends Equatable {
  final int totalFocusMinutes;
  final int totalCompletedTasks;
  final int totalStudySessions;
  final int currentStreak;
  final int longestStreak;

  const UserStats({
    required this.totalFocusMinutes,
    required this.totalCompletedTasks,
    required this.totalStudySessions,
    required this.currentStreak,
    required this.longestStreak,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) =>
      _$UserStatsFromJson(json);
  Map<String, dynamic> toJson() => _$UserStatsToJson(this);

  @override
  List<Object?> get props => [
        totalFocusMinutes,
        totalCompletedTasks,
        totalStudySessions,
        currentStreak,
        longestStreak,
      ];
}

/// 自习室准入资格
@JsonSerializable()
class StudyRoomEligibility extends Equatable {
  final int daysSinceRegistration;
  final int totalFocusSessions;
  final double totalFocusHours;
  final bool canCreateStudyRoom;

  const StudyRoomEligibility({
    required this.daysSinceRegistration,
    required this.totalFocusSessions,
    required this.totalFocusHours,
    required this.canCreateStudyRoom,
  });

  factory StudyRoomEligibility.fromJson(Map<String, dynamic> json) =>
      _$StudyRoomEligibilityFromJson(json);
  Map<String, dynamic> toJson() => _$StudyRoomEligibilityToJson(this);

  /// 获取准入进度描述
  String get progressDescription {
    if (canCreateStudyRoom) {
      return '已满足创建自习室条件';
    }

    final needDays = 3 - daysSinceRegistration;
    final needSessions = 5 - totalFocusSessions;
    final needHours = 3 - totalFocusHours;

    if (needDays > 0) {
      return '还需注册 $needDays 天';
    }

    if (needSessions > 0 && needHours > 0) {
      return '还需 $needSessions 次专注会话 或 ${needHours.toStringAsFixed(1)} 小时';
    }

    return '即将满足条件';
  }

  @override
  List<Object?> get props => [
        daysSinceRegistration,
        totalFocusSessions,
        totalFocusHours,
        canCreateStudyRoom,
      ];
}

/// 认证响应
@JsonSerializable()
class AuthResponse extends Equatable {
  final User user;
  final AuthTokens tokens;

  const AuthResponse({
    required this.user,
    required this.tokens,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);

  @override
  List<Object?> get props => [user, tokens];
}

/// 认证令牌
@JsonSerializable()
class AuthTokens extends Equatable {
  final String accessToken;
  final String refreshToken;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);
  Map<String, dynamic> toJson() => _$AuthTokensToJson(this);

  @override
  List<Object?> get props => [accessToken, refreshToken];
}
