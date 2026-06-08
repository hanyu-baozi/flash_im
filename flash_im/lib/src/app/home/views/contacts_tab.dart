import 'package:flutter/material.dart';

class ContactsTab extends StatelessWidget {
  const ContactsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '通讯录（敬请期待）',
        style: TextStyle(fontSize: 15, color: Color(0xFF999999)),
      ),
    );
  }
}