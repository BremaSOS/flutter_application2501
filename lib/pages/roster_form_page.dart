import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/roster.dart';

// ─────────────────────────────────────────────
// Model temporary untuk 1 baris mapel di form
// ─────────────────────────────────────────────
class _MapelEntry {
  final TextEditingController namaController;
  TimeOfDay jamMulai;
  TimeOfDay jamSelesai;

  _MapelEntry({
    String nama = '',
    this.jamMulai = const TimeOfDay(hour: 7, minute: 0),
    this.jamSelesai = const TimeOfDay(hour: 8, minute: 30),
  }) : namaController = TextEditingController(text: nama);

  void dispose() => namaController.dispose();
}

// ─────────────────────────────────────────────
// HALAMAN FORM: tambah banyak mapel sekaligus
// ─────────────────────────────────────────────
class RosterFormPage extends StatefulWidget {
  final Roster? roster; // null = mode tambah bulk, tidak null = edit satu

  const RosterFormPage({super.key, this.roster});

  @override
  State<RosterFormPage> createState() => _RosterFormPageState();
}

class _RosterFormPageState extends State<RosterFormPage> {
  final List<String> _hariList = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  String _selectedHari = 'Senin';

  // List mapel yang akan diinput sekaligus
  final List<_MapelEntry> _entries = [];
  bool _isLoading = false;

  // Untuk mode edit satu roster
  final _editFormKey = GlobalKey<FormState>();
  final _editNamaController = TextEditingController();
  TimeOfDay _editJamMulai = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _editJamSelesai = const TimeOfDay(hour: 8, minute: 30);
  String _editHari = 'Senin';

