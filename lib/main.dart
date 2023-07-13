import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ebiseekleta_app/GeoLocation.dart';
import 'package:ebiseekleta_app/Homescreen.dart';
import 'package:ebiseekleta_app/OnboardingScreen.dart';
import 'package:ebiseekleta_app/Settingscreen.dart';
import 'package:ebiseekleta_app/camscreen.dart';
import 'package:ebiseekleta_app/utils/globals.dart';
import 'package:ebiseekleta_app/utils/theme_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:developer' as developer;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

enum Options { none, home, frame, vision, location, setting }

int? isViewed;

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  isViewed = prefs.getInt('onBoard');

  Globals.init();
  runApp(
    ChangeNotifierProvider(
      create: (context) => InternetConnection(),
      child: MaterialApp(
        themeMode: ThemeProvider().themeMode,
        theme: MyThemes.lightTheme,
        darkTheme: MyThemes.darkTheme,
        debugShowCheckedModeBanner: false,
        home: isViewed != 0 ? OnboardingScreen() : MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Connectivity _connectivity = Connectivity();
  final NetworkInfo _networkInfo = NetworkInfo();

  late final SharedPreferences _prefs;

  Options option = Options.none;

  ConnectivityResult _connectivityResult = ConnectivityResult.none;
  bool _isGpsEnabled = false;
  bool _isInternetConnected = false;
  String? _wifiName;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    initPrefs();

    Timer.periodic(new Duration(milliseconds: 500), (timer) async {
      await _checkGps();
      await _checkInternetConnection();
      await _checkWifiName();
      await _checkConnectivityResult();
      setState(() {});
    });

    Vibration.cancel();
  }

  void initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
              onTap: () async {
                if (!_isGpsEnabled) {
                  const snackBar = SnackBar(
                      content: Text('Make sure your mobile GPS is enabled.'));
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);

                  return null;
                }

                if (_wifiName == null) {
                  _wifiName = await getWifiName();
                }

                if (_wifiName != '"ESP32-CAM-EBISEEKLETA"') {
                  const snackBar = SnackBar(
                      content: Text(
                          'Make sure your mobile is connected to "ESP32-CAM-EBISEEKLETA".'));
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);

                  return null;
                }

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
                if (!_isGpsEnabled || !_isInternetConnected) {
                  const snackBar = SnackBar(
                      content: Text(
                          'Make sure GPS and Internet Connection is enabled.'));
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);

                  return;
                }

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
                if (mounted) {
                  setState(() {
                    option = Options.home;
                  });
                }
              },
            ),
          ],
        ),
      );

  Future<void> _checkGps() async {
    _isGpsEnabled = await Geolocator.isLocationServiceEnabled();
    _prefs.setBool('gpsstat', _isGpsEnabled);
  }

  Future<void> _checkInternetConnection() async {
    try {
      var result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _isInternetConnected = true;
      } else {
        _isInternetConnected = false;
      }
    } on SocketException catch (_) {
      _isInternetConnected = false;
    }
    _prefs.setBool('internetstat', _isInternetConnected);
  }

  Future<String?> getWifiName() async {
    String? wifiName;

    try {
      if (!kIsWeb && Platform.isIOS) {
        // ignore: deprecated_member_use
        var status = await _networkInfo.getLocationServiceAuthorization();
        if (status == LocationAuthorizationStatus.notDetermined) {
          // ignore: deprecated_member_use
          status = await _networkInfo.requestLocationServiceAuthorization();
        }
        if (status == LocationAuthorizationStatus.authorizedAlways ||
            status == LocationAuthorizationStatus.authorizedWhenInUse) {
          wifiName = await _networkInfo.getWifiName();
        } else {
          wifiName = await _networkInfo.getWifiName();
        }
      } else {
        wifiName = await _networkInfo.getWifiName();
      }
    } on PlatformException catch (e) {
      developer.log('Failed to get Wifi Name', error: e);
      wifiName = 'Failed to get Wifi Name';
    }
    return wifiName;
  }

  Future<void> _checkWifiName() async {
    String? wifiName = await getWifiName();

    _wifiName = wifiName ?? _wifiName ?? 'null';

    _prefs.setString('wifistat', _wifiName!);
  }

  Future<void> _checkConnectivityResult() async {
    ConnectivityResult? result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print(e.toString());
    }

    _connectivityResult = result ?? _connectivityResult;

    _prefs.setInt('connectivityResult', _connectivityResult.index);

    // if (Platform.isAndroid) {
    //   print('Checking Android permissions');
    //   var status = await Permission.location.status;
    //   // Blocked?
    //   if (status.isDenied || status.isRestricted) {
    //     // Ask the user to unblock
    //     if (await Permission.location.request().isGranted) {
    //       // Either the permission was already granted before or the user just granted it.
    //       print('Location permission granted');
    //     } else {
    //       print('Location permission not granted');
    //     }
    //   } else {
    //     print('Permission already granted (previous execution?)');
    //   }
    // }
  }

  Widget task(Options option) {
    if (option == Options.frame) {
      return const CamScreen();
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
}
//   _ConnectWebSocket() {
//     Future.delayed(const Duration(milliseconds: 100)).then((_) {
//       Navigator.pushReplacement(context,
//           MaterialPageRoute(builder: (BuildContext context) => CamScreen()));
//     });
//   }
// }
