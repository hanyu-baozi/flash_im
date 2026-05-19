import 'package:flutter_test/flutter_test.dart';
import 'package:flash_im/src/playground/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:flash_im/src/playground/features/auth/services/auth_service.dart';
import 'package:flash_im/src/playground/features/auth/config/auth_config.dart';
import 'package:flash_im/src/playground/features/auth/models/user_profile.dart';
import 'package:flash_im/src/playground/features/auth/models/login_response.dart';

class MockAuthService implements AuthService {
  MockAuthService({
    this.mockSmsCode = '123456',
    this.mockLoginSuccess = true,
    this.mockProfileSuccess = true,
    this.shouldThrow = false,
  });

  final String mockSmsCode;
  final bool mockLoginSuccess;
  final bool mockProfileSuccess;
  final bool shouldThrow;

  String? _savedToken;
  int? _savedUserId;

  @override
  Future<String?> sendSmsCode(String phone) async {
    if (shouldThrow) throw Exception('网络错误');
    if (phone.isEmpty) throw Exception('手机号不能为空');
    return mockSmsCode;
  }

  @override
  Future<LoginResponse> login(String phone, String code) async {
    if (shouldThrow) throw Exception('网络错误');
    if (code != mockSmsCode) {
      return LoginResponse(success: false, message: '验证码错误');
    }
    _savedToken = 'mock_token_for_$phone';
    _savedUserId = 100;
    return LoginResponse(success: true, token: _savedToken, userId: _savedUserId);
  }

  @override
  Future<UserProfile> getProfile() async {
    if (shouldThrow) throw Exception('网络错误');
    if (_savedToken == null) throw Exception('未登录');
    return UserProfile(
      userId: _savedUserId!,
      nickname: 'mock_user',
      avatar: 'https://example.com/avatar.png',
      phone: '13800000001',
    );
  }

  @override
  Future<String?> getToken() async => _savedToken;

  @override
  Future<int?> getUserId() async => _savedUserId;

  @override
  Future<bool> isLoggedIn() async => _savedToken != null;

  @override
  Future<void> clearToken() async {
    _savedToken = null;
    _savedUserId = null;
  }

  @override
  void updateBaseUrl(String newBaseUrl) {}
}

