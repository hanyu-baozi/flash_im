import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditSignaturePage extends StatefulWidget {
  final String signature;

  const EditSignaturePage({super.key, required this.signature});

  @override
  State<EditSignaturePage> createState() => _EditSignaturePageState();
}

class _EditSignaturePageState extends State<EditSignaturePage> {
  late final TextEditingController _ctrl;
  static const int maxLength = 100;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.signature);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('修改签名'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        actions: [
          TextButton(
            onPressed: _handleSave,
            child: const Text(
              '完成',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF4F46E5),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _ctrl,
              autofocus: true,
              maxLines: 3,
              minLines: 1,
              maxLength: maxLength,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              decoration: const InputDecoration(
                hintText: '写点什么吧...',
                border: InputBorder.none,
                counterText: '',
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF191919),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_ctrl.text.length}/$maxLength',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSave() {
    final signature = _ctrl.text.trim();
    Navigator.pop(context, signature.isEmpty ? null : signature);
  }
}
