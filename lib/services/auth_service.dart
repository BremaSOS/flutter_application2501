import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<void> register(String nama, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nama', nama);
    await prefs.setString('password', password);
  }

  static Future<bool> login(String nama, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final savedNama = prefs.getString('nama');
    final savedPassword = prefs.getString('password');

    if (nama == savedNama && password == savedPassword) {
      return true;
    }
    return false;
  }
}
