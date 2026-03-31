import 'package:flutter/material.dart';
import 'home_page.dart';
import 'register_page.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isPressed = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCEAF7),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 380,
            margin: const EdgeInsets.symmetric(vertical: 40),
            padding: const EdgeInsets.fromLTRB(32, 36, 32, 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  "assets/images/imagelogin.png",
                  height: 160,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Sign In",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Welcome back, please login",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 28),

                // EMAIL / USERNAME
                TextField(
                  controller: namaController,
                  decoration: InputDecoration(
                    hintText: "Email / Username",
                    prefixIcon: const Icon(Icons.person_outline, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2)),
                  ),
                ),
                const SizedBox(height: 16),

                // PASSWORD
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // SIGN IN BUTTON
                GestureDetector(
                  onTapDown: _isLoading ? null : (_) => setState(() => _isPressed = true),
                  onTapCancel: () => setState(() => _isPressed = false),
                  onTapUp: _isLoading ? null : (_) async {
                    setState(() { _isPressed = false; _isLoading = true; });

                    final isValid = await AuthService.login(
                      namaController.text.trim(),
                      passwordController.text,
                    );

                    setState(() => _isLoading = false);

                    if (isValid) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Email/username atau password salah!'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    transform: Matrix4.identity()..scale(_isPressed ? 0.97 : 1.0),
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)]),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: const Color(0xFF2196F3).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                        : const Text("SIGN IN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                  ),
                ),
                const SizedBox(height: 20),

                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                  child: const Text("Don't have an account? Register", style: TextStyle(color: Color(0xFF2196F3))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}