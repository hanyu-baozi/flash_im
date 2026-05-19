import 'package:flutter/material.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'auth_profile_page.dart';

class AuthLoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const AuthLoginPage({super.key, this.onLoginSuccess});

  @override
  State<AuthLoginPage> createState() => _AuthLoginPageState();
}

class _AuthLoginPageState extends State<AuthLoginPage> {
  late AuthViewModel _viewModel;
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = AuthViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            return Stack(
              children: [
                _buildBody(),
                if (_viewModel.isLoading)
                  Container(
                    color: Colors.black12,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 60, 32, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 48),
            _buildPhoneInput(),
            const SizedBox(height: 16),
            _buildCodeInput(),
            const SizedBox(height: 12),
            if (_viewModel.displayCode != null)
              _buildCodeHint(),
            const SizedBox(height: 32),
            _buildLoginButton(),
            if (_viewModel.errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorHint(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '欢迎登录',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '使用手机号和验证码登录',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF999999),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInput() {
    return _InputField(
      controller: _phoneController,
      label: '手机号',
      hint: '请输入手机号',
      icon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      maxLength: 11,
      onChanged: (value) => _viewModel.setPhone(value),
    );
  }

  Widget _buildCodeInput() {
    return _InputField(
      controller: _codeController,
      label: '验证码',
      hint: '请输入验证码',
      icon: Icons.lock_outline,
      keyboardType: TextInputType.number,
      maxLength: 6,
      onChanged: (value) => _viewModel.setCode(value),
      action: _buildSendCodeButton(),
    );
  }

  Widget _buildSendCodeButton() {
    final canSend = _viewModel.canSendCode;
    final countdown = _viewModel.countdown;

    return GestureDetector(
      onTap: canSend ? () => _viewModel.sendCode() : null,
      child: Text(
        countdown > 0 ? '${countdown}s' : '获取验证码',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: canSend
              ? const Color(0xFF4F46E5)
              : const Color(0xFFCCCCCC),
        ),
      ),
    );
  }

  Widget _buildCodeHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFF22C55E)),
          const SizedBox(width: 8),
          Text(
            '测试验证码: ${_viewModel.displayCode}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF16A34A),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    final canLogin = _viewModel.canLogin;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: canLogin ? _handleLogin : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canLogin
              ? const Color(0xFF4F46E5)
              : const Color(0xFFE5E7EB),
          foregroundColor: canLogin ? Colors.white : const Color(0xFF9CA3AF),
          elevation: canLogin ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          '登 录',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: Color(0xFFEF4444)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _viewModel.errorMessage!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFDC2626),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _viewModel.clearError(),
            child: const Icon(Icons.close, size: 16, color: Color(0xFFEF4444)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    await _viewModel.login();
    if (mounted && _viewModel.isLoggedIn) {
      if (widget.onLoginSuccess != null) {
        widget.onLoginSuccess!();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthProfilePage()),
        );
      }
    }
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final int maxLength;
  final Widget? action;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.keyboardType,
    required this.maxLength,
    this.action,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLength: maxLength,
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1A1A1A),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 15,
                color: Color(0xFFCCCCCC),
              ),
              prefixIcon: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
              suffixIcon: action != null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: action,
                    )
                  : null,
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
