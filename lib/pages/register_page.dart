import 'package:flutter/material.dart';
import 'home_page.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController namaController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  bool isValidEmail(String email) => RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: color, width: width));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCEAF7),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            margin: const EdgeInsets.symmetric(vertical: 40),
            padding: const EdgeInsets.fromLTRB(32, 36, 32, 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, spreadRadius: 4)],
            ),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Create Account", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 6),
                  const Text("Fill in the details to register", style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 28),

                  TextFormField(
                    controller: namaController,
                    decoration: InputDecoration(hintText: "Full Name", prefixIcon: const Icon(Icons.person_outline, color: Colors.grey), filled: true, fillColor: Colors.grey.shade50, border: _border(Colors.grey.shade300), enabledBorder: _border(Colors.grey.shade300), focusedBorder: _border(const Color(0xFF2196F3), width: 2), errorBorder: _border(Colors.red), focusedErrorBorder: _border(Colors.red, width: 2)),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Nama tidak boleh kosong";
                      if (v.length < 3) return "Nama minimal 3 karakter";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(hintText: "Email", prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey), filled: true, fillColor: Colors.grey.shade50, border: _border(Colors.grey.shade300), enabledBorder: _border(Colors.grey.shade300), focusedBorder: _border(const Color(0xFF2196F3), width: 2), errorBorder: _border(Colors.red), focusedErrorBorder: _border(Colors.red, width: 2)),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Email tidak boleh kosong";
                      if (!isValidEmail(v)) return "Format email tidak valid";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(hintText: "Password", prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey), filled: true, fillColor: Colors.grey.shade50, border: _border(Colors.grey.shade300), enabledBorder: _border(Colors.grey.shade300), focusedBorder: _border(const Color(0xFF2196F3), width: 2), errorBorder: _border(Colors.red), focusedErrorBorder: _border(Colors.red, width: 2),
                      suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Password tidak boleh kosong";
                      if (v.length < 6) return "Password minimal 6 karakter";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(hintText: "Confirm Password", prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey), filled: true, fillColor: Colors.grey.shade50, border: _border(Colors.grey.shade300), enabledBorder: _border(Colors.grey.shade300), focusedBorder: _border(const Color(0xFF2196F3), width: 2), errorBorder: _border(Colors.red), focusedErrorBorder: _border(Colors.red, width: 2),
                      suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm))),
                    validator: (v) => v != passwordController.text ? "Password tidak sama" : null,
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                      onPressed: _isLoading ? null : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _isLoading = true);
                        await AuthService.register(namaController.text.trim(), emailController.text.trim(), passwordController.text);
                        setState(() => _isLoading = false);
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
                      },
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("REGISTER", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}