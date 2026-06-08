import 'package:shared_preferences/shared_preferences.dart';

import '../models/login_response.dart';
import '../models/user_profile.dart';
import '../services/auth_api_service.dart';

class AuthRepository {
  final AuthApiService _apiService;
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'auth_user_id';

  AuthRepository({AuthApiService? apiService})
      : _apiService = apiService ?? AuthApiService();

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveToken(String token, int? userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (userId != null) {
      await prefs.setInt(_userIdKey, userId);
    }
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
  }

  Future<String?> sendSms(String phone) async {
    return _apiService.sendSms(phone);
  }

  Future<LoginResponse> login(String phone, String code) async {
    final loginResp = await _apiService.login(phone, code);
    if (loginResp.success && loginResp.token != null) {
      await saveToken(loginResp.token!, loginResp.userId);
    }
    return loginResp;
  }

  Future<LoginResponse> loginWithPassword(
      String phone, String password) async {
    final loginResp = await _apiService.loginWithPassword(phone, password);
    if (loginResp.success && loginResp.token != null) {
      await saveToken(loginResp.token!, loginResp.userId);
    }
    return loginResp;
  }

  Future<UserProfile> getProfile() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('未登录');
    }
    return _apiService.getProfile(token);
  }

  Future<bool> setupPassword(String password) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('未登录');
    }
    return _apiService.setupPassword(password, token);
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('未登录');
    }
    return _apiService.changePassword(oldPassword, newPassword, token);
  }

  Future<bool> updateProfile({String? nickname, String? avatar, String? signature}) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('未登录');
    }
    return _apiService.updateProfile(
        nickname: nickname, avatar: avatar, signature: signature, token: token);
  }
}