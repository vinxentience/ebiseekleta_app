import 'dart:async';

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_vision/flutter_vision.dart';

class Detector {
  late final FlutterVision _vision;
  late final Stream<Uint8List> _channelStream;

  final StreamController<List<Map<String, dynamic>>> _resultsController =
      StreamController.broadcast();

  ui.Size? _imageSize;

  StreamSubscription<Uint8List>? _imageBytesSub;
  StreamSubscription<Uint8List>? _imageSizeSub;

  bool _isDetecting = false;

  Detector(Stream<Uint8List> imageBytes) {
    _vision = FlutterVision();

    _channelStream = imageBytes;

    _imageSizeSub = _channelStream.listen((event) {
      if (_imageSize == null) {
        ui.decodeImageFromList(event, (result) {
          _imageSize = ui.Size(
            result.width.toDouble(),
            result.height.toDouble(),
          );
        });
        _imageSizeSub?.cancel();
      }
    });

    _vision
        .loadYoloModel(
      labels: 'assets/trafficlabels.txt',
      modelPath: 'assets/traffic-yolov8n.tflite',
      modelVersion: "yolov8",
      numThreads: 1,
      useGpu: true,
    )
        .then((_) {
      _imageBytesSub = _channelStream.listen((event) async {
        if (_isDetecting) return;

        _isDetecting = true;

        final results = await _yoloOnFrame(event);
        _resultsController.add(results);

        _isDetecting = false;
      });
    });
  }

  Future<List<Map<String, dynamic>>> _yoloOnFrame(Uint8List bytes) async {
    final results = await _vision.yoloOnImage(
      bytesList: bytes,
      imageHeight: imageSize.height.toInt(),
      imageWidth: imageSize.width.toInt(),
    );

    return results;
  }

  Stream<List<Map<String, dynamic>>> get results => _resultsController.stream;
  ui.Size get imageSize =>
      _imageSize ?? ui.Size(0, 0); // todo: set default size

  Future<void> dispose() async {
    await _imageSizeSub?.cancel();
    await _imageBytesSub?.cancel();
    await _resultsController.close();
    await _vision.closeYoloModel();
  }
}
