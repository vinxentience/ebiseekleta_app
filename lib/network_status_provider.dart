import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ebiseekleta_app/utils/network_util.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';

class NetworkStatusProvider extends ChangeNotifier {
  bool _isGpsEnabled = false;
  bool _isInternetConnected = false;
  ConnectivityResult _connectivityResult = ConnectivityResult.none;
  String? _wifiName;

  late StreamSubscription _geolocatorSub;
  late StreamSubscription _connectivitySub;
  late StreamSubscription _wifiNameSub;

  NetworkStatusProvider() {
    NetworkUtil.isGpsEnabled().then((value) {
      _isGpsEnabled = value;
      notifyListeners();
    });

    NetworkUtil.getConnectivityResult().then((value) {
      _connectivityResult = value;
      notifyListeners();
    });

    NetworkUtil.getWifiName().then((value) {
      _wifiName = value;
      notifyListeners();
    });

    NetworkUtil.isInternetConnected().then((value) {
      _isInternetConnected = value;
      notifyListeners();
    });

    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((event) async {
      _connectivityResult = event;

      if (_connectivityResult != ConnectivityResult.none) {
        NetworkUtil.isInternetConnected().then((value) {
          _isInternetConnected = value;
          notifyListeners();
        });
        NetworkUtil.getWifiName().then((value) {
          _wifiName = value;
          notifyListeners();
        });
      }

      if (_connectivityResult == ConnectivityResult.none) {
        _isInternetConnected = false;
        _wifiName = null;
      }

      notifyListeners();
    });

    _geolocatorSub = Geolocator.getServiceStatusStream().listen((event) async {
      _isGpsEnabled = event == ServiceStatus.enabled;

      NetworkUtil.isInternetConnected().then((value) {
        _isInternetConnected = value;
        notifyListeners();
      });
      NetworkUtil.getWifiName().then((value) {
        _wifiName = value;
        notifyListeners();
      });

      notifyListeners();
    });

    // wifiName
    _wifiNameSub =
        Stream.periodic(const Duration(seconds: 1)).listen((event) async {
      NetworkUtil.getWifiName().then((value) {
        _wifiName = value;
        notifyListeners();
      });
    });
  }

  bool get isGpsEnabled => _isGpsEnabled;
  bool get isInternetConnected => _isInternetConnected;
  ConnectivityResult get connectivityResult => _connectivityResult;
  String? get wifiName => _wifiName;

  @override
  void dispose() async {
    super.dispose();
    await _connectivitySub.cancel();
    await _geolocatorSub.cancel();
    await _wifiNameSub.cancel();
  }
}
