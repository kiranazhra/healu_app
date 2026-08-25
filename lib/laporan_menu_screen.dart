import 'package:flutter/material.dart';
import 'rekam_medis_list_screen.dart';
import 'laporan_mood_screen.dart';
import 'resep_obat_list_screen.dart';
import 'invoice_pembayaran_screen.dart';
import 'admin_bottom_nav.dart';

class HealUColors {
  static const Color background = Color(0xFFF8F6F1);
  static const Color primary = Color(0xFF7DBA6F);
  static const Color primaryLight = Color(0xFFEAF4E5);
  static const Color primaryDark = Color(0xFF4A8F3F);
  static const Color border = Color(0xFFE8E8E8);
  static const Color textPrimary = Color(0xFF2E2E2E);
  static const Color textSecondary = Color(0xFF757575);
}

class LaporanMenuScreen extends StatelessWidget {
  final String? idUser;
  final String? role;

  const LaporanMenuScreen({super.key, this.idUser, this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealUColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _menuCard(
                      context,
                      icon: Icons.description_outlined,
                      title: "Laporan Rekam Medis",
                      subtitle: "Rekam medis SOAP pasien",
                      iconColor: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RekamMedisListScreen(
                              title: 'Laporan Rekam Medis',
                              isReadOnly: true,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _menuCard(
                      context,
                      icon: Icons.mood_outlined,
                      title: "Analisis Mood",
                      subtitle: "Riwayat mood pasien",
                      iconColor: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LaporanMoodScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    _menuCard(
                      context,
                      icon: Icons.medication_outlined,
                      title: "Laporan Resep Obat",
                      subtitle: "Pantau seluruh resep obat pasien",
                      iconColor: Colors.deepPurple,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ResepObatListScreen(
                              isReadOnly: true,
                              title: 'Laporan Resep Obat',
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
                      subtitle: "Riwayat invoice seluruh pasien",
                      iconColor: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InvoicePembayaranScreen(
                              idPasien: null, // empty string = mode admin, lihat semua
                            ),
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
      bottomNavigationBar: AdminBottomNav(
        currentIndex: 2,
        idUser: idUser,
        role: role,
      ),
    );
  }

  // ── HEADER GRADASI (mengikuti gaya Admin Dashboard) ─────────────
  Widget _buildHeader(BuildContext context) {
    // Tombol back hanya muncul kalau screen ini benar-benar ditumpuk
    // (misal dibuka lewat "Lihat Laporan" di dashboard). Kalau dibuka
    // lewat tab navbar (pushReplacement), tidak ada yang bisa di-pop,
    // jadi tombol back otomatis disembunyikan.
    final bool showBackButton = Navigator.canPop(context);

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
                if (showBackButton) ...[
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: HealUColors.primaryDark,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                const Text(
                  "Kelola Laporan Pasien",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: HealUColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Lihat dan kelola laporan pasien",
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
