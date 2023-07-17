import 'dart:async';
import 'dart:typed_data';

import 'package:web_socket_channel/io.dart';

class ExternalCameraChannel {
  // singleton IOWebSocketChannel
  late IOWebSocketChannel _channel;
  late Stream<Uint8List> _imageBytesStream;

  // singleton instance
  static final ExternalCameraChannel _instance =
      ExternalCameraChannel._internal();

  // private constructor
  ExternalCameraChannel._internal() {
    _channel = IOWebSocketChannel.connect('ws://192.168.4.1:8888');
    _imageBytesStream = _channel.stream.cast<Uint8List>().asBroadcastStream(
          onListen: (subscription) {
            print("listening to image bytes stream");
          },
          onCancel: (subscription) => print("cancelling image bytes stream"),
        );
  }

  // factory constructor
  factory ExternalCameraChannel() {
    return _instance;
  }

  IOWebSocketChannel get channel => _channel;
  Stream<Uint8List> get imageBytesStream => _imageBytesStream;
}
