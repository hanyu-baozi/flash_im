import 'package:flutter/material.dart';

/// 顶部搜索栏（仿微信样式）
class ConversationSearchBar extends StatelessWidget {
  const ConversationSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 18, color: Color(0xFF999999)),
          SizedBox(width: 4),
          Text(
            '搜索',
            style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
          ),
        ],
      ),
    );
  }
}