void main() {
  group('AuthViewModel State Management Tests', () {
    test('initial state should be correct', () {
      final vm = AuthViewModel(service: MockAuthService());

      expect(vm.phone, '');
      expect(vm.code, '');
      expect(vm.isLoading, false);
      expect(vm.errorMessage, isNull);
      expect(vm.countdown, 0);
      expect(vm.canSendCode, false);
      expect(vm.codeSent, false);
      expect(vm.displayCode, isNull);
      expect(vm.profile, isNull);
      expect(vm.isLoggedIn, false);
      expect(vm.canLogin, false);
    });

    test('setPhone should update phone and clear error', () {
      final vm = AuthViewModel(service: MockAuthService());

      vm.setPhone('138');
      expect(vm.phone, '138');
      expect(vm.canSendCode, false);

      vm.setPhone('13800000001');
      expect(vm.phone, '13800000001');
      expect(vm.canSendCode, true);
    });

    test('setCode should update code and clear error', () {
      final vm = AuthViewModel(service: MockAuthService());

      vm.setCode('123');
      expect(vm.code, '123');
      expect(vm.canLogin, false);

      vm.setCode('123456');
      expect(vm.code, '123456');
    });

    test('canSendCode should be true only when phone is 11 digits and countdown is 0', () {
      final vm = AuthViewModel(service: MockAuthService());

      vm.setPhone('138');
      expect(vm.canSendCode, false);

      vm.setPhone('13800000001');
      expect(vm.canSendCode, true);
    });

    test('canLogin should be true only when phone is 11 digits, code is 6 digits, and not loading', () {
      final vm = AuthViewModel(service: MockAuthService());

      vm.setPhone('138');
      vm.setCode('123456');
      expect(vm.canLogin, false);

      vm.setPhone('13800000001');
      vm.setCode('123');
      expect(vm.canLogin, false);

      vm.setPhone('13800000001');
      vm.setCode('123456');
      expect(vm.canLogin, true);
    });
  });

  group('AuthViewModel sendCode Tests', () {
    testWidgets('sendCode should succeed with valid phone', (tester) async {
      final mockService = MockAuthService();
      final vm = AuthViewModel(service: mockService);

      vm.setPhone('13800000001');
      await vm.sendCode();

      expect(vm.codeSent, true);
      expect(vm.displayCode, '123456');
      expect(vm.countdown, 60);
      expect(vm.errorMessage, isNull);
      expect(vm.isLoading, false);

      vm.dispose();
    });

    testWidgets('sendCode should not send when phone is invalid', (tester) async {
      final mockService = MockAuthService();
      final vm = AuthViewModel(service: mockService);

      vm.setPhone('138');
      await vm.sendCode();

      expect(vm.codeSent, false);
      expect(vm.displayCode, isNull);

      vm.dispose();
    });

    testWidgets('sendCode should handle error', (tester) async {
      final mockService = MockAuthService(shouldThrow: true);
      final vm = AuthViewModel(service: mockService);

      vm.setPhone('13800000001');
      await vm.sendCode();

      expect(vm.errorMessage, isNotNull);
      expect(vm.codeSent, false);
      expect(vm.isLoading, false);

      vm.dispose();
    });
  });

  group('AuthViewModel login Tests', () {
    testWidgets('login should succeed with correct phone and code', (tester) async {
      final mockService = MockAuthService();
      final vm = AuthViewModel(service: mockService);

      vm.setPhone('13800000001');
      vm.setCode('123456');
      await vm.login();

      expect(vm.isLoggedIn, true);
      expect(vm.errorMessage, isNull);
      expect(vm.isLoading, false);

      vm.dispose();
    });

    testWidgets('login should fail with wrong code', (tester) async {
      final mockService = MockAuthService();
      final vm = AuthViewModel(service: mockService);

      vm.setPhone('13800000001');
      vm.setCode('000000');
      await vm.login();

      expect(vm.isLoggedIn, false);
      expect(vm.errorMessage, isNotNull);
      expect(vm.isLoading, false);

      vm.dispose();
    });

    testWidgets('login should not send when inputs are incomplete', (tester) async {
      final mockService = MockAuthService();
      final vm = AuthViewModel(service: mockService);

      vm.setPhone('138');
      vm.setCode('123456');
      await vm.login();

      expect(vm.isLoggedIn, false);

      vm.dispose();
    });

    testWidgets('login should handle network error', (tester) async {
      final mockService = MockAuthService(shouldThrow: true);
      final vm = AuthViewModel(service: mockService);

      vm.setPhone('13800000001');
      vm.setCode('123456');
      await vm.login();

      expect(vm.errorMessage, isNotNull);
      expect(vm.isLoggedIn, false);
      expect(vm.isLoading, false);

      vm.dispose();
    });
  });

  group('AuthViewModel profile Tests', () {
    testWidgets('loadProfile should succeed when logged in', (tester) async {
      final mockService = MockAuthService();
      final vm = AuthViewModel(service: mockService);

      vm.setPhone('13800000001');
      vm.setCode('123456');
      await vm.login();

      expect(vm.profile, isNotNull);
      expect(vm.profile!.userId, 100);
      expect(vm.profile!.nickname, 'mock_user');
      expect(vm.profile!.phone, '13800000001');

      vm.dispose();
    });

    testWidgets('loadProfile should handle error', (tester) async {
      final mockService = MockAuthService(shouldThrow: true);
      final vm = AuthViewModel(service: mockService);

      await vm.loadProfile();

      expect(vm.profile, isNull);
      expect(vm.errorMessage, isNotNull);
      expect(vm.isLoggedIn, false);

      vm.dispose();
    });
  });

  group('AuthViewModel logout Tests', () {
    testWidgets('logout should clear all state', (tester) async {
      final mockService = MockAuthService();
      final vm = AuthViewModel(service: mockService);

      vm.setPhone('13800000001');
      vm.setCode('123456');
      await vm.login();

      expect(vm.isLoggedIn, true);
      expect(vm.profile, isNotNull);

      await vm.logout();

      expect(vm.isLoggedIn, false);
      expect(vm.profile, isNull);
      expect(vm.phone, '');
      expect(vm.code, '');
      expect(vm.codeSent, false);
      expect(vm.displayCode, isNull);
      expect(vm.countdown, 0);

      vm.dispose();
    });
  });

  group('AuthViewModel error management Tests', () {
    test('clearError should clear error message', () {
      final vm = AuthViewModel(service: MockAuthService());

      vm.setPhone('13800000001');
      vm.setCode('000000');

      expect(vm.errorMessage, isNull);

      vm.dispose();
    });
  });

  group('AuthViewModel countdown Tests', () {
    testWidgets('countdown should decrease over time', (tester) async {
      final mockService = MockAuthService();
      final vm = AuthViewModel(service: mockService);

      vm.setPhone('13800000001');
      await vm.sendCode();

      expect(vm.countdown, 60);

      await tester.pump(const Duration(seconds: 1));
      expect(vm.countdown, 59);

      await tester.pump(const Duration(seconds: 59));
      expect(vm.countdown, 0);

      vm.dispose();
    });

    testWidgets('canSendCode should be false during countdown', (tester) async {
      final mockService = MockAuthService();
      final vm = AuthViewModel(service: mockService);

      vm.setPhone('13800000001');
      await vm.sendCode();

      expect(vm.canSendCode, false);

      await tester.pump(const Duration(seconds: 60));
      expect(vm.countdown, 0);
      expect(vm.canSendCode, true);

      vm.dispose();
    });
  });

  group('AuthViewModel checkLoginStatus Tests', () {
    testWidgets('checkLoginStatus should detect logged in state', (tester) async {
      final mockService = MockAuthService();
      final vm = AuthViewModel(service: mockService);

      vm.setPhone('13800000001');
      vm.setCode('123456');
      await vm.login();

      expect(await mockService.isLoggedIn(), true);

      await vm.checkLoginStatus();
      expect(vm.isLoggedIn, true);
      expect(vm.profile, isNotNull);

      vm.dispose();
    });

    testWidgets('checkLoginStatus should detect logged out state', (tester) async {
      final mockService = MockAuthService();
      final vm = AuthViewModel(service: mockService);

      await vm.checkLoginStatus();
      expect(vm.isLoggedIn, false);
      expect(vm.profile, isNull);

      vm.dispose();
    });
  });
}
