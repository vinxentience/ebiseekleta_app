import 'dart:async';

import 'package:ebiseekleta_app/main.dart';
import 'package:ebiseekleta_app/providers/permission_provider.dart';
import 'package:ebiseekleta_app/providers/redirector_provider.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class CheckPermissionScreen extends StatefulWidget {
  const CheckPermissionScreen({super.key});

  @override
  State<CheckPermissionScreen> createState() => _CheckPermissionScreenState();
}

class _CheckPermissionScreenState extends State<CheckPermissionScreen>
    with WidgetsBindingObserver {
  late PermissionProvider _permissionProvider;
  Timer? timer;
  @override
  void initState() {
    super.initState();
    _permissionProvider = context.read<PermissionProvider>();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _permissionProvider.loadPermissions().then((_) {
        if (_permissionProvider.isAllPermissionGranted()) {
          //context.read<RedirectorProvider>().changeToMainScreen();
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => MainScreen()));
        }
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<PermissionProvider>(
          builder: (context, permission, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Spacer(),
                Image.asset(
                  'assets/logo.png',
                  scale: 1.5,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        leading: Icon(Icons.location_on),
                        title: Text(
                          'Location Permission: ${permission.location.isGranted}',
                          style: TextStyle(fontSize: 20),
                        ),
                        trailing: Icon(
                          permission.location.isGranted
                              ? Icons.check
                              : Icons.close,
                          color: permission.location.isGranted
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      ListTile(
                        leading: Icon(Icons.sms),
                        title: Text(
                          'Send SMS Permission: ${permission.sms.isGranted}',
                        ),
                        trailing: Icon(
                          permission.sms.isGranted ? Icons.check : Icons.close,
                          color: permission.sms.isGranted
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          permission.requestLocationPermission().then((_) {
                            if (_permissionProvider.location.isDenied) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Location Permission Denied.'
                                    ' Please try again.',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                            if (_permissionProvider
                                .location.isPermanentlyDenied) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Location Permission Permanently Denied.'
                                    ' Please enable it in app settings.',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          });
                        },
                        child: Text('Request Location Permission'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await permission.requestSendSmsPermission();
                        },
                        child: Text('Request Send SMS Permission'),
                      ),
                      // go do settings
                      ElevatedButton(
                        onPressed: () {
                          openAppSettings();
                        },
                        child: Text('Go to Settings'),
                      ),
                    ],
                  ),
                ),
                Spacer(),
              ],
            );
          },
        ),
      ),
    );
  }
}
