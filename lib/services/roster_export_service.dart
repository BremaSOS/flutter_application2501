import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/roster.dart';

class RosterExportService {
  /// Export semua roster ke JSON dan share via WhatsApp/dll
  static Future<String?> exportToJson() async {
    try {
      final box = Hive.box<Roster>('rosters');
      if (box.isEmpty) return 'Belum ada jadwal untuk diekspor';

      // Susun data
      final List<Map<String, dynamic>> jadwalList = box.values.map((r) => {
        'mataPelajaran': r.mataPelajaran,
        'hari': r.hari,
        'jamMulai': r.jamMulai,
        'jamSelesai': r.jamSelesai,
      }).toList();

      final jsonData = json.encode({'jadwal': jadwalList}, toEncodable: (o) => o);
      // Pretty print
      final prettyJson = const JsonEncoder.withIndent('  ').convert({'jadwal': jadwalList});

      if (kIsWeb) {
        // Web: tidak bisa share file, tampilkan saja
        return prettyJson;
      }

      // Mobile: simpan ke file sementara lalu share
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/jadwal_sekolah.json');
      await file.writeAsString(prettyJson);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Jadwal Sekolah',
        text: 'Ini file jadwal sekolah saya. Import ke aplikasi School Reminder ya!',
      );

      return null; // null = sukses
    } catch (e) {
      return 'Gagal export: $e';
    }
  }
}