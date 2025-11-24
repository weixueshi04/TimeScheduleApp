import 'package:flutter/foundation.dart';
import '../../data/models/study_room.dart';
import '../../data/repositories/study_room_repository.dart';
import '../../data/services/websocket_service.dart';

enum StudyRoomStatus {
  initial,
  loading,
  loaded,
  error,
  inRoom,
}

class StudyRoomProvider with ChangeNotifier {
  final StudyRoomRepository _repository;
  final WebSocketService _wsService;

  StudyRoomProvider({
    required StudyRoomRepository repository,
    required WebSocketService wsService,
  })  : _repository = repository,
        _wsService = wsService {
    _setupWebSocketListeners();
  }

  // State
  StudyRoomStatus _status = StudyRoomStatus.initial;
  List<StudyRoom> _studyRooms = [];
  StudyRoom? _currentRoom;
  String? _errorMessage;
  bool _isLoading = false;

  // Matching state
  bool _isMatching = false;
  String? _matchingMessage;

  // Real-time participants and energy data
  Map<int, List<Participant>> _roomParticipants = {};
  Map<int, Map<int, int>> _participantEnergy = {}; // roomId -> userId -> energy

  // Getters
  StudyRoomStatus get status => _status;
  List<StudyRoom> get studyRooms => _studyRooms;
  StudyRoom? get currentRoom => _currentRoom;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isMatching => _isMatching;
  String? get matchingMessage => _matchingMessage;
  bool get isInRoom => _currentRoom != null;

  List<Participant> getRoomParticipants(int roomId) {
    return _roomParticipants[roomId] ?? [];
  }

  int getParticipantEnergy(int roomId, int userId) {
    return _participantEnergy[roomId]?[userId] ?? 0;
  }

  // Fetch study rooms list
  Future<void> fetchStudyRooms() async {
    _setStatus(StudyRoomStatus.loading);
    _isLoading = true;
    notifyListeners();

    try {
      _studyRooms = await _repository.getStudyRooms();
      _setStatus(StudyRoomStatus.loaded);
      _errorMessage = null;
    } catch (e) {
      _setStatus(StudyRoomStatus.error);
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new study room
  Future<StudyRoom?> createStudyRoom({
    required String name,
    required int durationMinutes,
    required String scheduledStartTime,
    int maxParticipants = 4,
    String? taskCategory,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final request = CreateStudyRoomRequest(
        name: name,
        durationMinutes: durationMinutes,
        scheduledStartTime: scheduledStartTime,
        maxParticipants: maxParticipants,
        taskCategory: taskCategory,
      );

      final room = await _repository.createStudyRoom(request);
      _studyRooms.insert(0, room);
      _currentRoom = room;
      _setStatus(StudyRoomStatus.inRoom);

      // Join WebSocket room
      _wsService.joinStudyRoom(room.id);

      _errorMessage = null;
      return room;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Join an existing study room
  Future<bool> joinStudyRoom(int roomId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.joinStudyRoom(roomId);

      // Fetch updated room details
      final room = await _repository.getStudyRoomDetail(roomId);
      _currentRoom = room;
      _setStatus(StudyRoomStatus.inRoom);

      // Join WebSocket room
      _wsService.joinStudyRoom(roomId);

      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Leave current study room
  Future<bool> leaveStudyRoom() async {
    if (_currentRoom == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _repository.leaveStudyRoom(_currentRoom!.id);

      // Leave WebSocket room
      _wsService.leaveStudyRoom(_currentRoom!.id);

      _currentRoom = null;
      _setStatus(StudyRoomStatus.loaded);
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Start matching for a study room
  Future<bool> startMatching({
    required int durationMinutes,
    required String scheduledStartTime,
    String? taskCategory,
  }) async {
    _isMatching = true;
    _matchingMessage = '正在为您寻找合适的学习伙伴...';
    notifyListeners();

    try {
      // Send matching request
      _wsService.emit('start_matching', {
        'durationMinutes': durationMinutes,
        'scheduledStartTime': scheduledStartTime,
        'taskCategory': taskCategory,
      });

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isMatching = false;
      _matchingMessage = null;
      notifyListeners();
      return false;
    }
  }

  // Cancel matching
  void cancelMatching() {
    _wsService.emit('cancel_matching', {});
    _isMatching = false;
    _matchingMessage = null;
    notifyListeners();
  }

  // Update energy level for current user in current room
  void updateEnergy(int energyLevel, String focusState) {
    if (_currentRoom == null) return;

    _wsService.updateEnergy(
      roomId: _currentRoom!.id,
      energyLevel: energyLevel,
      focusState: focusState,
    );
  }

  // Send chat message
  void sendChatMessage(String message) {
    if (_currentRoom == null) return;

    _wsService.sendChatMessage(
      roomId: _currentRoom!.id,
      message: message,
    );
  }

  // Setup WebSocket event listeners
  void _setupWebSocketListeners() {
    // User joined room
    _wsService.onUserJoined((data) {
      final roomId = data['roomId'] as int?;
      if (roomId != null && _currentRoom?.id == roomId) {
        // Refresh room details to get updated participants
        _refreshCurrentRoom();
      }
    });

    // User left room
    _wsService.onUserLeft((data) {
      final roomId = data['roomId'] as int?;
      if (roomId != null && _currentRoom?.id == roomId) {
        _refreshCurrentRoom();
      }
    });

    // Energy update
    _wsService.onEnergyUpdate((data) {
      final roomId = data['roomId'] as int?;
      final userId = data['userId'] as int?;
      final energyLevel = data['energyLevel'] as int?;

      if (roomId != null && userId != null && energyLevel != null) {
        if (_participantEnergy[roomId] == null) {
          _participantEnergy[roomId] = {};
        }
        _participantEnergy[roomId]![userId] = energyLevel;
        notifyListeners();
      }
    });

    // Room started
    _wsService.onRoomStarted((data) {
      final roomId = data['roomId'] as int?;
      if (roomId != null && _currentRoom?.id == roomId) {
        _currentRoom = _currentRoom!.copyWith(status: 'in_progress');
        notifyListeners();
      }
    });

    // Room ended
    _wsService.onRoomEnded((data) {
      final roomId = data['roomId'] as int?;
      if (roomId != null && _currentRoom?.id == roomId) {
        _currentRoom = _currentRoom!.copyWith(status: 'completed');
        notifyListeners();
      }
    });

    // Matching success
    _wsService.on('matching_success', (data) {
      _isMatching = false;
      _matchingMessage = '匹配成功！';

      final roomId = data['roomId'] as int?;
      if (roomId != null) {
        // Auto join the matched room
        joinStudyRoom(roomId);
      }

      notifyListeners();
    });

    // Matching failed
    _wsService.on('matching_failed', (data) {
      _isMatching = false;
      _matchingMessage = '匹配失败，请重试';
      _errorMessage = data['message']?.toString();
      notifyListeners();
    });

    // Chat message received
    _wsService.onChatMessage((data) {
      // Handle chat message (could store in a separate list)
      notifyListeners();
    });
  }

  // Refresh current room details
  Future<void> _refreshCurrentRoom() async {
    if (_currentRoom == null) return;

    try {
      final room = await _repository.getStudyRoomDetail(_currentRoom!.id);
      _currentRoom = room;
      _roomParticipants[room.id] = room.participants ?? [];
      notifyListeners();
    } catch (e) {
      // Silently fail, keep current data
    }
  }

  // Set status helper
  void _setStatus(StudyRoomStatus status) {
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up WebSocket listeners if needed
    super.dispose();
  }
}
