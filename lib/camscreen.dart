import 'dart:async';

import 'package:background_sms/background_sms.dart';
import 'package:ebiseekleta_app/gyro_provider.dart';
import 'package:ebiseekleta_app/services/sms_service.dart';
import 'package:ebiseekleta_app/utils/detector.dart';

import 'package:ebiseekleta_app/utils/painter.dart';

import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:web_socket_channel/io.dart';

double x = 0, y = 0, z = 0;
bool isTitled = false;
bool isTooClose = false;
Position? _currentPosition;

class CamScreen extends StatefulWidget {
  // final WebSocketChannel channel;
  // final Stream imageStream;
  const CamScreen({
    super.key,
    // required this.channel,
    // required this.imageStream,
  });

  @override
  State<CamScreen> createState() => _CamScreenState();
}

class _CamScreenState extends State<CamScreen> {
  late final SharedPreferences _prefs;
  late final SmsService _smsService;

  final double videoWidth = 640;
  final double videoHeight = 480;

  double newVideoSizeWidth = 640;
  double newVideoSizeHeight = 480;

  late bool isLandscape;

  //FLUTTER VISION
  bool isDetecting = false;

  int _start = 10;
  bool isFunctionExecuted = false;
  bool isMessageSent = false;

  // websocket
  late final IOWebSocketChannel channel;
  late final Detector _detector;

