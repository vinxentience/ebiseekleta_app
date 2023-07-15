import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionProvider extends ChangeNotifier {
  bool _isLocationGranted = false;
  bool _isSendSmsGranted = false;

  PermissionProvider() {}

  void requestLocationPermission() async {
    final status = await Permission.location.request();

    _isLocationGranted = status.isGranted;
    notifyListeners();
  }

  void requestSendSmsPermission() async {
    final status = await Permission.sms.request();

    _isSendSmsGranted = status.isGranted;
    notifyListeners();
  }

  bool get isLocationGranted => _isLocationGranted;
  bool get isSendSmsGranted => _isSendSmsGranted;
}
