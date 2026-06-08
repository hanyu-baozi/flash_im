class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:3000';

  static const String smsPath = '/auth/sms';
  static const String loginPath = '/auth/login';
  static const String passwordLoginPath = '/auth/login/password';
  static const String passwordSetupPath = '/auth/password/setup';
  static const String changePasswordPath = '/auth/password';
  static const String profilePath = '/user/profile';
  static const String updateProfilePath = '/user/profile';

  static const int connectTimeout = 10000;
  static const int countdownSeconds = 60;

  static String get smsUrl => '$baseUrl$smsPath';
  static String get loginUrl => '$baseUrl$loginPath';
  static String get passwordLoginUrl => '$baseUrl$passwordLoginPath';
  static String get passwordSetupUrl => '$baseUrl$passwordSetupPath';
  static String get profileUrl => '$baseUrl$profilePath';
}