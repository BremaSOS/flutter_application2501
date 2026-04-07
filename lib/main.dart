import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/roster.dart';
import 'models/task.dart';
import 'services/notification_service.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar transparan
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Init Hive
  await Hive.initFlutter();
  Hive.registerAdapter(RosterAdapter());
  Hive.registerAdapter(TaskAdapter());
  await Hive.openBox<Roster>('rosters');
  await Hive.openBox<Task>('tasks');

  // Init Notifikasi
  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Reminder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2196F3)),
        useMaterial3: true,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF5F7FF),
      ),
      // ✅ Buka SplashScreen dulu, otomatis redirect ke HomePage
      home: const SplashScreen(),
    );
  }
}