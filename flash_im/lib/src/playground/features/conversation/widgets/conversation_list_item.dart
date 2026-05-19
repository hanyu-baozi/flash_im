import 'package:flutter/material.dart';
import '../models/conversation_item.dart';

class ConversationListItem extends StatelessWidget {
  final ConversationItem item;
  final VoidCallback? onTap;

  const ConversationListItem({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: const Color(0xFFE5E5E5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ConversationAvatar(item: item),
            const SizedBox(width: 12),
            Expanded(
              child: _ConversationContent(item: item),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationAvatar extends StatelessWidget {
  final ConversationItem item;

  const _ConversationAvatar({required this.item});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: _AvatarImage(avatarUrl: item.avatarUrl, title: item.title),
        ),
        if (item.type == ConversationType.group)
          Positioned(
            bottom: -2,
            right: -2,
            child: _GroupBadge(),
          ),
      ],
    );
  }
}

class _AvatarImage extends StatelessWidget {
  final String? avatarUrl;
  final String title;

  const _AvatarImage({this.avatarUrl, required this.title});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return Image.network(
        avatarUrl!,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _DefaultAvatar(title: title),
      );
    }
    return _DefaultAvatar(title: title);
  }
}

class _DefaultAvatar extends StatelessWidget {
  final String title;

  const _DefaultAvatar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      color: _AvatarColorGenerator.getColor(title),
      alignment: Alignment.center,
      child: Text(
        _getAvatarText(title),
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getAvatarText(String title) {
    if (title.isEmpty) return '?';
    return title.substring(0, 1);
  }
}

class _AvatarColorGenerator {
  static const List<Color> _colors = [
    Color(0xFFFFB6C1),
    Color(0xFF87CEEB),
    Color(0xFF98FB98),
    Color(0xFFDDA0DD),
    Color(0xFFFFD700),
    Color(0xFFFFA07A),
    Color(0xFF20B2AA),
    Color(0xFF778899),
    Color(0xFFB0C4DE),
    Color(0xFFDB7093),
  ];

  static Color getColor(String title) {
    if (title.isEmpty) return _colors[0];
    int hash = title.hashCode.abs();
    return _colors[hash % _colors.length];
  }
}

class _GroupBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50),
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.center,
      child: const Text(
        '群',
        style: TextStyle(
          fontSize: 8,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ConversationContent extends StatelessWidget {
  final ConversationItem item;

  const _ConversationContent({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.time,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                item.displayMessage,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF999999),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (item.isMuted) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.notifications_off,
                size: 14,
                color: Color(0xFF999999),
              ),
            ],
            if (item.unreadCount > 0) ...[
              const SizedBox(width: 6),
              _UnreadBadge(count: item.unreadCount),
            ],
          ],
        ),
      ],
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final displayText = count > 99 ? '99+' : count.toString();

    return Container(
      constraints: const BoxConstraints(minWidth: 18, maxHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B30),
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: Text(
        displayText,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.w500,
          height: 1.0,
        ),
      ),
    );
  }
}
