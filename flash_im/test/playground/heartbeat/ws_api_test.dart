import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:flash_im/src/playground/features/heartbeat/models/connection_state.dart';

/// WsConnection 将 WebSocket 的单订阅流转为可多次读取的消息队列
class WsConnection {
  final WebSocketChannel _channel;
  final StreamController<Map<String, dynamic>> _controller =
      StreamController.broadcast();
  StreamSubscription? _sub;
  bool _isClosed = false;

  WsConnection._(this._channel) {
    _sub = _channel.stream.listen(
      (data) {
        if (!_controller.isClosed) {
          final decoded = jsonDecode(data as String) as Map<String, dynamic>;
          _controller.add(decoded);
        }
      },
      onError: (e) {
        if (!_controller.isClosed) _controller.addError(e);
      },
      onDone: () {
        _isClosed = true;
        if (!_controller.isClosed) _controller.close();
      },
    );
  }

  /// 建立连接
  static WsConnection connect(String url) {
    final channel = WebSocketChannel.connect(Uri.parse(url));
    return WsConnection._(channel);
  }

  /// 发送文本
  void send(String text) => _channel.sink.add(text);

  /// 等待下一条消息，超时则失败
  Future<Map<String, dynamic>> waitForMessage({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_isClosed) throw StateError('连接已关闭');
    return _controller.stream.first.timeout(
      timeout,
      onTimeout: () => throw TimeoutException(
          '等待 WebSocket 消息超时 (${timeout.inSeconds}s)'),
    );
  }

  /// 关闭连接
  Future<void> close() async {
    await _sub?.cancel();
    await _channel.sink.close();
    _isClosed = true;
    if (!_controller.isClosed) await _controller.close();
  }

  /// 连接是否已关闭
  bool get isClosed => _isClosed;
}

/// 心跳通信模块 WebSocket API 测试
///
/// 脱离 UI，直接测试 WebSocket 的连接、收发消息、断开逻辑
///
/// 运行前提：本地服务器已启动 (node IM/server.js)
/// 运行命令：flutter test test/playground/heartbeat/ws_api_test.dart
void main() {
  // ─── 配置区 ───────────────────────────────────────────────
  const serverHost = '127.0.0.1';
  const serverPort = 3000;
  final wsUrl = 'ws://$serverHost:$serverPort/ws';

  // ═══════════════════════════════════════════════════════════
  //  1. 连接后应收到欢迎消息
  // ═══════════════════════════════════════════════════════════
  group('1. 连接后收到欢迎消息', () {
    WsConnection? conn;

    tearDown(() {
      conn?.close();
      conn = null;
    });

    test('连接 ws 后服务器主动推送 welcome', () async {
      print('━━━ [连接] 正在连接 $wsUrl ...');
      conn = WsConnection.connect(wsUrl);

      final msg = await conn!.waitForMessage();
      print('━━━ [收到] $msg');

      expect(msg['type'], 'welcome', reason: '连接后应收到 type=welcome');
      expect(msg['message'], isNotNull, reason: 'welcome 消息内容不应为空');

      print('━━━ [通过] 欢迎消息验证成功 ✓');
    });
  });

  // ═══════════════════════════════════════════════════════════
  //  2. 发送文本能收到 echo 回复
  // ═══════════════════════════════════════════════════════════
  group('2. 发送文本收到 echo 回复', () {
    WsConnection? conn;

    setUp(() async {
      conn = WsConnection.connect(wsUrl);
      final welcome = await conn!.waitForMessage();
      print('━━━ [连接] 收到 welcome: ${welcome['message']}');
    });

    tearDown(() {
      conn?.close();
      conn = null;
    });

    test('发送纯文本 → 收到 echo 回复', () async {
      const text = '你好，心跳测试';
      print('━━━ [发送] $text');
      conn!.send(text);

      final echo = await conn!.waitForMessage();
      print('━━━ [收到] $echo');

      expect(echo['type'], 'echo', reason: '回复类型应为 echo');
      expect(echo['message'], contains(text), reason: 'echo 应包含原始文本');

      print('━━━ [通过] 纯文本 echo 验证成功 ✓');
    });

    test('发送 JSON → 收到 echo 回复', () async {
      final payload = jsonEncode({
        'type': 'heartbeat',
        'seq': 1,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      print('━━━ [发送] $payload');
      conn!.send(payload);

      final echo = await conn!.waitForMessage();
      print('━━━ [收到] $echo');

      expect(echo['type'], 'echo');
      expect(echo['message'], contains('heartbeat'),
          reason: 'echo 应包含原始 JSON');

      print('━━━ [通过] JSON echo 验证成功 ✓');
    });

    test('连续发送多条消息 → 依次收到 echo', () async {
      const messages = ['msg_A', 'msg_B', 'msg_C'];

      for (final msg in messages) {
        print('━━━ [发送] $msg');
        conn!.send(msg);
      }

      for (var i = 0; i < messages.length; i++) {
        final echo = await conn!.waitForMessage(
            timeout: const Duration(seconds: 10));
        print('━━━ [收到] 第${i + 1}条 echo: $echo');

        expect(echo['type'], 'echo');
        expect(echo['message'], contains(messages[i]),
            reason: '第${i + 1}条 echo 应包含 "${messages[i]}"');
      }

      print('━━━ [通过] 连续消息 echo 验证成功 ✓');
    });
  });

  // ═══════════════════════════════════════════════════════════
  //  3. 断开后状态正确
  // ═══════════════════════════════════════════════════════════
  group('3. 断开后状态正确', () {
    test('客户端主动关闭 → 连接标记为已关闭、状态为 disconnected', () async {
      // ── 连接 ──
      final conn = WsConnection.connect(wsUrl);
      final welcome = await conn.waitForMessage();
      print('━━━ [连接] 收到 welcome: ${welcome['message']}');

      // ── 断开 ──
      print('━━━ [断开] 客户端主动关闭连接 ...');
      await conn.close();

      expect(conn.isClosed, isTrue, reason: '关闭后 isClosed 应为 true');

      // ── 验证状态模型 ──
      final state = HeartbeatConnectionState(
        status: ConnectionStatus.disconnected,
        serverAddress: wsUrl,
      );
      expect(state.status, ConnectionStatus.disconnected);
      expect(state.statusText, '已断开');

      print('━━━ [通过] 断开状态验证成功 ✓');
    });

    test('断开后再次连接应能正常收发', () async {
      // ── 第一次连接 ──
      var conn = WsConnection.connect(wsUrl);
      var msg = await conn.waitForMessage();
      print('━━━ [第1次连接] welcome: ${msg['message']}');

      conn.send('before_disconnect');
      var echo = await conn.waitForMessage();
      print('━━━ [第1次收到] $echo');

      // ── 断开 ──
      await conn.close();
      print('━━━ [断开] 第1次连接已关闭');

      // ── 第二次连接 ──
      conn = WsConnection.connect(wsUrl);
      msg = await conn.waitForMessage();
      print('━━━ [第2次连接] welcome: ${msg['message']}');

      expect(msg['type'], 'welcome', reason: '重连后应再次收到 welcome');

      conn.send('after_reconnect');
      echo = await conn.waitForMessage();
      print('━━━ [第2次收到] $echo');

      expect(echo['type'], 'echo');
      expect(echo['message'], contains('after_reconnect'));

      await conn.close();

      print('━━━ [通过] 重连续接验证成功 ✓');
    });
  });
}
