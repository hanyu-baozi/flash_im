import 'dart:async';
import 'package:dio/dio.dart';
import '../models/connection_state.dart';
import '../config/heartbeat_config.dart';

/// 心跳通信服务
class HeartbeatService {
  final Dio _dio;
  Timer? _heartbeatTimer;
  bool _isRunning = false;

  HeartbeatService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(
          baseUrl: HeartbeatConfig.baseUrl,
          connectTimeout: const Duration(milliseconds: HeartbeatConfig.connectTimeout),
          receiveTimeout: const Duration(milliseconds: HeartbeatConfig.connectTimeout),
        ));

  /// 发送心跳请求
  Future<HeartbeatResponse> sendHeartbeat() async {
    final startTime = DateTime.now();
    
    try {
      final response = await _dio.get(HeartbeatConfig.heartbeatPath);
      final endTime = DateTime.now();
      final latency = endTime.difference(startTime).inMilliseconds;

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return HeartbeatResponse(
          success: true,
          latency: latency,
          serverTime: data['serverTime'] as String?,
          message: data['message'] as String?,
        );
      } else {
        return HeartbeatResponse(
          success: false,
          latency: latency,
          errorMessage: '请求失败: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      final endTime = DateTime.now();
      final latency = endTime.difference(startTime).inMilliseconds;
      
      String errorMessage;
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = '连接超时';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = '响应超时';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = '网络连接失败';
      } else {
        errorMessage = '请求失败: ${e.message}';
      }
      
      return HeartbeatResponse(
        success: false,
        latency: latency,
        errorMessage: errorMessage,
      );
    } catch (e) {
      return HeartbeatResponse(
        success: false,
        errorMessage: '心跳请求失败: $e',
      );
    }
  }

  /// 发送消息（带内容的心跳）
  Future<MessageResponse> sendMessage(String message) async {
    final startTime = DateTime.now();

    try {
      final response = await _dio.post(
        HeartbeatConfig.heartbeatPath,
        data: {'message': message},
      );
      final endTime = DateTime.now();
      final latency = endTime.difference(startTime).inMilliseconds;

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return MessageResponse(
          success: true,
          latency: latency,
          originalMessage: message,
          replyMessage: data['replyMessage'] as String? ?? '',
          serverTime: data['serverTime'] as String?,
        );
      } else {
        return MessageResponse(
          success: false,
          latency: latency,
          originalMessage: message,
          errorMessage: '发送失败: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      final endTime = DateTime.now();
      final latency = endTime.difference(startTime).inMilliseconds;

      String errorMessage;
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = '连接超时';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = '响应超时';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = '网络连接失败';
      } else {
        errorMessage = '发送失败: ${e.message}';
      }

      return MessageResponse(
        success: false,
        latency: latency,
        originalMessage: message,
        errorMessage: errorMessage,
      );
    } catch (e) {
      return MessageResponse(
        success: false,
        originalMessage: message,
        errorMessage: '消息发送异常: $e',
      );
    }
  }

  /// 开始心跳定时器
  void startHeartbeat({
    required void Function(HeartbeatConnectionState) onStateChanged,
    Duration interval = const Duration(milliseconds: HeartbeatConfig.heartbeatInterval),
  }) {
    if (_isRunning) return;
    
    _isRunning = true;
    
    // 立即发送一次心跳
    _sendHeartbeatInternal(onStateChanged);
    
    // 设置定时器
    _heartbeatTimer = Timer.periodic(interval, (timer) {
      _sendHeartbeatInternal(onStateChanged);
    });
  }

  /// 内部心跳发送方法
  Future<void> _sendHeartbeatInternal(
    void Function(HeartbeatConnectionState) onStateChanged,
  ) async {
    // 先通知连接中状态
    onStateChanged(HeartbeatConnectionState(
      status: ConnectionStatus.connecting,
      serverAddress: HeartbeatConfig.baseUrl,
    ));

    final response = await sendHeartbeat();
    
    if (response.success) {
      onStateChanged(HeartbeatConnectionState(
        status: ConnectionStatus.connected,
        lastHeartbeatTime: DateTime.now(),
        serverAddress: HeartbeatConfig.baseUrl,
        latency: response.latency,
      ));
    } else {
      onStateChanged(HeartbeatConnectionState(
        status: ConnectionStatus.disconnected,
        serverAddress: HeartbeatConfig.baseUrl,
        errorMessage: response.errorMessage,
      ));
    }
  }

  /// 停止心跳
  void stopHeartbeat() {
    _isRunning = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// 更新基础 URL
  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
    HeartbeatConfig.updateBaseUrl(newBaseUrl);
  }

  /// 是否正在运行
  bool get isRunning => _isRunning;

  /// 释放资源
  void dispose() {
    stopHeartbeat();
  }
}

/// 心跳响应数据
class HeartbeatResponse {
  final bool success;
  final int? latency;
  final String? serverTime;
  final String? message;
  final String? errorMessage;

  HeartbeatResponse({
    required this.success,
    this.latency,
    this.serverTime,
    this.message,
    this.errorMessage,
  });
}

/// 消息响应数据
class MessageResponse {
  final bool success;
  final int? latency;
  final String originalMessage;
  final String? replyMessage;
  final String? serverTime;
  final String? errorMessage;

  MessageResponse({
    required this.success,
    this.latency,
    required this.originalMessage,
    this.replyMessage,
    this.serverTime,
    this.errorMessage,
  });
}
