import 'package:geolocator/geolocator.dart';

abstract class LocationUtil {
  static Future<String> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return 'https://www.google.com/maps/?q=${position.latitude},${position.longitude}';
  }
}
