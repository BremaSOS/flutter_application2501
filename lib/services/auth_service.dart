import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<void> register(String nama, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nama', nama);
    await prefs.setString('email', email);
    await prefs.setString('password', password);
  }

  static Future<bool> login(String emailOrUsername, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final savedNama     = prefs.getString('nama');
    final savedEmail    = prefs.getString('email');
    final savedPassword = prefs.getString('password');

    final inputLower    = emailOrUsername.trim().toLowerCase();
    final emailMatch    = savedEmail?.toLowerCase() == inputLower;
    final usernameMatch = savedNama?.toLowerCase() == inputLower;

    return (emailMatch || usernameMatch) && password == savedPassword;
  }

  static Future<void> logout() async {
    // Tidak hapus data akun, hanya session
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isLoggedIn');
  }

  static Future<String?> getNama() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('nama');
  }
}