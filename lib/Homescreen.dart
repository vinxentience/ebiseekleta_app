import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ebiseekleta_app/utils/globals.dart';
import 'package:flutter/material.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  ConnectivityResult connectivityStatus = ConnectivityResult.none;
  String? wifiName;

  bool isGPSenabled = false;
  bool isInternetConnected = false;

  bool? gpsstat, internetstat;
  String? wifistat;

  late Timer networkTimer;

  @override
  void initState() {
    super.initState();
    networkTimer = Timer.periodic(
        new Duration(milliseconds: 500), (_) async => getNetworkStatus());
  }

  void getNetworkStatus() {
    isGPSenabled = Globals.prefs.getBool('gpsstat') ?? false;
    isInternetConnected = Globals.prefs.getBool('internetstat') ?? false;
    wifiName = Globals.prefs.getString('wifistat') ?? "null";
    connectivityStatus = Globals.prefs.getInt('connectivityResult') == null
        ? ConnectivityResult.none
        : ConnectivityResult
            .values[Globals.prefs.getInt('connectivityResult')!];
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    networkTimer.cancel();
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
          leading: (connectivityStatus == ConnectivityResult.wifi) ||
                  (connectivityStatus == ConnectivityResult.mobile)
              ? const Icon(
                  Icons.check,
                  color: Colors.green,
                )
              : const Icon(
                  Icons.close,
                  color: Colors.red,
                ),
          title: Text('Connection Status: ${connectivityStatus.toString()}'),
        ),
        ListTile(
          leading: wifiName != "null"
              ? const Icon(
                  Icons.check,
                  color: Colors.green,
                )
              : const Icon(
                  Icons.close,
                  color: Colors.red,
                ),
          title: Text(
              "Connected To: ${wifiName == "null" ? "WIFI or GPS is disabled" : wifiName}"),
        ),
        ListTile(
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
        ),
        ListTile(
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
        ),
      ],
    ));
  }
}
