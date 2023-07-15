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
  late PermissionProvider _permissionProvider;

  @override
  void initState() {
    super.initState();

    _permissionProvider = context.read<PermissionProvider>()
      ..addListener(_onPermissionDenied);
  }

  @override
  void dispose() {
    super.dispose();

    context.read<PermissionProvider>().removeListener(_onPermissionDenied);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<PermissionProvider>(builder: (context, permission, _) {
          return Column(
            children: [
              ListTile(
                leading: Icon(Icons.location_on),
                title: Text(
                  'Location Permission: ${permission.location.isGranted}',
                  style: TextStyle(fontSize: 20),
                ),
                trailing: Icon(
                  permission.location.isGranted ? Icons.check : Icons.close,
                  color:
                      permission.location.isGranted ? Colors.green : Colors.red,
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
          );
        }),
      ),
    );
  }

  void _onPermissionDenied() {
    if (_permissionProvider.lastPermissionRequested == null) return;

    if (_permissionProvider.lastPermissionRequestedStatus ==
        PermissionStatus.granted) return;

    if (_permissionProvider.lastPermissionRequestedStatus ==
        PermissionStatus.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_permissionProvider.lastPermissionRequested} Permission Denied.'
            ' Please try again.',
          ),
          duration: Duration(seconds: 1),
        ),
      );
    }

    if (_permissionProvider.lastPermissionRequestedStatus ==
        PermissionStatus.permanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_permissionProvider.lastPermissionRequested} Permission Permanently Denied.'
            ' Please go to Settings and enable the ${_permissionProvider.lastPermissionRequested} Permission.',
          ),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}