  //gyro
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];
  Timer? _timer;
  late final GyroProvider gyroProvider;

  double getObjectPxPercentage(objHeight, objWidth, camHeight, camWidth) {
    double objectPixels = (objHeight * objWidth);
    final percentagePx = (objectPixels / (camHeight * camWidth)) * 100.0;
    return percentagePx;
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() => _currentPosition = position);
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<bool?> get _supportCustomSim async =>
      await BackgroundSms.isSupportCustomSim;

  _notifyCloseContact() async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    String cyclistLocation =
        "https://www.google.com/maps/?q=${_currentPosition?.latitude},${_currentPosition?.longitude}";

    var obtainedName = sharedPreferences.getString('username');
    var obtainedNumbers = sharedPreferences.getStringList('phonenumber');
    print("$cyclistLocation");
    print("$obtainedName, $obtainedNumbers");

    // obtainedNumbers?.forEach((item) {
    //   _sendMessage(item,
    //       "$obtainedName is in trouble need help! Location at: $cyclistLocation",
    //       simSlot: 2);
    // });

    if (await _isPermissionGranted()) {
      if ((await _supportCustomSim)!) {
        obtainedNumbers?.forEach((item) {
          _sendMessage(item,
              "$obtainedName is in trouble need help! Location at: $cyclistLocation",
              simSlot: 1);
        });
      } else {
        obtainedNumbers?.forEach((item) {
          _sendMessage(item,
              "$obtainedName is in trouble need help! Location at: $cyclistLocation",
              simSlot: 2);
        });
      }
      isMessageSent = true;
    } else {
      _getPermission();
    }
  }

  _sendMessage(String phoneNumber, String message, {int? simSlot}) async {
    var result = await BackgroundSms.sendMessage(
        phoneNumber: phoneNumber, message: message, simSlot: simSlot);
    print("THIS IS THE RESULT: $result");
    if (result == SmsStatus.sent) {
      print("Sent");
    } else {
      print("Failed");
    }
  }

  _getPermission() async => await [
        Permission.sms,
      ].request();

  Future<bool> _isPermissionGranted() async =>
      await Permission.sms.status.isGranted;

  void startTimer() {
    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(
      oneSec,
      (Timer timer) async {
        if (timer.isActive) {
          if (_start > 0) {
            setState(() {
              _start--;
            });
          } else {
            if (!isMessageSent) {
              //await _getCurrentPosition();
              print("yeeeyerss");
              isMessageSent = true;
            }
          }
        } else {
          _start = 10;
          isMessageSent = false;
          startTimer();
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();

    channel = IOWebSocketChannel.connect('ws://192.168.4.1:8888');
    _detector = Detector(channel);
    gyroProvider = GyroProvider();

    SharedPreferences.getInstance().then((value) {
      _prefs = value;

      _smsService = SmsService(
        cyclist: _prefs.getString('username')!,
        recipients: _prefs.getStringList('phonenumber')!,
      );

      gyroProvider.addListener(() {
        print('changed');
        if (gyroProvider.exceededMaximumDuration) {
          print('>>>> send message');
          // get current location
          // send message
          _smsService.send(location: 'Teyvat');
        }
      });
    });
  }

  @override
  void dispose() async {
    super.dispose();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    await _detector.dispose();
    await channel.sink.close();
    gyroProvider.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: gyroProvider,
      child: Scaffold(
        body: RotatedBox(
          quarterTurns: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              StreamBuilder(
                stream: _detector.image,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                        Text(
                          "Make sure that this device is connected to 'ESP32-CAM-EBISEEKLETA'",
                        ),
                        SizedBox(height: 20),
                        SizedBox(height: 20),
                        Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blueAccent,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      StreamBuilder(
                          stream: _detector.results,
                          builder: (context, snapshot_) {
                            // print(snapshot_.data);
                            return CustomPaint(
                              foregroundPainter: BoundingBoxPainter(
                                  snapshot_.data ?? [],
                                  Size(_detector.size.width.toDouble(),
                                      _detector.size.height.toDouble())),
                              child: FittedBox(
                                fit: BoxFit.fill,
                                child: Image.memory(
                                  snapshot.data!,
                                  gaplessPlayback: true,
                                ),
                              ),
                            );
                          }),
                      Consumer<GyroProvider>(
                        builder: (context, gyro, child) {
                          // print(
                          //     'Consumer - ${gyro.isTilted}: ${gyro.countdown}');

                          return gyro.isTilted
                              ? Text("titled - warning : ${gyro.countdown} sec",
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 18.0,
                                  ))
                              : const Text(
                                  "normal",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18.0,
                                  ),
                                );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Future<void> loadYoloModel() async {
  //   await vision.loadYoloModel(
  //       labels: 'assets/trafficlabels.txt',
  //       modelPath: 'assets/traffic-yolov8n.tflite',
  //       modelVersion: "yolov8",
  //       numThreads: 1,
  //       useGpu: true);
  //   setState(() {
  //     isLoaded = true;
  //   });
  // }

  // Future<List<Map<String, dynamic>>> yoloOnFrame(Uint8List imageBytes) async {
  //   final decodedImage = imageLib.decodeJpg(imageBytes)!;

  //   cameraImage = decodedImage;

  //   final results = await vision.yoloOnImage(
  //     bytesList: imageLib.encodeJpg(decodedImage),
  //     imageHeight: decodedImage.height,
  //     imageWidth: decodedImage.width,
  //   );

  //   print(results);
  //   return results;
  // }
}


  // Future<Image> yoloOnStream(List<Uint8List> cameraImage, double cameraHeight,
  //     double cameraWidth) async {
  //   int height = cameraHeight.toInt();
  //   int width = cameraWidth.toInt();
  //   final result = await vision.yoloOnFrame(
  //       bytesList: cameraImage,
  //       imageHeight: height,
  //       imageWidth: width,
  //       iouThreshold: 0.5,
  //       confThreshold: 0.5,
  //       classThreshold: 0.5);
  //   if (result.isNotEmpty) {
  //     if (mounted) {
  //       setState(() {
  //         yoloResults = result;
  //         print(result);
  //       });
  //     }
  //   }
  //   return Image.memory(
  //     cameraImage as Uint8List,
  //     gaplessPlayback: true,
  //     width: cameraWidth,
  //     height: cameraHeight,
  //   );
  // }

  // Future<void> startDetection(Image image) async {
  //   setState(() {
  //     isDetecting = true;
  //   });
  //   // await controller.startImageStream((image) async {
  //   //   if (isDetecting) {
  //   //     cameraImage = image;
  //   //     yoloOnFrame(image);
  //   //   }
  //   yoloOnFrame(cameraImage, cameraHeight, cameraWidth)
  // }

  // Future<void> stopDetection() async {
  //   setState(() {
  //     isTitled = false;
  //     isDetecting = false;
  //     isMessageSent = false;
  //     _start = 10;
  //     yoloResults.clear();
  //   });
  // }


// // class YoloOnStweam extends StatefulWidget {
// //   double cameraHeight;
// //   double cameraWidth;
// //   List<Uint8List> byte;

// //   YoloOnStweam(
// //       {super.key,
// //       required this.cameraHeight,
// //       required this.cameraWidth,
// //       required this.byte});

// //   @override
// //   State<YoloOnStweam> createState() => _YoloOnStweamState();
// // }

// // class _YoloOnStweamState extends State<YoloOnStweam> {
// //   var _globalKey = new GlobalKey();

// //   //FLUTTER VISION
// //   late FlutterVision vision;
// //   late List<Map<String, dynamic>> yoloResults;
// //   bool isLoaded = false;
// //   bool isDetecting = false;

// //   @override
// //   void initState() {
// //     // TODO: implement initState
// //     vision = FlutterVision();
// //     _initYolo();
// //   }

// //   _initYolo() async {
// //     int height = widget.cameraHeight.toInt();
// //     int width = widget.cameraWidth.toInt();
// //     final result = await vision.yoloOnFrame(
// //         bytesList: widget.byte,
// //         imageHeight: height,
// //         imageWidth: width,
// //         iouThreshold: 0.5,
// //         confThreshold: 0.5,
// //         classThreshold: 0.5);
// //     if (result.isNotEmpty) {
// //       if (mounted) {
// //         setState(() {
// //           yoloResults = result;
// //           print(result);
// //         });
// //       }
// //     }
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Image.memory(
// //       widget.byte,
// //       gaplessPlayback: true,
// //       width: widget.cameraWidth,
// //       height: widget.cameraHeight,
// //     );
// //     ;
// //   }
// }


