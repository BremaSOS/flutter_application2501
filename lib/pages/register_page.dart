import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_page.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _namaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String v) => RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v);

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    await AuthService.register(
      _namaController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);
    HapticFeedback.mediumImpact();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── HEADER ──
                  const Text(
                    'Buat Akun',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Daftar untuk mulai menggunakan aplikasi',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),

                  const SizedBox(height: 28),

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

                        _label('Nama Lengkap'),
                        const SizedBox(height: 6),
                        _formField(
                          controller: _namaController,
                          hint: 'Masukkan nama lengkap',
                          icon: Icons.person_outline_rounded,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Nama wajib diisi';
                            if (v.length < 3) return 'Minimal 3 karakter';
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        _label('Email'),
                        const SizedBox(height: 6),
                        _formField(
                          controller: _emailController,
                          hint: 'Masukkan email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email wajib diisi';
                            if (!_isValidEmail(v)) return 'Format email tidak valid';
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        _label('Password'),
                        const SizedBox(height: 6),
                        _formField(
                          controller: _passwordController,
                          hint: 'Minimal 6 karakter',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscurePass,
                          suffix: _eyeButton(_obscurePass, () => setState(() => _obscurePass = !_obscurePass)),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password wajib diisi';
                            if (v.length < 6) return 'Minimal 6 karakter';
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        _label('Konfirmasi Password'),
                        const SizedBox(height: 6),
                        _formField(
                          controller: _confirmController,
                          hint: 'Ulangi password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscureConfirm,
                          suffix: _eyeButton(_obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
                          validator: (v) => v != _passwordController.text ? 'Password tidak sama' : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── REGISTER BUTTON ──
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF2196F3).withOpacity(0.6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('Daftar Sekarang', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── LOGIN LINK ──
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Sudah punya akun? ', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text('Masuk', style: TextStyle(fontSize: 13, color: Color(0xFF2196F3), fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
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

  Widget _eyeButton(bool obscure, VoidCallback onTap) => IconButton(
        icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: const Color(0xFF94A3B8)),
        onPressed: onTap,
      );

  Widget _formField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEF4444))),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
        errorStyle: const TextStyle(fontSize: 11),
      ),
    );
  }
}