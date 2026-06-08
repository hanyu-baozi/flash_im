import 'package:flutter/material.dart';

class MessagesTab extends StatelessWidget {
  const MessagesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '消息（敬请期待）',
        style: TextStyle(fontSize: 15, color: Color(0xFF999999)),
      ),
    );
  }
}