/// API 配置类
class ApiConfig {
  /// 基础 URL，可配置
  static String baseUrl = 'http://192.168.2.19:3000';

  /// 会话列表接口路径
  static const String conversationPath = '/conversation';

  /// 获取完整的会话列表 URL
  static String get conversationUrl => '$baseUrl$conversationPath';

  /// 更新基础 URL
  static void updateBaseUrl(String newBaseUrl) {
    baseUrl = newBaseUrl;
  }
}
