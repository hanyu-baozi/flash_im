/// 心跳通信 API 配置类
class HeartbeatConfig {
  /// 基础 URL，可配置
  static String baseUrl = 'http://192.168.2.19:3000';

  /// 心跳接口路径
  static const String heartbeatPath = '/heartbeat';

  /// 获取完整的心跳 URL
  static String get heartbeatUrl => '$baseUrl$heartbeatPath';

  /// 心跳间隔（毫秒）
  static const int heartbeatInterval = 5000;

  /// 连接超时时间（毫秒）
  static const int connectTimeout = 10000;

  /// 更新基础 URL
  static void updateBaseUrl(String newBaseUrl) {
    baseUrl = newBaseUrl;
  }
}
