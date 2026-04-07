import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/roster.dart';
import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/roster_import_service.dart';
import '../services/roster_export_service.dart';
import 'login_page.dart';
import 'roster_form_page.dart';
import 'task_form_page.dart';

// ─────────────────────────────────────────────
//  SPLASH / INTRO SCREEN
// ─────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();

    // Logo: muncul dengan bounce
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _logoScale = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _logoFade = CurvedAnimation(parent: _logoController, curve: Curves.easeOut);

    // Progress bar: mengisi dari 0 ke 1 selama 2.5 detik
    _progressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _progressAnim = CurvedAnimation(parent: _progressController, curve: Curves.easeInOut);

    _logoController.forward().then((_) async {
      await Future.delayed(const Duration(milliseconds: 300));
      _progressController.forward();
      await Future.delayed(const Duration(milliseconds: 2600));
      if (mounted) {
        Navigator.pushReplacement(context, _fadeRoute(const HomePage()));
      }
    });
  }

  Route _fadeRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      );

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Tengah: logo + nama app ──
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lingkaran hijau dengan gambar di dalamnya
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF4CAF50),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withOpacity(0.35),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Image.asset(
                            'assets/images/imagelogin.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Nama app
                  FadeTransition(
                    opacity: _logoFade,
                    child: const Text(
                      'School Reminder',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FadeTransition(
                    opacity: _logoFade,
                    child: const Text(
                      'Catat tugas, jangan sampai telat',
                      style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
            ),

            // ── Bawah: progress bar seperti GoPay ──
            Positioned(
              bottom: 48,
              left: size.width * 0.25,
              right: size.width * 0.25,
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (_, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progressAnim.value,
                        minHeight: 4,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Memuat...',
                    style: TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HOME PAGE (DASHBOARD)
// ─────────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _userName = '';

  final List<String> _hariOrder = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadUser();
  }

  Future<void> _loadUser() async {
    final nama = await AuthService.getNama();
    setState(() => _userName = nama ?? 'Siswa');
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Yakin ingin keluar dari akun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService.logout();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  void _rescheduleNotifications() {
    final box = Hive.box<Roster>('rosters');
    NotificationService.scheduleRosterNotifications(box.values.toList());
  }

  Future<void> _deleteRoster(Roster roster) async {
    final confirm = await _confirmDelete('Hapus jadwal ${roster.mataPelajaran}?');
    if (confirm == true) {
      await roster.delete();
      _rescheduleNotifications();
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirm = await _confirmDelete('Hapus tugas ${task.mataPelajaran}?');
    if (confirm == true) {
      await NotificationService.cancelDeadlineNotifications(task.id);
      await task.delete();
    }
  }

  Future<bool?> _confirmDelete(String message) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Konfirmasi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          content: Text(message, style: const TextStyle(fontSize: 14)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        ),
      );

  String _formatDeadline(DateTime dt) {
    final diff = dt.difference(DateTime.now()).inDays;
    final d = '${dt.day}/${dt.month}/${dt.year}';
    if (diff < 0) return '$d · Terlambat';
    if (diff == 0) return '$d · Hari ini!';
    if (diff == 1) return '$d · Besok';
    return '$d · $diff hari lagi';
  }

  Color _deadlineColor(DateTime dt) {
    final diff = dt.difference(DateTime.now()).inDays;
    if (diff < 0) return const Color(0xFFEF4444);
    if (diff <= 2) return const Color(0xFFF97316);
    if (diff <= 7) return const Color(0xFFEAB308);
    return const Color(0xFF22C55E);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildRosterTab(), _buildTaskTab()],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF2196F3),
      ),
      child: Column(
        children: [
          // Logout di kanan atas
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _logout,
                child: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Gambar di tengah
          Image.asset(
            'assets/images/imagelogin.png',
            height: 100,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 10),
          // Nama user
          Text(
            'Halo, $_userName 👋',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 2),
          const Text(
            'Semangat belajar hari ini!',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF2196F3),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: const Color(0xFF2196F3),
          unselectedLabelColor: Colors.white,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: '📅  Jadwal'),
            Tab(text: '📝  Tugas'),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    final isRosterTab = _tabController.index == 0;

    if (!isRosterTab) {
      // Tab Tugas — FAB biasa
      return FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Tambah Tugas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        onPressed: () async {
          final rosterBox = Hive.box<Roster>('rosters');
          if (rosterBox.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Tambahkan jadwal pelajaran terlebih dahulu!'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ));
            return;
          }
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskFormPage()));
        },
      );
    }

    // Tab Jadwal — tampilkan 2 pilihan: manual atau import JSON
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tombol: Import JSON
        _fabMini(
          icon: Icons.upload_file_rounded,
          label: 'Import JSON',
          color: const Color(0xFF10B981),
          onTap: _importJson,
        ),
        const SizedBox(height: 10),
        // Tombol: Tambah Manual
        _fabMini(
          icon: Icons.edit_rounded,
          label: 'Tambah Manual',
          color: const Color(0xFF2196F3),
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const RosterFormPage()));
            _rescheduleNotifications();
          },
        ),
      ],
    );
  }

  Widget _fabMini({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Future<void> _importJson() async {
    // Tampilkan dialog preview format JSON dulu
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.upload_file_rounded, color: Color(0xFF10B981), size: 22),
            SizedBox(width: 8),
            Text('Import Jadwal JSON', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pastikan file JSON kamu menggunakan format berikut:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '{\n  "jadwal": [\n    {\n      "mataPelajaran": "MTK",\n      "hari": "Senin",\n      "jamMulai": "07:00",\n      "jamSelesai": "08:30"\n    }\n  ]\n}',
                style: TextStyle(fontSize: 11, color: Color(0xFF86EFAC), fontFamily: 'monospace', height: 1.5),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Hari yang valid: Senin, Selasa, Rabu, Kamis, Jumat, Sabtu, Minggu',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pilih File'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Tampilkan loading
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Memproses file...'),
          ]),
          duration: Duration(seconds: 10),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    final result = await RosterImportService.importFromJson();
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (result == null) return; // user cancel

    _rescheduleNotifications();

    // Tampilkan hasil
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              result.berhasil > 0 ? Icons.check_circle_rounded : Icons.error_rounded,
              color: result.berhasil > 0 ? const Color(0xFF10B981) : Colors.red,
              size: 22,
            ),
            const SizedBox(width: 8),
            const Text('Hasil Import', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  _resultRow('✅ Berhasil diimport', '${result.berhasil} jadwal', const Color(0xFF10B981)),
                  if (result.gagal > 0) ...[
                    const SizedBox(height: 6),
                    _resultRow('❌ Gagal', '${result.gagal} baris', Colors.red),
                  ],
                ],
              ),
            ),
            // Error detail
            if (result.pesanGagal.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Detail Error:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 120),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: result.pesanGagal.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $e', style: const TextStyle(fontSize: 11, color: Colors.red)),
                    )).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value, Color color) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      );

  Future<void> _exportJson() async {
    final error = await RosterExportService.exportToJson();
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  // ── ROSTER TAB ──
  Widget _buildRosterTab() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Roster>('rosters').listenable(),
      builder: (context, Box<Roster> box, _) {
        if (box.isEmpty) return _emptyState(Icons.calendar_today_outlined, 'Belum ada jadwal', 'Tap tombol + untuk menambah jadwal pelajaran');

        final Map<String, List<Roster>> byDay = {};
        for (final r in box.values) {
          byDay.putIfAbsent(r.hari, () => []).add(r);
        }
        for (final k in byDay.keys) {
          byDay[k]!.sort((a, b) => a.jamMulai.compareTo(b.jamMulai));
        }
        final days = _hariOrder.where((h) => byDay.containsKey(h)).toList();

        return Column(
          children: [
            // ── Tombol Share/Export JSON ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: GestureDetector(
                onTap: _exportJson,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.share_rounded, size: 16, color: Color(0xFF10B981)),
                      SizedBox(width: 8),
                      Text(
                        'Bagikan Jadwal ke Teman (Export JSON)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ── List Jadwal ──
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                itemCount: days.length + 1,
                itemBuilder: (_, i) {
                  if (i == days.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 32, bottom: 16),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF4CAF50),
                                boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6))],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Image.asset('assets/images/imagelogin.png', fit: BoxFit.contain),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text('Semangat belajar! 💪', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                    );
                  }
                  final hari = days[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 8, top: i == 0 ? 0 : 8),
                        child: Text(hari, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2196F3), letterSpacing: 0.5)),
                      ),
                      ...byDay[hari]!.map((r) => _rosterCard(r)),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _rosterCard(Roster roster) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_book_rounded, color: Color(0xFF2196F3), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(roster.mataPelajaran, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text('${roster.jamMulai} – ${roster.jamSelesai}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _iconBtn(Icons.edit_outlined, const Color(0xFF2196F3), () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => RosterFormPage(roster: roster)));
                _rescheduleNotifications();
              }),
              _iconBtn(Icons.delete_outline_rounded, const Color(0xFFEF4444), () => _deleteRoster(roster)),
            ],
          ),
        ],
      ),
    );
  }

  // ── TASK TAB ──
  Widget _buildTaskTab() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Task>('tasks').listenable(),
      builder: (context, Box<Task> box, _) {
        if (box.isEmpty) return _emptyState(Icons.assignment_outlined, 'Belum ada tugas', 'Tap tombol + untuk menambah tugas');

        final tasks = box.values.toList()..sort((a, b) => a.deadline.compareTo(b.deadline));

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: tasks.length,
          itemBuilder: (_, i) => _taskCard(tasks[i]),
        );
      },
    );
  }

  Widget _taskCard(Task task) {
    final color = _deadlineColor(task.deadline);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.assignment_rounded, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.mataPelajaran, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(task.deskripsi, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 12, color: color),
                      const SizedBox(width: 4),
                      Text(_formatDeadline(task.deadline), style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                _iconBtn(Icons.edit_outlined, const Color(0xFF2196F3), () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskFormPage(task: task)))),
                _iconBtn(Icons.delete_outline_rounded, const Color(0xFFEF4444), () => _deleteTask(task)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: color),
        ),
      );

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lingkaran hijau dengan gambar
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4CAF50),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Image.asset(
                'assets/images/imagelogin.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}