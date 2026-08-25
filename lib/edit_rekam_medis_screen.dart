import 'package:flutter/material.dart';
import 'services/api_client.dart';
import 'dart:convert';

class EditRekamMedisScreen extends StatefulWidget {
  final int idRekam;
  final String nomorRekam;
  final String namaPasien;
  final String namaDokter;
  final String subjektif;
  final String objektif;
  final String asesmen;
  final String plan;
  final String statusRekam;

  const EditRekamMedisScreen({
    super.key,
    required this.idRekam,
    required this.nomorRekam,
    required this.namaPasien,
    required this.namaDokter,
    required this.subjektif,
    required this.objektif,
    required this.asesmen,
    required this.plan,
    required this.statusRekam,
  });

  @override
  State<EditRekamMedisScreen> createState() => _EditRekamMedisScreenState();
}

class _EditRekamMedisScreenState extends State<EditRekamMedisScreen> {
  static const Color primaryGreen = Color(0xFF8EB76E);
  static const Color bgCream = Color(0xFFFFFDEC);

  late TextEditingController _subjektifController;
  late TextEditingController _objektifController;
  late TextEditingController _asesmenController;
  late TextEditingController _planController;

  bool _isLoading = false;
  late String _statusRekam;
  final String baseUrl =
      'https://chump-vividness-escapable.ngrok-free.dev/healu_api';

  @override
  void initState() {
    super.initState();
    _subjektifController = TextEditingController(text: widget.subjektif);
    _objektifController = TextEditingController(text: widget.objektif);
    _asesmenController = TextEditingController(text: widget.asesmen);
    _planController = TextEditingController(text: widget.plan);
    _statusRekam = widget.statusRekam;
  }

  @override
  void dispose() {
    _subjektifController.dispose();
    _objektifController.dispose();
    _asesmenController.dispose();
    _planController.dispose();
    super.dispose();
  }

  Future<void> _updateRekamMedis() async {
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
        Uri.parse('$baseUrl/update_rekam_medis.php'),
        body: {
          'id_rekam': widget.idRekam.toString(),
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
          'Edit Rekam Medis',
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
              // Info Card
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
                      'Nomor Rekam: ${widget.nomorRekam}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pasien: ${widget.namaPasien}',
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dokter: ${widget.namaDokter}',
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // SUBJEKTIF
              _buildSOAPSection(
                title: 'SUBJEKTIF (S)',
                controller: _subjektifController,
              ),
              const SizedBox(height: 16),

              // OBJEKTIF
              _buildSOAPSection(
                title: 'OBJEKTIF (O)',
                controller: _objektifController,
              ),
              const SizedBox(height: 16),

              // ASESMEN
              _buildSOAPSection(
                title: 'ASESMEN (A)',
                controller: _asesmenController,
              ),
              const SizedBox(height: 16),

              // PLAN
              _buildSOAPSection(title: 'PLAN (P)', controller: _planController),
              const SizedBox(height: 16),

              // Status
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
                      onPressed: _isLoading ? null : _updateRekamMedis,
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
                              'Perbarui',
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