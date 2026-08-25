// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'ringkasan_konsultasi_screen.dart';
import 'gender_avatar_helper.dart';

class RiwayatScreen extends StatelessWidget {
  final List<dynamic> listRiwayat;
  final String idUser;
  final String role;
  final String baseUrl;
  final Future<void> Function() onRefresh;

  const RiwayatScreen({
    super.key,
    required this.listRiwayat,
    required this.idUser,
    required this.role,
    required this.baseUrl,
    required this.onRefresh,
  });

  static const Color activeGreen = Color(0xFF8EB76E);

  String _formatHarga(dynamic harga) {
    if (harga == null) return '-';
    int nilai = int.tryParse(harga.toString()) ?? 0;
    String formatted = nilai.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)}.',
    );
    return 'Rp$formatted';
  }

  String _formatDurasi(dynamic durasi) {
    if (durasi == null) return '30 Menit';
    String bersih = durasi
        .toString()
        .replaceAll(RegExp(r'\s*menit\s*', caseSensitive: false), '')
        .trim();
    if (bersih.isEmpty) bersih = '30';
    return '$bersih Menit';
  }

  @override
  Widget build(BuildContext context) {
    if (listRiwayat.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              "Belum ada riwayat konsultasi",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: activeGreen,
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          const Text(
            "Riwayat Konsultasi",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...listRiwayat.map((item) => _buildRiwayatCard(context, item)),
        ],
      ),
    );
  }

  Widget _buildRiwayatCard(BuildContext context, Map<String, dynamic> data) {
    final String status = data['status_konsultasi']?.toString() ?? 'Selesai';
    final bool isSelesai = status.toLowerCase() == 'selesai';
    final bool isDibatalkan = status.toLowerCase() == 'dibatalkan';

    Color badgeColor;
    if (isSelesai) {
      badgeColor = activeGreen;
    } else if (isDibatalkan) {
      badgeColor = Colors.orange.shade600;
    } else {
      badgeColor = Colors.blue.shade500;
    }

    String namaDokter = data['nama_dokter'] ?? data['nama_lengkap'] ?? 'Dokter';
    String spesialis = data['spesialis'] ?? '-';
    String tanggal = data['tanggal_jadwal'] ?? '-';
    String jam = data['waktu_jadwal'] ?? '-';
    String durasi = _formatDurasi(data['durasi']);
    String totalBayar = data['total_harga'] ?? '-';
    String? alasanBatal = data['alasan_batal'];
    String? jenisKelaminDokter = data['jenis_kelamin_dokter']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + nama + badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar dokter disesuaikan dengan gender (konsisten dengan
              // KonsultasiScreen & SesiKonsultasiScreen), bukan gambar
              // statis lagi.
              GenderAvatarHelper.buildAvatar(
                namaDokter,
                jenisKelamin: jenisKelaminDokter,
                radius: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      namaDokter,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      spesialis,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 13,
                          color: activeGreen,
                        ),
                        Text(tanggal, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.access_time_outlined,
                          size: 13,
                          color: activeGreen,
                        ),
                        Text("$jam WIB", style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(maxWidth: 110),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.replaceAll('_', ' '),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF2F2F2)),
          const SizedBox(height: 12),

          // Durasi & Total Bayar (atau alasan batal)
          if (isDibatalkan) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Alasan pembatalan",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      alasanBatal ?? "Dibatalkan oleh pasien",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Total Pembayaran",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      "-",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildOutlineButton(
              icon: Icons.description_outlined,
              label: "Lihat Detail",
              onTap: () {},
              color: activeGreen,
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoItem("Durasi", durasi),
                _infoItem(
                  "Total Pembayaran",
                  _formatHarga(totalBayar),
                  align: CrossAxisAlignment.end,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildOutlineButton(
                    icon: Icons.description_outlined,
                    label: "Lihat Ringkasan",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RingkasanKonsultasiScreen(
                          dataRiwayat: data,
                          role: role,
                        ),
                      ),
                    ),
                    color: activeGreen,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildOutlineButton(
                    icon: Icons.star_border_rounded,
                    label: "Beri Ulasan",
                    onTap: () => _showUlasanDialog(context, data),
                    color: activeGreen,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoItem(
    String label,
    String value, {
    CrossAxisAlignment align = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildOutlineButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUlasanDialog(BuildContext context, Map<String, dynamic> data) {
    int rating = 5;
    final TextEditingController komentarCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Beri Ulasan",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setModalState(() => rating = i + 1),
                    child: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: komentarCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Tulis komentar kamu...",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF8F8F8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Ulasan berhasil dikirim!"),
                        backgroundColor: activeGreen,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activeGreen,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Kirim Ulasan",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}