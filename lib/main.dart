import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'splash_screen.dart';
import 'notification_helper.dart';
import 'user_session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationHelper.init();
  await initializeDateFormatting('id_ID', null);
  await UserSession.instance.load(); // <-- tambahkan ini
  runApp(const HealUApp());
}

class HealUApp extends StatelessWidget {
  const HealUApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HealU App',
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      // HALAMAN PERTAMA KALI JALAN:
      home: const SplashScreen(),
    );
  }
}