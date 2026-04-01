import 'package:shared_preferences/shared_preferences.dart';

class SettingsHelper {
  static Future<void> saveInterval(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('interval', value);
  }

  static Future<int> getInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('interval') ?? 5;
  }

  static Future<void> saveMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mode', mode);
  }

  static Future<String> getMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('mode') ?? 'auto';
  }

  static Future<void> saveNotif(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif', value);
  }

  static Future<bool> getNotif() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notif') ?? true;
  }
}
