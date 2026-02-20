import 'package:flutter/material.dart';
import 'home_page.dart';

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

  bool isValidEmail(String email) {
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return regex.hasMatch(email);
  }

  OutlineInputBorder borderStyle(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(40),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Text(
                  "Create Account",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                // ================= NAME =================
                TextFormField(
                  controller: namaController,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    enabledBorder: borderStyle(Colors.grey),
                    focusedBorder: borderStyle(Colors.blue),
                    errorBorder: borderStyle(Colors.red),
                    focusedErrorBorder: borderStyle(Colors.red),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Nama tidak boleh kosong";
                    }
                    if (value.length < 3) {
                      return "Nama minimal 3 karakter";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ================= EMAIL =================
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    enabledBorder: borderStyle(Colors.grey),
                    focusedBorder: borderStyle(Colors.blue),
                    errorBorder: borderStyle(Colors.red),
                    focusedErrorBorder: borderStyle(Colors.red),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Email tidak boleh kosong";
                    }
                    if (!isValidEmail(value)) {
                      return "Format email tidak valid";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ================= PASSWORD =================
                TextFormField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    enabledBorder: borderStyle(Colors.grey),
                    focusedBorder: borderStyle(Colors.blue),
                    errorBorder: borderStyle(Colors.red),
                    focusedErrorBorder: borderStyle(Colors.red),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setState(() =>
                            _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password tidak boleh kosong";
                    }
                    if (value.length < 6) {
                      return "Password minimal 6 karakter";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ================= CONFIRM PASSWORD =================
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    enabledBorder: borderStyle(Colors.grey),
                    focusedBorder: borderStyle(Colors.blue),
                    errorBorder: borderStyle(Colors.red),
                    focusedErrorBorder: borderStyle(Colors.red),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setState(() =>
                            _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != passwordController.text) {
                      return "Password tidak sama";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _isLoading
                        ? null
                        : () async {

                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                            setState(() => _isLoading = true);

                            await Future.delayed(
                                const Duration(seconds: 2));

                            setState(() => _isLoading = false);

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const HomePage()),
                            );
                          },
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.black,
                          )
                        : const Text("REGISTER"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}