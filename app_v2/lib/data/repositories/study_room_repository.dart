import 'package:logger/logger.dart';
import '../models/study_room.dart';
import '../services/api_client.dart';
import '../../core/constants/api_constants.dart';

/// 自习室仓库 - 处理自习室相关的API调用
class StudyRoomRepository {
  final ApiClient _apiClient;
  final Logger _logger = Logger();

  StudyRoomRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// 获取所有自习室列表
  Future<List<StudyRoom>> getStudyRooms({
    String? status,
    String? roomType,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.studyRooms,
        queryParameters: {
          if (status != null) 'status': status,
          if (roomType != null) 'roomType': roomType,
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.data['success'] != true) {
        throw Exception('Failed to fetch study rooms');
      }

      final List data = response.data['data'] as List;
      return data.map((json) => StudyRoom.fromJson(json)).toList();
    } catch (e) {
      _logger.e('Error fetching study rooms: $e');
      rethrow;
    }
  }

  /// 获取我的自习室
  Future<List<StudyRoom>> getMyStudyRooms({String? status}) async {
    try {
      final response = await _apiClient.get(
        ApiConstants.studyRoomsMy,
        queryParameters: {
          if (status != null) 'status': status,
        },
      );

      if (response.data['success'] != true) {
        throw Exception('Failed to fetch my study rooms');
      }

      final List data = response.data['data'] as List;
      return data.map((json) => StudyRoom.fromJson(json)).toList();
    } catch (e) {
      _logger.e('Error fetching my study rooms: $e');
      rethrow;
    }
  }

  /// 获取单个自习室详情
  Future<StudyRoom> getStudyRoom(int id) async {
    try {
      final response = await _apiClient.get('${ApiConstants.studyRooms}/$id');

      if (response.data['success'] != true) {
        throw Exception('Failed to fetch study room');
      }

      return StudyRoom.fromJson(response.data['data']);
    } catch (e) {
      _logger.e('Error fetching study room $id: $e');
      rethrow;
    }
  }

  /// 创建自习室
  Future<StudyRoom> createStudyRoom(CreateStudyRoomRequest request) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.studyRooms,
        data: request.toJson(),
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to create study room');
      }

      _logger.i('Study room created successfully');
      return StudyRoom.fromJson(response.data['data']);
    } catch (e) {
      _logger.e('Error creating study room: $e');
      rethrow;
    }
  }

  /// 加入自习室
  Future<void> joinStudyRoom(int roomId) async {
    try {
      final response = await _apiClient.post('${ApiConstants.studyRooms}/$roomId/join');

      if (response.data['success'] != true) {
        throw Exception(response.data['error']?['message'] ?? 'Failed to join study room');
      }

      _logger.i('Joined study room: $roomId');
    } catch (e) {
      _logger.e('Error joining study room $roomId: $e');
      rethrow;
    }
  }

  /// 离开自习室
  Future<Map<String, dynamic>> leaveStudyRoom(int roomId, {String? reason}) async {
    try {
      final response = await _apiClient.post(
        '${ApiConstants.studyRooms}/$roomId/leave',
        data: {
          if (reason != null) 'reason': reason,
        },
      );

      if (response.data['success'] != true) {
        throw Exception('Failed to leave study room');
      }

      _logger.i('Left study room: $roomId');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      _logger.e('Error leaving study room $roomId: $e');
      rethrow;
    }
  }

  /// 更新能量条
  Future<void> updateEnergy(int roomId, UpdateEnergyRequest request) async {
    try {
      final response = await _apiClient.put(
        '${ApiConstants.studyRooms}/$roomId/energy',
        data: request.toJson(),
      );

      if (response.data['success'] != true) {
        throw Exception('Failed to update energy');
      }

      _logger.d('Energy updated for room $roomId');
    } catch (e) {
      _logger.e('Error updating energy for room $roomId: $e');
      rethrow;
    }
  }

  /// 开始自习室会话（仅创建者）
  Future<void> startStudyRoom(int roomId) async {
    try {
      final response = await _apiClient.post('${ApiConstants.studyRooms}/$roomId/start');

      if (response.data['success'] != true) {
        throw Exception('Failed to start study room');
      }

      _logger.i('Study room started: $roomId');
    } catch (e) {
      _logger.e('Error starting study room $roomId: $e');
      rethrow;
    }
  }
}
