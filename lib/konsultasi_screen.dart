import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'pembayaran_screen.dart';
import 'riwayat_screen.dart';
import 'sesi_konsultasi_screen.dart';
import 'services/api_client.dart';
import 'gender_avatar_helper.dart'; // sesuaikan path jika berbeda

class KonsultasiScreen extends StatefulWidget {
  final String idUser;
  final String role;

  const KonsultasiScreen({super.key, required this.idUser, required this.role});

  @override
  State<KonsultasiScreen> createState() => _KonsultasiScreenState();
}

class _KonsultasiScreenState extends State<KonsultasiScreen> {
  int _selectedIndex = 0;
  List<dynamic> _listDokter = [];
  List<dynamic> _listRiwayat = [];
  bool _isLoading = true;
  Timer? _pollingTimer;

  final String baseUrl =
      "https://chump-vividness-escapable.ngrok-free.dev/healu_api";
  static const Color activeGreen = Color(0xFF8EB76E);
  static const Color bgColor = Color(0xFFFFFDEC);

  @override
  void initState() {
    super.initState();
    _fetchData();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchRiwayat(),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchDokter(), _fetchRiwayat()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchDokter() async {
    try {
      var res = await ApiClient.instance
          .get(Uri.parse("$baseUrl/get_dokters.php"))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        var json = jsonDecode(res.body);
        if (json['status'] == 'success' && mounted) {
          setState(() => _listDokter = json['data'] ?? []);
        }
      }
    } catch (e) {
      debugPrint("fetchDokter error: $e");
    }
  }

