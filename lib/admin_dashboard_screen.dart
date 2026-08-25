import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'login_screen.dart';
import 'admin_dokter_screen.dart';
import 'admin_pasien_screen.dart';
import 'laporan_menu_screen.dart';
import 'tambah_pasien_screen.dart';
import 'buat_konsultasi_screen.dart';
import 'admin_bottom_nav.dart';
import 'jadwal_screen.dart';
import 'services/api_client.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String idUser;
  final String role;

  const AdminDashboardScreen({
    super.key,
    required this.idUser,
    required this.role,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final String baseUrl =
      "https://chump-vividness-escapable.ngrok-free.dev/healu_api";
  final Color primaryGreen = const Color(0xFF8EB76E);
  final Color bgCream = const Color(0xFFFFFDEC);

  int _totalDokter = 0;
  int _totalPasien = 0;
  int _totalKonsultasi = 0;

  int _dokterBaru = 0;
  int _pasienBaru = 0;
  int _konsultasiBaru = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStatistik();
  }

  DateTime? _parseTanggal(Map item) {
    const possibleKeys = [
      'created_at',
      'tanggal_daftar',
      'tgl_daftar',
      'createdAt',
      'tanggal',
      'tgl',
    ];
    for (final key in possibleKeys) {
      final raw = item[key];
      if (raw != null) {
        try {
          return DateTime.parse(raw.toString());
        } catch (_) {}
      }
    }
    return null;
  }

  int _hitungBaru(List items, {int days = 7}) {
    final now = DateTime.now();
    int count = 0;
    for (final item in items) {
      if (item is Map) {
        final tanggal = _parseTanggal(item);
        if (tanggal != null && now.difference(tanggal).inDays <= days) {
          count++;
        }
      }
    }
    return count;
  }

  Future<void> _fetchStatistik() async {
  try {
    var resDokter = await ApiClient.instance
        .get(Uri.parse("$baseUrl/get_dokters.php"))
        .timeout(const Duration(seconds: 10));
    if (resDokter.statusCode == 200) {
      var json = jsonDecode(resDokter.body);
      if (json['status'] == 'success') {
        final dataDokter = (json['data'] as List?) ?? [];
        _totalDokter = dataDokter.length;
        _dokterBaru = _hitungBaru(dataDokter);
      }
    }

    var resPasien = await ApiClient.instance
        .get(Uri.parse("$baseUrl/get_pasien.php"))
        .timeout(const Duration(seconds: 10));
    if (resPasien.statusCode == 200) {
      var json = jsonDecode(resPasien.body);
      if (json['status'] == 'success') {
        final dataPasien = (json['data'] as List?) ?? [];
        _totalPasien = dataPasien.length;
        _pasienBaru = _hitungBaru(dataPasien);
      }
    }

    var resKonsultasi = await ApiClient.instance
        .get(Uri.parse("$baseUrl/get_total_konsultasi.php"))
        .timeout(const Duration(seconds: 10));
    if (resKonsultasi.statusCode == 200) {
      var json = jsonDecode(resKonsultasi.body);
      if (json['status'] == 'success') {
        _totalKonsultasi = json['total'] ?? 0;
        _konsultasiBaru = json['total_7_hari'] ?? json['baru'] ?? 0;
      }
    }

    if (mounted) setState(() => _isLoading = false);
  } catch (e) {
    debugPrint("fetchStatistik error: $e");
    if (mounted) setState(() => _isLoading = false);
  }
}

  void _showLogoutConfirm() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Konfirmasi Logout",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text("Apakah Anda yakin ingin keluar?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text(
                "Logout",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryGreen))
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildStatCards(),
                    const SizedBox(height: 28),
                    _buildAksiCepat(),
                    const SizedBox(height: 28),
                    _buildKelolaData(),
                    const SizedBox(height: 20),
                    _buildRingkasanAktivitas(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: 0,
        idUser: widget.idUser,
        role: widget.role,
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    JadwalScreen(idUser: widget.idUser, role: widget.role),
              ),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => LaporanMenuScreen(
                  idUser: widget.idUser,
                  role: widget.role,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primaryGreen.withValues(alpha: 0.55), bgCream],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 20, 26),
        child: Stack(
          children: [
            Positioned(
              right: -6,
              bottom: -10,
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  Image.asset(
                    'assets/images/dokumen.png',
                    width: 110,
                    height: 110,
                  ),
                  Positioned(
                    left: -18,
                    bottom: -6,
                    child: Image.asset(
                      'assets/images/plant.png',
                      width: 60,
                      height: 60,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Selamat datang,",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Row(
                            children: [
                              Text(
                                "Admin",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text("👋", style: TextStyle(fontSize: 22)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        _buildHeaderIcon(
                          Icons.logout_rounded,
                          showDot: false,
                          onTap: _showLogoutConfirm,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  "Kelola data dan pantau\naktivitas klinik dengan mudah.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(
    IconData icon, {
    bool showDot = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black54, size: 20),
          ),
          if (showDot)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              "Dokter",
              _totalDokter.toString(),
              Colors.blue.shade400,
              iconAsset: 'assets/images/doctor.svg',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              "Pasien",
              _totalPasien.toString(),
              Colors.orange.shade400,
              iconAsset: 'assets/images/patient.svg',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              "Konsultasi",
              _totalKonsultasi.toString(),
              primaryGreen,
              icon: Icons.chat_bubble_outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color color, {
    IconData? icon,
    String? iconAsset,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: iconAsset != null
                ? SvgPicture.asset(
                    iconAsset,
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  )
                : Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const Text(
            "Total",
            style: TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildAksiCepat() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Aksi Cepat",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAksiCepatItem(
                  "Tambah\nDokter",
                  Icons.person_add_alt_1_rounded,
                  Colors.blue.shade400,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminDokterScreen(
                        idUser: widget.idUser,
                        autoOpenAddForm: true,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _buildAksiCepatItem(
                  "Tambah\nPasien",
                  Icons.person_add_rounded,
                  Colors.orange.shade400,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TambahPasienScreen(
                        onRefresh: () => _fetchStatistik(),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _buildAksiCepatItem(
                  "Buat\nKonsultasi",
                  Icons.chat_bubble_outline_rounded,
                  primaryGreen,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          BuatKonsultasiScreen(idAdmin: widget.idUser),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _buildAksiCepatItem(
                  "Lihat\nLaporan",
                  Icons.description_outlined,
                  Colors.purple.shade400,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LaporanMenuScreen(
                        idUser: widget.idUser,
                        role: widget.role,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAksiCepatItem(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildKelolaData() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Kelola Data",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            "Kelola Dokter",
            "Tambah, edit, atau hapus data dokter",
            'assets/images/doctor.svg',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminDokterScreen(idUser: widget.idUser),
              ),
            ),
            Colors.blue.shade400,
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            "Kelola Pasien",
            "Lihat, edit, atau hapus data pasien",
            'assets/images/patient.svg',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminPasienScreen(idUser: widget.idUser),
              ),
            ),
            Colors.orange.shade400,
          ),
          const SizedBox(height: 12),
          _buildMenuCard(
            "Kelola Laporan",
            "Rekam medis & analisis mood pasien",
            'assets/images/file.svg',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LaporanMenuScreen(
                  idUser: widget.idUser,
                  role: widget.role,
                ),
              ),
            ),
            Colors.purple.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    String title,
    String subtitle,
    String iconAsset,
    VoidCallback onTap,
    Color color,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SvgPicture.asset(
                iconAsset,
                width: 22,
                height: 22,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildRingkasanAktivitas() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primaryGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryGreen.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ringkasan Aktivitas",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildRingkasanItem(
                    Icons.trending_up_rounded,
                    Colors.blue.shade400,
                    _dokterBaru,
                    "Dokter baru",
                  ),
                ),
                Expanded(
                  child: _buildRingkasanItem(
                    Icons.person_outline_rounded,
                    Colors.orange.shade400,
                    _pasienBaru,
                    "Pasien baru",
                  ),
                ),
                Expanded(
                  child: _buildRingkasanItem(
                    Icons.chat_bubble_outline_rounded,
                    primaryGreen,
                    _konsultasiBaru,
                    "Konsultasi baru",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRingkasanItem(
    IconData icon,
    Color color,
    int value,
    String label,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          "+$value",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        const Text(
          "7 hari terakhir",
          style: TextStyle(color: Colors.grey, fontSize: 9),
        ),
      ],
    );
  }
}