// ignore: file_names
import 'package:shared_preferences/shared_preferences.dart';

class SharedP {
  static Remove() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tok');
    await prefs.remove('user_id');

  }

  static Get(String key) async {
    var prefs = await SharedPreferences.getInstance();

    String? tokens = prefs.getString(key);
    return tokens;
  }

  static Save(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}
