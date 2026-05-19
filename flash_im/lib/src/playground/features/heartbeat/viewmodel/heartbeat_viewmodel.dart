import 'package:flutter/material.dart';
import '../models/connection_state.dart';
import '../services/heartbeat_service.dart';

/// 心跳通信 ViewModel
class HeartbeatViewModel extends ChangeNotifier {
  final HeartbeatService _service;
  HeartbeatConnectionState _connectionState = HeartbeatConnectionState();
  List<HeartbeatLog> _logs = [];
  List<MessageRecord> _messageHistory = [];
  bool _isAutoHeartbeat = false;

  HeartbeatViewModel({HeartbeatService? service})
      : _service = service ?? HeartbeatService();

  /// 获取当前连接状态
  HeartbeatConnectionState get connectionState => _connectionState;

  /// 获取日志列表
  List<HeartbeatLog> get logs => _logs;

  /// 获取消息历史记录
  List<MessageRecord> get messageHistory => _messageHistory;

  /// 是否正在自动心跳
  bool get isAutoHeartbeat => _isAutoHeartbeat;

  /// 发送单次心跳
  Future<void> sendHeartbeat() async {
    _addLog('开始发送心跳...');
    
    // 更新状态为连接中
    _connectionState = HeartbeatConnectionState(
      status: ConnectionStatus.connecting,
      serverAddress: '正在连接...',
    );
    notifyListeners();

    try {
      final response = await _service.sendHeartbeat();
      
      if (response.success) {
        _connectionState = HeartbeatConnectionState(
          status: ConnectionStatus.connected,
          lastHeartbeatTime: DateTime.now(),
          serverAddress: '已连接',
          latency: response.latency,
        );
        _addLog('心跳成功，延迟: ${response.latency}ms');
      } else {
        _connectionState = HeartbeatConnectionState(
          status: ConnectionStatus.disconnected,
          serverAddress: '连接失败',
          errorMessage: response.errorMessage,
        );
        _addLog('心跳失败: ${response.errorMessage}');
      }
    } catch (e) {
      _connectionState = HeartbeatConnectionState(
        status: ConnectionStatus.disconnected,
        serverAddress: '连接失败',
        errorMessage: e.toString(),
      );
      _addLog('心跳异常: $e');
    }
    
    notifyListeners();
  }

  /// 开始自动心跳
  void startAutoHeartbeat() {
    if (_isAutoHeartbeat) return;
    
    _isAutoHeartbeat = true;
    _addLog('开始自动心跳');
    notifyListeners();

    _service.startHeartbeat(
      onStateChanged: (state) {
        _connectionState = state;
        
        if (state.status == ConnectionStatus.connected) {
          _addLog('心跳成功，延迟: ${state.latency}ms');
        } else if (state.status == ConnectionStatus.disconnected) {
          _addLog('心跳失败: ${state.errorMessage}');
        }
        
        notifyListeners();
      },
    );
  }

  /// 停止自动心跳
  void stopAutoHeartbeat() {
    if (!_isAutoHeartbeat) return;
    
    _service.stopHeartbeat();
    _isAutoHeartbeat = false;
    _connectionState = HeartbeatConnectionState(
      status: ConnectionStatus.disconnected,
      serverAddress: '已停止',
    );
    _addLog('停止自动心跳');
    notifyListeners();
  }

  /// 发送消息
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    _addLog('发送消息: $message');

    // 添加到消息历史（发送）
    _messageHistory.insert(0, MessageRecord(
      time: DateTime.now(),
      type: MessageType.sent,
      content: message,
    ));

    try {
      final response = await _service.sendMessage(message);

      if (response.success) {
        // 添加到消息历史（接收）
        _messageHistory.insert(0, MessageRecord(
          time: DateTime.now(),
          type: MessageType.received,
          content: response.replyMessage ?? '',
          latency: response.latency,
        ));
        _addLog('消息发送成功，延迟: ${response.latency}ms');
      } else {
        _addLog('消息发送失败: ${response.errorMessage}');
      }
    } catch (e) {
      _addLog('消息发送异常: $e');
    }

    notifyListeners();
  }

  /// 清空消息历史
  void clearMessages() {
    _messageHistory.clear();
    notifyListeners();
  }

  /// 清空日志
  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  /// 添加日志
  void _addLog(String message) {
    _logs.insert(0, HeartbeatLog(
      time: DateTime.now(),
      message: message,
    ));
    
    // 限制日志数量
    if (_logs.length > 100) {
      _logs = _logs.sublist(0, 100);
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}

/// 心跳日志
class HeartbeatLog {
  final DateTime time;
  final String message;

  HeartbeatLog({
    required this.time,
    required this.message,
  });

  String get formattedTime {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

/// 消息类型枚举
enum MessageType {
  sent,      // 发送的消息
  received,  // 接收到的消息
}

/// 消息记录
class MessageRecord {
  final DateTime time;
  final MessageType type;
  final String content;
  final int? latency;

  MessageRecord({
    required this.time,
    required this.type,
    required this.content,
    this.latency,
  });

  String get formattedTime {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}
