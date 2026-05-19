import 'package:dio/dio.dart';
import '../models/conversation_item.dart';
import '../config/api_config.dart';

class ConversationService {
  final Dio _dio;

  ConversationService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  Future<List<ConversationItem>> getConversationList() async {
    try {
      final response = await _dio.get(ApiConfig.conversationPath);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map((json) => ConversationItem.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('请求失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('连接超时');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('响应超时');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('网络连接失败');
      } else {
        throw Exception('请求失败: ${e.message}');
      }
    } catch (e) {
      throw Exception('获取会话列表失败: $e');
    }
  }

  void updateBaseUrl(String newBaseUrl) {
    _dio.options.baseUrl = newBaseUrl;
    ApiConfig.updateBaseUrl(newBaseUrl);
  }
}
