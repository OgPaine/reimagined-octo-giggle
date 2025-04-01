import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UsageCollector {
  static const String _appOpenKey = 'appOpenCount';
  static const String _appOpenTimestampsKey = 'appOpenCount_timestamps';
  static const String _buttonPressKey = 'buttonPressCount';
  static const String _buttonPressDetailsKey = 'buttonPressDetails';

  /// Call this method when the app is opened.
  static Future<void> recordAppOpen() async {
    final prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt(_appOpenKey) ?? 0;
    count++;
    await prefs.setInt(_appOpenKey, count);

    // Record the timestamp of the app open.
    List<String> timestamps = prefs.getStringList(_appOpenTimestampsKey) ?? [];
    timestamps.add(DateTime.now().toIso8601String());
    await prefs.setStringList(_appOpenTimestampsKey, timestamps);
  }

  /// Call this method whenever a button is pressed.
  /// [buttonId] is an optional identifier for which button was pressed.
  static Future<void> recordButtonPress({String? buttonId}) async {
    final prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt(_buttonPressKey) ?? 0;
    count++;
    await prefs.setInt(_buttonPressKey, count);

    // Record detailed info for this press.
    List<Map<String, String>> details = [];
    String? storedDetails = prefs.getString(_buttonPressDetailsKey);
    if (storedDetails != null) {
      details = List<Map<String, String>>.from(jsonDecode(storedDetails));
    }
    details.add({
      'timestamp': DateTime.now().toIso8601String(),
      'buttonId': buttonId ?? 'unknown',
    });
    await prefs.setString(_buttonPressDetailsKey, jsonEncode(details));
  }

  /// Retrieves the total number of app open events.
  static Future<int> getAppOpenCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_appOpenKey) ?? 0;
  }

  /// Retrieves the total number of button press events.
  static Future<int> getButtonPressCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_buttonPressKey) ?? 0;
  }

  /// Retrieves the detailed button press log.
  static Future<List<Map<String, String>>> getButtonPressDetails() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedDetails = prefs.getString(_buttonPressDetailsKey);
    if (storedDetails != null) {
      return List<Map<String, String>>.from(jsonDecode(storedDetails));
    }
    return [];
  }
}
