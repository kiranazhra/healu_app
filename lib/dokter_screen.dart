import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'login_screen.dart';
import 'detail_konsultasi_dokter_screen.dart';
import 'rekam_medis_detail_screen.dart';
import 'tambah_rekam_medis_screen.dart';
import 'resep_obat_list_screen.dart';
import 'services/api_client.dart';

class DokterScreen extends StatefulWidget {
  final String idDokterUser;

  const DokterScreen({super.key, required this.idDokterUser});

  @override
  State<DokterScreen> createState() => _DokterScreenState();
}

class _DokterScreenState extends State<DokterScreen> {
  final String baseUrl =
      "https://chump-vividness-escapable.ngrok-free.dev/healu_api";
  final Color primaryGreen = const Color(0xFF8EB76E);

  List<dynamic> _daftarPasien = [];
  bool _isLoading = true;
  bool _isCheckingRekamMedis = false;
  int _selectedTab = 0; // 0 = Aktif, 1 = Riwayat
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    ambilDaftarPasien();
    // Polling setiap 5 detik
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => ambilDaftarPasien(),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> ambilDaftarPasien() async {
    try {
      var respon = await ApiClient.instance
          .get(
            Uri.parse(
              "$baseUrl/get_konsultasi_dokter.php?id_dokter_user=${widget.idDokterUser}",
            ),
          )
          .timeout(const Duration(seconds: 10));

      var data = jsonDecode(respon.body);

      if (data['status'] == 'success' && mounted) {
        setState(() {
          _daftarPasien = data['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Filter konsultasi aktif (termasuk yang menunggu pembayaran, karena belum selesai)
  List<dynamic> get _konsultasiAktif {
    return _daftarPasien
        .where(
          (k) =>
              k['status_konsultasi'] == 'berlangsung' ||
              k['status_konsultasi'] == 'menunggu_konsultasi' ||
              k['status_konsultasi'] == 'menunggu_pembayaran',
        )
        .toList();
  }

  // Filter riwayat (hanya yang benar-benar sudah selesai atau dibatalkan)
  List<dynamic> get _riwayat {
    return _daftarPasien
        .where(
          (k) =>
              k['status_konsultasi'] == 'selesai' ||
              k['status_konsultasi'] == 'dibatalkan',
        )
        .toList();
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
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status ?? '-';
    }
  }

  void _bukaDetailKonsultasi(Map<String, dynamic> konsultasi) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailKonsultasiDokterScreen(
          dataKonsultasi: konsultasi,
          idDokterUser: widget.idDokterUser,
          baseUrl: baseUrl,
          onRefresh: ambilDaftarPasien,
        ),
      ),
    ).then((_) => ambilDaftarPasien());
  }

  // Cek apakah rekam medis untuk konsultasi ini sudah ada -> routing ke Tambah atau Detail
  Future<void> _bukaRekamMedis(Map<String, dynamic> konsultasi) async {
    if (_isCheckingRekamMedis) return;

    final int idKonsultasi = int.tryParse(konsultasi['id'].toString()) ?? 0;
    final int idPasien = int.tryParse(konsultasi['id_pasien']?.toString() ?? '') ?? 0;
    final int idDokter = int.tryParse(widget.idDokterUser) ?? 0;
    final String namaPasien = (konsultasi['nama_pasien'] ?? 'Pasien').toString();
    final String namaDokter = (konsultasi['nama_dokter'] ?? 'Dokter').toString();

    if (idKonsultasi == 0 || idPasien == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data konsultasi tidak lengkap')),
      );
      return;
    }

    setState(() => _isCheckingRekamMedis = true);

    // Tampilkan loading sementara cek ke server
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient.instance
          .get(
            Uri.parse(
              '$baseUrl/get_rekam_medis_by_konsultasi.php?id_konsultasi=$idKonsultasi',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;
      Navigator.pop(context); // tutup loading dialog

      final result = jsonDecode(response.body);

      if (result['success'] == true && result['data'] != null) {
        // Sudah ada rekam medis -> buka detail (mode edit, dokter)
        final rm = result['data'];
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RekamMedisDetailScreen(
              idRekam: int.tryParse(rm['id_rekam'].toString()) ?? 0,
              nomorRekam: (rm['nomor_rekam'] ?? '-').toString(),
              namaPasien: (rm['nama_pasien'] ?? namaPasien).toString(),
              namaDokter: (rm['nama_dokter'] ?? namaDokter).toString(),
              spesialis: (rm['spesialis'] ?? '-').toString(),
              tanggalJadwal: (rm['tanggal_jadwal'] ?? '-').toString(),
              waktuJadwal: (rm['waktu_jadwal'] ?? '-').toString(),
              durasi: int.tryParse(rm['durasi']?.toString() ?? ''),
              subjektif: (rm['subjektif'] ?? '-').toString(),
              objektif: (rm['objektif'] ?? '-').toString(),
              asesmen: (rm['asesmen'] ?? '-').toString(),
              plan: (rm['plan'] ?? '-').toString(),
            ),
          ),
        ).then((result) {
          if (result == true) ambilDaftarPasien();
        });
      } else {
        // Belum ada rekam medis -> buka form tambah
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TambahRekamMedisScreen(
              idKonsultasi: idKonsultasi,
              idPasien: idPasien,
              idDokter: idDokter,
              namaPasien: namaPasien,
              namaDokter: namaDokter,
            ),
          ),
        ).then((result) {
          if (result == true) ambilDaftarPasien();
        });
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // tutup loading dialog kalau masih terbuka
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memeriksa rekam medis: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCheckingRekamMedis = false);
    }
  }

  // Buka daftar/CRUD resep obat untuk pasien pada konsultasi ini
  void _bukaResepObat(Map<String, dynamic> konsultasi) {
    final int idKonsultasi = int.tryParse(konsultasi['id'].toString()) ?? 0;
    final int idPasien = int.tryParse(konsultasi['id_pasien']?.toString() ?? '') ?? 0;
    final int idDokter = int.tryParse(widget.idDokterUser) ?? 0;
    final String namaPasien = (konsultasi['nama_pasien'] ?? 'Pasien').toString();

    if (idPasien == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data pasien tidak lengkap')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResepObatListScreen(
          idPasien: idPasien,
          idDokter: idDokter,
          idKonsultasi: idKonsultasi,
          title: 'Resep Obat - $namaPasien',
        ),
      ),
    ).then((_) => ambilDaftarPasien());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDEC),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Halo, Dokter 🩺',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Siap membantu pasien hari ini?',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text(
                              "Konfirmasi Logout",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            content: const Text(
                              "Apakah Anda yakin ingin keluar dari akun ini?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  "Batal",
                                  style: TextStyle(color: Colors.grey),
                                ),
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
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Keluar",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
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
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // RINGKASAN STATUS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Antrean Pasien',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_konsultasiAktif.length} Pasien Aktif',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // TAB PILLS (Aktif / Riwayat)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EDD8),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    _buildTabButton("Aktif", 0),
                    _buildTabButton("Riwayat", 1),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // LIST PASIEN
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: primaryGreen),
                    )
                  : _selectedTab == 0
                  ? _buildAktifList()
                  : _buildRiwayatList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    bool isActive = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isActive ? primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF79766B),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAktifList() {
    if (_konsultasiAktif.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              "Belum ada pasien aktif",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _konsultasiAktif.length,
      itemBuilder: (context, index) {
        var pasien = _konsultasiAktif[index];
        String namaPasien = pasien['nama_pasien'] ?? 'Pasien';
        String status = pasien['status_konsultasi'] ?? 'idle';

        return GestureDetector(
          onTap: () => _bukaDetailKonsultasi(pasien),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: status == 'berlangsung'
                    ? primaryGreen.withValues(alpha: 0.5)
                    : Colors.transparent,
                width: status == 'berlangsung' ? 1.5 : 0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: primaryGreen.withValues(alpha: 0.1),
                child: Icon(Icons.person, color: primaryGreen, size: 28),
              ),
              title: Text(
                namaPasien,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                _statusLabel(status),
                style: TextStyle(
                  fontSize: 12,
                  color: status == 'berlangsung' ? Colors.orange : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tombol Chat
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      color: primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tombol Rekam Medis
                  GestureDetector(
                    onTap: () => _bukaRekamMedis(pasien),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tombol Resep Obat
                  GestureDetector(
                    onTap: () => _bukaResepObat(pasien),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medication_outlined,
                        color: Colors.deepPurple,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRiwayatList() {
    if (_riwayat.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              "Tidak ada riwayat konsultasi",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _riwayat.length,
      itemBuilder: (context, index) {
        var pasien = _riwayat[index];
        String namaPasien = pasien['nama_pasien'] ?? 'Pasien';
        String status = pasien['status_konsultasi'] ?? 'idle';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey.shade200,
              child: Icon(Icons.person, color: Colors.grey, size: 28),
            ),
            title: Text(
              namaPasien,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              _statusLabel(status),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status == 'selesai'
                      ? Icons.check_circle
                      : Icons.highlight_off,
                  color: status == 'selesai' ? Colors.green : Colors.grey,
                  size: 20,
                ),
                const SizedBox(width: 8),
                // Tombol Rekam Medis & Resep Obat (hanya relevan kalau konsultasi selesai)
                if (status == 'selesai') ...[
                  GestureDetector(
                    onTap: () => _bukaRekamMedis(pasien),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _bukaResepObat(pasien),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.medication_outlined,
                        color: Colors.deepPurple,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}