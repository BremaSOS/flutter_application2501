import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/roster.dart';
import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'login_page.dart';
import 'roster_form_page.dart';
import 'task_form_page.dart';

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
    _loadUser();
  }

  Future<void> _loadUser() async {
    final nama = await AuthService.getNama();
    setState(() => _userName = nama ?? 'Siswa');
  }

  Future<void> _logout() async {
    await AuthService.logout();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  Future<void> _deleteRoster(Roster roster) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Jadwal'),
        content: Text('Hapus jadwal ${roster.mataPelajaran}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await roster.delete();
      _rescheduleNotifications();
    }
  }

  Future<void> _deleteTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Tugas'),
        content: Text('Hapus tugas ${task.mataPelajaran}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await NotificationService.cancelDeadlineNotifications(task.id);
      await task.delete();
    }
  }

  void _rescheduleNotifications() {
    final rosterBox = Hive.box<Roster>('rosters');
    NotificationService.scheduleRosterNotifications(rosterBox.values.toList());
  }

  String _formatDeadline(DateTime dt) {
    final diff = dt.difference(DateTime.now()).inDays;
    final dateStr = '${dt.day}/${dt.month}/${dt.year}';
    if (diff < 0) return '$dateStr (Terlambat)';
    if (diff == 0) return '$dateStr (Hari ini!)';
    if (diff == 1) return '$dateStr (Besok)';
    return '$dateStr ($diff hari lagi)';
  }

  Color _deadlineColor(DateTime dt) {
    final diff = dt.difference(DateTime.now()).inDays;
    if (diff < 0) return Colors.red;
    if (diff <= 2) return Colors.orange;
    if (diff <= 7) return Colors.amber;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('School Reminder', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Halo, $_userName 👋', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_today), text: 'Jadwal'),
            Tab(icon: Icon(Icons.assignment), text: 'Tugas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRosterTab(),
          _buildTaskTab(),
        ],
      ),
      floatingActionButton: ValueListenableBuilder(
        valueListenable: Hive.box<Roster>('rosters').listenable(),
        builder: (_, __, ___) {
          return FloatingActionButton.extended(
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: Text(_tabController.index == 0 ? 'Tambah Jadwal' : 'Tambah Tugas'),
            onPressed: () async {
              if (_tabController.index == 0) {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const RosterFormPage()));
                _rescheduleNotifications();
              } else {
                final rosterBox = Hive.box<Roster>('rosters');
                if (rosterBox.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tambahkan jadwal pelajaran terlebih dahulu!')),
                  );
                  return;
                }
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const TaskFormPage()));
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildRosterTab() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Roster>('rosters').listenable(),
      builder: (context, Box<Roster> box, _) {
        if (box.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Belum ada jadwal pelajaran', style: TextStyle(color: Colors.grey, fontSize: 16)),
                SizedBox(height: 8),
                Text('Tap tombol + untuk menambah jadwal', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          );
        }

        // Kelompokkan berdasarkan hari
        final Map<String, List<Roster>> byDay = {};
        for (final roster in box.values) {
          byDay.putIfAbsent(roster.hari, () => []).add(roster);
        }
        // Sort per hari
        for (final key in byDay.keys) {
          byDay[key]!.sort((a, b) => a.jamMulai.compareTo(b.jamMulai));
        }

        final sortedDays = _hariOrder.where((h) => byDay.containsKey(h)).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDays.length,
          itemBuilder: (_, i) {
            final hari = sortedDays[i];
            final items = byDay[hari]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(hari, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                ...items.map((roster) => _rosterCard(roster)),
                const SizedBox(height: 8),
              ],
            );
          },
        );
      },
    );
  }

  Widget _rosterCard(Roster roster) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2196F3).withOpacity(0.12),
          child: const Icon(Icons.book, color: Color(0xFF2196F3)),
        ),
        title: Text(roster.mataPelajaran, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${roster.jamMulai} – ${roster.jamSelesai}', style: const TextStyle(color: Colors.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF2196F3)),
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => RosterFormPage(roster: roster)));
                _rescheduleNotifications();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteRoster(roster),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTab() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Task>('tasks').listenable(),
      builder: (context, Box<Task> box, _) {
        if (box.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Belum ada tugas', style: TextStyle(color: Colors.grey, fontSize: 16)),
                SizedBox(height: 8),
                Text('Tap tombol + untuk menambah tugas', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          );
        }

        final tasks = box.values.toList()
          ..sort((a, b) => a.deadline.compareTo(b.deadline));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (_, i) => _taskCard(tasks[i]),
        );
      },
    );
  }

  Widget _taskCard(Task task) {
    final color = _deadlineColor(task.deadline);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(Icons.assignment, color: color),
        ),
        title: Text(task.mataPelajaran, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(task.deskripsi, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: color),
                const SizedBox(width: 4),
                Text(_formatDeadline(task.deadline), style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF2196F3)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaskFormPage(task: task))),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteTask(task),
            ),
          ],
        ),
      ),
    );
  }
}