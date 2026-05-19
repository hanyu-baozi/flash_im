import 'package:flutter/material.dart';
import '../viewmodel/chat_room_viewmodel.dart';
import '../models/chat_room_state.dart';

class ProfileView extends StatelessWidget {
  final ChatRoomViewModel viewModel;

  const ProfileView({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final state = viewModel.state;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          _buildHeader(state),
          SliverToBoxAdapter(child: _buildBody(context, state)),
        ],
      ),
    );
  }

  Widget _buildHeader(ChatRoomState state) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF07C160),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF07C160), const Color(0xFF06AD56)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  backgroundImage: state.avatar != null ? NetworkImage(state.avatar as String) : null,
                  child: state.avatar == null
                      ? Text(
                          (state.nickname ?? '?').substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.w500),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  state.nickname ?? '未登录',
                  style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: state.isConnected ? Colors.lightGreenAccent[100] : Colors.grey[300]),
                      const SizedBox(width: 4),
                      Text(
                        state.isConnected ? '已连接' : '未连接',
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ChatRoomState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SectionCard(
            title: '账号信息',
            children: [
              _InfoRow(label: '用户 ID', value: state.userId?.toString() ?? '-'),
              _InfoRow(label: '昵称', value: state.nickname ?? '-'),
              _InfoRow(label: '在线人数', value: '${state.onlineCount} 人'),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: '连接状态',
            children: [
              _StatusRow(label: '连接状态', status: state.status.name, isConnected: state.isConnected),
              if (state.lastHeartbeatTime != null)
                _InfoRow(label: '最近心跳', value: _formatTime(state.lastHeartbeatTime)),
              if (state.errorMessage != null && !state.isConnected)
                _ErrorRow(message: state.errorMessage ?? ''),
            ],
          ),
          const SizedBox(height: 16),
          _ActionCard(
            title: '操作',
            actions: [
              _ActionItem(
                icon: Icons.refresh_rounded,
                label: state.isConnected ? '重连' : '连接',
                color: const Color(0xFF07C160),
                onTap: () => viewModel.connect(),
              ),
              if (state.isConnected)
                _ActionItem(
                  icon: Icons.power_settings_new_rounded,
                  label: '断开',
                  color: const Color(0xFFEF4444),
                  onTap: () => viewModel.disconnect(),
                ),
              _ActionItem(
                icon: Icons.cleaning_services_rounded,
                label: '清空消息',
                color: const Color(0xFFFF9800),
                onTap: () => viewModel.clearMessages(),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '-';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8), child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF999999)))),
        ...children,
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(children: [
        Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF666666))),
        const Spacer(),
        Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)))),
      ]),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String status;
  final bool isConnected;

  const _StatusRow({required this.label, required this.status, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(children: [
        Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF666666))),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: isConnected ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(8)),
          child: Text(status == 'authenticated' ? '已认证' : status == 'connecting' || status == 'authenticating' ? '连接中' : '未连接', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isConnected ? const Color(0xFF2E7D32) : const Color(0xFFC62828))),
        ),
      ]),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  final String message;

  const _ErrorRow({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFFE0B2))),
      child: Row(children: [Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange[700]), const SizedBox(width: 8), Expanded(child: Text(message, style: TextStyle(fontSize: 13, color: Colors.orange[800])))]),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final List<Widget> actions;

  const _ActionCard({required this.title, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
      ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8), child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF999999)))),
        ...actions,
      ]),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: Icon(icon, size: 20, color: color)), const SizedBox(width: 12), Text(label, style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A))), const Spacer(), Icon(Icons.chevron_right, size: 20, color: Colors.grey[400])]),
      ),
    );
  }
}
