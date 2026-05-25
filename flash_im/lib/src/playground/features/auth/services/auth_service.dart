import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/login_response.dart';
import '../config/auth_config.dart';

class AuthService {
  final Dio _dio;
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'auth_user_id';

  AuthService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(
          baseUrl: AuthConfig.baseUrl,
          connectTimeout: const Duration(milliseconds: AuthConfig.connectTimeout),
          receiveTimeout: const Duration(milliseconds: AuthConfig.connectTimeout),
        ));

  Future<String?> sendSmsCode(String phone) async {
    try {
      final response = await _dio.post(
        AuthConfig.smsPath,
        data: {'phone': phone},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return data['code'] as String?;
        }
        throw Exception(data['message'] ?? '发送验证码失败');
      }
      throw Exception('请求失败: ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('发送验证码失败: $e');
    }
  }

  Future<LoginResponse> login(String phone, String code) async {
    try {
      final response = await _dio.post(
        AuthConfig.loginPath,
        data: {'phone': phone, 'code': code},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final loginResp = LoginResponse.fromJson(data);

        if (loginResp.success && loginResp.token != null) {
          await _saveToken(loginResp.token!, loginResp.userId);
        }

        return loginResp;
      }
      throw Exception('登录失败: ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('登录失败: $e');
    }
  }

  Future<LoginResponse> loginWithPassword(String phone, String password) async {
    try {
      final response = await _dio.post(
        AuthConfig.passwordLoginPath,
        data: {'phone': phone, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final loginResp = LoginResponse.fromJson(data);

        if (loginResp.success && loginResp.token != null) {
          await _saveToken(loginResp.token!, loginResp.userId);
        }

        return loginResp;
      }
      throw Exception('密码登录失败: ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('密码登录失败: $e');
    }
  }

  Future<UserProfile> getProfile() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('未登录，请先获取 Token');
    }

    try {
      final response = await _dio.get(
        AuthConfig.profilePath,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return UserProfile.fromJson(data);
        }
        throw Exception(data['message'] ?? '获取用户信息失败');
      }
      throw Exception('请求失败: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await clearToken();
        throw Exception('Token 已过期，请重新登录');
      }
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('获取用户信息失败: $e');
    }
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
  }

  Future<void> _saveToken(String token, int? userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (userId != null) {
      await prefs.setInt(_userIdKey, userId);
    }
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时';
      case DioExceptionType.receiveTimeout:
        return '响应超时';
      case DioExceptionType.connectionError:
        return '网络连接失败';
      default:
        return '请求失败: ${e.message}';
    }
  }

  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
    AuthConfig.updateBaseUrl(newBaseUrl);
  }
}
