import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TambahDokterScreen extends StatefulWidget {
  final String baseUrl;
  final Future<void> Function() onRefresh;

  const TambahDokterScreen({
    super.key,
    required this.baseUrl,
    required this.onRefresh,
  });

  @override
  State<TambahDokterScreen> createState() => _TambahDokterScreenState();
}

class _TambahDokterScreenState extends State<TambahDokterScreen> {
  final Color primaryGreen = const Color(0xFF8EB76E);
  bool _isLoading = false;

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _spesialisController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _strController = TextEditingController();
  final TextEditingController _noHpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _selectedStatus = 'online';

  bool _validateForm() {
    if (_namaController.text.trim().isEmpty) {
      _showError('Nama lengkap harus diisi');
      return false;
    }
    if (_spesialisController.text.trim().isEmpty) {
      _showError('Spesialis harus diisi');
      return false;
    }
    if (_hargaController.text.trim().isEmpty) {
      _showError('Harga konsultasi harus diisi');
      return false;
    }
    if (_emailController.text.trim().isEmpty) {
      _showError('Email harus diisi');
      return false;
    }

    // Validasi email format
    if (!_emailController.text.contains('@')) {
      _showError('Email tidak valid');
      return false;
    }

    return true;
  }

  Future<void> _simpanDokter() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      String apiUrl = "${widget.baseUrl}/tambah_dokter.php";

      debugPrint("═══ TAMBAH DOKTER ═══");
      debugPrint("URL: $apiUrl");
      debugPrint("Nama: ${_namaController.text}");
      debugPrint("Spesialis: ${_spesialisController.text}");
      debugPrint("Harga: ${_hargaController.text}");
      debugPrint("Email: ${_emailController.text}");

      var response = await http
          .post(
            Uri.parse(apiUrl),
            body: {
              'nama_lengkap': _namaController.text.trim(),
              'spesialis': _spesialisController.text.trim(),
              'harga_konsultasi': _hargaController.text.trim(),
              'rating': _ratingController.text.isEmpty
                  ? '0'
                  : _ratingController.text.trim(),
              'no_str': _strController.text.trim(),
              'nomor_telepon': _noHpController.text.trim(),
              'email': _emailController.text.trim(),
              'status': _selectedStatus,
            },
          )
          .timeout(const Duration(seconds: 15));

      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response: ${response.body}");

      if (response.statusCode == 200) {
        try {
          var json = jsonDecode(response.body);
          debugPrint("JSON Status: ${json['status']}");

          if (json['status'] == 'success') {
            if (!mounted) return;

            // Clear fields
            _namaController.clear();
            _spesialisController.clear();
            _hargaController.clear();
            _ratingController.clear();
            _strController.clear();
            _noHpController.clear();
            _emailController.clear();
            setState(() => _selectedStatus = 'online');

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text("✅ Dokter berhasil ditambahkan"),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );

            debugPrint("Refreshing data...");
            await widget.onRefresh();

            if (mounted) {
              debugPrint("Popping navigator...");
              Navigator.pop(context);
            }
          } else {
            _showError(json['message'] ?? 'Gagal menambahkan dokter');
            debugPrint("API Error: ${json['message']}");
          }
        } catch (e) {
          _showError('Error parsing response: $e');
          debugPrint("Parse Error: $e");
        }
      } else {
        _showError('Server error: ${response.statusCode}');
        debugPrint("HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      _showError('Error koneksi: $e');
      debugPrint("Connection Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _spesialisController.dispose();
    _hargaController.dispose();
    _ratingController.dispose();
    _strController.dispose();
    _noHpController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDEC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Tambah Dokter",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryGreen),
                  const SizedBox(height: 16),
                  const Text(
                    "Menambahkan dokter...",
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
                  _buildTextField(
                    _namaController,
                    "Nama Lengkap *",
                    "Masukkan nama dokter",
                    Icons.person,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    _spesialisController,
                    "Spesialis *",
                    "Contoh: Spesialis Kejiwaan",
                    Icons.medical_information_outlined,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    _hargaController,
                    "Harga Konsultasi *",
                    "Contoh: 150000",
                    Icons.attach_money,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    _ratingController,
                    "Rating (0-5)",
                    "Contoh: 4.5",
                    Icons.star,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    _strController,
                    "Nomor STR",
                    "Masukkan nomor STR",
                    Icons.card_membership,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    _noHpController,
                    "Nomor HP",
                    "Contoh: 08xxxxxxxxxx",
                    Icons.phone,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    _emailController,
                    "Email *",
                    "Contoh: dokter@healu.com",
                    Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Status Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Status",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButton<String>(
                          value: _selectedStatus,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                              value: 'online',
                              child: Text('Online'),
                            ),
                            DropdownMenuItem(
                              value: 'offline',
                              child: Text('Offline'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedStatus = value ?? 'online');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _simpanDokter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: Text(
                        _isLoading ? "Menyimpan..." : "Simpan Dokter",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    "* Wajib diisi",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: !_isLoading,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: primaryGreen),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryGreen, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
