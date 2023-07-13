import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ebiseekleta_app/utils/network_util.dart';
import 'package:flutter/material.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
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
          StreamBuilder<ConnectivityResult>(
            stream: NetworkUtil.connectivityResultStream,
            builder: (context, snapshot) {
              final result = snapshot.data ?? 'Loading...';

              return ListTile(
                leading: (result == ConnectivityResult.wifi) ||
                        (result == ConnectivityResult.mobile)
                    ? const Icon(
                        Icons.check,
                        color: Colors.green,
                      )
                    : const Icon(
                        Icons.close,
                        color: Colors.red,
                      ),
                title: Text('Connection Status: $result'),
              );
            },
          ),
          StreamBuilder<String?>(
            stream: NetworkUtil.wifiNameStream,
            builder: (context, snapshot) {
              final wifiName = snapshot.data;

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
                title: Text(snapshot.connectionState == ConnectionState.waiting
                    ? 'Loading...'
                    : "Connected To: ${wifiName ?? 'WIFI or GPS is disabled'}"),
              );
            },
          ),
          FutureBuilder<bool>(
            future: NetworkUtil.isGpsEnabled(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListTile(
                    leading: const CircularProgressIndicator(),
                    title: Text("GPS enabled: Loading..."));
              }

              return StreamBuilder<bool>(
                  initialData: snapshot.data ?? false,
                  stream: NetworkUtil.isGpsEnabledStream,
                  builder: (context, snapshot) {
                    return ListTile(
                      leading: snapshot.data == true
                          ? const Icon(
                              Icons.check,
                              color: Colors.green,
                            )
                          : const Icon(
                              Icons.close,
                              color: Colors.red,
                            ),
                      title: Text("GPS enabled: ${snapshot.data == true}"),
                    );
                  });
            },
          ),
          StreamBuilder<bool>(
            stream: NetworkUtil.isInternetConnectedStream,
            builder: (context, snapshot) {
              final isInternetConnected = snapshot.data ?? false;
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
            },
          ),
        ],
      ),
    );
  }
}
