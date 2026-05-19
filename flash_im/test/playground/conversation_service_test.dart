import 'package:flutter_test/flutter_test.dart';
import 'package:flash_im/src/playground/features/conversation/services/conversation_service.dart';
import 'package:flash_im/src/playground/features/conversation/models/conversation_item.dart';
import 'package:flash_im/src/playground/features/conversation/config/api_config.dart';

void main() {
  group('ConversationService Tests', () {
    late ConversationService service;

    setUp(() {
      ApiConfig.updateBaseUrl('http://127.0.0.1:3000');
      service = ConversationService();
    });

    test('ConversationItem fromJson should parse correctly', () {
      final json = {
        'id': '1',
        'title': '张三',
        'lastMsg': '晚上一起吃饭吗？',
        'time': '2026-04-25 18:30',
      };

      final item = ConversationItem.fromJson(json);

      expect(item.id, '1');
      expect(item.title, '张三');
      expect(item.lastMsg, '晚上一起吃饭吗？');
      expect(item.time, '2026-04-25 18:30');
    });

    test('ConversationItem toJson should serialize correctly', () {
      final item = ConversationItem(
        id: '2',
        title: '李四',
        lastMsg: '项目文档已发送',
        time: '2026-04-25 17:45',
      );

      final json = item.toJson();

      expect(json['id'], '2');
      expect(json['title'], '李四');
      expect(json['lastMsg'], '项目文档已发送');
      expect(json['time'], '2026-04-25 17:45');
    });

    test('ApiConfig should update base URL correctly', () {
      const newUrl = 'http://192.168.1.100:3000';
      ApiConfig.updateBaseUrl(newUrl);

      expect(ApiConfig.baseUrl, newUrl);
      expect(ApiConfig.conversationUrl, '$newUrl/conversation');
    });

    test('ConversationService should update base URL', () {
      const newUrl = 'http://192.168.1.100:3000';
      service.updateBaseUrl(newUrl);

      expect(ApiConfig.baseUrl, newUrl);
    });

    test('ConversationItem should handle message type labels', () {
      expect(
        ConversationItem(
          id: '1',
          title: 'A',
          lastMsg: 'msg',
          time: 'now',
          messageType: MessageType.transfer,
        ).messageTypeLabel,
        '[转账]',
      );

      expect(
        ConversationItem(
          id: '2',
          title: 'B',
          lastMsg: 'msg',
          time: 'now',
          messageType: MessageType.image,
        ).messageTypeLabel,
        '[图片]',
      );

      expect(
        ConversationItem(
          id: '3',
          title: 'C',
          lastMsg: 'msg',
          time: 'now',
          messageType: MessageType.sticker,
        ).messageTypeLabel,
        '[动画表情]',
      );

      expect(
        ConversationItem(
          id: '4',
          title: 'D',
          lastMsg: 'msg',
          time: 'now',
          messageType: MessageType.text,
        ).messageTypeLabel,
        '',
      );
    });

    test('ConversationItem displayMessage should combine type label and message', () {
      expect(
        ConversationItem(
          id: '1',
          title: 'A',
          lastMsg: '100元',
          time: 'now',
          messageType: MessageType.transfer,
        ).displayMessage,
        '[转账] 100元',
      );

      expect(
        ConversationItem(
          id: '2',
          title: 'B',
          lastMsg: '你好',
          time: 'now',
          messageType: MessageType.text,
        ).displayMessage,
        '你好',
      );
    });
  });

  group('ConversationItem Model Tests', () {
    test('toString should return formatted string', () {
      final item = ConversationItem(
        id: '5',
        title: '测试',
        lastMsg: '消息内容',
        time: '2026-04-25 12:00',
      );

      final str = item.toString();
      expect(str, contains('测试'));
      expect(str, contains('消息内容'));
      expect(str, contains('2026-04-25 12:00'));
    });

    test('should handle empty strings', () {
      final item = ConversationItem(
        id: '6',
        title: '',
        lastMsg: '',
        time: '',
      );

      expect(item.title, '');
      expect(item.lastMsg, '');
      expect(item.time, '');
    });
  });
}