  bool get _isEditMode => widget.roster != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      // Mode edit — isi dari data yang ada
      final r = widget.roster!;
      _editNamaController.text = r.mataPelajaran;
      _editHari = r.hari;
      _editJamMulai = _parseTime(r.jamMulai);
      _editJamSelesai = _parseTime(r.jamSelesai);
    } else {
      // Mode tambah — mulai dengan 1 baris kosong
      _entries.add(_MapelEntry());
    }
  }

  @override
  void dispose() {
    for (final e in _entries) e.dispose();
    _editNamaController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String t) {
    final p = t.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  bool _isAfter(TimeOfDay mulai, TimeOfDay selesai) =>
      (selesai.hour * 60 + selesai.minute) > (mulai.hour * 60 + mulai.minute);

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) => showTimePicker(
        context: context,
        initialTime: initial,
        builder: (ctx, child) => MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      );

  // ── SIMPAN MODE EDIT ──
  Future<void> _saveEdit() async {
    if (!_editFormKey.currentState!.validate()) return;
    if (!_isAfter(_editJamMulai, _editJamSelesai)) {
      _showSnack('Jam selesai harus setelah jam mulai!', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    widget.roster!.mataPelajaran = _editNamaController.text.trim();
    widget.roster!.hari = _editHari;
    widget.roster!.jamMulai = _fmt(_editJamMulai);
    widget.roster!.jamSelesai = _fmt(_editJamSelesai);
    await widget.roster!.save();
    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  // ── SIMPAN MODE BULK ──
  Future<void> _saveBulk() async {
    // Validasi semua baris
    bool hasError = false;
    for (int i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      if (e.namaController.text.trim().isEmpty) {
        _showSnack('Mapel baris ${i + 1} belum diisi!', isError: true);
        hasError = true;
        break;
      }
      if (!_isAfter(e.jamMulai, e.jamSelesai)) {
        _showSnack('Jam selesai baris ${i + 1} harus setelah jam mulai!', isError: true);
        hasError = true;
        break;
      }
    }
    if (hasError) return;

    setState(() => _isLoading = true);
    final box = Hive.box<Roster>('rosters');
    for (int i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      await box.add(Roster(
        id: '${DateTime.now().millisecondsSinceEpoch}_$i',
        mataPelajaran: e.namaController.text.trim(),
        hari: _selectedHari,
        jamMulai: _fmt(e.jamMulai),
        jamSelesai: _fmt(e.jamSelesai),
      ));
    }
    setState(() => _isLoading = false);
    _showSnack('${_entries.length} mapel berhasil disimpan ✅');
    await Future.delayed(const Duration(milliseconds: 600));
    Navigator.pop(context);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        title: Text(_isEditMode ? 'Edit Jadwal' : 'Tambah Jadwal'),
        elevation: 0,
      ),
      body: _isEditMode ? _buildEditForm() : _buildBulkForm(),
    );
  }

  // ════════════════════════════════════════════
  // UI: MODE EDIT (satu roster)
  // ════════════════════════════════════════════
  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecor(),
        child: Form(
          key: _editFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Mata Pelajaran'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _editNamaController,
                decoration: _inputDecor(hint: 'Contoh: Matematika', icon: Icons.book_rounded),
                validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              _label('Hari'),
              const SizedBox(height: 8),
              _hariDropdown(_editHari, (v) => setState(() => _editHari = v!)),
              const SizedBox(height: 16),
              _label('Waktu'),
              const SizedBox(height: 8),
              _timeRow(
                mulai: _editJamMulai,
                selesai: _editJamSelesai,
                onPickMulai: () async {
                  final t = await _pickTime(_editJamMulai);
                  if (t != null) setState(() => _editJamMulai = t);
                },
                onPickSelesai: () async {
                  final t = await _pickTime(_editJamSelesai);
                  if (t != null) setState(() => _editJamSelesai = t);
                },
              ),
              const SizedBox(height: 28),
              _saveButton('Simpan Perubahan', _saveEdit),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  // UI: MODE BULK (input banyak mapel sekaligus)
  // ════════════════════════════════════════════
  Widget _buildBulkForm() {
    return Column(
      children: [
        // ── Pilih Hari ──
        Container(
          color: const Color(0xFF2196F3),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih Hari', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _hariList.map((hari) {
                    final isSelected = hari == _selectedHari;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedHari = hari),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          hari,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? const Color(0xFF2196F3) : Colors.white,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // ── Info ──
        Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFF2196F3)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tambah semua mata pelajaran hari $_selectedHari sekaligus, lalu tap Simpan.',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF2196F3)),
                ),
              ),
            ],
          ),
        ),

        // ── List Mapel ──
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: _entries.length,
            itemBuilder: (_, i) => _mapelCard(i),
          ),
        ),
      ],
    );
  }

  Widget _mapelCard(int i) {
    final e = _entries[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header baris
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Mata Pelajaran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
              ),
              // Tombol hapus baris (hanya jika lebih dari 1)
              if (_entries.length > 1)
                GestureDetector(
                  onTap: () => setState(() {
                    _entries[i].dispose();
                    _entries.removeAt(i);
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Input nama mapel
          TextField(
            controller: e.namaController,
            decoration: _inputDecor(hint: 'Contoh: Matematika', icon: Icons.book_rounded),
            style: const TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 12),

          // Jam mulai & selesai
          Row(
            children: [
              Expanded(
                child: _timeChip(
                  label: 'Mulai',
                  time: e.jamMulai,
                  onTap: () async {
                    final t = await _pickTime(e.jamMulai);
                    if (t != null) setState(() => e.jamMulai = t);
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('→', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ),
              Expanded(
                child: _timeChip(
                  label: 'Selesai',
                  time: e.jamSelesai,
                  onTap: () async {
                    final t = await _pickTime(e.jamSelesai);
                    if (t != null) setState(() => e.jamSelesai = t);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tombol Tambah Mapel + Simpan (bottom) ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        title: Text(_isEditMode ? 'Edit Jadwal' : 'Tambah Jadwal'),
        elevation: 0,
      ),
      body: _isEditMode ? _buildEditForm() : _buildBulkForm(),
      bottomNavigationBar: _isEditMode
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
              ),
              child: Row(
                children: [
                  // Tombol tambah baris mapel
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _entries.add(_MapelEntry(
                            jamMulai: _entries.isNotEmpty ? _entries.last.jamSelesai : const TimeOfDay(hour: 7, minute: 0),
                            jamSelesai: _entries.isNotEmpty
                                ? TimeOfDay(
                                    hour: (_entries.last.jamSelesai.hour + 1).clamp(0, 23),
                                    minute: _entries.last.jamSelesai.minute,
                                  )
                                : const TimeOfDay(hour: 8, minute: 30),
                          ))),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Tambah Mapel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2196F3),
                        side: const BorderSide(color: Color(0xFF2196F3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tombol simpan semua
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveBulk,
                      icon: _isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(
                        _isLoading ? 'Menyimpan...' : 'Simpan ${_entries.length} Mapel',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ══════════════════════════
  // HELPER WIDGETS
  // ══════════════════════════

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)));

  BoxDecoration _cardDecor() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      );

  InputDecoration _inputDecor({required String hint, required IconData icon}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.5)),
      );

  Widget _hariDropdown(String value, ValueChanged<String?> onChanged) => DropdownButtonFormField<String>(
        value: value,
        decoration: _inputDecor(hint: '', icon: Icons.calendar_today_rounded),
        items: _hariList.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
        onChanged: onChanged,
      );

  Widget _timeRow({
    required TimeOfDay mulai,
    required TimeOfDay selesai,
    required VoidCallback onPickMulai,
    required VoidCallback onPickSelesai,
  }) =>
      Row(
        children: [
          Expanded(child: _timeChip(label: 'Mulai', time: mulai, onTap: onPickMulai)),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('→', style: TextStyle(fontSize: 18, color: Colors.grey))),
          Expanded(child: _timeChip(label: 'Selesai', time: selesai, onTap: onPickSelesai)),
        ],
      );

  Widget _timeChip({required String label, required TimeOfDay time, required VoidCallback onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF2196F3)),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  Text(_fmt(time), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF2196F3))),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _saveButton(String label, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isLoading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      );
}