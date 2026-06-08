import 'package:flutter/material.dart';

import '../repositories/auth_repository.dart';

class PasswordDialog extends StatefulWidget {
  final VoidCallback onSetupSuccess;
  final VoidCallback onSkip;

  const PasswordDialog({
    super.key,
    required this.onSetupSuccess,
    required this.onSkip,
  });

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _repo = AuthRepository();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('设置密码'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '检测到您尚未设置密码，建议立即设置以便后续使用密码登录。',
            style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: '密码',
              hintText: '请输入密码（至少6位）',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: '确认密码',
              hintText: '请再次输入密码',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off
                      : Icons.visibility,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.of(context).pop();
                  widget.onSkip();
                },
          child: const Text('暂不设置'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSetup,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('确认'),
        ),
      ],
    );
  }

  Future<void> _handleSetup() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password != confirm) {
      _showSnackBar('两次密码不一致');
      return;
    }
    if (password.length < 6) {
      _showSnackBar('密码至少6位');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _repo.setupPassword(password);
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSetupSuccess();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString());
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}