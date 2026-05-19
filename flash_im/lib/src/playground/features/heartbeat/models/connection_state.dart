/// 连接状态枚举
enum ConnectionStatus {
  connecting,  // 连接中
  connected,   // 已连接
  disconnected, // 已断开
}

/// 连接状态模型
class HeartbeatConnectionState {
  final ConnectionStatus status;
  final DateTime? lastHeartbeatTime;
  final String? serverAddress;
  final int? latency; // 延迟（毫秒）
  final String? errorMessage;

  HeartbeatConnectionState({
    this.status = ConnectionStatus.disconnected,
    this.lastHeartbeatTime,
    this.serverAddress,
    this.latency,
    this.errorMessage,
  });

  /// 获取状态显示文本
  String get statusText {
    switch (status) {
      case ConnectionStatus.connecting:
        return '连接中';
      case ConnectionStatus.connected:
        return '已连接';
      case ConnectionStatus.disconnected:
        return '已断开';
    }
  }

  /// 获取状态颜色
  int get statusColor {
    switch (status) {
      case ConnectionStatus.connecting:
        return 0xFFFFA500; // 橙色
      case ConnectionStatus.connected:
        return 0xFF4CAF50; // 绿色
      case ConnectionStatus.disconnected:
        return 0xFFF44336; // 红色
    }
  }

  /// 复制并更新状态
  HeartbeatConnectionState copyWith({
    ConnectionStatus? status,
    DateTime? lastHeartbeatTime,
    String? serverAddress,
    int? latency,
    String? errorMessage,
  }) {
    return HeartbeatConnectionState(
      status: status ?? this.status,
      lastHeartbeatTime: lastHeartbeatTime ?? this.lastHeartbeatTime,
      serverAddress: serverAddress ?? this.serverAddress,
      latency: latency ?? this.latency,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// 清除错误信息
  HeartbeatConnectionState clearError() {
    return HeartbeatConnectionState(
      status: status,
      lastHeartbeatTime: lastHeartbeatTime,
      serverAddress: serverAddress,
      latency: latency,
      errorMessage: null,
    );
  }

  @override
  String toString() {
    return 'ConnectionState(status: $status, lastHeartbeatTime: $lastHeartbeatTime, latency: ${latency}ms)';
  }
}
