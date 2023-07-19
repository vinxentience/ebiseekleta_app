import 'dart:async';

import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:web_socket_channel/io.dart';
import 'package:image/image.dart' as imageLib;

class Detector {
  final IOWebSocketChannel channel;
  late final Stream<Uint8List> _channelStream;

  final StreamController<List<Map<String, dynamic>>> _resultsController =
      StreamController.broadcast(sync: true);

  late final FlutterVision _vision;
  Size _size = Size(640, 480); // image size of the esp32 camera

  bool _isDetecting = false;

  Detector(this.channel) {
    _channelStream = channel.stream
        .map(
          (event) => event as Uint8List,
        )
        .asBroadcastStream();

    _vision = FlutterVision();

    _vision
        .loadYoloModel(
      labels: 'assets/trafficlabels.txt',
      modelPath: 'assets/traffic-yolov8n.tflite',
      modelVersion: "yolov8",
      numThreads: 1,
      useGpu: true,
    )
        .then((_) {
      _channelStream.listen((event) async {
        if (_isDetecting) return;

        // decodeImageFromList(event, (result) {
        //   print('${result.height} ${result.width}');
        // });

        _isDetecting = true;

        final results = await _yoloOnFrame(event);
        _resultsController.add(results);

        print('results: $results');

        _isDetecting = false;
      });
    });

    // _subscription = _channelStream.listen((event) async {
    //   if (_isDetecting) return;

    //   _isDetecting = true;

    //   _imageController.add(event);

    //   final decodedImage = imageLib.decodeJpg(event)!;

    //   _size ??= Size(
    //     decodedImage.width.toDouble(),
    //     decodedImage.height.toDouble(),
    //   );
    //   _resultsController.add(await _yoloOnFrame(decodedImage));

    //   _isDetecting = false;
    // });
  }

  Future<List<Map<String, dynamic>>> _yoloOnFrame(Uint8List imageBytes) async {
    final results = await _vision.yoloOnImage(
      bytesList: imageBytes,
      imageHeight: _size.height.toInt(),
      imageWidth: _size.width.toInt(),
    );
    return results;
  }

  Stream<List<Map<String, dynamic>>> get results => _resultsController.stream;
  Stream<Uint8List> get image => _channelStream;

  Size get size => _size;

  Future<void> stopDetecting() async {
    // await _channelStream.drain();
    // await _vision.closeYoloModel();
  }
}
