import 'package:flutter/material.dart';
import 'laporan_menu_screen.dart' show HealUColors;

class BantuanScreen extends StatelessWidget {
  const BantuanScreen({super.key});

  static const List<Map<String, String>> _faqList = [
    {
      'q': 'Bagaimana cara menambah dokter baru?',
      'a':
          'Buka menu Beranda, pilih "Tambah Dokter" di bagian Aksi Cepat, lalu isi data dokter pada formulir yang muncul.',
    },
    {
      'q': 'Bagaimana cara melihat laporan mood pasien?',
      'a':
          'Buka menu Laporan di navigasi bawah, lalu pilih kategori laporan yang ingin dilihat.',
    },
    {
      'q': 'Kenapa jadwal dokter tidak muncul?',
      'a':
          'Pastikan koneksi internet stabil, lalu tarik layar ke bawah pada halaman Jadwal untuk memuat ulang data.',
    },
    {
      'q': 'Bagaimana cara mengubah kata sandi?',
      'a':
          'Buka menu Profil, pilih "Ubah Kata Sandi" pada bagian Pengaturan, lalu ikuti instruksi yang tersedia.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealUColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    "Pertanyaan Umum",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: HealUColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._faqList.map((faq) => _buildFaqTile(faq['q']!, faq['a']!)),
                  const SizedBox(height: 24),
                  const Text(
                    "Hubungi Kami",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: HealUColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildContactTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: 'support@healu.id',
                  ),
                  const SizedBox(height: 10),
                  _buildContactTile(
                    icon: Icons.phone_outlined,
                    label: 'WhatsApp',
                    value: '+62 812-3456-7890',
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text(
                      'HealU App v1.0.0',
                      style: TextStyle(
                        fontSize: 11,
                        color: HealUColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.fromLTRB(12, 8, 20, 22),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: HealUColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 4),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bantuan",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: HealUColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Pusat bantuan & pertanyaan umum",
                  style: TextStyle(
                    fontSize: 12,
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

  Widget _buildFaqTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HealUColors.border),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          iconColor: HealUColors.primary,
          collapsedIconColor: Colors.grey,
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: HealUColors.textPrimary,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: const TextStyle(
                  fontSize: 12,
                  color: HealUColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HealUColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: HealUColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: HealUColors.primary),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: HealUColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: HealUColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}