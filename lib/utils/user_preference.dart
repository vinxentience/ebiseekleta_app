import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static SharedPreferences? _preferences;
  static const _isVisited = 'visited';
  static const _keyCyclistName = 'username';
  static const _keyPhoneNumber = 'phonenumber';

  static Future<SharedPreferences> init() async =>
      await SharedPreferences.getInstance();

  static Future setName(String username) async =>
      await _preferences?.setString(_keyCyclistName, username);

  static String? getName() => _preferences?.getString(_keyCyclistName);

  static Future setPhoneNumber(List<String> phoneNumber) async =>
      await _preferences?.setStringList(_keyPhoneNumber, phoneNumber);

  static List<String>? getPhoneNumber() =>
      _preferences?.getStringList(_keyPhoneNumber);

  static Future setVisited(bool visitation) async =>
      await _preferences?.setBool(_isVisited, visitation);

  static bool? getVisited() => _preferences?.getBool(_isVisited);
}
