import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  String? wifiName,
      wifiBSSID,
      wifiIPv4,
      wifiIPv6,
      wifiGatewayIP,
      wifiBroadcast,
      wifiSubmask;
  String _networkInfoStatus = 'Unknown';
  String _WifiSSID = "";
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  final StreamController<bool> _gpsStatus = StreamController<bool>();
  final StreamController<String> _wifiNameStatus = StreamController<String>();
  final StreamController<bool> _internetStatus = StreamController<bool>();
  final NetworkInfo _networkInfo = NetworkInfo();
  bool _wifiStatus = false;
  bool isGPSenabled = false;
  bool isInternetConnected = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _initNetworkInfo();
    _checkGps();
    checkConnection();
    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _gpsStatus.close();
    _internetStatus.close();
    _wifiNameStatus.close();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initConnectivity() async {
    ConnectivityResult? result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print(e.toString());
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return Future.value(null);
    }

    if (Platform.isAndroid) {
      print('Checking Android permissions');
      var status = await Permission.location.status;
      // Blocked?
      if (status.isDenied || status.isRestricted) {
        // Ask the user to unblock
        if (await Permission.location.request().isGranted) {
          // Either the permission was already granted before or the user just granted it.
          print('Location permission granted');
        } else {
          print('Location permission not granted');
        }
      } else {
        print('Permission already granted (previous execution?)');
      }
    }

    return _updateConnectionStatus(result!);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/logo.png',
          scale: 1.5,
        ),
        const SizedBox(
          height: 10,
        ),
        ListTile(
          leading: const Icon(
            Icons.check,
            color: Colors.green,
          ),
          title: Text('Connection Status: ${_connectionStatus.toString()}'),
        ),
        StreamBuilder(
            initialData: "",
            stream: _wifiNameStatus.stream,
            builder: (context, snapshot) {
              return ListTile(
                leading: wifiName != null
                    ? const Icon(
                        Icons.check,
                        color: Colors.green,
                      )
                    : const Icon(
                        Icons.close,
                        color: Colors.red,
                      ),
                title: Text("Connected To: $wifiName"),
              );
            }),
        StreamBuilder(
            initialData: false,
            stream: _gpsStatus.stream,
            builder: (context, snapshot) {
              return ListTile(
                leading: isGPSenabled
                    ? const Icon(
                        Icons.check,
                        color: Colors.green,
                      )
                    : const Icon(
                        Icons.close,
                        color: Colors.red,
                      ),
                title: Text("GPS enabled: $isGPSenabled"),
              );
            }),
        StreamBuilder(
            initialData: false,
            stream: _internetStatus.stream,
            builder: (context, snapshot) {
              return ListTile(
                leading: isInternetConnected
                    ? const Icon(
                        Icons.check,
                        color: Colors.green,
                      )
                    : const Icon(
                        Icons.close,
                        color: Colors.red,
                      ),
                title: Text("Internet Connection: $isInternetConnected"),
              );
            }),
      ],
    ));
  }

  void _checkGps() async {
    Timer.periodic(Duration(milliseconds: 500), (timer) async {
      if (!_gpsStatus.isClosed) {
        isGPSenabled = await Geolocator.isLocationServiceEnabled();
        _gpsStatus.sink.add(isGPSenabled);
      } else {
        _gpsStatus.close();
      }
    });
  }

  Future<void> checkConnection() async {
    Timer.periodic(Duration(milliseconds: 500), (timer) async {
      try {
        var result = await InternetAddress.lookup('google.com');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          isInternetConnected = true;
          _internetStatus.add(isInternetConnected);
        } else {
          isInternetConnected = false;
          _internetStatus.add(isInternetConnected);
          _internetStatus.close();
        }
      } on SocketException catch (_) {
        isInternetConnected = false;
        _internetStatus.add(isInternetConnected);
        _internetStatus.close();
      }
    });
  }

  Future<void> _initNetworkInfo() async {
    Timer.periodic(Duration(milliseconds: 500), (timer) async {
      try {
        if (!kIsWeb && Platform.isIOS) {
          // ignore: deprecated_member_use
          var status = await _networkInfo.getLocationServiceAuthorization();
          if (status == LocationAuthorizationStatus.notDetermined) {
            // ignore: deprecated_member_use
            status = await _networkInfo.requestLocationServiceAuthorization();
          }
          if (status == LocationAuthorizationStatus.authorizedAlways ||
              status == LocationAuthorizationStatus.authorizedWhenInUse) {
            wifiName = await _networkInfo.getWifiName();
          } else {
            wifiName = await _networkInfo.getWifiName();
          }
        } else {
          wifiName = await _networkInfo.getWifiName();
        }
      } on PlatformException catch (e) {
        developer.log('Failed to get Wifi Name', error: e);
        wifiName = 'Failed to get Wifi Name';
      }

      try {
        if (!kIsWeb && Platform.isIOS) {
          // ignore: deprecated_member_use
          var status = await _networkInfo.getLocationServiceAuthorization();
          if (status == LocationAuthorizationStatus.notDetermined) {
            // ignore: deprecated_member_use
            status = await _networkInfo.requestLocationServiceAuthorization();
          }
          if (status == LocationAuthorizationStatus.authorizedAlways ||
              status == LocationAuthorizationStatus.authorizedWhenInUse) {
            wifiBSSID = await _networkInfo.getWifiBSSID();
          } else {
            wifiBSSID = await _networkInfo.getWifiBSSID();
          }
        } else {
          wifiBSSID = await _networkInfo.getWifiBSSID();
        }
      } on PlatformException catch (e) {
        developer.log('Failed to get Wifi BSSID', error: e);
        wifiBSSID = 'Failed to get Wifi BSSID';
      }

      try {
        wifiIPv4 = await _networkInfo.getWifiIP();
      } on PlatformException catch (e) {
        developer.log('Failed to get Wifi IPv4', error: e);
        wifiIPv4 = 'Failed to get Wifi IPv4';
      }

      try {
        if (!Platform.isWindows) {
          wifiIPv6 = await _networkInfo.getWifiIPv6();
        }
      } on PlatformException catch (e) {
        developer.log('Failed to get Wifi IPv6', error: e);
        wifiIPv6 = 'Failed to get Wifi IPv6';
      }

      try {
        if (!Platform.isWindows) {
          wifiSubmask = await _networkInfo.getWifiSubmask();
        }
      } on PlatformException catch (e) {
        developer.log('Failed to get Wifi submask address', error: e);
        wifiSubmask = 'Failed to get Wifi submask address';
      }

      try {
        if (!Platform.isWindows) {
          wifiBroadcast = await _networkInfo.getWifiBroadcast();
        }
      } on PlatformException catch (e) {
        developer.log('Failed to get Wifi broadcast', error: e);
        wifiBroadcast = 'Failed to get Wifi broadcast';
      }

      try {
        if (!Platform.isWindows) {
          wifiGatewayIP = await _networkInfo.getWifiGatewayIP();
        }
      } on PlatformException catch (e) {
        developer.log('Failed to get Wifi gateway address', error: e);
        wifiGatewayIP = 'Failed to get Wifi gateway address';
      }
      if (!_wifiNameStatus.isClosed) {
        if (wifiName != null) {
          _wifiNameStatus.sink.add(wifiName!);
        } else {
          _wifiNameStatus.close();
        }
      }
    });
  }
}
