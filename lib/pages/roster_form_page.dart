import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/roster.dart';

class RosterFormPage extends StatefulWidget {
  final Roster? roster; // null = tambah baru, tidak null = edit

  const RosterFormPage({super.key, this.roster});

  @override
  State<RosterFormPage> createState() => _RosterFormPageState();
}

class _RosterFormPageState extends State<RosterFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _mataPelajaranController = TextEditingController();

  String _selectedHari = 'Senin';
  TimeOfDay _jamMulai = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _jamSelesai = const TimeOfDay(hour: 8, minute: 30);
  bool _isLoading = false;

  final List<String> _hariList = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

  @override
  void initState() {
    super.initState();
    if (widget.roster != null) {
      final r = widget.roster!;
      _mataPelajaranController.text = r.mataPelajaran;
      _selectedHari = r.hari;
      _jamMulai = _parseTime(r.jamMulai);
      _jamSelesai = _parseTime(r.jamSelesai);
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isMulai) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isMulai ? _jamMulai : _jamSelesai,
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (picked != null) {
      setState(() {
        if (isMulai) _jamMulai = picked;
        else _jamSelesai = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi jam selesai harus setelah jam mulai
    final mulaiMinutes = _jamMulai.hour * 60 + _jamMulai.minute;
    final selesaiMinutes = _jamSelesai.hour * 60 + _jamSelesai.minute;
    if (selesaiMinutes <= mulaiMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jam selesai harus setelah jam mulai!'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    final box = Hive.box<Roster>('rosters');

    if (widget.roster != null) {
      // Edit
      widget.roster!.mataPelajaran = _mataPelajaranController.text.trim();
      widget.roster!.hari = _selectedHari;
      widget.roster!.jamMulai = _formatTime(_jamMulai);
      widget.roster!.jamSelesai = _formatTime(_jamSelesai);
      await widget.roster!.save();
    } else {
      // Tambah baru
      final roster = Roster(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        mataPelajaran: _mataPelajaranController.text.trim(),
        hari: _selectedHari,
        jamMulai: _formatTime(_jamMulai),
        jamSelesai: _formatTime(_jamSelesai),
      );
      await box.add(roster);
    }

    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.roster != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        title: Text(isEdit ? 'Edit Jadwal' : 'Tambah Jadwal'),
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
                TextFormField(
                  controller: _mataPelajaranController,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Matematika',
                    prefixIcon: const Icon(Icons.book, color: Color(0xFF2196F3)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2)),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Nama mata pelajaran wajib diisi' : null,
                ),
                const SizedBox(height: 20),

                // HARI
                const Text('Hari', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedHari,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF2196F3)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2)),
                  ),
                  items: _hariList.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                  onChanged: (v) => setState(() => _selectedHari = v!),
                ),
                const SizedBox(height: 20),

                // JAM MULAI & SELESAI
                const Text('Waktu', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _timePicker('Jam Mulai', _jamMulai, () => _pickTime(true))),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('–', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey))),
                    Expanded(child: _timePicker('Jam Selesai', _jamSelesai, () => _pickTime(false))),
                  ],
                ),
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
                        : Text(isEdit ? 'Simpan Perubahan' : 'Tambah Jadwal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _timePicker(String label, TimeOfDay time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Color(0xFF2196F3)),
                const SizedBox(width: 6),
                Text(_formatTime(time), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2196F3))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}