  Future<void> _fetchRiwayat() async {
    try {
      String url = widget.role == 'dokter'
          ? "$baseUrl/get_konsultasi_dokter.php?id_dokter_user=${widget.idUser}"
          : "$baseUrl/get_riwayat_konsultasi.php?id_pasien_user=${widget.idUser}";

      var res = await ApiClient.instance
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        var json = jsonDecode(res.body);
        if (json['status'] == 'success' && mounted) {
          setState(() => _listRiwayat = json['data'] ?? []);
        }
      }
    } catch (e) {
      debugPrint("fetchRiwayat error: $e");
    }
  }

  Map<String, dynamic>? get _sesiAktif {
    try {
      return _listRiwayat.firstWhere(
        (r) =>
            r['status_konsultasi'] == 'menunggu_pembayaran' ||
            r['status_konsultasi'] == 'menunggu_konsultasi' ||
            r['status_konsultasi'] == 'berlangsung',
      );
    } catch (_) {
      return null;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'menunggu_pembayaran':
        return 'Menunggu Pembayaran';
      case 'menunggu_konsultasi':
        return 'Menunggu Konsultasi';
      case 'berlangsung':
        return 'Sedang Berlangsung';
      case 'selesai':
        return 'Selesai';
      default:
        return status ?? '-';
    }
  }

  // Format angka jadi "150.000" (pemisah ribuan pakai titik, ala format
  // rupiah Indonesia).
  String _formatRibuan(String angkaMentah) {
    final angka = int.tryParse(angkaMentah) ?? 0;
    final str = angka.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final posisiDariKanan = str.length - i;
      buffer.write(str[i]);
      if (posisiDariKanan > 1 && posisiDariKanan % 3 == 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }

  void _bukaLanjutanSesi(Map<String, dynamic> sesi) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SesiKonsultasiScreen(
          idKonsultasi: sesi['id'].toString(),
          idUser: widget.idUser,
          role: widget.role,
          baseUrl: baseUrl,
          onSelesai: _fetchData,
          detail: sesi,
        ),
      ),
    ).then((_) => _fetchData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Konsultasi",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        // Tombol filter (Icons.tune) dihapus sesuai permintaan.
      ),
      body: Column(
        children: [
          if (_sesiAktif != null) _buildActiveBanner(_sesiAktif!),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0EDD8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  _buildTabButton("Daftar", 0),
                  _buildTabButton("Riwayat", 1),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: activeGreen),
                  )
                : _selectedIndex == 0
                ? _buildDaftarDokter()
                : RiwayatScreen(
                    listRiwayat: _listRiwayat,
                    idUser: widget.idUser,
                    role: widget.role,
                    baseUrl: baseUrl,
                    onRefresh: _fetchData,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBanner(Map<String, dynamic> sesi) {
    String statusLabel = _statusLabel(sesi['status_konsultasi']);
    return GestureDetector(
      onTap: () => _bukaLanjutanSesi(sesi),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFFCC00).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFB8860B), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ada sesi aktif",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF7A5800),
                    ),
                  ),
                  Text(
                    "${sesi['nama_dokter'] ?? '-'} · $statusLabel",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9A7000),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Color(0xFFB8860B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    bool isActive = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isActive ? activeGreen : Colors.transparent,
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

  Widget _buildDaftarDokter() {
    if (_listDokter.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              "Belum ada dokter tersedia",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: activeGreen,
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        itemCount: _listDokter.length,
        itemBuilder: (_, i) => _buildDoctorCard(_listDokter[i]),
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> dokter) {
    bool isOnline = dokter['status']?.toString().toLowerCase() == 'online';
    String harga =
        dokter['harga_konsultasi']?.toString() ??
        dokter['harga']?.toString() ??
        "150000";
    double rating = double.tryParse(dokter['rating']?.toString() ?? "0") ?? 0.0;

    String namaDokter = dokter['nama_lengkap'] ?? 'Nama Dokter';
    String? jenisKelaminDokter = dokter['jenis_kelamin']?.toString();

    bool adaSesiAktif = _listRiwayat.any(
      (r) =>
          r['id_dokter'].toString() == dokter['id_dokter'].toString() &&
          (r['status_konsultasi'] == 'berlangsung' ||
              r['status_konsultasi'] == 'menunggu_konsultasi' ||
              r['status_konsultasi'] == 'menunggu_pembayaran'),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: adaSesiAktif
              ? activeGreen.withValues(alpha: 0.5)
              : const Color(0xFFE8E8E8),
          width: adaSesiAktif ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar dokter sekarang pakai SVG lokal lewat GenderAvatarHelper
              // (menyesuaikan gender dari field 'jenis_kelamin' backend, atau
              // ditebak dari nama kalau field itu belum tersedia).
              GenderAvatarHelper.buildAvatar(
                namaDokter,
                jenisKelamin: jenisKelaminDokter,
                radius: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            namaDokter,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: activeGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Lihat Detail",
                            style: TextStyle(
                              color: activeGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dokter['spesialis'] ?? 'Spesialis',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 15),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline
                                ? Colors.green
                                : Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isOnline ? "Online" : "Offline",
                          style: TextStyle(
                            fontSize: 12,
                            color: isOnline ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: _buildStepIndicator(dokter),
          ),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Biaya Sesi",
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Rp${_formatRibuan(harga)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              adaSesiAktif
                  ? _buildLanjutButton(dokter)
                  : _buildDaftarButton(dokter),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaftarButton(Map<String, dynamic> dokter) {
    return ElevatedButton(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PembayaranScreen(
              dataDokter: dokter,
              idUser: widget.idUser,
              role: widget.role,
            ),
          ),
        );
        _fetchData();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: activeGreen,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      ),
      child: const Text(
        "DAFTAR",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLanjutButton(Map<String, dynamic> dokter) {
    var sesi = _listRiwayat.firstWhere(
      (r) =>
          r['id_dokter'].toString() == dokter['id_dokter'].toString() &&
          (r['status_konsultasi'] == 'berlangsung' ||
              r['status_konsultasi'] == 'menunggu_konsultasi' ||
              r['status_konsultasi'] == 'menunggu_pembayaran'),
      orElse: () => null,
    );
    return ElevatedButton.icon(
      onPressed: sesi != null ? () => _bukaLanjutanSesi(sesi) : null,
      icon: const Icon(Icons.play_arrow, size: 18, color: Colors.white),
      label: const Text(
        "LANJUT",
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange.shade600,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }

  Widget _buildStepIndicator(Map<String, dynamic> dokter) {
    String currentStatus = 'idle';
    try {
      var sesi = _listRiwayat.firstWhere(
        (r) => r['id_dokter'].toString() == dokter['id_dokter'].toString(),
      );
      currentStatus = sesi['status_konsultasi'] ?? 'idle';
    } catch (_) {}

    int activeStep = _statusToStep(currentStatus);

    final steps = [
      {"icon": Icons.calendar_today_outlined, "label": "Jadwal"},
      {"icon": Icons.wallet_outlined, "label": "Pembayaran"},
      {"icon": Icons.chat_bubble_outline, "label": "Konsultasi"},
      {"icon": Icons.description_outlined, "label": "Selesai"},
    ];

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          int stepBefore = i ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              color: stepBefore < activeStep
                  ? activeGreen
                  : Colors.grey.shade300,
            ),
          );
        }
        int idx = i ~/ 2;
        bool done = idx < activeStep;
        bool active = idx == activeStep;
        return Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done || active ? activeGreen : Colors.grey.shade200,
              ),
              child: Icon(
                done ? Icons.check : steps[idx]["icon"] as IconData,
                size: 17,
                color: done || active ? Colors.white : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              steps[idx]["label"] as String,
              style: TextStyle(
                fontSize: 9,
                color: done || active ? activeGreen : Colors.grey,
                fontWeight: done || active
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            if (active && currentStatus != 'idle')
              Text(
                _statusLabel(currentStatus).split(' ').last,
                style: const TextStyle(fontSize: 8, color: Colors.orange),
              ),
          ],
        );
      }),
    );
  }

  int _statusToStep(String status) {
    switch (status) {
      case 'menunggu_pembayaran':
        return 1;
      case 'menunggu_konsultasi':
        return 2;
      case 'berlangsung':
        return 2;
      case 'selesai':
        return 3;
      default:
        return 0;
    }
  }
}