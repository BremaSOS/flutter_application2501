import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/roster.dart';
import '../models/task.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Notifikasi tidak didukung di Web — skip
    if (kIsWeb) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Minta permission Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Payload berisi nama mata pelajaran
  }

  // =========================================================
  // JADWAL NOTIFIKASI: muncul SETELAH jam pelajaran selesai
  // =========================================================
  static Future<void> scheduleRosterNotifications(
      List<Roster> rosters) async {
    if (kIsWeb) return;

    // Batalkan semua notifikasi roster lama
    for (int i = 100; i < 200; i++) {
      await _plugin.cancel(i);
    }

    final hariMap = {
      'Senin': DateTime.monday,
      'Selasa': DateTime.tuesday,
      'Rabu': DateTime.wednesday,
      'Kamis': DateTime.thursday,
      'Jumat': DateTime.friday,
      'Sabtu': DateTime.saturday,
      'Minggu': DateTime.sunday,
    };

    for (int i = 0; i < rosters.length; i++) {
      final roster = rosters[i];
      final targetWeekday = hariMap[roster.hari];
      if (targetWeekday == null) continue;

      final parts = roster.jamSelesai.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;

      final scheduled = _nextWeekday(targetWeekday, hour, minute);

      await _plugin.zonedSchedule(
        100 + i,
        '📚 ${roster.mataPelajaran} selesai!',
        'Apakah ada tugas dari pelajaran ${roster.mataPelajaran} hari ini?',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'roster_channel',
            'Notifikasi Jadwal',
            channelDescription: 'Notifikasi setelah pelajaran selesai',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // ✅ FIX: parameter wajib yang sebelumnya tidak ada
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: roster.mataPelajaran,
      );
    }
  }

  // =========================================================
  // NOTIFIKASI DEADLINE: 7 hari & 2 hari sebelum deadline
  // =========================================================
  static Future<void> scheduleDeadlineNotifications(Task task) async {
    if (kIsWeb) return;

    final taskIndex = task.id.hashCode.abs() % 900;

    final reminders = [
      {'days': 7, 'id': taskIndex},
      {'days': 2, 'id': taskIndex + 1000},
    ];

    for (final r in reminders) {
      final reminderDate =
          task.deadline.subtract(Duration(days: r['days'] as int));

      if (reminderDate.isBefore(DateTime.now())) continue;

      final scheduled = tz.TZDateTime.from(
        DateTime(reminderDate.year, reminderDate.month, reminderDate.day, 8, 0),
        tz.local,
      );

      await _plugin.zonedSchedule(
        r['id'] as int,
        '⏰ Deadline ${r['days']} hari lagi!',
        'Tugas ${task.mataPelajaran}: ${task.deskripsi}',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'deadline_channel',
            'Notifikasi Deadline',
            channelDescription: 'Pengingat deadline tugas',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // ✅ FIX: parameter wajib yang sebelumnya tidak ada
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: task.mataPelajaran,
      );
    }
  }

  static Future<void> cancelDeadlineNotifications(String taskId) async {
    if (kIsWeb) return;
    final taskIndex = taskId.hashCode.abs() % 900;
    await _plugin.cancel(taskIndex);
    await _plugin.cancel(taskIndex + 1000);
  }

  static tz.TZDateTime _nextWeekday(int weekday, int hour, int minute) {
    var now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> showInstant(String title, String body,
      {String? payload}) async {
    if (kIsWeb) return;
    await _plugin.show(
      0,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_channel',
          'Notifikasi Instan',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }
}