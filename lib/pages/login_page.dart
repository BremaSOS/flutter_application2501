import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_page.dart';
import 'register_page.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _namaController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_namaController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Isi semua kolom terlebih dahulu'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    final isValid = await AuthService.login(
      _namaController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (isValid) {
      HapticFeedback.mediumImpact();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
    } else {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email/username atau password salah'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                height: size.height - MediaQuery.of(context).padding.top,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),

                      // ── LOGO ──
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2196F3).withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/imagelogin.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── TITLE ──
                      const Text(
                        'Selamat Datang',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Masuk untuk melanjutkan',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── FORM CARD ──
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2196F3).withOpacity(0.06),
                              blurRadius: 24,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // Email / Username
                            _label('Email atau Username'),
                            const SizedBox(height: 6),
                            _inputField(
                              controller: _namaController,
                              hint: 'Masukkan email atau username',
                              icon: Icons.person_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                            ),

                            const SizedBox(height: 16),

                            // Password
                            _label('Password'),
                            const SizedBox(height: 6),
                            _inputField(
                              controller: _passwordController,
                              hint: 'Masukkan password',
                              icon: Icons.lock_outline_rounded,
                              obscure: _obscurePassword,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 20,
                                  color: const Color(0xFF94A3B8),
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── LOGIN BUTTON ──
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF2196F3).withOpacity(0.6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Text(
                                  'Masuk',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
                                ),
                        ),
                      ),

                      const Spacer(),

                      // ── REGISTER LINK ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Belum punya akun? ', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                            child: const Text(
                              'Daftar',
                              style: TextStyle(fontSize: 13, color: Color(0xFF2196F3), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
      );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.5),
        ),
      ),
    );
  }
}