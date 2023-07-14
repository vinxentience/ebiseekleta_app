import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ebiseekleta_app/network_status_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child:
          Consumer<NetworkStatusProvider>(builder: (context, networkStatus, _) {
        return Column(
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
              leading: (networkStatus.connectivityResult ==
                          ConnectivityResult.wifi) ||
                      (networkStatus.connectivityResult ==
                          ConnectivityResult.mobile)
                  ? const Icon(
                      Icons.check,
                      color: Colors.green,
                    )
                  : const Icon(
                      Icons.close,
                      color: Colors.red,
                    ),
              title: Text(
                  'Connection Status: ${networkStatus.connectivityResult}'),
            ),
            ListTile(
              leading: networkStatus.wifiName != null
                  ? const Icon(
                      Icons.check,
                      color: Colors.green,
                    )
                  : const Icon(
                      Icons.close,
                      color: Colors.red,
                    ),
              title: Text(
                  "Connected To: ${networkStatus.wifiName ?? 'WIFI or GPS is disabled'}"),
            ),
            ListTile(
              leading: networkStatus.isGpsEnabled
                  ? const Icon(
                      Icons.check,
                      color: Colors.green,
                    )
                  : const Icon(
                      Icons.close,
                      color: Colors.red,
                    ),
              title: Text("GPS enabled: ${networkStatus.isGpsEnabled}"),
            ),
            ListTile(
              leading: networkStatus.isInternetConnected
                  ? const Icon(
                      Icons.check,
                      color: Colors.green,
                    )
                  : const Icon(
                      Icons.close,
                      color: Colors.red,
                    ),
              title: Text(
                  "Internet Connection: ${networkStatus.isInternetConnected}"),
            ),
          ],
        );
      }),
    );
  }
}
