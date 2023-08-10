import 'dart:async';

import 'dart:typed_data';
import 'dart:ui';

import 'package:ebiseekleta_app/utils/globals.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_vision/flutter_vision.dart';

class Detector {
  late final Stream<Uint8List> _channelStream;

  final StreamController<List<Map<String, dynamic>>> _resultsController =
      StreamController.broadcast(sync: true);

  //final FlutterVision _vision = Globals.vision;
  final FlutterVision _vision = Globals.vision;

  Size _size = Size(640, 480); // image size of the esp32 camera

  bool _isDetecting = false;

  Detector(Stream<Uint8List> imageStream) {
    _channelStream = imageStream;

    _channelStream.listen((event) async {
      if (_isDetecting) return;

      _isDetecting = true;

      var results = await _yoloOnFrame(event);

      results = results.map(mapLabel).where(filterResult).toList();
      print(results);

      _resultsController.add(results);

      _isDetecting = false;
    });
  }
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

  Map<String, dynamic> mapLabel(Map<String, dynamic> e) {
    final String label = e['tag'];

    switch (label) {
      case 'car':
      case 'motorcycle':
      case 'bus':
      case 'truck':
      case 'jeep':
      case 'tricycle':
        e['tag'] = 'vehicle';
        break;
      case 'bicycle':
      case 'person':
        e['tag'] = 'person';
        break;
      default:
    }

    return e;
  }

  bool filterResult(Map<String, dynamic> e) {
    return e['tag'] == 'vehicle' || e['tag'] == 'person';
  }

  Future<List<Map<String, dynamic>>> _yoloOnFrame(Uint8List imageBytes) async {
    final results = await _vision.yoloOnImage(
        bytesList: imageBytes,
        imageHeight: _size.height.toInt(),
        imageWidth: _size.width.toInt(),
        iouThreshold: 0.7,
        confThreshold: 0.7,
        classThreshold: 0.7);
    return results;
  }

  Future detect(Uint8List imageBytes) async {
    if (_isDetecting) return;
    _isDetecting = true;
    var results = await _yoloOnFrame(imageBytes);
    _resultsController.add(results);
    _isDetecting = false;
  }

  Stream<List<Map<String, dynamic>>> get results => _resultsController.stream;
  Stream<Uint8List> get image => _channelStream;

  Size get size => _size;
}
