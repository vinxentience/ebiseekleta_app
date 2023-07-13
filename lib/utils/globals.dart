import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class Globals {
  static final _info = NetworkInfo();
  static late final InternetConnectionChecker internetChecker;
  static late final SharedPreferences prefs;

  static void init() async {
    internetChecker = InternetConnectionChecker.createInstance(
      checkInterval: Duration(milliseconds: 500),
    );
    prefs = await SharedPreferences.getInstance();
  }
}
