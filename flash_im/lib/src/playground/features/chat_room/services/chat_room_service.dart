import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/chat_room_config.dart';
import '../models/chat_message.dart';
import '../models/chat_room_state.dart';

class ChatRoomService {
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  StreamSubscription? _subscription;

  final void Function(ChatRoomState) onStateChanged;
  final void Function(ChatMessage)? onMessage;
  final void Function(String content, String time, int onlineCount)? onSystemMessage;
  final void Function(String error)? onAuthError;
  final void Function()? onTokenExpired;

  ChatRoomState _state = const ChatRoomState();
  bool _disposed = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  String? _pendingToken;
  bool _connectionError = false;

  ChatRoomService({
    required this.onStateChanged,
    this.onMessage,
    this.onSystemMessage,
    this.onAuthError,
    this.onTokenExpired,
  });

  ChatRoomState get state => _state;

  Future<void> connect(String token) async {
    if (_disposed) return;
    if (_channel != null) await disconnect();

    _pendingToken = token;
    _connectionError = false;
    _setState(const ChatRoomState(status: ChatConnectionStatus.connecting));

    try {
      print('[ChatRoomService] 连接中... ${ChatRoomConfig.wsUrl}');
      _channel = WebSocketChannel.connect(Uri.parse(ChatRoomConfig.wsUrl));

      _subscription = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _setState(const ChatRoomState(status: ChatConnectionStatus.authenticating));

      await Future.delayed(const Duration(milliseconds: 500));
      if (_channel != null && !_disposed && !_connectionError) {
        _sendAuth(token);
        _startHeartbeat();
      }
    } catch (e) {
      print('[ChatRoomService] 连接异常: $e');
      _setError('连接失败: $e');
    }
  }

  void _sendAuth(String token) {
    if (_channel == null || _disposed) return;
    try {
      _channel!.sink.add(jsonEncode({'type': 'auth', 'token': token}));
      print('[ChatRoomService] 已发送认证消息');
    } catch (e) {
      print('[ChatRoomService] 发送认证消息失败: $e');
    }
  }

  void _onMessage(dynamic message) {
    if (_disposed || _channel == null) return;

    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;
      print('[ChatRoomService] 收到消息: type=$type');

      switch (type) {
        case 'auth_success':
          _setState(ChatRoomState(
            status: ChatConnectionStatus.authenticated,
            userId: data['userId'] as int?,
            nickname: data['nickname'] as String?,
            avatar: data['avatar'] as String?,
            onlineCount: data['onlineCount'] as int? ?? 0,
          ));
          _reconnectAttempts = 0;
          break;

        case 'auth_error':
          onAuthError?.call(data['message'] as String? ?? '认证失败');
          onTokenExpired?.call();
          _setError(data['message'] as String? ?? '认证失败');
          break;

        case 'pong':
          _setState(_state.copyWith(
            lastHeartbeatTime: DateTime.now(),
          ));
          break;

        case 'chat_message':
          if (onMessage != null) {
            final msg = ChatMessage.fromJson(data, currentUserId: _state.userId);
            onMessage!(msg);
          }
          break;

        case 'system_message':
          onSystemMessage?.call(
            data['content'] as String? ?? '',
            data['time'] as String? ?? '',
            data['onlineCount'] as int? ?? 0,
          );
          if (data['onlineCount'] != null) {
            _setState(_state.copyWith(onlineCount: data['onlineCount'] as int));
          }
          break;

        case 'error':
          _setError(data['message'] as String? ?? '服务器错误');
          break;
      }
    } catch (e) {}
  }

  void _onError(Object error) {
    _connectionError = true;
    print('[ChatRoomService] 连接错误: $error');
    _setError('连接异常: $error');
  }

  void _onDone() {
    if (_disposed) return;
    print('[ChatRoomService] 连接断开');
    _stopHeartbeat();

    if (_state.isConnected && _reconnectAttempts < _maxReconnectAttempts && !_isAuthError) {
      _reconnectAttempts++;
      _scheduleReconnect();
    } else {
      _setState(const ChatRoomState(status: ChatConnectionStatus.disconnected));
    }
  }

  bool get _isAuthError =>
      _state.errorMessage != null &&
      (_state.errorMessage!.contains('认证') ||
       _state.errorMessage!.contains('Token') ||
       _state.errorMessage!.contains('401'));

  void _scheduleReconnect() {
    _setState(ChatRoomState(
      status: ChatConnectionStatus.connecting,
      errorMessage: '正在重连... ($_reconnectAttempts/$_maxReconnectAttempts)',
    ));

    final delay = Duration(seconds: _reconnectAttempts * 2);
    _reconnectTimer = Timer(delay, () async {
      if (_disposed || _pendingToken == null) return;
      connect(_pendingToken!);
    });
  }

  void sendMessage(String content) {
    print('[ChatRoomService] sendMessage: channel=$_channel, isConnected=${_state.isConnected}');
    if (_channel == null || !_state.isConnected) return;

    _channel!.sink.add(jsonEncode({
      'type': 'message',
      'content': content,
      'msgType': 'text',
    }));
    print('[ChatRoomService] 消息已发送: $content');
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(
      const Duration(milliseconds: ChatRoomConfig.heartbeatInterval ~/ 3),
      (_) => sendPing(),
    );
  }

  void sendPing() {
    if (_channel == null || !_state.isConnected) return;
    try {
      _channel!.sink.add(jsonEncode({'type': 'ping', 'timestamp': DateTime.now().millisecondsSinceEpoch}));
    } catch (e) {}
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _setState(ChatRoomState newState) {
    _state = newState;
    onStateChanged(newState);
  }

  void _setError(String error) {
    _setState(ChatRoomState(
      status: ChatConnectionStatus.error,
      errorMessage: error,
    ));
  }

  Future<void> disconnect() async {
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
    _pendingToken = null;
    _reconnectAttempts = 0;
    _setState(const ChatRoomState());
  }

  void dispose() {
    _disposed = true;
    disconnect();
  }
}
