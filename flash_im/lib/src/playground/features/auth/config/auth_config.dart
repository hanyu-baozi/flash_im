import '../../../config/playground_config.dart';

class AuthConfig {
  static String get baseUrl => PlaygroundConfig.baseUrl;

  static const String smsPath = '/auth/sms';
  static const String loginPath = '/auth/login';
  static const String profilePath = '/user/profile';

  static const int countdownSeconds = 60;
  static const int connectTimeout = 10000;

  static String get smsUrl => '$baseUrl$smsPath';
  static String get loginUrl => '$baseUrl$loginPath';
  static String get profileUrl => '$baseUrl$profilePath';

  static void updateBaseUrl(String newBaseUrl) {
    PlaygroundConfig.updateBaseUrl(newBaseUrl);
  }
}
