import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:network_info_plus/network_info_plus.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.light;
  bool get isDarkMode => themeMode == ThemeMode.dark;
  void toggleTheme(bool isOn) {
    themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class MyThemes {
  static final darkTheme = ThemeData(
    scaffoldBackgroundColor: Colors.grey.shade900,
    primaryColor: Colors.black,
    colorScheme: ColorScheme.dark(),
    iconTheme: IconThemeData(color: Colors.blueAccent.shade200, opacity: 0.8),
  );

  static final lightTheme = ThemeData(
    scaffoldBackgroundColor: Colors.white,
    primaryColor: Colors.white,
    colorScheme: ColorScheme.light(),
    iconTheme: IconThemeData(color: Colors.white30, opacity: 0.8),
  );
}

class InternetConnection extends ChangeNotifier {
  bool isConnected = false;
  String connectedWifiName = '';
  InternetConnectionChecker _checker = InternetConnectionChecker();
  final _info = NetworkInfo();

  ChangeNotifier() {
    setWifiName();
    _checker.onStatusChange.listen((event) async {
      final isConnected = event == InternetConnectionStatus.connected;

      if (isConnected) {
        setWifiName();
      }

      notifyListeners();
    });
  }

  void setWifiName() async {
    connectedWifiName = (await _info.getWifiName()) ?? '';
  }
}
