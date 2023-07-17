import 'dart:ui';

import 'package:ebiseekleta_app/GeoLocation.dart';
import 'package:ebiseekleta_app/Homescreen.dart';
import 'package:ebiseekleta_app/Settingscreen.dart';
import 'package:ebiseekleta_app/camscreen.dart';
import 'package:ebiseekleta_app/check_permission_screen.dart';
import 'package:ebiseekleta_app/network_status_provider.dart';
import 'package:ebiseekleta_app/providers/permission_provider.dart';
import 'package:ebiseekleta_app/providers/redirector_provider.dart';

import 'package:ebiseekleta_app/utils/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

enum Options { none, home, frame, vision, location, setting }

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final permissionProvider = PermissionProvider();

  await permissionProvider.loadPermissions();

  final initialScreen = permissionProvider.isAllPermissionGranted()
      ? Screen.main
      : Screen.checkPermission;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<NetworkStatusProvider>(
          create: (_) => NetworkStatusProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => InternetConnection(),
        ),
        ChangeNotifierProvider.value(value: permissionProvider),
        ChangeNotifierProvider(
          create: (_) => RedirectorProvider(initial: initialScreen),
        ),
      ],
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeProvider().themeMode,
      theme: MyThemes.lightTheme,
      darkTheme: MyThemes.darkTheme,
      home: Consumer<RedirectorProvider>(
        builder: (context, redirector, child) {
          switch (redirector.screen) {
            case Screen.onboard:
              return CheckPermissionScreen();
            case Screen.checkPermission:
              return CheckPermissionScreen();
            case Screen.main:
              return MainScreen();
          }
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  Options option = Options.none;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    Vibration.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<PermissionProvider>().loadPermissions().then((_) {
        if (!context.read<PermissionProvider>().isAllPermissionGranted()) {
          context.read<RedirectorProvider>().changeToCheckPermissionScreen();
        }
      });
    }
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
              final networkStatus = context.read<NetworkStatusProvider>();

              final isGpsEnabled = networkStatus.isGpsEnabled;
              final wifiName = networkStatus.wifiName;

              if (!isGpsEnabled) {
                const snackBar = SnackBar(
                    content: Text('Make sure your mobile GPS is enabled.'));
                ScaffoldMessenger.of(context).showSnackBar(snackBar);

                return;
              }

              if (wifiName == null || wifiName != '"ESP32-CAM-EBISEEKLETA"') {
                const snackBar = SnackBar(
                    content: Text(
                        'Make sure your mobile is connected to "ESP32-CAM-EBISEEKLETA".'));
                ScaffoldMessenger.of(context).showSnackBar(snackBar);

                return;
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
            onTap: () async {
              final networkStatus = context.read<NetworkStatusProvider>();

              await networkStatus.loadAllStatus();

              final isGpsEnabled = networkStatus.isGpsEnabled;
              final isInternetConnected = networkStatus.isInternetConnected;

              if (!isGpsEnabled || !isInternetConnected) {
                const snackBar = SnackBar(
                    content: Text(
                        'Make sure GPS and Internet Connection is enabled.'));
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
                option = Options.home;
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
  }

  Widget task(Options option) {
    switch (option) {
      case Options.frame:
        return const CamScreen();
      case Options.setting:
        return const SetttingScreen();
      case Options.home:
        return const Homepage();
      case Options.location:
        return const GeoLocation();
      default:
        return const Homepage();
    }
  }
}
