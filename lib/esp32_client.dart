import 'dart:io';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;

class Esp32SocketClient {
  // singleton instance
  static Esp32SocketClient? _instance;

  late IOWebSocketChannel? _client;
  bool _isConnected = false;

  // private constructor
  Esp32SocketClient._internal() {}

  static Esp32SocketClient getInstance() {
    return _instance ??= Esp32SocketClient._internal();
  }

  IOWebSocketChannel get channel => _client!;

  Future<void> connect() async {
    if (_isConnected) {
      return;
    }

    WebSocket.connect('ws://192.168.4.1:8888').then((ws) {
      _client = IOWebSocketChannel(ws);

      _isConnected = true;
    }).onError((error, stackTrace) {
      print("error connecting to socket: $error");
    });
  }

  Future<void> disconnect() async {
    if (!_isConnected) {
      return;
    }

    _isConnected = false;
    await _client!.sink.close(status.goingAway);
    _client = null;
  }
}
