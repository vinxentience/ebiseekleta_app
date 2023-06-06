import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:sensors_plus/sensors_plus.dart';

enum Options { none, home, frame, vision }

late List<CameraDescription> cameras;
double x = 0, y = 0, z = 0;
bool isTitled = false;
bool isTooClose = false;
//DISTANCE CONSTANTS
const double KNOWN_DISTANCE = 45.0;
const double PERSON_WIDTH = 16.0;
const double MOBILE_WIDTH = 3.0;

class YoloVideo extends StatefulWidget {
  const YoloVideo({Key? key}) : super(key: key);

  @override
  State<YoloVideo> createState() => _YoloVideoState();
}

//Distance Estimation Function
double getObjectPxPercentage(objHeight, objWidth, camHeight, camWidth) {
  double objectPixels = (objHeight * objWidth);
  final percentagePx = (objectPixels / (camHeight * camWidth)) * 100.0;
  return percentagePx;
}

class _YoloVideoState extends State<YoloVideo> {
  //Distance Estimation
  late CameraController controller;
  late FlutterVision vision;
  late List<Map<String, dynamic>> yoloResults;
  CameraImage? cameraImage;
  bool isLoaded = false;
  bool isDetecting = false;

  @override
  void initState() {
    super.initState();
    initCamera();
    initGyro();
  }

  initCamera() async {
    cameras = await availableCameras();
    vision = FlutterVision();
    controller = CameraController(cameras[0], ResolutionPreset.low);
    controller.initialize().then((value) {
      loadYoloModel().then((value) {
        if (mounted) {
          setState(() {
            isLoaded = true;
            isDetecting = false;
            yoloResults = [];
          });
        }
      });
    });
  }

  initGyro() async {
    accelerometerEvents.listen((AccelerometerEvent event) {
      x = event.x;
      y = event.y;
      z = event.z;
      if ((x > 7 && x < 11) && (y > -3 && y < 1) && (z > -2 && z < 2)) {
        isTitled = false;
      } else {
        isTitled = true;
      }
      setState(() {});
    });
  }

  @override
  void dispose() async {
    super.dispose();
    controller.dispose();
    await vision.closeYoloModel();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    if (!isLoaded) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text("Model not loaded, waiting for it"),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: CameraPreview(
            controller,
          ),
        ),
        ...displayBoxesAroundRecognizedObjects(size),
        Positioned(
          bottom: 75,
          width: MediaQuery.of(context).size.width,
          child: Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  width: 5, color: Colors.white, style: BorderStyle.solid),
            ),
            child: isDetecting
                ? IconButton(
                    onPressed: () async {
                      stopDetection();
                    },
                    icon: const Icon(
                      Icons.stop,
                      color: Colors.red,
                    ),
                    iconSize: 50,
                  )
                : IconButton(
                    onPressed: () async {
                      await startDetection();
                    },
                    icon: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                    ),
                    iconSize: 50,
                  ),
          ),
        ),
        RotatedBox(
            quarterTurns: 1,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isTitled
                    ? const Text("titled - warning",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 18.0,
                        ))
                    : const Text(
                        "normal",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                        ),
                      ),
              ],
            )),
      ],
    );
  }

  Future<void> loadYoloModel() async {
    await vision.loadYoloModel(
        labels: 'assets/trafficlabels.txt',
        modelPath: 'assets/traffic-yolov8n.tflite',
        modelVersion: "yolov8",
        numThreads: 2,
        useGpu: true);
    setState(() {
      isLoaded = true;
    });
  }

  Future<void> yoloOnFrame(CameraImage cameraImage) async {
    final result = await vision.yoloOnFrame(
        bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage.height,
        imageWidth: cameraImage.width,
        iouThreshold: 0.5,
        confThreshold: 0.5,
        classThreshold: 0.5);
    if (result.isNotEmpty) {
      if (mounted) {
        setState(() {
          yoloResults = result;
        });
      }
    }
  }

  Future<void> startDetection() async {
    setState(() {
      isDetecting = true;
    });
    if (controller.value.isStreamingImages) {
      return;
    }
    await controller.startImageStream((image) async {
      if (isDetecting) {
        cameraImage = image;
        yoloOnFrame(image);
      }
    });
  }

  Future<void> stopDetection() async {
    setState(() {
      isDetecting = false;
      yoloResults.clear();
    });
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    //Distance Estimation
    if (yoloResults.isEmpty) return [];

    double factorX = screen.width / (cameraImage?.height ?? 1);
    double factorY = screen.height / (cameraImage?.width ?? 1);

    Color colorPick = const Color.fromARGB(255, 50, 233, 30);
    return yoloResults.map((result) {
      double objheight = result["box"][3] - result["box"][1];
      double objwidth = result["box"][2] - result["box"][0];
      int? camheight = cameraImage?.height;
      int? camwidth = cameraImage?.width;
      double percentage =
          getObjectPxPercentage(objheight, objwidth, camheight, camwidth);
      String str = percentage.toStringAsFixed(2);

      if (percentage > 40) {
        isTooClose = true;
      } else {
        isTooClose = false;
      }
      // double focalPerson = getFocalLength(KNOWN_DISTANCE, PERSON_WIDTH,
      //     (result["box"][2] - result["box"][0]) * factorX);
      // double distance = getDistance(focalPerson, PERSON_WIDTH,
      //     (result["box"][2] - result["box"][0]) * factorX);

      //APPROXIMATE
      // double mid_x = (result["box"][2] + result["box"][0]) / 2;
      // double mid_y = ((result["box"][3] + result["box"][1])) / 2;
      // num  = ((result["box"][2] - result["box"][0]) * factorX) / 100;
      //num apxDistance = pow((((result["box"][2] - result["box"][0]))), 4);
      //num apxDistance = pow(1 - ((result["box"][2] - result["box"][0]) * factorX), 4.0);

      return Positioned(
        left: result["box"][0] * factorX,
        top: result["box"][1] * factorY,
        width: objwidth * factorX,
        height: objheight * factorY,
        child: RotatedBox(
          quarterTurns: 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10.0)),
              border: Border.all(color: Colors.pink, width: 2.0),
            ),
            child: isTooClose
                ? Text(
                    "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}% : $str% WARNING TOO CLOSE",
                    style: TextStyle(
                      background: Paint()..color = colorPick,
                      color: Colors.red,
                      fontSize: 18.0,
                    ),
                  )
                : Text(
                    "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}% : $str%",
                    style: TextStyle(
                      background: Paint()..color = colorPick,
                      color: Colors.white,
                      fontSize: 18.0,
                    ),
                  ),
          ),
        ),
      );
    }).toList();
  }
}
