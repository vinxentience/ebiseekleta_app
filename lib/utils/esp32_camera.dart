import 'dart:typed_data';

import 'package:web_socket_channel/io.dart';

class Esp32Camera {
  late IOWebSocketChannel _channel;
  late Stream<Uint8List> _imageBytesStream;

  // singleton instance
  static final Esp32Camera _instance = Esp32Camera._internal();

  // private constructor
  Esp32Camera._internal() {
    _channel = IOWebSocketChannel.connect('ws://192.168.4.1:8888');
    _imageBytesStream = _channel.stream.cast<Uint8List>().asBroadcastStream(
          onListen: (subscription) {
            print("listening to image bytes stream");
          },
          onCancel: (subscription) => print("cancelling image bytes stream"),
        );
  }

  // factory constructor
  factory Esp32Camera() {
    return _instance;
  }

  IOWebSocketChannel get channel => _channel;
  Stream<Uint8List> get imageBytesStream => _imageBytesStream;

  void addListener(void Function(Uint8List onData) func) {
    _imageBytesStream.listen((event) {
      print('listening');
      func(event);
    });
  }
}
