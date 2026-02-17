import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'register_page.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final TextEditingController namaController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [

          // 🔵 LEFT SIDE IMAGE
          Expanded(
            flex: 4,
            child: Container(
              color: const Color(0xFF1565C0),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Image.asset(
                    "assets/images/trophy.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // ⚪ RIGHT SIDE FORM
          Expanded(
            flex: 6,
            child: Container(
              color: Colors.white,
              child: Center(
                child: SizedBox(
                  width: 400,
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        const Text(
                          "Sign In",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 40),

                        TextField(
                          controller: namaController,
                          decoration: const InputDecoration(
                            labelText: "Email / Nama",
                            border: UnderlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 20),

                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Password",
                            border: UnderlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 40),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () async {
                              bool success = await AuthService.login(
                                namaController.text,
                                passwordController.text,
                              );

                              if (success) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const HomePage()),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Login gagal")),
                                );
                              }
                            },
                            child: const Text(
                              "SIGN IN",
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => RegisterPage()),
                            );
                          },
                          child: const Text("Don't have an account? Register"),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
