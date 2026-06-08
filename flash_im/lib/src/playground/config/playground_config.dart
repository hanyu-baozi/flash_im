class PlaygroundConfig {
  static String baseUrl = 'http://10.0.2.2:3000';

  static const String chatRoomWsPath = '/ws/chat_room';

  static String get wsUrl => baseUrl.replaceAll('http', 'ws') + chatRoomWsPath;

  static void updateBaseUrl(String newBaseUrl) {
    baseUrl = newBaseUrl;
  }
}
