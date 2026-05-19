import '../../../config/playground_config.dart';

class ChatRoomConfig {
  static String get baseUrl => PlaygroundConfig.baseUrl;

  static const int heartbeatInterval = 30000;
  static const int connectTimeout = 10000;

  static String get wsUrl => PlaygroundConfig.wsUrl;
}
