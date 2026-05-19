enum ConversationType {
  single,
  group,
}

enum MessageType {
  text,
  image,
  transfer,
  sticker,
  voice,
  video,
  file,
  redPacket,
}

class ConversationItem {
  final String id;
  final String title;
  final String lastMsg;
  final String time;
  final String? avatarUrl;
  final int unreadCount;
  final ConversationType type;
  final MessageType messageType;
  final bool isMuted;

  ConversationItem({
    required this.id,
    required this.title,
    required this.lastMsg,
    required this.time,
    this.avatarUrl,
    this.unreadCount = 0,
    this.type = ConversationType.single,
    this.messageType = MessageType.text,
    this.isMuted = false,
  });

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    return ConversationItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String,
      lastMsg: json['lastMsg'] as String,
      time: json['time'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      unreadCount: json['unreadCount'] as int? ?? 0,
      type: ConversationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ConversationType.single,
      ),
      messageType: MessageType.values.firstWhere(
        (e) => e.name == json['messageType'],
        orElse: () => MessageType.text,
      ),
      isMuted: json['isMuted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lastMsg': lastMsg,
      'time': time,
      'avatarUrl': avatarUrl,
      'unreadCount': unreadCount,
      'type': type.name,
      'messageType': messageType.name,
      'isMuted': isMuted,
    };
  }

  String get messageTypeLabel {
    switch (messageType) {
      case MessageType.image:
        return '[图片]';
      case MessageType.transfer:
        return '[转账]';
      case MessageType.sticker:
        return '[动画表情]';
      case MessageType.voice:
        return '[语音]';
      case MessageType.video:
        return '[视频]';
      case MessageType.file:
        return '[文件]';
      case MessageType.redPacket:
        return '[红包]';
      case MessageType.text:
        return '';
    }
  }

  String get displayMessage {
    if (messageTypeLabel.isNotEmpty) {
      return '$messageTypeLabel $lastMsg';
    }
    return lastMsg;
  }

  @override
  String toString() {
    return 'ConversationItem(id: $id, title: $title, lastMsg: $lastMsg, time: $time)';
  }
}
