import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:logger/logger.dart';
import '../../core/constants/api_constants.dart';
import 'token_service.dart';

/// WebSocket连接状态
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

/// WebSocket事件类型
class WSEvents {
  // 连接事件
  static const String connect = 'connect';
  static const String disconnect = 'disconnect';
  static const String authenticate = 'authenticate';
  static const String authenticated = 'authenticated';
  static const String error = 'error';

  // 心跳事件
  static const String ping = 'ping';
  static const String pong = 'pong';

  // 自习室事件
  static const String joinRoom = 'join_room';
  static const String leaveRoom = 'leave_room';
  static const String roomJoined = 'room_joined';
  static const String roomLeft = 'room_left';
  static const String userJoined = 'user_joined';
  static const String userLeft = 'user_left';

  // 实时更新
  static const String energyUpdate = 'energy_update';
  static const String focusStateChange = 'focus_state_change';
  static const String participantUpdate = 'participant_update';

  // 会话事件
  static const String sessionStarted = 'session_started';
  static const String sessionEnded = 'session_ended';
  static const String breakStarted = 'break_started';
  static const String breakEnded = 'break_ended';

  // 聊天事件
  static const String chatMessage = 'chat_message';
  static const String chatHistory = 'chat_history';

  // 通知
  static const String notification = 'notification';
}

/// WebSocket服务 - 管理实时通信
class WebSocketService {
  IO.Socket? _socket;
  final TokenService _tokenService;
  final Logger _logger = Logger();

  // 连接状态
  ConnectionState _connectionState = ConnectionState.disconnected;
  ConnectionState get connectionState => _connectionState;

  // 心跳定时器
  Timer? _heartbeatTimer;
  Timer? _pongTimeoutTimer;
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _pongTimeout = Duration(seconds: 10);

  // 重连机制
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _initialReconnectDelay = Duration(seconds: 1);
  Timer? _reconnectTimer;

  // 连接状态监听器
  final _connectionStateController =
      StreamController<ConnectionState>.broadcast();
  Stream<ConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  bool get isConnected => _socket?.connected ?? false;

  WebSocketService(this._tokenService);

  /// 连接WebSocket服务器
  Future<void> connect() async {
    if (isConnected) {
      _logger.w('WebSocket already connected');
      return;
    }

    try {
      _updateConnectionState(ConnectionState.connecting);

      final token = await _tokenService.getAccessToken();
      if (token == null) {
        throw Exception('No access token available');
      }

      _socket = IO.io(
        ApiConstants.wsUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect() // 禁用自动连接，我们手动管理
            .setAuth({'token': token})
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setReconnectionAttempts(_maxReconnectAttempts)
            .build(),
      );

      _setupEventHandlers();
      _socket!.connect();

      _logger.i('WebSocket connecting to ${ApiConstants.wsUrl}');
    } catch (e) {
      _logger.e('Error connecting WebSocket: $e');
      _updateConnectionState(ConnectionState.failed);
      rethrow;
    }
  }

  /// 设置事件处理器
  void _setupEventHandlers() {
    _socket!.onConnect((_) {
      _logger.i('✅ WebSocket connected (ID: ${_socket!.id})');
      _updateConnectionState(ConnectionState.connected);
      _reconnectAttempts = 0; // 重置重连次数
      _startHeartbeat(); // 启动心跳
    });

    _socket!.onDisconnect((_) {
      _logger.w('❌ WebSocket disconnected');
      _stopHeartbeat(); // 停止心跳
      _updateConnectionState(ConnectionState.disconnected);
      _attemptReconnect(); // 尝试重连
    });

    _socket!.on(WSEvents.error, (data) {
      _logger.e('WebSocket error: $data');
    });

    _socket!.on(WSEvents.authenticated, (data) {
      _logger.i('✅ Authenticated as: ${data['user']['username']}');
    });

    // 监听pong响应
    _socket!.on(WSEvents.pong, (_) {
      _logger.d('← Received pong');
      _cancelPongTimeout();
    });
  }

