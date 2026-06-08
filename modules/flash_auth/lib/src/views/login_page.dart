import 'dart:async';

import 'package:flutter/material.dart';

import '../models/login_response.dart';
import '../repositories/auth_repository.dart';
import 'password_dialog.dart';

class _SmsMode {
  final codeCtrl = TextEditingController();
  String? displayCode;
  int countdown = 0;
  Timer? timer;

  bool canLogin(String phone) =>
      phone.length == 11 && codeCtrl.text.length >= 4;

  Future<String?> sendCode(String phone, AuthRepository repo) async {
    final code = await repo.sendSms(phone);
    displayCode = code;
    return code;
  }

  void startCountdown(void Function() onTick) {
    countdown = 60;
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      countdown--;
      onTick();
      if (countdown == 0) {
        t.cancel();
      }
    });
  }

  Future<LoginResponse> login(String phone, AuthRepository repo) async {
    return repo.login(phone, codeCtrl.text);
  }

  void dispose() {
    codeCtrl.dispose();
    timer?.cancel();
  }
}

class _PasswordMode {
  final pwdCtrl = TextEditingController();

  bool canLogin(String phone) =>
      phone.length == 11 && pwdCtrl.text.length >= 6;

  Future<LoginResponse> login(String phone, AuthRepository repo) async {
    return repo.loginWithPassword(phone, pwdCtrl.text);
  }

  void dispose() {
    pwdCtrl.dispose();
  }
}

mixin LoginLogic on State<LoginPage> {
  final phoneCtrl = TextEditingController();
  final _repo = AuthRepository();

  var _isLoading = false;
  String? _error;
  var _isPasswordMode = false;

  final _sms = _SmsMode();
  final _pwd = _PasswordMode();

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPasswordMode => _isPasswordMode;

  String? get displayCode => _isPasswordMode ? null : _sms.displayCode;
  int get countdown => _isPasswordMode ? 0 : _sms.countdown;
  bool get canSendCode =>
      !_isPasswordMode && _sms.countdown == 0 && phoneCtrl.text.length == 11;

  TextEditingController get inputCtrl =>
      _isPasswordMode ? _pwd.pwdCtrl : _sms.codeCtrl;

  bool get canLogin {
    if (_isPasswordMode) return _pwd.canLogin(phoneCtrl.text);
    return _sms.canLogin(phoneCtrl.text);
  }

  void toggleMode() {
    setState(() {
      _isPasswordMode = !_isPasswordMode;
      _error = null;
    });
  }

  void clearError() => setState(() => _error = null);

  Future<void> sendCode() async {
    if (_isPasswordMode) return;
    setState(() => _isLoading = true);
    try {
      await _sms.sendCode(phoneCtrl.text, _repo);
      _sms.startCountdown(() {
        if (mounted) setState(() {});
      });
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  LoginResponse? _lastLoginResp;

  Future<bool> login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (_isPasswordMode) {
        _lastLoginResp = await _pwd.login(phoneCtrl.text, _repo);
      } else {
        _lastLoginResp = await _sms.login(phoneCtrl.text, _repo);
      }
      if (!_lastLoginResp!.success) {
        setState(() {
          _error = _lastLoginResp!.message ?? '登录失败';
          _isLoading = false;
        });
        return false;
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      return false;
    }
    setState(() => _isLoading = false);
    return true;
  }

  void disposeAll() {
    phoneCtrl.dispose();
    _sms.dispose();
    _pwd.dispose();
  }
}

class LoginPage extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginPage({super.key, this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with LoginLogic {
  @override
  void initState() {
    super.initState();
    phoneCtrl.addListener(_onInputChanged);
    _sms.codeCtrl.addListener(_onInputChanged);
    _pwd.pwdCtrl.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    phoneCtrl.removeListener(_onInputChanged);
    _sms.codeCtrl.removeListener(_onInputChanged);
    _pwd.pwdCtrl.removeListener(_onInputChanged);
    disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Stack(
          children: [
            _buildBody(),
            if (isLoading)
              Container(
                color: Colors.black12,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
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
            if (isPasswordMode) _buildPasswordInput() else _buildCodeInput(),
            const SizedBox(height: 12),
            if (!isPasswordMode && displayCode != null) _buildCodeHint(),
            const SizedBox(height: 32),
            _buildLoginButton(),
            const SizedBox(height: 24),
            _buildModeSwitch(),
            if (error != null) ...[
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
        Text(
          isPasswordMode ? '使用手机号和密码登录' : '使用手机号和验证码登录',
          style: const TextStyle(
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
      controller: phoneCtrl,
      label: '手机号',
      hint: '请输入手机号',
      icon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      maxLength: 11,
    );
  }

  Widget _buildCodeInput() {
    return _InputField(
      controller: inputCtrl,
      label: '验证码',
      hint: '请输入验证码',
      icon: Icons.lock_outline,
      keyboardType: TextInputType.number,
      maxLength: 6,
      action: _buildSendCodeButton(),
    );
  }

  Widget _buildSendCodeButton() {
    return GestureDetector(
      onTap: canSendCode ? () => sendCode() : null,
      child: Text(
        countdown > 0 ? '${countdown}s' : '获取验证码',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: canSendCode
              ? const Color(0xFF4F46E5)
              : const Color(0xFFCCCCCC),
        ),
      ),
    );
  }

  Widget _buildPasswordInput() {
    return _InputField(
      controller: inputCtrl,
      label: '密码',
      hint: '请输入密码',
      icon: Icons.lock_outline,
      keyboardType: TextInputType.visiblePassword,
      maxLength: 20,
      obscureText: true,
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
            '测试验证码: $displayCode',
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
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: canLogin ? _handleLogin : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              canLogin ? const Color(0xFF4F46E5) : const Color(0xFFE5E7EB),
          foregroundColor:
              canLogin ? Colors.white : const Color(0xFF9CA3AF),
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

  Widget _buildModeSwitch() {
    return Center(
      child: GestureDetector(
        onTap: () => toggleMode(),
        child: Text(
          isPasswordMode ? '验证码登录' : '密码登录',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF4F46E5),
            decoration: TextDecoration.underline,
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
              error!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFDC2626),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => clearError(),
            child:
                const Icon(Icons.close, size: 16, color: Color(0xFFEF4444)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    final success = await login();
    if (!mounted || !success) return;
    _onLoginSuccess();
  }

  void _onLoginSuccess() {
    if (_lastLoginResp?.hasPassword == true) {
      _navigateToMain();
    } else {
      _showPasswordDialog();
    }
  }

  void _showPasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PasswordDialog(
        onSetupSuccess: () => _navigateToMain(),
        onSkip: () => _navigateToMain(),
      ),
    );
  }

  void _navigateToMain() {
    widget.onLoginSuccess?.call();
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
  final bool obscureText;

  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.keyboardType,
    required this.maxLength,
    this.action,
    this.obscureText = false,
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
            obscureText: obscureText,
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
              prefixIcon:
                  Icon(icon, color: const Color(0xFF4F46E5), size: 20),
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