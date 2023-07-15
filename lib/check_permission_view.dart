import 'package:ebiseekleta_app/permission_provider.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class CheckPermissionView extends StatefulWidget {
  const CheckPermissionView({super.key});

  @override
  State<CheckPermissionView> createState() => _CheckPermissionViewState();
}

class _CheckPermissionViewState extends State<CheckPermissionView> {
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
    return Consumer<PermissionProvider>(builder: (context, permission, _) {
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
              color: permission.location.isGranted ? Colors.green : Colors.red,
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
    });
  }

  void _onPermissionDenied() {
    if (_permissionProvider.location == PermissionStatus.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location Permission Denied. Please try again.'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    if (_permissionProvider.location == PermissionStatus.permanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location Permission Permanently Denied.'
            ' Please go to Settings and enable the Location Permission.',
          ),
          duration: Duration(seconds: 1),
        ),
      );
    }

    if (_permissionProvider.sms == PermissionStatus.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Send SMS Permission Denied. Please try again.'),
          duration: Duration(seconds: 1),
        ),
      );
    }

    if (_permissionProvider.sms == PermissionStatus.permanentlyDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Send SMS Permission Permanently Denied.'
            ' Please go to Settings and enable the Send SMS Permission.',
          ),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}
