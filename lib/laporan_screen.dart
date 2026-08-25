import 'package:flutter/material.dart';
import 'laporan_mood_wellness_screen.dart';
import 'invoice_pembayaran_screen.dart';
import 'resep_obat_list_screen.dart';
import 'rekam_medis_list_screen.dart';

class HealUColors {
  static const Color background = Color(0xFFFFFDEC);
  static const Color primary = Color(0xFF8EB76E);
  static const Color primaryLight = Color(0xFFEAF4E5);
  static const Color primaryDark = Color(0xFF6B9E5E);
  static const Color border = Color(0xFFE8E8E8);
  static const Color textPrimary = Color(0xFF2E2E2E);
  static const Color textSecondary = Color(0xFF757575);
}

class LaporanScreen extends StatelessWidget {
  final String idPasien;
  const LaporanScreen({super.key, required this.idPasien});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealUColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _menuCard(
                      context,
                      icon: Icons.description_outlined,
                      title: "Laporan Rekam Medis",
                      subtitle: "Riwayat SOAP dari dokter",
                      iconColor: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RekamMedisListScreen(
                              title: 'Rekam Medis Saya',
                              isReadOnly: true,
                              idPasien: int.tryParse(idPasien),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _menuCard(
                      context,
                      icon: Icons.mood_outlined,
                      title: "Laporan Mood & Wellness",
                      subtitle: "Riwayat mood & catatan jurnal",
                      iconColor: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                LaporanMoodWellnessScreen(idPasien: idPasien),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _menuCard(
                      context,
                      icon: Icons.medication_outlined,
                      title: "Resep Obat Digital",
                      subtitle: "Obat aktif & jadwal minum",
                      iconColor: Colors.deepPurple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ResepObatListScreen(
                              idPasien: int.tryParse(idPasien),
                              isReadOnly: true,
                              title: 'Resep Obat Digital',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _menuCard(
                      context,
                      icon: Icons.receipt_long_outlined,
                      title: "Invoice Pembayaran",
                      subtitle: "Riwayat tagihan & pembayaran",
                      iconColor: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                InvoicePembayaranScreen(idPasien: idPasien),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                Icons.assignment_outlined,
                size: 110,
                color: HealUColors.primaryDark.withValues(alpha: 0.12),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  "Riwayat & Laporan",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: HealUColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Rangkuman data kesehatan Anda",
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

  Widget _menuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: HealUColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: HealUColors.textSecondary,
                      fontSize: 12,
                    ),
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
}