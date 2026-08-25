// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'ringkasan_konsultasi_screen.dart';
import 'gender_avatar_helper.dart';

class SesiKonsultasiScreen extends StatefulWidget {
  final String idKonsultasi;
  final String idUser;
  final String role;
  final String baseUrl;
  final VoidCallback onSelesai;
  final Map<String, dynamic> detail;

  const SesiKonsultasiScreen({
    super.key,
    required this.idKonsultasi,
    required this.idUser,
    required this.role,
    required this.baseUrl,
    required this.onSelesai,
    required this.detail,
  });

  @override
  State<SesiKonsultasiScreen> createState() => _SesiKonsultasiScreenState();
}

class _SesiKonsultasiScreenState extends State<SesiKonsultasiScreen> {
  final Color primaryGreen = const Color(0xFF8EB76E);
  final Color bgCream = const Color(0xFFFFFDEC);

  late Map<String, dynamic> _detail;

  @override
  void initState() {
    super.initState();
    _detail = widget.detail;
  }

  void _bukaChat() {
    String namaDokter = _detail['nama_dokter'] ?? 'Dr. Dokter';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          idKonsultasi: widget.idKonsultasi,
          namaLawanBicara: namaDokter,
          idUser: widget.idUser,
          idRole: widget.role,
        ),
      ),
    );
  }

  void _akhiriDanSimpan() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Akhiri & Simpan Laporan?"),
        content: const Text(
          "Apakah konsultasi sudah selesai? Data akan disimpan sebagai riwayat.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);

              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RingkasanKonsultasiScreen(
                      dataRiwayat: _detail,
                      role: widget.role,
                    ),
                  ),
                );
              }
            },
            child: const Text(
              "Simpan & Lanjut",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'menunggu_pembayaran':
        return 'Menunggu Pembayaran';
      case 'menunggu_konsultasi':
        return 'Menunggu Dimulai';
      case 'berlangsung':
        return 'Sedang Berlangsung';
      case 'selesai':
        return 'Selesai';
      default:
        return status ?? '-';
    }
  }

  String _formatHarga(dynamic harga) {
    if (harga == null) return 'Rp0';
    int nilai = int.tryParse(harga.toString()) ?? 0;
    String formatted = nilai.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match.group(1)}.',
    );
    return 'Rp$formatted';
  }

  @override
  Widget build(BuildContext context) {
    String namaDokter = _detail['nama_dokter'] ?? 'Dr. Dokter';
    String? jenisKelaminDokter = _detail['jenis_kelamin_dokter']?.toString();

    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Sesi Konsultasi",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Dokter
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar dokter disesuaikan dengan gender (konsisten
                  // dengan KonsultasiScreen), bukan gambar statis lagi.
                  GenderAvatarHelper.buildAvatar(
                    namaDokter,
                    jenisKelamin: jenisKelaminDokter,
                    radius: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          namaDokter,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _detail['spesialis'] ?? 'Spesialis',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _statusLabel(_detail['status_konsultasi']),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7A5800),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Ringkasan Sesi
            const Text(
              "Ringkasan Sesi",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    "Jadwal",
                    "${_detail['tanggal_jadwal'] ?? '-'}\n${_detail['waktu_jadwal'] ?? '-'} WIB",
                  ),
                  const Divider(height: 24),
                  _buildSummaryRow(
                    "Durasi",
                    "${_detail['durasi'] ?? '30'} Menit",
                  ),
                  const Divider(height: 24),
                  _buildSummaryRow(
                    "Biaya",
                    _formatHarga(_detail['total_harga']),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Aksi
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _bukaChat,
                icon: const Icon(Icons.chat, color: Colors.white),
                label: const Text(
                  "Buka Chat",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Hanya tampilkan tombol "Akhiri & Simpan Laporan" jika role = dokter
            if (widget.role == 'dokter')
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _akhiriDanSimpan,
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                    "Akhiri & Simpan Laporan",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryGreen, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Button "Menunggu Dokter"
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  "Menunggu Dokter...",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}