import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/chat_room_state.dart';
import '../services/chat_room_service.dart';

class ChatRoomViewModel extends ChangeNotifier {
  ChatRoomService? _service;
  ChatRoomState _state = const ChatRoomState();
  final List<ChatMessage> _messages = [];
  final List<_SystemMessageItem> _systemMessages = [];

  final void Function()? onTokenExpired;

  ChatRoomViewModel({this.onTokenExpired});

  ChatRoomState get state => _state;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<_SystemMessageItem> get systemMessages => List.unmodifiable(_systemMessages);
  bool get isLoading => _state.isConnecting;
  bool get isConnected => _state.isConnected;

  Future<void> connect() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      _updateState(const ChatRoomState(
        status: ChatConnectionStatus.error,
        errorMessage: '请先登录',
      ));
      onTokenExpired?.call();
      return;
    }

    _service?.dispose();

    _service = ChatRoomService(
      onStateChanged: _onStateChanged,
      onMessage: _onMessage,
      onSystemMessage: _onSystemMessage,
      onAuthError: _onAuthError,
      onTokenExpired: _handleTokenExpired,
    );

    await _service!.connect(token);
  }

  void _onStateChanged(ChatRoomState newState) {
    _state = newState;
    if (newState.status == ChatConnectionStatus.disconnected) {
      _handleTokenExpired();
    }
    notifyListeners();
  }

  void _onMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  void _onSystemMessage(String content, String time, int onlineCount) {
    _systemMessages.add(_SystemMessageItem(content: content, time: time));
    if (_state.onlineCount != onlineCount) {
      _state = _state.copyWith(onlineCount: onlineCount);
    }
    notifyListeners();
  }

  void _onAuthError(String error) {}

  void _handleTokenExpired() async {
    await _clearToken();
    onTokenExpired?.call();
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_user_id');
  }

  void sendMessage(String content) {
    if (content.trim().isEmpty) return;
    _service?.sendMessage(content.trim());
  }

  void clearMessages() {
    _messages.clear();
    _systemMessages.clear();
    notifyListeners();
  }

  Future<void> disconnect() async {
    _service?.dispose();
    _service = null;
    _updateState(const ChatRoomState());
  }

  void _updateState(ChatRoomState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _service?.dispose();
    super.dispose();
  }
}

class _SystemMessageItem {
  final String content;
  final String time;

  _SystemMessageItem({required this.content, required this.time});
}