  /// 更新连接状态
  void _updateConnectionState(ConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      _connectionStateController.add(newState);
      _logger.d('Connection state changed to: $newState');
    }
  }

  /// 启动心跳机制
  void _startHeartbeat() {
    _stopHeartbeat(); // 先停止旧的心跳

    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (isConnected) {
        _logger.d('→ Sending ping');
        _socket!.emit(WSEvents.ping);

        // 设置pong超时
        _pongTimeoutTimer?.cancel();
        _pongTimeoutTimer = Timer(_pongTimeout, () {
          _logger.w('⚠ Pong timeout - connection may be dead');
          _handleConnectionDead();
        });
      }
    });

    _logger.i('Heartbeat started (interval: $_heartbeatInterval)');
  }

  /// 停止心跳机制
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = null;
    _logger.d('Heartbeat stopped');
  }

  /// 取消pong超时
  void _cancelPongTimeout() {
    _pongTimeoutTimer?.cancel();
    _pongTimeoutTimer = null;
  }

  /// 处理连接死亡
  void _handleConnectionDead() {
    _logger.w('Connection appears dead, forcing disconnect and reconnect');
    disconnect();
    _attemptReconnect();
  }

  /// 尝试重连
  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _logger.e('Max reconnect attempts reached ($_maxReconnectAttempts)');
      _updateConnectionState(ConnectionState.failed);
      return;
    }

    _reconnectAttempts++;
    _updateConnectionState(ConnectionState.reconnecting);

    // 计算退避延迟（指数退避）
    final delay = _initialReconnectDelay * (1 << (_reconnectAttempts - 1));
    final cappedDelay = delay > const Duration(seconds: 30)
        ? const Duration(seconds: 30)
        : delay;

    _logger.i(
      'Attempting reconnect #$_reconnectAttempts in ${cappedDelay.inSeconds}s',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(cappedDelay, () {
      _logger.i('Reconnecting... (attempt $_reconnectAttempts)');
      connect();
    });
  }

  /// 断开连接
  void disconnect() {
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _logger.i('WebSocket disconnected');
    }

    _updateConnectionState(ConnectionState.disconnected);
  }

  /// 释放资源
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _logger.i('WebSocketService disposed');
  }

  /// 发送事件
  void emit(String event, [dynamic data]) {
    if (!isConnected) {
      _logger.w('Cannot emit $event: WebSocket not connected');
      return;
    }

    _socket!.emit(event, data);
    _logger.d('→ Emitted: $event with data: $data');
  }

  /// 监听事件
  void on(String event, Function(dynamic) handler) {
    _socket?.on(event, (data) {
      _logger.d('← Received: $event with data: $data');
      handler(data);
    });
  }

  /// 取消监听事件
  void off(String event) {
    _socket?.off(event);
  }

  // ==================== 自习室相关方法 ====================

  /// 加入自习室
  void joinStudyRoom(int roomId) {
    emit(WSEvents.joinRoom, {'roomId': roomId});
  }

  /// 离开自习室
  void leaveStudyRoom(int roomId) {
    emit(WSEvents.leaveRoom, {'roomId': roomId});
  }

  /// 更新能量条
  void updateEnergy({
    required int roomId,
    required int energyLevel,
    required String focusState,
  }) {
    emit(WSEvents.energyUpdate, {
      'roomId': roomId,
      'energyLevel': energyLevel,
      'focusState': focusState,
    });
  }

  /// 改变专注状态
  void changeFocusState({
    required int roomId,
    required String focusState,
  }) {
    emit(WSEvents.focusStateChange, {
      'roomId': roomId,
      'focusState': focusState,
    });
  }

  /// 开始休息
  void startBreak({
    required int roomId,
    required int duration,
  }) {
    emit(WSEvents.breakStarted, {
      'roomId': roomId,
      'duration': duration,
    });
  }

  /// 结束休息
  void endBreak({required int roomId}) {
    emit(WSEvents.breakEnded, {'roomId': roomId});
  }

  /// 发送聊天消息
  void sendChatMessage({
    required int roomId,
    required String message,
  }) {
    emit(WSEvents.chatMessage, {
      'roomId': roomId,
      'message': message,
    });
  }

  // ==================== 事件监听方法 ====================

  /// 监听加入房间成功
  void onRoomJoined(Function(Map<String, dynamic>) handler) {
    on(WSEvents.roomJoined, (data) => handler(data as Map<String, dynamic>));
  }

  /// 监听离开房间
  void onRoomLeft(Function(Map<String, dynamic>) handler) {
    on(WSEvents.roomLeft, (data) => handler(data as Map<String, dynamic>));
  }

  /// 监听用户加入
  void onUserJoined(Function(Map<String, dynamic>) handler) {
    on(WSEvents.userJoined, (data) => handler(data as Map<String, dynamic>));
  }

  /// 监听用户离开
  void onUserLeft(Function(Map<String, dynamic>) handler) {
    on(WSEvents.userLeft, (data) => handler(data as Map<String, dynamic>));
  }

  /// 监听能量更新
  void onEnergyUpdate(Function(Map<String, dynamic>) handler) {
    on(WSEvents.energyUpdate, (data) => handler(data as Map<String, dynamic>));
  }

  /// 监听专注状态变化
  void onFocusStateChange(Function(Map<String, dynamic>) handler) {
    on(WSEvents.focusStateChange, (data) => handler(data as Map<String, dynamic>));
  }

  /// 监听休息开始
  void onBreakStarted(Function(Map<String, dynamic>) handler) {
    on(WSEvents.breakStarted, (data) => handler(data as Map<String, dynamic>));
  }

  /// 监听休息结束
  void onBreakEnded(Function(Map<String, dynamic>) handler) {
    on(WSEvents.breakEnded, (data) => handler(data as Map<String, dynamic>));
  }

  /// 监听聊天消息
  void onChatMessage(Function(Map<String, dynamic>) handler) {
    on(WSEvents.chatMessage, (data) => handler(data as Map<String, dynamic>));
  }

  /// 监听通知
  void onNotification(Function(Map<String, dynamic>) handler) {
    on(WSEvents.notification, (data) => handler(data as Map<String, dynamic>));
  }

  /// 监听会话开始
  void onRoomStarted(Function(Map<String, dynamic>) handler) {
    on(WSEvents.sessionStarted, (data) => handler(data as Map<String, dynamic>));
  }

  /// 监听会话结束
  void onRoomEnded(Function(Map<String, dynamic>) handler) {
    on(WSEvents.sessionEnded, (data) => handler(data as Map<String, dynamic>));
  }
}
