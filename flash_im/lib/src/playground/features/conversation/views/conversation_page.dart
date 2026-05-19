import 'package:flutter/material.dart';
import '../viewmodel/conversation_viewmodel.dart';
import '../widgets/conversation_list_item.dart';
import '../widgets/conversation_search_bar.dart';

class ConversationPage extends StatefulWidget {
  const ConversationPage({super.key});

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  late ConversationViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = ConversationViewModel();
    _viewModel.loadConversations();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          const ConversationSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFEDEDED),
      elevation: 0,
      centerTitle: true,
      title: const Text(
        '微信',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1A),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Color(0xFF1A1A1A)),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF1A1A1A)),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildBody() {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_viewModel.hasError) {
          return _ErrorView(
            message: _viewModel.errorMessage!,
            onRetry: () => _viewModel.loadConversations(),
          );
        }

        if (!_viewModel.hasData) {
          return const _EmptyView();
        }

        return RefreshIndicator(
          onRefresh: _viewModel.refreshConversations,
          child: ListView.separated(
            itemCount: _viewModel.conversations.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              indent: 76,
              color: Color(0xFFE5E5E5),
            ),
            itemBuilder: (context, index) {
              return ConversationListItem(
                item: _viewModel.conversations[index],
                onTap: () {},
              );
            },
          ),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: Color(0xFF999999)),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '暂无会话',
        style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
      ),
    );
  }
}
