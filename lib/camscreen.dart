import 'package:blinking_text/blinking_text.dart';
import 'package:ebiseekleta_app/gyro_provider.dart';
import 'package:ebiseekleta_app/services/sms_service.dart';
import 'package:ebiseekleta_app/utils/detector.dart';
import 'package:ebiseekleta_app/utils/esp32_camera.dart';
import 'package:ebiseekleta_app/utils/location_util.dart';

import 'package:ebiseekleta_app/utils/painter.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

double x = 0, y = 0, z = 0;
bool isTitled = false;
bool isTooClose = false;

class CamScreen extends StatefulWidget {
  const CamScreen({super.key});

  @override
  State<CamScreen> createState() => _CamScreenState();
}

class _CamScreenState extends State<CamScreen> {
  final Esp32Camera _extCam = Esp32Camera();
  late final SharedPreferences _prefs;
  late final SmsService _smsService;

  final double videoWidth = 640;
  final double videoHeight = 480;

  double newVideoSizeWidth = 640;
  double newVideoSizeHeight = 480;

  late bool isLandscape;

  late final Detector _detector;

  List<Map<String, dynamic>> results = [];
  bool isDetecting = false;

  late final GyroProvider gyroProvider;

  @override
  void initState() {
    super.initState();
    _extCam.reconnect();
    _detector = Detector(_extCam.imageBytesStream);
    gyroProvider = GyroProvider();

    SharedPreferences.getInstance().then((value) {
      _prefs = value;

      _smsService = SmsService(
        cyclist: _prefs.getString('username')!,
        recipients: _prefs.getStringList('phonenumber')!,
      );

      gyroProvider.addListener(() async {
        if (gyroProvider.exceededMaximumDuration) {
          final String googleMapLink = await LocationUtil.getCurrentLocation();
          _smsService.send(location: googleMapLink);
        }
      });
    });

    _extCam.addListener((onData) async {
      if (isDetecting) return;

      isDetecting = true;

      await _detector.detect(onData);
      isDetecting = false;
    });
  }

  @override
  void dispose() async {
    super.dispose();
    _extCam.disconnect();
    gyroProvider.stopListening();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: gyroProvider,
      child: Scaffold(
        body: Stack(
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
                        return RotatedBox(
                          quarterTurns: 1,
                          child: CustomPaint(
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
                          ),
                        );
                      },
                    ),
                    RotatedBox(
                      quarterTurns: 1,
                      child: Consumer<GyroProvider>(
                        builder: (context, gyro, child) {
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
                    ),
                    Consumer<GyroProvider>(builder: (context, gyro, child) {
                      return Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: IconButton(
                            onPressed: () {
                              gyro.reset();
                            },
                            icon: Icon(Icons.restart_alt),
                            iconSize: 50,
                          ),
                        ),
                      );
                    }),
                    Consumer<GyroProvider>(builder: (context, gyro, child) {
                      return RotatedBox(
                        quarterTurns: 1,
                        child: Align(
                          alignment: Alignment.center,
                          child: gyro.exceededMaximumDuration
                              ? BlinkText(
                                  'FALL DETECTED. \n SENDING SOS TO CLOSE CONTACT!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 30, color: Colors.white),
                                  beginColor: Colors.white,
                                  endColor: Colors.yellow,
                                  duration: Duration(seconds: 1))
                              : Text(""),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
