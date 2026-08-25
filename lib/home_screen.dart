// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:healu_app/laporan_screen.dart';
import 'login_screen.dart';
import 'monitoring_screen.dart';
import 'profile_screen.dart';
import 'quotes_screen.dart';
import 'konsultasi_screen.dart';
import 'reminder_obat_screen.dart';
import 'sos_screen.dart';

class HomeScreen extends StatefulWidget {
  final String email;
  final String idPasien;

  // Constructor wajib menerima parameter email dan idPasien
  const HomeScreen({super.key, required this.email, required this.idPasien});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bottomNavIndex = 0;
  late List<Widget> _pages; // Mengontrol indeks navigasi bawah

  @override
  void initState() {
    super.initState();
    // Inisialisasi daftar halaman di sini
    _pages = [
      const Center(child: Text("Home")), // Ganti dengan widget Home Anda
      LaporanScreen(
        idPasien: widget.idPasien,
      ), // Ganti dengan widget Riwayat Anda
      QuotesScreen(), // Ganti dengan widget Quotes Anda
      ProfileScreen(
        userEmail: widget.email,
      ), // Halaman Profil yang sudah dibuat
    ];
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar Aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _logout(); // Memanggil fungsi _logout yang sudah Anda miliki
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk membersihkan tumpukan halaman dan kembali ke halaman Login
  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) =>
          false, // Menghapus semua riwayat tumpukan halaman agar tidak bisa di-back
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDEC),
      // 1. Body menggunakan IndexedStack agar bisa berganti halaman
      body: SafeArea(
        child: IndexedStack(
          index: _pages[_bottomNavIndex] == const Center(child: Text("Home"))
              ? 0
              : _bottomNavIndex, // Menentukan halaman yang aktif berdasarkan indeks
          children: [
            // Index 0: Konten Home Anda
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // HEADER: Nama Pengguna & Tombol Logout
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${widget.email} 🌿',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Semoga harimu lebih baik hari ini!',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showLogoutDialog(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Colors.redAccent,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // BAGIAN 1: INPUT MOOD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mood hari ini',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Text(
                            'Bagaimana perasaanmu?',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _emojiButton('🟢', 'Sangat Baik'),
                              _emojiButton('🟡', 'Baik'),
                              _emojiButton('⚪', 'Biasa Saja'),
                              _emojiButton('🟠', 'Buruk'),
                              _emojiButton('🔴', 'Sangat Buruk'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // BAGIAN 2: GRID MENU
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.3,
                      children: [
                        _menuCard(
                          'Konsultasi',
                          Icons.chat_bubble_outline_rounded,
                          Colors.blue.shade300,
                        ),
                        _menuCard(
                          'Monitoring',
                          Icons.analytics_outlined,
                          Colors.pink.shade300,
                        ),
                        _menuCard(
                          'Reminder Obat',
                          Icons.access_time_rounded,
                          Colors.orange.shade300,
                        ),
                        _menuCard(
                          'SOS Darurat',
                          Icons.emergency_share_outlined,
                          Colors.red.shade300,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // BAGIAN 3: QUOTES
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCECD0),
                        borderRadius: BorderRadius.circular(24),
                        image: const DecorationImage(
                          image: AssetImage(
                            'assets/images/background_quotes2.jpg',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quotes Hari Ini',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '"You are stronger than you think, even on your hardest days."',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Index 1, 2, 3: Placeholder Halaman lain
            LaporanScreen(idPasien: widget.idPasien),
            QuotesScreen(),
            ProfileScreen(userEmail: widget.email),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) => setState(() => _bottomNavIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF8EB76E),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: 'Quotes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _emojiButton(String emoji, String status) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mood kamu terdata: $status'),
            backgroundColor: const Color(0xFF8EB76E),
          ),
        );
      },
      child: Text(emoji, style: const TextStyle(fontSize: 28)),
    );
  }

  Widget _menuCard(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (title == 'Monitoring') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MonitoringScreen(userEmail: widget.email),
                ),
              );
            } else if (title == 'Konsultasi') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      KonsultasiScreen(idUser: widget.idPasien, role: 'pasien'),
                ),
              );
            } else if (title == 'Reminder Obat') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ReminderObatScreen(idUser: widget.idPasien),
                ),
              );
            } else if (title == 'SOS Darurat') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SosScreen(idPasien: widget.idPasien),
                ),
              );
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Membuka Fitur $title')));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 32, color: color),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
