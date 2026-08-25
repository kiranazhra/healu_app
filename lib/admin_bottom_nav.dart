import 'package:flutter/material.dart';
import 'laporan_menu_screen.dart' show HealUColors, LaporanMenuScreen;
import 'jadwal_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_profile_screen.dart';
import 'user_session.dart';

class AdminBottomNav extends StatelessWidget {
  const AdminBottomNav({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.idUser,
    this.role,
  });

  final int currentIndex;
  final ValueChanged<int>? onTap;
  final String? idUser;
  final String? role;

  void _handleTap(BuildContext context, int index) {
    // Fallback ke sesi tersimpan kalau parameter dari widget kosong
    final uid = idUser ?? UserSession.instance.idUser;
    final r = role ?? UserSession.instance.role;

    debugPrint('TAP index=$index idUser=$uid role=$r');

    if (onTap != null) {
      onTap!(index);
      return;
    }
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        if (uid != null && r != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AdminDashboardScreen(idUser: uid, role: r),
            ),
          );
        } else {
          debugPrint('Beranda: sesi tidak ditemukan (idUser/role null)');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesi tidak ditemukan, silakan login ulang.'),
            ),
          );
        }
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => JadwalScreen(idUser: uid, role: r),
          ),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LaporanMenuScreen()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminProfileScreen(idUser: uid, role: r),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: HealUColors.primary,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: (index) => _handleTap(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: "Beranda",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          label: "Jadwal",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.description_outlined),
          label: "Laporan",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: "Profil",
        ),
      ],
    );
  }
}
