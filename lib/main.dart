import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:ebiseekleta_app/GeoLocation.dart';
import 'package:ebiseekleta_app/Homescreen.dart';
import 'package:ebiseekleta_app/OnboardSetting.dart';
import 'package:ebiseekleta_app/OnboardingScreen.dart';
import 'package:ebiseekleta_app/Settingscreen.dart';
import 'package:ebiseekleta_app/YoloVideo.dart';
import 'package:ebiseekleta_app/utils/user_preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

enum Options { none, home, frame, vision, location, setting }

int? isViewed;

late List<CameraDescription> cameras;
main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  isViewed = prefs.getInt('onBoard');
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isViewed != 0 ? OnboardingScreen() : MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Options option = Options.none;
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    Vibration.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: task(option),
      floatingActionButton: SpeedDial(
        //margin bottom
        icon: Icons.menu, //icon on Floating action button
        activeIcon: Icons.close, //icon when menu is expanded on button
        backgroundColor: Colors.black12, //background color of button
        foregroundColor: Colors.white, //font color, icon color in button
        activeBackgroundColor:
            Colors.deepPurpleAccent, //background color when menu is expanded
        activeForegroundColor: Colors.white,
        visible: true,
        closeManually: false,
        curve: Curves.bounceIn,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        buttonSize: const Size(56.0, 56.0),
        children: [
          SpeedDialChild(
            //speed dial child
            child: const Icon(Icons.settings),
            backgroundColor: Colors.amber,
            foregroundColor: Colors.white,
            label: 'Settings',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () {
              setState(() {
                option = Options.setting;
              });
            },
          ),
          SpeedDialChild(
            //speed dial child
            child: const Icon(Icons.video_call),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            label: 'Live View',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () {
              setState(() {
                option = Options.frame;
              });
            },
          ),
          SpeedDialChild(
            //speed dial child
            child: const Icon(Icons.gps_fixed),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            label: 'Geolocation',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () {
              setState(() {
                option = Options.location;
              });
            },
          ),
          SpeedDialChild(
            child: const Icon(Icons.home),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            label: 'Home',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () {
              setState(() {
                option = Options.home;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget task(Options option) {
    if (option == Options.frame) {
      return const YoloVideo();
    }
    if (option == Options.setting) {
      return const SetttingScreen();
    }
    if (option == Options.home) {
      return const Homepage();
    }
    if (option == Options.location) {
      return const GeoLocation();
    }
    return const Homepage();
  }

  //   _ConnectWebSocket() {
  //   Future.delayed(Duration(milliseconds: 100)).then((_) {
  //     Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(
  //             builder: (BuildContext context) => MyHomePage(
  //                   channel:
  //                       IOWebSocketChannel.connect('ws://192.168.4.1:8888'),
  //                 )));
  //   });
  // }
}
