import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'dart:developer' as dev;

abstract class NetworkUtil {
  static final _networkInfo = NetworkInfo();
  static final _connectivity = Connectivity();

  static Future<bool> isGpsEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<bool> isInternetConnected() async {
    try {
      var result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } on SocketException catch (_) {
      return false;
    }

    return false;
  }

  static Future<String?> getWifiName() async {
    String? wifiName;

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
      dev.log('Failed to get Wifi Name', error: e);
      wifiName = 'Failed to get Wifi Name';
    }
    return wifiName;
  }

  static Future<ConnectivityResult> getConnectivityResult() async {
    try {
      return await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print(e.toString());
    }

    // if (Platform.isAndroid) {
    //   print('Checking Android permissions');
    //   var status = await Permission.location.status;
    //   // Blocked?
    //   if (status.isDenied || status.isRestricted) {
    //     // Ask the user to unblock
    //     if (await Permission.location.request().isGranted) {
    //       // Either the permission was already granted before or the user just granted it.
    //       print('Location permission granted');
    //     } else {
    //       print('Location permission not granted');
    //     }
    //   } else {
    //     print('Permission already granted (previous execution?)');
    //   }
    // }

    return ConnectivityResult.none;
  }
}
