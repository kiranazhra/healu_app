import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'konsultasi_screen.dart';
import 'dokter_screen.dart';
import 'admin_dashboard_screen.dart';

class NavigationRouter {
  static Route<dynamic> generateRoute(
    String idUser,
    String role,
  ) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'superadmin':
        return MaterialPageRoute(
          builder: (_) => AdminDashboardScreen(
            idUser: idUser,
            role: role,
          ),
        );

      case 'dokter':
        return MaterialPageRoute(
          builder: (_) => DokterScreen(idDokterUser: idUser),
        );

      case 'pasien':
        return MaterialPageRoute(
          builder: (_) => KonsultasiScreen(
            idUser: idUser,
            role: role,
          ),
        );

      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}