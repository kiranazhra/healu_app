import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditPasienScreen extends StatefulWidget {
  final int idPasien;
  final Map<String, dynamic> data;
  final Future<void> Function() onRefresh;

  const EditPasienScreen({
    super.key,
    required this.idPasien,
    required this.data,
    required this.onRefresh,
  });

  @override
  State<EditPasienScreen> createState() => _EditPasienScreenState();
}

class _EditPasienScreenState extends State<EditPasienScreen> {
  final String baseUrl =
      "https://chump-vividness-escapable.ngrok-free.dev/healu_api";
  final Color primaryGreen = const Color(0xFF8EB76E);

  bool _isLoading = false;

  late TextEditingController _namaController;
  late TextEditingController _emailController;
  late TextEditingController _noHpController;
  late TextEditingController _tglLahirController;
  late TextEditingController _alamatController;

  late String _selectedJenisKelamin;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(
      text: widget.data['nama_lengkap'] ?? '',
    );
    _emailController = TextEditingController(text: widget.data['email'] ?? '');
    _noHpController = TextEditingController(
      text: widget.data['nomor_telepon'] ?? '',
    );
    _tglLahirController = TextEditingController(
      text: widget.data['tanggal_lahir'] ?? '',
    );
    _alamatController = TextEditingController(
      text: widget.data['alamat'] ?? '',
    );
    _selectedJenisKelamin = widget.data['jenis_kelamin'] ?? 'Laki-laki';
  }

  Future<void> _updatePasien() async {
    if (_namaController.text.isEmpty || _emailController.text.isEmpty) {
      _showError('Nama dan email harus diisi');
      return;
    }

    setState(() => _isLoading = true);

    try {
      var response = await http
          .post(
            Uri.parse("$baseUrl/update_pasien.php"),
            body: {
              'id_pasien': widget.idPasien.toString(),
              'nama_lengkap': _namaController.text,
              'email': _emailController.text,
              'nomor_telepon': _noHpController.text,
              'tanggal_lahir': _tglLahirController.text,
              'jenis_kelamin': _selectedJenisKelamin,
              'alamat': _alamatController.text,
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);

        if (json['status'] == 'success') {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Pasien berhasil diperbarui"),
              backgroundColor: Colors.green,
            ),
          );

          await widget.onRefresh();
          if (!mounted) return;
          Navigator.pop(context);
        } else {
          _showError(json['message'] ?? 'Gagal memperbarui pasien');
        }
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _noHpController.dispose();
    _tglLahirController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Pasien'),
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama Lengkap
                  _buildTextField(
                    _namaController,
                    "Nama Lengkap",
                    "Masukkan nama pasien",
                    Icons.person,
                  ),
                  const SizedBox(height: 16),

                  // Email
                  _buildTextField(
                    _emailController,
                    "Email",
                    "Masukkan email",
                    Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Nomor HP
                  _buildTextField(
                    _noHpController,
                    "Nomor HP",
                    "Contoh: 08xxxxxxxxxx",
                    Icons.phone,
                  ),
                  const SizedBox(height: 16),

                  // Tanggal Lahir
                  _buildTextField(
                    _tglLahirController,
                    "Tanggal Lahir",
                    "YYYY-MM-DD",
                    Icons.calendar_today,
                  ),
                  const SizedBox(height: 16),

                  // Jenis Kelamin
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Jenis Kelamin",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButton<String>(
                          value: _selectedJenisKelamin,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                              value: 'Laki-laki',
                              child: Text('Laki-laki'),
                            ),
                            DropdownMenuItem(
                              value: 'Perempuan',
                              child: Text('Perempuan'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(
                              () =>
                                  _selectedJenisKelamin = value ?? 'Laki-laki',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Alamat
                  _buildTextField(
                    _alamatController,
                    "Alamat",
                    "Masukkan alamat",
                    Icons.location_on,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  // Tombol Update
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _updatePasien,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Perbarui Pasien",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: maxLines == 1
                ? Icon(icon, color: primaryGreen, size: 20)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: primaryGreen, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
