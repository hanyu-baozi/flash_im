import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flash_im/src/playground/features/auth/services/auth_service.dart';
import 'package:flash_im/src/playground/features/auth/models/login_type.dart';
import 'package:flash_im/src/playground/features/auth/config/auth_config.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AuthService 接口请求测试
/// 使用 Dio 拦截器模拟后端响应，确保测试稳定性和隔离性
/// 运行命令：flutter test test/playground/auth/auth_service_test.dart
void main() {
  late AuthService service;
  late Dio mockDio;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    AuthConfig.updateBaseUrl('http://127.0.0.1:3000');
    mockDio = Dio(BaseOptions(
      baseUrl: AuthConfig.baseUrl,
      connectTimeout: const Duration(milliseconds: AuthConfig.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AuthConfig.connectTimeout),
    ));

    mockDio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (options.path == '/auth/sms' && options.method == 'POST') {
          final phone = options.data['phone'] as String;
          if (phone.isEmpty) {
            handler.reject(DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 400,
                data: {'success': false, 'message': '手机号不能为空'},
              ),
            ));
          } else {
            handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {'success': true, 'message': '验证码已发送', 'code': '123456'},
            ));
          }
        } else if (options.path == '/auth/login' && options.method == 'POST') {
          final phone = options.data['phone'] as String;
          final code = options.data['code'] as String;
          if (code == '123456') {
            handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'login_type': 'sms',
                'token': 'mock_jwt_token_for_$phone',
                'user_id': 42,
                'nickname': phone,
                'avatar': 'https://api.dicebear.com/7.x/identicon/png?seed=$phone',
              },
            ));
          } else {
            handler.reject(DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 401,
                data: {'success': false, 'login_type': 'sms', 'message': '验证码错误或已过期'},
              ),
            ));
          }
        } else if (options.path == '/auth/login/password' && options.method == 'POST') {
          final phone = options.data['phone'] as String;
          final password = options.data['password'] as String;
          if (phone == '13800000001' && password == '123456') {
            handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'login_type': 'password',
                'token': 'mock_jwt_token_for_$phone',
                'user_id': 1,
                'nickname': 'Alice',
                'avatar': 'https://api.dicebear.com/7.x/identicon/png?seed=alice',
              },
            ));
          } else if (phone == '13800000001') {
            handler.reject(DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 401,
                data: {'success': false, 'login_type': 'password', 'message': '密码错误'},
              ),
            ));
          } else {
            handler.reject(DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 401,
                data: {'success': false, 'login_type': 'password', 'message': '用户不存在'},
              ),
            ));
          }
        } else if (options.path == '/user/profile' && options.method == 'GET') {
          final authHeader = options.headers['Authorization'] as String?;
          if (authHeader == null || !authHeader.startsWith('Bearer ')) {
            handler.reject(DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 401,
                data: {'success': false, 'message': 'Token 缺失'},
              ),
            ));
          } else {
            handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'user_id': 42,
                'nickname': 'mock_user',
                'avatar': 'https://example.com/avatar.png',
                'phone': '13800000001',
              },
            ));
          }
        } else {
          handler.next(options);
        }
      },
    ));

    service = AuthService(dio: mockDio);
  });

  group('POST /auth/sms Tests', () {
    test('should return 6-digit verification code for valid phone', () async {
      final code = await service.sendSmsCode('13800000001');

      expect(code, isNotNull);
      expect(code!.length, 6);
      expect(code, '123456');
    });

    test('should throw exception for empty phone', () async {
      try {
        await service.sendSmsCode('');
        fail('Expected an exception');
      } catch (e) {
        expect(e.toString(), anyOf(
          contains('手机号不能为空'),
          contains('发送验证码失败'),
          contains('请求失败'),
        ));
      }
    });
  });

  group('POST /auth/login Tests', () {
    test('should login successfully with correct code', () async {
      final response = await service.login('13800000001', '123456');

      expect(response.success, true);
      expect(response.loginType, LoginType.sms);
      expect(response.token, 'mock_jwt_token_for_13800000001');
      expect(response.userId, 42);
      expect(response.nickname, '13800000001');
      expect(response.message, isNull);
    });

    test('should fail with wrong code', () async {
      try {
        await service.login('13800000001', '000000');
        fail('Expected an exception');
      } catch (e) {
        expect(e.toString(), anyOf(
          contains('验证码错误'),
          contains('登录失败'),
          contains('请求失败'),
        ));
      }
    });

    test('should fail with empty code', () async {
      try {
        await service.login('13800000001', '');
        fail('Expected an exception');
      } catch (e) {
        expect(e.toString(), anyOf(
          contains('登录失败'),
          contains('请求失败'),
        ));
      }
    });

    test('should save token after successful login', () async {
      await service.login('13800000001', '123456');

      final token = await service.getToken();
      final userId = await service.getUserId();

      expect(token, 'mock_jwt_token_for_13800000001');
      expect(userId, 42);
    });
  });

  group('POST /auth/login/password Tests', () {
    test('should login successfully with correct password', () async {
      final response = await service.loginWithPassword('13800000001', '123456');

      expect(response.success, true);
      expect(response.loginType, LoginType.password);
      expect(response.token, 'mock_jwt_token_for_13800000001');
      expect(response.userId, 1);
      expect(response.nickname, 'Alice');
      expect(response.avatar, 'https://api.dicebear.com/7.x/identicon/png?seed=alice');
      expect(response.message, isNull);
    });

    test('should fail with wrong password', () async {
      try {
        await service.loginWithPassword('13800000001', 'wrong');
        fail('Expected an exception');
      } catch (e) {
        expect(e.toString(), anyOf(
          contains('密码错误'),
          contains('密码登录失败'),
          contains('请求失败'),
        ));
      }
    });

    test('should fail with non-existent user', () async {
      try {
        await service.loginWithPassword('13900000000', '123456');
        fail('Expected an exception');
      } catch (e) {
        expect(e.toString(), anyOf(
          contains('用户不存在'),
          contains('密码登录失败'),
          contains('请求失败'),
        ));
      }
    });

    test('should fail with empty password', () async {
      try {
        await service.loginWithPassword('13800000001', '');
        fail('Expected an exception');
      } catch (e) {
        expect(e.toString(), anyOf(
          contains('密码登录失败'),
          contains('请求失败'),
        ));
      }
    });

    test('should save token after successful password login', () async {
      await service.loginWithPassword('13800000001', '123456');

      final token = await service.getToken();
      final userId = await service.getUserId();

      expect(token, 'mock_jwt_token_for_13800000001');
      expect(userId, 1);
    });
  });

  group('GET /user/profile Tests', () {
    test('should return user profile with valid token', () async {
      await service.login('13800000001', '123456');

      final profile = await service.getProfile();

      expect(profile.userId, 42);
      expect(profile.nickname, 'mock_user');
      expect(profile.avatar, 'https://example.com/avatar.png');
      expect(profile.phone, '13800000001');
    });

    test('should return user profile after password login', () async {
      await service.loginWithPassword('13800000001', '123456');

      final profile = await service.getProfile();

      expect(profile.userId, 42);
      expect(profile.nickname, 'mock_user');
      expect(profile.phone, '13800000001');
    });

    test('should throw exception without token', () async {
      await service.clearToken();

      try {
        await service.getProfile();
        fail('Expected an exception');
      } catch (e) {
        expect(e, isA<Exception>());
        expect(e.toString(), contains('未登录'));
      }
    });
  });

  group('Token Management Tests', () {
    test('isLoggedIn should return false when no token', () async {
      await service.clearToken();

      final loggedIn = await service.isLoggedIn();

      expect(loggedIn, false);
    });

    test('isLoggedIn should return true after SMS login', () async {
      await service.login('13800000001', '123456');

      final loggedIn = await service.isLoggedIn();

      expect(loggedIn, true);
    });

    test('isLoggedIn should return true after password login', () async {
      await service.loginWithPassword('13800000001', '123456');

      final loggedIn = await service.isLoggedIn();

      expect(loggedIn, true);
    });

    test('clearToken should remove token and userId', () async {
      await service.login('13800000001', '123456');

      expect(await service.getToken(), isNotNull);
      expect(await service.getUserId(), isNotNull);

      await service.clearToken();

      expect(await service.getToken(), isNull);
      expect(await service.getUserId(), isNull);
      expect(await service.isLoggedIn(), false);
    });

    test('clearToken should clear password login token', () async {
      await service.loginWithPassword('13800000001', '123456');

      expect(await service.getToken(), isNotNull);

      await service.clearToken();

      expect(await service.getToken(), isNull);
      expect(await service.isLoggedIn(), false);
    });
  });

  group('Network Error Handling Tests', () {
    test('should handle connection error gracefully', () async {
      AuthConfig.updateBaseUrl('http://127.0.0.1:9999');
      final badDio = Dio(BaseOptions(
        baseUrl: AuthConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: 100),
        receiveTimeout: const Duration(milliseconds: 100),
      ));
      final badService = AuthService(dio: badDio);

      try {
        await badService.sendSmsCode('13800000001');
        fail('Expected an exception');
      } catch (e) {
        expect(e.toString(), anyOf(
          contains('网络连接失败'),
          contains('连接超时'),
          contains('请求失败'),
        ));
      }
    });

    test('should handle network error for password login', () async {
      AuthConfig.updateBaseUrl('http://127.0.0.1:9999');
      final badDio = Dio(BaseOptions(
        baseUrl: AuthConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: 100),
        receiveTimeout: const Duration(milliseconds: 100),
      ));
      final badService = AuthService(dio: badDio);

      try {
        await badService.loginWithPassword('13800000001', '123456');
        fail('Expected an exception');
      } catch (e) {
        expect(e.toString(), anyOf(
          contains('网络连接失败'),
          contains('连接超时'),
          contains('请求失败'),
        ));
      }
    });

    test('should handle 401 token expired in getProfile', () async {
      final expiredDio = Dio(BaseOptions(
        baseUrl: AuthConfig.baseUrl,
      ));
      expiredDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/auth/login' && options.method == 'POST') {
            handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'token': 'mock_jwt_token',
                'user_id': 42,
              },
            ));
          } else if (options.path == '/user/profile') {
            handler.reject(DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 401,
                data: {'success': false, 'message': 'Token 无效或已过期'},
              ),
            ));
          } else {
            handler.next(options);
          }
        },
      ));

      final expiredService = AuthService(dio: expiredDio);

      await expiredService.login('13800000001', '123456');
      expect(await expiredService.getToken(), isNotNull);

      try {
        await expiredService.getProfile();
        fail('Expected an exception');
      } catch (e) {
        expect(e.toString(), contains('Token 已过期'));
        expect(await expiredService.getToken(), isNull);
      }
    });
  });
}
