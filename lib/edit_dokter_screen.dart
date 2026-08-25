import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditDokterScreen extends StatefulWidget {
  final Map<String, dynamic> dataDokter;
  final String baseUrl;
  final Future<void> Function() onRefresh;

  const EditDokterScreen({
    super.key,
    required this.dataDokter,
    required this.baseUrl,
    required this.onRefresh,
  });

  @override
  State<EditDokterScreen> createState() => _EditDokterScreenState();
}

class _EditDokterScreenState extends State<EditDokterScreen> {
  final Color primaryGreen = const Color(0xFF8EB76E);
  bool _isLoading = false;

  late TextEditingController _namaController;
  late TextEditingController _spesialisController;
  late TextEditingController _hargaController;
  late TextEditingController _ratingController;
  late TextEditingController _strController;
  late TextEditingController _noHpController;
  late TextEditingController _emailController;

  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(
      text: widget.dataDokter['nama_lengkap'] ?? '',
    );
    _spesialisController = TextEditingController(
      text: widget.dataDokter['spesialis'] ?? '',
    );
    _hargaController = TextEditingController(
      text: widget.dataDokter['harga_konsultasi']?.toString() ?? '',
    );
    _ratingController = TextEditingController(
      text: widget.dataDokter['rating']?.toString() ?? '0',
    );
    _strController = TextEditingController(
      text: widget.dataDokter['no_str'] ?? '',
    );
    _noHpController = TextEditingController(
      text: widget.dataDokter['nomor_telepon'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.dataDokter['email'] ?? '',
    );
    _selectedStatus =
        widget.dataDokter['status']?.toString().toLowerCase() ?? 'online';
  }

  Future<void> _updateDokter() async {
    if (_namaController.text.isEmpty ||
        _spesialisController.text.isEmpty ||
        _hargaController.text.isEmpty) {
      _showError('Nama, spesialis, dan harga harus diisi');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String apiUrl = "${widget.baseUrl}/update_dokter.php";

      debugPrint("═══ UPDATE DOKTER ═══");
      debugPrint("URL: $apiUrl");
      debugPrint("ID Dokter: ${widget.dataDokter['id_dokter']}");
      debugPrint("Nama: ${_namaController.text}");

      var response = await http
          .post(
            Uri.parse(apiUrl),
            body: {
              'id_dokter': widget.dataDokter['id_dokter'].toString(),
              'nama_lengkap': _namaController.text,
              'spesialis': _spesialisController.text,
              'harga_konsultasi': _hargaController.text,
              'rating': _ratingController.text.isEmpty
                  ? '0'
                  : _ratingController.text,
              'no_str': _strController.text,
              'nomor_telepon': _noHpController.text,
              'email': _emailController.text,
              'status': _selectedStatus,
            },
          )
          .timeout(const Duration(seconds: 15));

      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Raw Response: ${response.body}");

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        debugPrint("JSON Status: ${json['status']}");
        debugPrint("JSON Message: ${json['message']}");

        if (json['status'] == 'success') {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Dokter berhasil diperbarui"),
              backgroundColor: Colors.green,
            ),
          );

          debugPrint("Calling onRefresh...");
          await widget.onRefresh();

          if (!mounted) return;

          debugPrint("Popping navigator...");
          Navigator.pop(context);
        } else {
          _showError(json['message'] ?? 'Gagal memperbarui dokter');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Exception: $e");
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Dokter",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    _namaController,
                    "Nama Lengkap",
                    "Masukkan nama dokter",
                    Icons.person,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    _spesialisController,
                    "Spesialis",
                    "Contoh: Spesialis Kejiwaan",
                    Icons.medical_information_outlined,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    _hargaController,
                    "Harga Konsultasi",
                    "Masukkan harga",
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
                    "Email",
                    "Masukkan email",
                    Icons.email,
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

                  // Tombol Update
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateDokter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Perbarui Dokter",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
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
    int maxLines = 1,
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
          maxLines: maxLines,
          enabled: !_isLoading,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: maxLines == 1 ? Icon(icon, color: primaryGreen) : null,
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
