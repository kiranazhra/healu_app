// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'services/api_client.dart';

class TambahObatScreen extends StatefulWidget {
  final String idUser; // Menerima ID Pasien

  const TambahObatScreen({super.key, required this.idUser});

  @override
  State<TambahObatScreen> createState() => _TambahObatScreenState();
}

class _TambahObatScreenState extends State<TambahObatScreen> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _dosisController = TextEditingController();
  final TextEditingController _waktuController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  bool _isSaving = false;

  Future<void> simpanObat() async {
    if (_namaController.text.isEmpty || _waktuController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nama obat dan waktu minum wajib diisi!")),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      final response = await ApiClient.instance.post(
        Uri.parse(
          "https://chump-vividness-escapable.ngrok-free.dev/healu_api/add_reminder.php",
        ),
        body: {
          "id_pasien": widget.idUser,
          "nama_obat": _namaController.text,
          "dosis": _dosisController.text,
          "waktu_minum": _waktuController.text,
          "catatan": _catatanController.text,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pop(context);
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text("Gagal menyimpan data ke server.")),
        );
      }
    } catch (e) {
      debugPrint("Error menyimpan data: $e");
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text("Terjadi kesalahan jaringan.")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _dosisController.dispose();
    _waktuController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDEC), // Krem
      appBar: AppBar(
        title: const Text(
          "Tambah Obat",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Nama Obat"),
            _buildField(_namaController, "Contoh: Paracetamol"),

            _buildLabel("Dosis"),
            _buildField(_dosisController, "Contoh: 500 mg"),

            _buildLabel("Waktu Minum"),
            _buildField(_waktuController, "Contoh: 08:00, 20:00"),

            _buildLabel("Catatan (Opsional)"),
            _buildField(
              _catatanController,
              "Catatan tambahan sebelum/sesudah makan...",
              maxLines: 3,
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8EB76E),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              onPressed: _isSaving ? null : simpanObat,
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Simpan Pengingat",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
