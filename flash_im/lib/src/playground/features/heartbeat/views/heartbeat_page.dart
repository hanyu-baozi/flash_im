import 'package:flutter/material.dart';
import '../viewmodel/heartbeat_viewmodel.dart';
import '../models/connection_state.dart';
import '../viewmodel/heartbeat_viewmodel.dart' show MessageRecord, MessageType;

/// 心跳通信测试页面
class HeartbeatPage extends StatefulWidget {
  const HeartbeatPage({super.key});

  @override
  State<HeartbeatPage> createState() => _HeartbeatPageState();
}

class _HeartbeatPageState extends State<HeartbeatPage> {
  late HeartbeatViewModel _viewModel;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = HeartbeatViewModel();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('心跳通信测试'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _viewModel.clearLogs(),
            tooltip: '清空日志',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return Column(
            children: [
              _buildStatusCard(),
              _buildControlButtons(),
              _buildMessageSection(),
              const Divider(height: 1),
              Expanded(child: _buildLogList()),
            ],
          );
        },
      ),
    );
  }

  /// 构建状态卡片
  Widget _buildStatusCard() {
    final state = _viewModel.connectionState;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatusIndicator(state),
          const SizedBox(height: 16),
          _buildStatusDetails(state),
        ],
      ),
    );
  }

  /// 构建状态指示器
  Widget _buildStatusIndicator(HeartbeatConnectionState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Color(state.statusColor),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(state.statusColor).withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          state.statusText,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(state.statusColor),
          ),
        ),
      ],
    );
  }

  /// 构建状态详情
  Widget _buildStatusDetails(HeartbeatConnectionState state) {
    return Column(
      children: [
        _buildDetailRow('服务器地址', state.serverAddress ?? '未设置'),
        if (state.latency != null)
          _buildDetailRow('延迟', '${state.latency}ms'),
        if (state.lastHeartbeatTime != null)
          _buildDetailRow('最后心跳', _formatTime(state.lastHeartbeatTime!)),
        if (state.errorMessage != null)
          _buildDetailRow('错误信息', state.errorMessage!, isError: true),
      ],
    );
  }

  /// 构建详情行
  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: isError ? const Color(0xFFF44336) : const Color(0xFF333333),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建控制按钮
  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _viewModel.sendHeartbeat(),
              icon: const Icon(Icons.favorite, size: 20),
              label: const Text('发送心跳'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _viewModel.isAutoHeartbeat
                ? ElevatedButton.icon(
                    onPressed: () => _viewModel.stopAutoHeartbeat(),
                    icon: const Icon(Icons.stop, size: 20),
                    label: const Text('停止自动'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFFF44336),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: () => _viewModel.startAutoHeartbeat(),
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: const Text('开始自动'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF4CAF50),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// 构建消息区域
  Widget _buildMessageSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 消息标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '消息通信',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_viewModel.messageHistory.isNotEmpty)
                  TextButton(
                    onPressed: () => _viewModel.clearMessages(),
                    child: const Text('清空'),
                  ),
              ],
            ),
          ),

          // 消息列表
          if (_viewModel.messageHistory.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  '暂无消息记录',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: _viewModel.messageHistory.length,
                itemBuilder: (context, index) {
                  final message = _viewModel.messageHistory[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),

          // 输入框和发送按钮
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '输入消息...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (value) => _handleSendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _handleSendMessage,
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 处理发送消息
  void _handleSendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      _viewModel.sendMessage(message);
      _messageController.clear();
    }
  }

  /// 构建消息气泡
  Widget _buildMessageBubble(MessageRecord message) {
    final isSent = message.type == MessageType.sent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSent
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isSent ? 12 : 4),
                  bottomRight: Radius.circular(isSent ? 4 : 12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSent
                          ? Theme.of(context).primaryColor
                          : Colors.black87,
                    ),
                  ),
                  if (message.latency != null || !isSent)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        isSent
                            ? '${message.formattedTime}'
                            : '${message.formattedTime} · ${message.latency}ms',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建日志列表
  Widget _buildLogList() {
    if (_viewModel.logs.isEmpty) {
      return const Center(
        child: Text(
          '暂无日志',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF999999),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _viewModel.logs.length,
      itemBuilder: (context, index) {
        final log = _viewModel.logs[index];
        return _buildLogItem(log);
      },
    );
  }

  /// 构建日志项
  Widget _buildLogItem(HeartbeatLog log) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[${log.formattedTime}]',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF999999),
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              log.message,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}
