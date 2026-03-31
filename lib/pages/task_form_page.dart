import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/roster.dart';
import '../services/notification_service.dart';

class TaskFormPage extends StatefulWidget {
  final Task? task; // null = tambah baru

  const TaskFormPage({super.key, this.task});

  @override
  State<TaskFormPage> createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _deskripsiController = TextEditingController();

  String? _selectedMapel;
  DateTime? _deadline;
  bool _isLoading = false;

  List<String> _mapelList = [];

  @override
  void initState() {
    super.initState();
    _loadMapelList();

    if (widget.task != null) {
      _selectedMapel = widget.task!.mataPelajaran;
      _deskripsiController.text = widget.task!.deskripsi;
      _deadline = widget.task!.deadline;
    }
  }

  void _loadMapelList() {
    final rosterBox = Hive.box<Roster>('rosters');
    final mapelSet = rosterBox.values.map((r) => r.mataPelajaran).toSet();
    setState(() => _mapelList = mapelSet.toList()..sort());
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF2196F3)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal deadline terlebih dahulu!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final box = Hive.box<Task>('tasks');

    if (widget.task != null) {
      // Edit — batalkan notifikasi lama dulu
      await NotificationService.cancelDeadlineNotifications(widget.task!.id);
      widget.task!.mataPelajaran = _selectedMapel!;
      widget.task!.deskripsi = _deskripsiController.text.trim();
      widget.task!.deadline = _deadline!;
      await widget.task!.save();
      await NotificationService.scheduleDeadlineNotifications(widget.task!);
    } else {
      // Tambah baru
      final task = Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        mataPelajaran: _selectedMapel!,
        deskripsi: _deskripsiController.text.trim(),
        deadline: _deadline!,
        dibuatPada: DateTime.now(),
      );
      await box.add(task);
      await NotificationService.scheduleDeadlineNotifications(task);
    }

    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.task != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        title: Text(isEdit ? 'Edit Tugas' : 'Tambah Tugas'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12)],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // MATA PELAJARAN
                const Text('Mata Pelajaran', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedMapel,
                  hint: const Text('Pilih mata pelajaran'),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.book, color: Color(0xFF2196F3)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2)),
                  ),
                  items: _mapelList.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (v) => setState(() => _selectedMapel = v),
                  validator: (v) => v == null ? 'Pilih mata pelajaran' : null,
                ),
                const SizedBox(height: 20),

                // DESKRIPSI
                const Text('Deskripsi Tugas', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _deskripsiController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Kerjakan soal halaman 45-47',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2)),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Deskripsi tugas wajib diisi' : null,
                ),
                const SizedBox(height: 20),

                // DEADLINE
                const Text('Tanggal Deadline', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDeadline,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFF2196F3)),
                        const SizedBox(width: 12),
                        Text(
                          _deadline == null
                              ? 'Pilih tanggal deadline'
                              : DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_deadline!),
                          style: TextStyle(
                            color: _deadline == null ? Colors.grey : Colors.black87,
                            fontSize: 15,
                            fontWeight: _deadline == null ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_deadline != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active, color: Color(0xFF2196F3), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Kamu akan mendapat pengingat 7 hari dan 2 hari sebelum deadline.',
                            style: const TextStyle(color: Color(0xFF2196F3), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // SAVE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                    ),
                    onPressed: _isLoading ? null : _save,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(isEdit ? 'Simpan Perubahan' : 'Simpan Tugas', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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