import 'package:flutter/foundation.dart';

enum Screen { onboard, checkPermission, main }

class RedirectorProvider extends ChangeNotifier {
  Screen _screen = Screen.onboard;

  Screen get screen => _screen;

  void changeToOnboardScreen() {
    _screen = Screen.onboard;
    notifyListeners();
  }

  void changeToCheckPermissionScreen() {
    _screen = Screen.checkPermission;
    notifyListeners();
  }

  void changeToMainScreen() {
    _screen = Screen.main;
    notifyListeners();
  }
}
