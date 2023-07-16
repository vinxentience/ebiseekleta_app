import 'package:flutter/foundation.dart';

enum Screen { onboard, checkPermission, main }

class RedirectorProvider extends ChangeNotifier {
  Screen _screen = Screen.onboard;

  Screen get screen => _screen;

  set screen(Screen value) {
    _screen = value;
    notifyListeners();
  }
}
