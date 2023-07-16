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

  Stream<void> _periodicStream =
      Stream.periodic(const Duration(seconds: 1), (value) => print(value))
          .asBroadcastStream();

  StreamSubscription? _geolocatorSub;
  StreamSubscription? _connectivitySub;
  StreamSubscription? _wifiNameSub;

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
  }

  bool get isGpsEnabled => _isGpsEnabled;
  bool get isInternetConnected => _isInternetConnected;
  ConnectivityResult get connectivityResult => _connectivityResult;
  String? get wifiName => _wifiName;

  void startListeningToChanges() async {
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
    _geolocatorSub = Geolocator.getServiceStatusStream().listen(_onGpsChanged);
    _wifiNameSub = _periodicStream.listen((_) => _updateWifiName());
  }

  Future<void> stopListeningToChanges() async {
    await _connectivitySub?.cancel();
    await _geolocatorSub?.cancel();
    await _wifiNameSub?.cancel();

    _connectivitySub = null;
    _geolocatorSub = null;
    _wifiNameSub = null;
  }

  void _onGpsChanged(event) async {
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
  }

  void _onConnectivityChanged(event) async {
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
  }

  void _updateWifiName() {
    NetworkUtil.getWifiName().then((value) {
      _wifiName = value;
      notifyListeners();
    });
  }

  @override
  void dispose() async {
    super.dispose();
    await stopListeningToChanges();
  }
}
