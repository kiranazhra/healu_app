import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'chat_screen.dart';
import 'services/api_client.dart';

class DetailKonsultasiDokterScreen extends StatefulWidget {
  final Map<String, dynamic> dataKonsultasi;
  final String idDokterUser;
  final String baseUrl;
  final Future<void> Function() onRefresh;

  const DetailKonsultasiDokterScreen({
    super.key,
    required this.dataKonsultasi,
    required this.idDokterUser,
    required this.baseUrl,
    required this.onRefresh,
  });

  @override
  State<DetailKonsultasiDokterScreen> createState() =>
      _DetailKonsultasiDokterScreenState();
}

class _DetailKonsultasiDokterScreenState
    extends State<DetailKonsultasiDokterScreen> {
  final Color primaryGreen = const Color(0xFF8EB76E);
  late Map<String, dynamic> _konsultasi;
  bool _isLoading = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _konsultasi = widget.dataKonsultasi;

    // Polling setiap 5 detik (tidak terlalu sering)
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchDetailTerbaru(),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDetailTerbaru() async {
    try {
      var response = await ApiClient.instance
          .get(
            Uri.parse(
              "${widget.baseUrl}/get_detail_konsultasi.php?id=${_konsultasi['id']}",
            ),
          )
          .timeout(const Duration(seconds: 5)); // Kurangi dari 10 ke 5 detik

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json['status'] == 'success' && mounted) {
          setState(() {
            _konsultasi = json['data'];
          });
        }
      }
    } catch (e) {
      debugPrint("Poll error: $e");
    }
  }

  Future<void> _akhiriKonsultasi() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Akhiri Konsultasi?"),
        content: const Text(
          "Apakah Anda yakin ingin mengakhiri konsultasi dengan pasien ini?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(dialogContext);

              if (!mounted) return;
              setState(() => _isLoading = true);

              // Ambil messenger & navigator SEBELUM async gap
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);

              try {
                var response = await ApiClient.instance
                    .post(
                      Uri.parse(
                        "${widget.baseUrl}/update_status_konsultasi.php",
                      ),
                      body: {
                        'id_konsultasi': _konsultasi['id'].toString(),
                        'status': 'selesai',
                      },
                    )
                    .timeout(const Duration(seconds: 5));

                if (!mounted) return;

                if (response.statusCode == 200) {
                  var json = jsonDecode(response.body);

                  if (json['status'] == 'success') {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text("✅ Konsultasi berhasil diakhiri"),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 1),
                      ),
                    );

                    // Refresh & kembali langsung
                    await widget.onRefresh();
                    if (!mounted) return;
                    navigator.pop();
                  } else {
                    _showError(
                      messenger,
                      json['message'] ?? 'Gagal mengakhiri konsultasi',
                    );
                  }
                }
              } catch (e) {
                if (!mounted) return;
                _showError(messenger, 'Error: $e');
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text("Akhiri", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showError(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    String namaPasien = _konsultasi['nama_pasien'] ?? 'Pasien';
    String status = _konsultasi['status_konsultasi'] ?? 'idle';
    String idKonsultasi = _konsultasi['id'].toString();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDEC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Detail Konsultasi",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryGreen),
                  const SizedBox(height: 16),
                  const Text(
                    "Memproses...",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Pasien
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
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: primaryGreen.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                namaPasien,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: status == 'berlangsung'
                                      ? Colors.orange.withValues(alpha: 0.1)
                                      : status == 'selesai'
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _statusLabel(status),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: status == 'berlangsung'
                                        ? Colors.orange
                                        : status == 'selesai'
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ringkasan Konsultasi
                  const Text(
                    "Ringkasan Konsultasi",
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
                          "${_konsultasi['tanggal_jadwal'] ?? '-'} ${_konsultasi['waktu_jadwal'] ?? '-'}",
                        ),
                        const Divider(height: 20),
                        _buildSummaryRow(
                          "Durasi",
                          "${_konsultasi['durasi'] ?? '30'} Menit",
                        ),
                        const Divider(height: 20),
                        _buildSummaryRow(
                          "Biaya",
                          "Rp${_konsultasi['total_harga'] ?? '0'}",
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Aksi
                  if (status != 'selesai') ...[
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                idKonsultasi: idKonsultasi,
                                namaLawanBicara: namaPasien,
                                idUser: widget.idDokterUser,
                                idRole: 'dokter',
                              ),
                            ),
                          ).then((_) => _fetchDetailTerbaru());
                        },
                        icon: const Icon(Icons.chat, color: Colors.white),
                        label: const Text(
                          "Buka Chat",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _akhiriKonsultasi,
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Akhiri Konsultasi",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "✅ Konsultasi Selesai",
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(
          value,
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
