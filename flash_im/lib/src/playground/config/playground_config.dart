class PlaygroundConfig {
  static String baseUrl = 'http://10.0.2.2:3000';

  static const String wsPath = '/ws';
  static const String chatRoomWsPath = '/ws/chat_room';
  static const String smsPath = '/auth/sms';
  static const String loginPath = '/auth/login';
  static const String profilePath = '/user/profile';

  static String get wsUrl => baseUrl.replaceAll('http', 'ws') + chatRoomWsPath;

  static void updateBaseUrl(String newBaseUrl) {
    baseUrl = newBaseUrl;
  }
}
