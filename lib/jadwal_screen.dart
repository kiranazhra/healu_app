import 'package:flutter/material.dart';
import 'package:healu_app/services/api_client.dart';
import 'dart:convert';
import 'laporan_menu_screen.dart' show HealUColors;
import 'admin_bottom_nav.dart';
import 'user_session.dart';

class JadwalScreen extends StatefulWidget {
  final String? idUser;
  final String? role;

  const JadwalScreen({super.key, this.idUser, this.role});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen>
    with SingleTickerProviderStateMixin {
  static const String _baseUrl =
      'https://chump-vividness-escapable.ngrok-free.dev/healu_api';

  late TabController _tabController;

  late final String? _idUser;
  late final String? _role;

  List<dynamic> _jadwalDokter = [];
  List<dynamic> _jadwalPasien = [];
  bool _isLoadingDokter = true;
  bool _isLoadingPasien = true;

  @override
  void initState() {
    super.initState();
    _idUser = widget.idUser ?? UserSession.instance.idUser;
    _role = widget.role ?? UserSession.instance.role;
    _tabController = TabController(length: 2, vsync: this);
    _fetchJadwalDokter();
    _fetchJadwalPasien();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchJadwalDokter() async {
    setState(() => _isLoadingDokter = true);
    try {
      final res = await ApiClient.instance
          .get(Uri.parse('$_baseUrl/get_jadwal_dokter.php'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['status'] == 'success') {
          setState(() {
            _jadwalDokter = json['data'] ?? [];
            _isLoadingDokter = false;
          });
          return;
        }
      }
      setState(() => _isLoadingDokter = false);
    } catch (e) {
      debugPrint('Error fetch jadwal dokter: $e');
      if (mounted) setState(() => _isLoadingDokter = false);
    }
  }

  Future<void> _fetchJadwalPasien() async {
    setState(() => _isLoadingPasien = true);
    try {
      final res = await ApiClient.instance
          .get(Uri.parse('$_baseUrl/get_jadwal_konsultasi.php'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['status'] == 'success') {
          setState(() {
            _jadwalPasien = json['data'] ?? [];
            _isLoadingPasien = false;
          });
          return;
        }
      }
      setState(() => _isLoadingPasien = false);
    } catch (e) {
      debugPrint('Error fetch jadwal pasien: $e');
      if (mounted) setState(() => _isLoadingPasien = false);
    }
  }

  String _formatTanggal(String? tanggal) {
    if (tanggal == null || tanggal.isEmpty) return '-';
    const bulanPendek = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    try {
      final date = DateTime.parse(tanggal);
      return '${date.day} ${bulanPendek[date.month - 1]} ${date.year}';
    } catch (_) {
      return tanggal;
    }
  }

  // Ubah status mentah dari API jadi label singkat yang manusiawi,
  // supaya badge tidak jadi terlalu panjang dan memicu overflow.
  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu_pembayaran':
        return 'Menunggu Bayar';
      case 'menunggu_konsultasi':
        return 'Menunggu';
      case 'berlangsung':
        return 'Berlangsung';
      case 'selesai':
        return 'Selesai';
      case 'batal':
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealUColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildJadwalDokterTab(), _buildJadwalPasienTab()],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNav(
        currentIndex: 1,
        idUser: _idUser,
        role: _role,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HealUColors.primary.withValues(alpha: 0.55),
            HealUColors.background,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                Icons.calendar_month_outlined,
                size: 100,
                color: HealUColors.primaryDark.withValues(alpha: 0.12),
              ),
            ),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Jadwal",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: HealUColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Pantau jadwal dokter & konsultasi pasien",
                  style: TextStyle(
                    fontSize: 13,
                    color: HealUColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: HealUColors.border),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: HealUColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.all(4),
          labelColor: Colors.white,
          unselectedLabelColor: HealUColors.textSecondary,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: "Jadwal Dokter"),
            Tab(text: "Jadwal Pasien"),
          ],
        ),
      ),
    );
  }

  Widget _buildJadwalDokterTab() {
    if (_isLoadingDokter) {
      return const Center(
        child: CircularProgressIndicator(color: HealUColors.primary),
      );
    }
    if (_jadwalDokter.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_busy_outlined,
        title: 'Belum ada jadwal dokter',
        subtitle: 'Jadwal praktik dokter akan tampil di sini',
        onRefresh: _fetchJadwalDokter,
      );
    }
    return RefreshIndicator(
      color: HealUColors.primary,
      onRefresh: _fetchJadwalDokter,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _jadwalDokter.length,
        itemBuilder: (context, i) {
          final d = _jadwalDokter[i];
          final nama = (d['nama_dokter'] ?? d['nama'] ?? '-').toString();
          final spesialis = (d['spesialis'] ?? '-').toString();
          final tanggal = (d['tanggal_jadwal'] ?? '').toString();
          final jam = (d['waktu_jadwal'] ?? '-').toString();
          final statusRaw = (d['status_konsultasi'] ?? 'Aktif').toString();
          final isAktif = statusRaw.toLowerCase() != 'batal';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HealUColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.medical_services_outlined,
                    color: Colors.blue.shade400,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama dokter + badge status sejajar, tapi nama
                      // dibungkus Flexible+ellipsis supaya tidak mendorong
                      // badge keluar layar kalau namanya panjang.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              nama,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: HealUColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(
                            label: _statusLabel(statusRaw),
                            color: isAktif
                                ? HealUColors.primaryDark
                                : Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        spesialis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: HealUColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Baris tanggal & jam dibungkus Wrap supaya kalau
                      // ruang tidak cukup, elemen turun ke baris baru
                      // alih-alih memaksa muat dan overflow.
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          _iconText(Icons.calendar_today, _formatTanggal(tanggal)),
                          _iconText(Icons.access_time, jam),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildJadwalPasienTab() {
    if (_isLoadingPasien) {
      return const Center(
        child: CircularProgressIndicator(color: HealUColors.primary),
      );
    }
    if (_jadwalPasien.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_note_outlined,
        title: 'Belum ada jadwal konsultasi',
        subtitle: 'Konsultasi pasien yang terjadwal akan tampil di sini',
        onRefresh: _fetchJadwalPasien,
      );
    }
    return RefreshIndicator(
      color: HealUColors.primary,
      onRefresh: _fetchJadwalPasien,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _jadwalPasien.length,
        itemBuilder: (context, i) {
          final d = _jadwalPasien[i];
          final namaPasien = (d['nama_pasien'] ?? '-').toString();
          final namaDokter = (d['nama_dokter'] ?? '-').toString();
          final tanggal = (d['tanggal_jadwal'] ?? '').toString();
          final jam = (d['waktu_jadwal'] ?? '-').toString();
          final statusRaw = (d['status_konsultasi'] ?? 'Menunggu').toString();

          Color statusColor;
          switch (statusRaw.toLowerCase()) {
            case 'selesai':
              statusColor = HealUColors.primaryDark;
              break;
            case 'berlangsung':
              statusColor = Colors.blue;
              break;
            case 'batal':
            case 'dibatalkan':
              statusColor = Colors.red;
              break;
            default:
              statusColor = Colors.orange;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HealUColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.event_outlined,
                    color: Colors.orange.shade400,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              namaPasien,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: HealUColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(
                            label: _statusLabel(statusRaw),
                            color: statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'dengan $namaDokter',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: HealUColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          _iconText(Icons.calendar_today, _formatTanggal(tanggal)),
                          _iconText(Icons.access_time, jam),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper kecil untuk pasangan ikon+teks (tanggal/jam), dipakai di Wrap
  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: HealUColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: HealUColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(
      color: HealUColors.primary,
      onRefresh: onRefresh,
      child: ListView(
        children: [
          SizedBox(
            height: 420,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: HealUColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 48, color: HealUColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: HealUColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: HealUColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}