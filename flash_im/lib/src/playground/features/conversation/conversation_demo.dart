import 'package:flutter/material.dart';
import 'models/conversation_item.dart';
import 'services/conversation_service.dart';
import 'config/api_config.dart';

/// Conversation 功能演示页面
class ConversationDemo extends StatefulWidget {
  const ConversationDemo({super.key});

  @override
  State<ConversationDemo> createState() => _ConversationDemoState();
}

class _ConversationDemoState extends State<ConversationDemo> {
  final ConversationService _service = ConversationService();
  List<ConversationItem> _conversations = [];
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _urlController.text = ApiConfig.baseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  /// 加载会话列表
  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final conversations = await _service.getConversationList();
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// 更新 API 地址
  void _updateApiUrl() {
    final newUrl = _urlController.text.trim();
    if (newUrl.isNotEmpty) {
      _service.updateBaseUrl(newUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API 地址已更新为: $newUrl')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation Demo'),
        backgroundColor: Colors.amber,
      ),
      body: Column(
        children: [
          // API 配置区域
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'API 配置',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: '基础 URL',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _updateApiUrl,
                      child: const Text('更新'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // 操作按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _loadConversations,
                icon: const Icon(Icons.refresh),
                label: const Text('获取会话列表'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // 内容区域
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '加载失败',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      );
    }

    if (_conversations.isEmpty) {
      return const Center(
        child: Text('点击上方按钮获取会话列表'),
      );
    }

    return ListView.separated(
      itemCount: _conversations.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.amber,
            child: Text(
              conversation.title.isNotEmpty ? conversation.title[0] : '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(
            conversation.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            conversation.lastMsg,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            conversation.time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        );
      },
    );
  }
}
