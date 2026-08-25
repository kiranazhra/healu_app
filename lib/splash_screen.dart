import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'admin_dashboard_screen.dart';
import 'home_screen.dart';
import 'dokter_screen.dart';
import 'user_session.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

// Mengaktifkan SingleTickerProviderStateMixin untuk menangani animasi waktu yang presisi
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    // 1. KONTROLER ANIMASI: Diatur berjalan selama tepat 5 detik
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // 2. TWEEN ANIMASI: Mengalirkan angka linear dari 0.0 (0%) ke 1.0 (100%)
    _progressAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ), // Efek akselerasi halus di awal & akhir
        )..addListener(() {
          // Memicu pembangunan ulang widget setiap kali angka persen berubah
          setState(() {});
        });

    // 3. JALANKAN ANIMASI
    _animationController.forward();

    // 4. PERPINDAHAN HALAMAN: Otomatis pindah saat durasi 5 detik animasi selesai
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _goToNextScreen();
      }
    });
  }

  void _goToNextScreen() {
    final idUser = UserSession.instance.idUser;
    final role = UserSession.instance.role;

    Widget nextScreen;

    if (idUser != null && role != null) {
      // Sesi ditemukan → arahkan sesuai role, tidak perlu login ulang
      switch (role) {
        case 'admin':
        case 'superadmin':
          nextScreen = AdminDashboardScreen(idUser: idUser, role: role);
          break;
        case 'dokter':
          nextScreen = DokterScreen(idDokterUser: idUser);
          break;
        case 'pasien':
          nextScreen = HomeScreen(email: '', idPasien: idUser);
          break;
        default:
          nextScreen = const LoginScreen();
      }
    } else {
      // Tidak ada sesi tersimpan → ke halaman login
      nextScreen = const LoginScreen();
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(
          milliseconds: 1000,
        ), // Efek memudar halaman selama 1 detik
      ),
    );
  }

  @override
  void dispose() {
    _animationController
        .dispose(); // Membersihkan memori kontroler saat berpindah halaman
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mengonversi nilai animasi (0.0 - 1.0) menjadi format angka integer persen (0 - 100)
    int presentaseAngka = (_progressAnimation.value * 100).toInt();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDEC), // Warna krem HealU Anda
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Baris Judul & Ikon Asli Anda
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'HealU',
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8EB76E),
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.spa, color: Color(0xFF8EB76E), size: 40),
              ],
            ),
            const SizedBox(height: 8),
            // Slogan Asli Anda
            const Text(
              'You Matter, We Care ❤️',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 60),

            // INDIKATOR LOADING HORIZONTAL BERBASIS PERSEN
            SizedBox(
              width: 160, // Lebar tiang loading
              height: 5, // Ketebalan garis loading
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _progressAnimation
                      .value, // Mengikuti jalannya nilai animasi (0.0 ke 1.0)
                  backgroundColor: const Color(0xFFE5E5E5),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF8EB76E),
                  ), // Hijau Sage
                ),
              ),
            ),
            const SizedBox(height: 12),

            // TEKS INDIKATOR PERSENTASE REAL-TIME (1% - 100%)
            Text(
              '$presentaseAngka%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8EB76E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}