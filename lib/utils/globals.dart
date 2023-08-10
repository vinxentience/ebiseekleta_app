import 'package:flutter_vision/flutter_vision.dart';

abstract class Globals {
  static late FlutterVision vision;

  static Future init() async {
    vision = FlutterVision();

    await vision.loadYoloModel(
      labels: 'assets/yolov8.txt',
      modelPath: 'assets/yolov8.tflite',
      modelVersion: "yolov8",
      numThreads: 1,
      useGpu: false,
    );
  }
}
