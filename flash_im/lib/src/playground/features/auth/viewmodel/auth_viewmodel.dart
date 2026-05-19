import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../config/auth_config.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _service;

  String _phone = '';
  String _code = '';
  bool _isLoading = false;
  String? _errorMessage;
  int _countdown = 0;
  bool _codeSent = false;
  String? _displayCode;
  UserProfile? _profile;
  bool _isLoggedIn = false;

  Timer? _countdownTimer;

  AuthViewModel({AuthService? service})
      : _service = service ?? AuthService();

  String get phone => _phone;
  String get code => _code;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get countdown => _countdown;
  bool get canSendCode => _countdown == 0 && _phone.length == 11;
  bool get codeSent => _codeSent;
  String? get displayCode => _displayCode;
  UserProfile? get profile => _profile;
  bool get isLoggedIn => _isLoggedIn;
  bool get canLogin => _phone.length == 11 && _code.length == 6 && !_isLoading;

  void setPhone(String value) {
    _phone = value;
    _errorMessage = null;
    notifyListeners();
  }

  void setCode(String value) {
    _code = value;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> sendCode() async {
    if (!canSendCode) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final code = await _service.sendSmsCode(_phone);
      _codeSent = true;
      _displayCode = code;
      _startCountdown();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login() async {
    if (!canLogin) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _service.login(_phone, _code);
      if (response.success) {
        _isLoggedIn = true;
        try {
          await loadProfile();
        } catch (_) {}
      } else {
        _errorMessage = response.message ?? '登录失败';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _service.getProfile();
      _isLoggedIn = true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoggedIn = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _service.clearToken();
    _profile = null;
    _isLoggedIn = false;
    _phone = '';
    _code = '';
    _codeSent = false;
    _displayCode = null;
    _countdown = 0;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    notifyListeners();
  }

  Future<void> checkLoginStatus() async {
    _isLoggedIn = await _service.isLoggedIn();
    if (_isLoggedIn) {
      await loadProfile();
    }
    notifyListeners();
  }

  void _startCountdown() {
    _countdown = AuthConfig.countdownSeconds;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown <= 0) {
        timer.cancel();
        _countdown = 0;
      } else {
        _countdown--;
      }
      notifyListeners();
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
