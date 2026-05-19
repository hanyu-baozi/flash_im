import 'package:flutter/material.dart';
import 'features/fireworks/fireworks_page.dart';
import 'features/conversation/views/conversation_page.dart';
import 'features/heartbeat/views/heartbeat_page.dart';
import 'features/auth/views/auth_login_page.dart';
import 'features/chat_room/views/chat_room_page.dart';

class PlaygroundHome extends StatelessWidget {
  const PlaygroundHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('开发游乐场'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.verified_user_outlined, color: Color(0xFF4F46E5)),
            title: const Text('用户认证 (Auth)'),
            subtitle: const Text('手机号验证码登录 - 个人信息展示'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AuthLoginPage()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.forum_outlined, color: Color(0xFF07C160)),
            title: const Text('聊天室 (ChatRoom)'),
            subtitle: const Text('WebSocket + JWT 认证 + 心跳 - 微信风格'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatRoomPage()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.whatshot_outlined, color: Color(0xFFEF4444)),
            title: const Text('烟花秀'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FireworksPage()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline, color: Color(0xFF22C55E)),
            title: const Text('会话列表 (Conversation)'),
            subtitle: const Text('微信风格会话列表 - 模拟数据'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ConversationPage()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.favorite_outline, color: Color(0xFF7C3AED)),
            title: const Text('心跳通信 (Heartbeat)'),
            subtitle: const Text('WebSocket 心跳测试 - 连接状态监控'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HeartbeatPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
