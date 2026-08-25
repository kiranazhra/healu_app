import 'package:flutter/material.dart';
import 'services/api_client.dart';
import 'dart:convert';

class TambahRekamMedisScreen extends StatefulWidget {
  final int idKonsultasi;
  final int idPasien;
  final int idDokter;
  final String namaPasien;
  final String namaDokter;

  const TambahRekamMedisScreen({
    super.key,
    required this.idKonsultasi,
    required this.idPasien,
    required this.idDokter,
    required this.namaPasien,
    required this.namaDokter,
  });

  @override
  State<TambahRekamMedisScreen> createState() => _TambahRekamMedisScreenState();
}

class _TambahRekamMedisScreenState extends State<TambahRekamMedisScreen> {
  static const Color primaryGreen = Color(0xFF8EB76E);
  static const Color bgCream = Color(0xFFFFFDEC);

  final TextEditingController _subjektifController = TextEditingController();
  final TextEditingController _objektifController = TextEditingController();
  final TextEditingController _asesmenController = TextEditingController();
  final TextEditingController _planController = TextEditingController();

  bool _isLoading = false;
  String _statusRekam = 'draft';
  final String baseUrl =
      'https://chump-vividness-escapable.ngrok-free.dev/healu_api';

  @override
  void dispose() {
    _subjektifController.dispose();
    _objektifController.dispose();
    _asesmenController.dispose();
    _planController.dispose();
    super.dispose();
  }

  Future<void> _simpanRekamMedis() async {
    if (_subjektifController.text.isEmpty ||
        _objektifController.text.isEmpty ||
        _asesmenController.text.isEmpty ||
        _planController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Semua field harus diisi!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiClient.instance.post(
        Uri.parse('$baseUrl/tambah_rekam_medis.php'),
        body: {
          'id_konsultasi': widget.idKonsultasi.toString(),
          'id_pasien': widget.idPasien.toString(),
          'id_dokter': widget.idDokter.toString(),
          'subjektif': _subjektifController.text,
          'objektif': _objektifController.text,
          'asesmen': _asesmenController.text,
          'plan': _planController.text,
          'status_rekam': _statusRekam,
        },
      );

      if (!mounted) return;

      final result = jsonDecode(response.body);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['message']}'),
            backgroundColor: primaryGreen,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message']}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        title: const Text(
          'Tambah Rekam Medis',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Pasien & Dokter
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryGreen.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pasien: ${widget.namaPasien}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dokter: ${widget.namaDokter}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Konsultasi ID: HU-2026-${widget.idKonsultasi.toString().padLeft(5, '0')}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // SUBJEKTIF
              _buildSOAPSection(
                title: 'SUBJEKTIF (S) - KELUHAN PASIEN',
                controller: _subjektifController,
                hint: 'Tuliskan keluhan dan gejala yang dirasakan pasien...',
              ),
              const SizedBox(height: 16),

              // OBJEKTIF
              _buildSOAPSection(
                title: 'OBJEKTIF (O) - PEMERIKSAAN KLINIS',
                controller: _objektifController,
                hint: 'Hasil pemeriksaan fisik, vital signs, dll...',
              ),
              const SizedBox(height: 16),

              // ASESMEN
              _buildSOAPSection(
                title: 'ASESMEN (A) - DIAGNOSA MEDIS',
                controller: _asesmenController,
                hint: 'Diagnosa berdasarkan subjektif dan objektif...',
              ),
              const SizedBox(height: 16),

              // PLAN
              _buildSOAPSection(
                title: 'PLAN (P) - RENCANA & TERAPI',
                controller: _planController,
                hint: 'Rencana terapi, obat, edukasi, follow-up...',
              ),
              const SizedBox(height: 16),

              // Status Rekam
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status Rekam Medis',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    RadioGroup<String>(
                      groupValue: _statusRekam,
                      onChanged: (value) {
                        setState(() => _statusRekam = value!);
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Draft'),
                              value: 'draft',
                              activeColor: primaryGreen,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text('Final'),
                              value: 'final',
                              activeColor: primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _simpanRekamMedis,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Simpan Rekam Medis',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSOAPSection({
    required String title,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: primaryGreen,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 5,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: primaryGreen, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }
}