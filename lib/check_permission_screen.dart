import 'package:ebiseekleta_app/permission_provider.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class CheckPermissionScreen extends StatefulWidget {
  const CheckPermissionScreen({super.key});

  @override
  State<CheckPermissionScreen> createState() => _CheckPermissionScreenState();
}

class _CheckPermissionScreenState extends State<CheckPermissionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<PermissionProvider>(builder: (context, permission, _) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text(
                    'Location Permission: ${permission.location.isGranted}',
                    style: TextStyle(fontSize: 20),
                  ),
                  trailing: Icon(
                    permission.location.isGranted ? Icons.check : Icons.close,
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
                    color: permission.sms.isGranted ? Colors.green : Colors.red,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    permission.requestLocationPermission();
                  },
                  child: Text('Request Location Permission'),
                ),
                ElevatedButton(
                  onPressed: () {
                    permission.requestSendSmsPermission();
                  },
                  child: Text('Request Send SMS Permission'),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
