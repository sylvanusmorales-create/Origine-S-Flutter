import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config.dart';

class WsService {
  WebSocketChannel? _channel;
  bool _connected = false;
  Function(Map<String, dynamic>)? onEvent;

  Future<void> connect(int convId) async {
    disconnect();
    final wsBase = await Config.getWsUrl();
    _channel = WebSocketChannel.connect(Uri.parse('$wsBase/ws/$convId'));
    _connected = true;

    _channel!.stream.listen(
      (data) {
        final event = jsonDecode(data) as Map<String, dynamic>;
        onEvent?.call(event);
      },
      onError: (error) {
        _connected = false;
        onEvent?.call({'type': 'error', 'message': error.toString()});
      },
      onDone: () {
        _connected = false;
        onEvent?.call({'type': 'disconnected'});
      },
    );
  }

  void sendMessage(String content) {
    if (!_connected) return;
    _channel?.sink.add(jsonEncode({'action': 'message', 'content': content}));
  }

  void stop() {
    if (!_connected) return;
    _channel?.sink.add(jsonEncode({'action': 'stop'}));
  }

  void disconnect() {
    _connected = false;
    _channel?.sink.close();
    _channel = null;
  }

  bool get isConnected => _connected;
}