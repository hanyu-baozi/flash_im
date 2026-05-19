class ChatMessage {
  final String id;
  final int fromUserId;
  final String fromNickname;
  final String fromAvatar;
  final String content;
  final String type;
  final String time;
  final bool isSelf;

  ChatMessage({
    required this.id,
    required this.fromUserId,
    required this.fromNickname,
    required this.fromAvatar,
    required this.content,
    this.type = 'text',
    required this.time,
    this.isSelf = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, {int? currentUserId}) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      fromUserId: json['fromUserId'] as int? ?? 0,
      fromNickname: json['fromNickname'] as String? ?? '',
      fromAvatar: json['fromAvatar'] as String? ?? '',
      content: json['content'] as String? ?? '',
      type: json['msgType'] as String? ?? 'text',
      time: json['time'] as String? ?? '',
      isSelf: currentUserId != null && json['fromUserId'] == currentUserId,
    );
  }
}

class SystemMessage {
  final String content;
  final String time;
  final int onlineCount;

  SystemMessage({
    required this.content,
    required this.time,
    required this.onlineCount,
  });

  factory SystemMessage.fromJson(Map<String, dynamic> json) {
    return SystemMessage(
      content: json['content'] as String? ?? '',
      time: json['time'] as String? ?? '',
      onlineCount: json['onlineCount'] as int? ?? 0,
    );
  }
}
