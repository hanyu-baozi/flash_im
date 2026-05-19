enum ChatConnectionStatus {
  disconnected,
  connecting,
  authenticating,
  authenticated,
  error,
}

class ChatRoomState {
  final ChatConnectionStatus status;
  final String? errorMessage;
  final int? userId;
  final String? nickname;
  final String? avatar;
  final int onlineCount;
  final DateTime? lastHeartbeatTime;
  final int latency;

  const ChatRoomState({
    this.status = ChatConnectionStatus.disconnected,
    this.errorMessage,
    this.userId,
    this.nickname,
    this.avatar,
    this.onlineCount = 0,
    this.lastHeartbeatTime,
    this.latency = 0,
  });

  ChatRoomState copyWith({
    ChatConnectionStatus? status,
    String? errorMessage,
    int? userId,
    String? nickname,
    String? avatar,
    int? onlineCount,
    DateTime? lastHeartbeatTime,
    int? latency,
  }) {
    return ChatRoomState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? (status == ChatConnectionStatus.authenticated ? null : this.errorMessage),
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      onlineCount: onlineCount ?? this.onlineCount,
      lastHeartbeatTime: lastHeartbeatTime ?? this.lastHeartbeatTime,
      latency: latency ?? this.latency,
    );
  }

  bool get isConnected => status == ChatConnectionStatus.authenticated;
  bool get isConnecting => status == ChatConnectionStatus.connecting || status == ChatConnectionStatus.authenticating;
}
