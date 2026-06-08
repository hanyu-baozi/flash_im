import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/login_response.dart';
import '../models/user_profile.dart';

class AuthApiService {
  static void Function()? onUnauthorized;

  final Dio _dio;

  AuthApiService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout:
              const Duration(milliseconds: ApiConfig.connectTimeout),
          receiveTimeout:
              const Duration(milliseconds: ApiConfig.connectTimeout),
        )) {
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          onUnauthorized?.call();
        }
        handler.next(error);
      },
    ));
  }

  Future<String?> sendSms(String phone) async {
    try {
      final response = await _dio.post(
        ApiConfig.smsPath,
        data: {'phone': phone},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return data['code'] as String?;
        }
        throw Exception(data['message'] ?? '发送验证码失败');
      }
      throw Exception('发送验证码失败: ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('发送验证码失败: $e');
    }
  }

  Future<LoginResponse> login(String phone, String code) async {
    try {
      final response = await _dio.post(
        ApiConfig.loginPath,
        data: {'phone': phone, 'code': code},
      );

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('登录失败: ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('登录失败: $e');
    }
  }

  Future<LoginResponse> loginWithPassword(
      String phone, String password) async {
    try {
      final response = await _dio.post(
        ApiConfig.passwordLoginPath,
        data: {'phone': phone, 'password': password},
      );

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('密码登录失败: ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('密码登录失败: $e');
    }
  }

  Future<UserProfile> getProfile(String token) async {
    try {
      final response = await _dio.get(
        ApiConfig.profilePath,
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
      throw Exception('获取用户信息失败: ${response.statusCode}');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Token 已过期，请重新登录');
      }
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('获取用户信息失败: $e');
    }
  }

  Future<bool> setupPassword(String password, String token) async {
    try {
      final response = await _dio.post(
        ApiConfig.passwordSetupPath,
        data: {'password': password},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return true;
        }
        throw Exception(data['message'] ?? '设置密码失败');
      }
      throw Exception('设置密码失败: ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('设置密码失败: $e');
    }
  }

  Future<bool> changePassword(
      String oldPassword, String newPassword, String token) async {
    try {
      final response = await _dio.post(
        ApiConfig.changePasswordPath,
        data: {'old_password': oldPassword, 'new_password': newPassword},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return true;
        }
        throw Exception(data['message'] ?? '修改密码失败');
      }
      throw Exception('修改密码失败: ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('修改密码失败: $e');
    }
  }

  Future<bool> updateProfile({
    String? nickname,
    String? avatar,
    String? signature,
    required String token,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (nickname != null) body['nickname'] = nickname;
      if (avatar != null) body['avatar'] = avatar;
      if (signature != null) body['signature'] = signature;

      final response = await _dio.put(
        ApiConfig.updateProfilePath,
        data: body,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return true;
        }
        throw Exception(data['message'] ?? '更新资料失败');
      }
      throw Exception('更新资料失败: ${response.statusCode}');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('更新资料失败: $e');
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
}