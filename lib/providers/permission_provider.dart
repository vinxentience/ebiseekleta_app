import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionProvider extends ChangeNotifier {
  PermissionStatus _location = PermissionStatus.denied;
  PermissionStatus _sms = PermissionStatus.denied;
  String? _lastPermissionRequested;
  PermissionStatus? _lastPermissionRequestedStatus;

  PermissionStatus get location => _location;
  PermissionStatus get sms => _sms;
  String? get lastPermissionRequested => _lastPermissionRequested;
  PermissionStatus? get lastPermissionRequestedStatus =>
      _lastPermissionRequestedStatus;

  Future<void> loadPermissions() async {
    _location = await Permission.location.status;
    _sms = await Permission.sms.status;
    notifyListeners();
  }

  void requestLocationPermission() async {
    _location = await Permission.location.request();
    _lastPermissionRequested = 'Location';
    _lastPermissionRequestedStatus = _location;
    notifyListeners();
  }

  void requestSendSmsPermission() async {
    _sms = await Permission.sms.request();
    _lastPermissionRequested = 'SMS';
    _lastPermissionRequestedStatus = _sms;
    notifyListeners();
  }

  bool isAllPermissionGranted() {
    return _location.isGranted && _sms.isGranted;
  }
}
