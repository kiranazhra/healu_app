// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'services/api_client.dart';
import 'dart:convert';
import 'chat_screen.dart';
import 'gender_avatar_helper.dart';

class PembayaranScreen extends StatefulWidget {
  final Map<String, dynamic> dataDokter;
  final String idUser;
  final String role;

  const PembayaranScreen({
    super.key,
    required this.dataDokter,
    required this.idUser,
    required this.role,
  });

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  final Color primaryGreen = const Color(0xFF7A9E5E);
  final Color bgCream = const Color(0xFFFBFBFA);
  final String baseUrl =
      "https://chump-vividness-escapable.ngrok-free.dev/healu_api";

  String _selectedPaymentMethod = "OVO";
  int _currentStep = 2;
  String? _idKonsultasi;

  void _prosesVerifikasiPembayaran() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: primaryGreen),
            const SizedBox(width: 20),
            const Text("Memproses pembayaran..."),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      Navigator.pop(context);

      try {
        var response = await ApiClient.instance.post(
          Uri.parse("$baseUrl/daftar_konsultasi.php"),
          body: {
            'id_pasien': widget.idUser,
            'id_dokter': widget.dataDokter['id_dokter'].toString(),
            'tanggal_jadwal': '2025-05-24',
            'waktu_jadwal': '10:00',
            'durasi': '30',
            'total_harga':
                widget.dataDokter['harga_konsultasi']?.toString() ?? '150000',
          },
        );

        if (response.statusCode == 200) {
          var json = jsonDecode(response.body);

          if (json['status'] == 'success') {
            _idKonsultasi = json['id_konsultasi']?.toString();

            if (!mounted) return;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryGreen.withAlpha(26),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: primaryGreen,
                        size: 70,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Pembayaran Berhasil!",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Konsultasi Anda sekarang aktif.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() => _currentStep = 3);
                          _goToChatScreen();
                        },
                        child: const Text(
                          "Mulai Chat Dokter",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            _showErrorDialog(json['message'] ?? 'Pendaftaran gagal');
          }
        } else {
          _showErrorDialog('Gagal menghubungi server');
        }
      } catch (e) {
        _showErrorDialog('Error: $e');
      }
    });
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _goToChatScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          idKonsultasi: _idKonsultasi ?? "1",
          namaLawanBicara:
              widget.dataDokter['nama_lengkap'] ?? 'Dr. Andi Sp.KJ',
          idUser: widget.idUser,
          idRole: widget.role,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String namaDokter = widget.dataDokter['nama_lengkap'] ?? 'Dr. Andi Sp.KJ';
    String spesialis = widget.dataDokter['spesialis'] ?? 'Spesialis Kejiwaan';
    String? jenisKelaminDokter = widget.dataDokter['jenis_kelamin']?.toString();
    String harga =
        widget.dataDokter['harga_konsultasi']?.toString() ??
        widget.dataDokter['harga']?.toString() ??
        "150000";

    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Konsultasi",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.black54),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar dokter disesuaikan dengan gender (SVG lokal
                        // lewat GenderAvatarHelper), konsisten dengan
                        // KonsultasiScreen & SesiKonsultasiScreen.
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
                              const SizedBox(height: 2),
                              Text(
                                spesialis,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.orange,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    "4.9",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.check_circle,
                                    color: primaryGreen,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Online",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: primaryGreen,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            "Lihat Detail",
                            style: TextStyle(color: primaryGreen, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildCustomStepper(),
                  const SizedBox(height: 24),
                  const Text(
                    "Ringkasan Konsultasi",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow(
                          Icons.calendar_month,
                          "Jadwal",
                          "Sabtu, 24 Mei 2025\n10:00 - 10:30 WIB",
                        ),
                        const Divider(height: 24),
                        _buildSummaryRow(
                          Icons.people_outline,
                          "Dokter",
                          "$namaDokter\n$spesialis",
                        ),
                        const Divider(height: 24),
                        _buildSummaryRow(
                          Icons.access_time,
                          "Durasi",
                          "30 Menit",
                        ),
                        const Divider(height: 24),
                        _buildSummaryRow(
                          Icons.local_offer_outlined,
                          "Biaya Konsultasi",
                          _currentStep > 2 ? "LUNAS" : "Rp $harga",
                          isPaid: _currentStep > 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_currentStep == 2) ...[
                    const Text(
                      "Pilih Metode Pembayaran",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildPaymentMethodTile("OVO"),
                    _buildPaymentMethodTile("GoPay"),
                    _buildPaymentMethodTile("Dana"),
                    _buildPaymentMethodTile("Transfer Bank"),
                  ] else if (_currentStep == 3) ...[
                    const Text(
                      "Aksi Konsultasi",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _goToChatScreen,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: primaryGreen.withAlpha(26),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primaryGreen),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.chat, color: primaryGreen, size: 32),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Lanjutkan Chat dengan Dokter",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: primaryGreen,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    "Konsultasi Anda sedang berlangsung.",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: primaryGreen,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else if (_currentStep == 4) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 40,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Konsultasi Selesai",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Terima kasih telah berkonsultasi di Healu.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (_currentStep == 2)
            _buildBottomActionBar(
              "Bayar Sekarang",
              "Rp $harga",
              _prosesVerifikasiPembayaran,
              "Pembayaran aman & terenkripsi",
            )
          else if (_currentStep == 3)
            _buildBottomActionBar(
              "Akhiri Konsultasi",
              "Selesaikan Sesi",
              () {
                setState(() => _currentStep = 4);
              },
              "Sesi chat akan ditutup secara permanen",
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(
    String title,
    String subtitle,
    VoidCallback onTap,
    String footerText,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: _currentStep == 3 ? Colors.redAccent : primaryGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _currentStep == 3 ? Icons.info_outline : Icons.lock_outline,
                color: Colors.grey,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                footerText,
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(String title) {
    bool isSelected = _selectedPaymentMethod == title;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? primaryGreen : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.indigo,
          ),
        ),
        trailing: Radio<String>(
          value: title,
          groupValue: _selectedPaymentMethod,
          activeColor: primaryGreen,
          onChanged: (value) {
            setState(() {
              _selectedPaymentMethod = value!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    IconData icon,
    String label,
    String value, {
    bool isPaid = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: primaryGreen, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          textAlign: TextAlign.end,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isPaid ? primaryGreen : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomStepper() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStepItem("1. Jadwal", Icons.calendar_today, true, false),
        _buildStepItem(
          "2. Pembayaran",
          Icons.payment,
          _currentStep >= 2,
          _currentStep == 2,
        ),
        _buildStepItem(
          "3. Konsultasi",
          Icons.chat_bubble_outline,
          _currentStep >= 3,
          _currentStep == 3,
        ),
        _buildStepItem(
          "4. Selesai",
          Icons.task_alt,
          _currentStep >= 4,
          _currentStep == 4,
        ),
      ],
    );
  }

  Widget _buildStepItem(
    String title,
    IconData icon,
    bool isActive,
    bool isCurrent,
  ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: isActive ? primaryGreen : Colors.grey.shade200,
          child: Icon(
            icon,
            size: 16,
            color: isActive ? Colors.white : Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title.split(".")[1].trim(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: isCurrent || isActive
                ? FontWeight.bold
                : FontWeight.normal,
            color: isCurrent
                ? primaryGreen
                : (isActive ? Colors.black87 : Colors.grey),
          ),
        ),
        Text(
          isCurrent ? "Berlangsung" : (isActive ? "Selesai" : "Menunggu"),
          style: TextStyle(
            fontSize: 8,
            color: isCurrent
                ? Colors.orange
                : (isActive ? primaryGreen : Colors.grey),
          ),
        ),
      ],
    );
  }
}