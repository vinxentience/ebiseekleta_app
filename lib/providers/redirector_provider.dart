import 'package:flutter/foundation.dart';

enum Screen { onboard, checkPermission, main }

class RedirectorProvider extends ChangeNotifier {
  late Screen _screen;

  RedirectorProvider({Screen initial = Screen.onboard}) {
    _screen = initial;
  }

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
