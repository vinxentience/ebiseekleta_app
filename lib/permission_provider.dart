import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionProvider extends ChangeNotifier {
  PermissionStatus _location = PermissionStatus.denied;
  PermissionStatus _sms = PermissionStatus.denied;

  PermissionProvider() {}

  void requestLocationPermission() async {
    _location = await Permission.location.request();
    notifyListeners();
  }

  void requestSendSmsPermission() async {
    _sms = await Permission.sms.request();
    notifyListeners();
  }

  PermissionStatus get location => _location;
  PermissionStatus get sms => _sms;
}
