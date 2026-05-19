import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../viewmodel/chat_room_viewmodel.dart';

class ChatListView extends StatefulWidget {
  final ChatRoomViewModel viewModel;

  const ChatListView({super.key, required this.viewModel});

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAppBar(),
        Expanded(child: _buildBody()),
        if (widget.viewModel.isConnected) _buildInputBar(),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFEDEDED),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Text(
            '聊天室',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const Spacer(),
          _buildStatusBadge(),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final state = widget.viewModel.state;
    String text;
    Color color;

    switch (state.status) {
      case var s when s.name == 'authenticated':
        text = '${state.onlineCount}人在线';
        color = const Color(0xFF07C160);
        break;
      case var s when s.name == 'connecting' || s.name == 'authenticating':
        text = '连接中...';
        color = const Color(0xFFFF9800);
        break;
      case var s when s.name == 'error':
        text = state.errorMessage ?? '连接失败';
        color = const Color(0xFFEF4444);
        break;
      default:
        text = '未连接';
        color = const Color(0xFF999999);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final state = widget.viewModel.state;
    final messages = widget.viewModel.messages;

    if (state.status.name == 'disconnected') {
      return _buildDisconnectedView();
    }

    if (messages.isEmpty && !widget.viewModel.isLoading) {
      return _buildEmptyView();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return _ChatBubble(message: messages[index]);
      },
    );
  }

  Widget _buildDisconnectedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_outlined, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '未连接到聊天室',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '请先登录后重试',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => widget.viewModel.connect(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('重新连接'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF07C160),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.forum_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('暂无消息', style: TextStyle(fontSize: 15, color: Colors.grey[400])),
          const SizedBox(height: 6),
          Text('发送第一条消息开始聊天吧', style: TextStyle(fontSize: 13, color: Colors.grey[350])),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () {},
              child: const Icon(Icons.emoji_emotions_outlined, size: 28, color: Color(0xFF666666)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 80),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [LengthLimitingTextInputFormatter(500)],
                  style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
                  decoration: InputDecoration(
                    hintText: '输入消息...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF07C160), Color(0xFF06AD56)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.viewModel.sendMessage(text);
      _textController.clear();
    }
  }
}

class _ChatBubble extends StatelessWidget {
  final dynamic message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isSelf = message.isSelf as bool? ?? false;

    return Align(
      alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        child: Column(
          crossAxisAlignment: isSelf ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isSelf) ...[
              Padding(
                padding: const EdgeInsets.only(left: 44, bottom: 2),
                child: Text(
                  message.fromNickname as String? ?? '',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF576B95), fontWeight: FontWeight.w500),
                ),
              ),
            ],
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isSelf) ...[
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: message.fromAvatar != null ? NetworkImage(message.fromAvatar as String) : null,
                    child: message.fromAvatar == null
                        ? Text((message.fromNickname as String? ?? '?').substring(0, 1), style: const TextStyle(fontSize: 13, color: Colors.white))
                        : null,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelf ? const Color(0xFF95EC69) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: isSelf ? const Radius.circular(12) : Radius.zero,
                        bottomRight: isSelf ? Radius.zero : const Radius.circular(12),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1)),
                      ],
                    ),
                    child: Text(
                      message.content as String? ?? '',
                      style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E), height: 1.4),
                    ),
                  ),
                ),
                if (isSelf) ...[
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: message.fromAvatar != null ? NetworkImage(message.fromAvatar as String) : null,
                    child: message.fromAvatar == null
                        ? Text((message.fromNickname as String? ?? '?').substring(0, 1), style: const TextStyle(fontSize: 13, color: Colors.white))
                        : null,
                  ),
                ],
              ],
            ),
            Padding(
              padding: EdgeInsets.only(right: isSelf ? 44 : 0, left: isSelf ? 0 : 44, top: 2),
              child: Text(
                message.time as String? ?? '',
                style: const TextStyle(fontSize: 10, color: Color(0xFFBDBDBD)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
