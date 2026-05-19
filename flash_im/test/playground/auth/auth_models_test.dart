import 'package:flutter_test/flutter_test.dart';
import 'package:flash_im/src/playground/features/auth/models/user_profile.dart';
import 'package:flash_im/src/playground/features/auth/models/login_response.dart';
import 'package:flash_im/src/playground/features/auth/config/auth_config.dart';

void main() {
  group('UserProfile Model Tests', () {
    test('fromJson should parse server response correctly', () {
      final json = {
        'user_id': 1,
        'nickname': '13800000001',
        'avatar': 'https://api.dicebear.com/7.x/identicon/svg?seed=13800000001',
        'phone': '13800000001',
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.userId, 1);
      expect(profile.nickname, '13800000001');
      expect(profile.avatar, 'https://api.dicebear.com/7.x/identicon/svg?seed=13800000001');
      expect(profile.phone, '13800000001');
    });

    test('toJson should serialize correctly', () {
      final profile = UserProfile(
        userId: 42,
        nickname: 'test_user',
        avatar: 'https://example.com/avatar.png',
        phone: '13900000002',
      );

      final json = profile.toJson();

      expect(json['user_id'], 42);
      expect(json['nickname'], 'test_user');
      expect(json['avatar'], 'https://example.com/avatar.png');
      expect(json['phone'], '13900000002');
    });

    test('fromJson and toJson should be reversible', () {
      final original = UserProfile(
        userId: 100,
        nickname: 'reversible_test',
        avatar: 'https://example.com/test.png',
        phone: '13900000003',
      );

      final restored = UserProfile.fromJson(original.toJson());

      expect(restored.userId, original.userId);
      expect(restored.nickname, original.nickname);
      expect(restored.avatar, original.avatar);
      expect(restored.phone, original.phone);
    });

    test('toString should return formatted string', () {
      final profile = UserProfile(
        userId: 1,
        nickname: 'test',
        avatar: 'https://example.com/a.png',
        phone: '13800000001',
      );

      final str = profile.toString();

      expect(str, contains('1'));
      expect(str, contains('test'));
      expect(str, contains('13800000001'));
    });

    test('should handle empty string fields', () {
      final json = {
        'user_id': 0,
        'nickname': '',
        'avatar': '',
        'phone': '',
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.userId, 0);
      expect(profile.nickname, '');
      expect(profile.avatar, '');
      expect(profile.phone, '');
    });
  });

  group('LoginResponse Model Tests', () {
    test('fromJson should parse successful login response', () {
      final json = {
        'success': true,
        'token': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test',
        'user_id': 1,
      };

      final response = LoginResponse.fromJson(json);

      expect(response.success, true);
      expect(response.token, 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test');
      expect(response.userId, 1);
      expect(response.message, isNull);
    });

    test('fromJson should parse failed login response', () {
      final json = {
        'success': false,
        'message': '验证码错误或已过期',
      };

      final response = LoginResponse.fromJson(json);

      expect(response.success, false);
      expect(response.token, isNull);
      expect(response.userId, isNull);
      expect(response.message, '验证码错误或已过期');
    });

    test('fromJson should handle partial fields', () {
      final json = {
        'success': true,
      };

      final response = LoginResponse.fromJson(json);

      expect(response.success, true);
      expect(response.token, isNull);
      expect(response.userId, isNull);
      expect(response.message, isNull);
    });

    test('constructor should create instance with all fields', () {
      final response = LoginResponse(
        success: true,
        token: 'test_token',
        userId: 99,
        message: null,
      );

      expect(response.success, true);
      expect(response.token, 'test_token');
      expect(response.userId, 99);
      expect(response.message, isNull);
    });
  });

  group('AuthConfig Tests', () {
    test('should have correct default values', () {
      expect(AuthConfig.countdownSeconds, 60);
      expect(AuthConfig.connectTimeout, 10000);
      expect(AuthConfig.smsPath, '/auth/sms');
      expect(AuthConfig.loginPath, '/auth/login');
      expect(AuthConfig.profilePath, '/user/profile');
    });

    test('URL getters should combine baseUrl and path correctly', () {
      const testUrl = 'http://test.example.com:3000';
      AuthConfig.updateBaseUrl(testUrl);

      expect(AuthConfig.smsUrl, '$testUrl/auth/sms');
      expect(AuthConfig.loginUrl, '$testUrl/auth/login');
      expect(AuthConfig.profileUrl, '$testUrl/user/profile');
    });

    test('updateBaseUrl should change baseUrl', () {
      const original = 'http://original:3000';
      const updated = 'http://updated:3000';

      AuthConfig.updateBaseUrl(original);
      expect(AuthConfig.baseUrl, original);

      AuthConfig.updateBaseUrl(updated);
      expect(AuthConfig.baseUrl, updated);
    });
  });
}
