import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionProvider extends ChangeNotifier {
  PermissionStatus _location = PermissionStatus.denied;
  PermissionStatus _sms = PermissionStatus.denied;

  PermissionStatus get location => _location;
  PermissionStatus get sms => _sms;

  void loadPermissions() async {
    _location = await Permission.location.status;
    _sms = await Permission.sms.status;
    notifyListeners();
  }

  void requestAllPermission() async {
    _location = await Permission.location.request();
    _sms = await Permission.sms.request();
    notifyListeners();
  }

  void requestLocationPermission() async {
    _location = await Permission.location.request();
    notifyListeners();
  }

  void requestSendSmsPermission() async {
    _sms = await Permission.sms.request();
    notifyListeners();
  }

  bool isAllPermissionGranted() {
    return _location.isGranted && _sms.isGranted;
  }
}
