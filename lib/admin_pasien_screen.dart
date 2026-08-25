import 'package:flutter/material.dart';
import 'services/api_client.dart';
import 'dart:convert';
import 'edit_pasien_screen.dart';
import 'rekam_medis_list_screen.dart';
import 'tambah_pasien_screen.dart';

class AdminPasienScreen extends StatefulWidget {
  final String idUser;
  final bool autoOpenAddForm;

  const AdminPasienScreen({
    super.key,
    required this.idUser,
    this.autoOpenAddForm = false,
  });

  @override
  State<AdminPasienScreen> createState() => _AdminPasienScreenState();
}

class _AdminPasienScreenState extends State<AdminPasienScreen> {
  final String baseUrl =
      "https://chump-vividness-escapable.ngrok-free.dev/healu_api";
  final Color primaryGreen = const Color(0xFF8EB76E);

  List<dynamic> _daftarPasien = [];
  List<dynamic> _daftarPasienFiltered = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPasien();
    _searchController.addListener(_filterPasien);

    if (widget.autoOpenAddForm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _bukaTambahPasien();
      });
    }
  }

  void _bukaTambahPasien() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TambahPasienScreen(onRefresh: _fetchPasien),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPasien() async {
    try {
      var response = await ApiClient.instance
          .get(Uri.parse("$baseUrl/get_pasien.php"))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _daftarPasien = data['data'] ?? [];
            _daftarPasienFiltered = _daftarPasien;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetchPasien: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterPasien() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _daftarPasienFiltered = _daftarPasien
          .where(
            (pasien) =>
                pasien['nama_lengkap'].toString().toLowerCase().contains(
                  query,
                ) ||
                pasien['email'].toString().toLowerCase().contains(query) ||
                pasien['nomor_telepon'].toString().toLowerCase().contains(
                  query,
                ),
          )
          .toList();
    });
  }

  Future<void> _hapusPasien(int idPasien) async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text("Konfirmasi Hapus"),
          content: const Text("Apakah Anda yakin ingin menghapus pasien ini?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(dialogContext);
                final messenger = ScaffoldMessenger.of(context);

                try {
                  var response = await ApiClient.instance.post(
                    Uri.parse("$baseUrl/delete_pasien.php"),
                    body: {'id_pasien': idPasien.toString()},
                  );

                  if (!mounted) return; 

                  var data = jsonDecode(response.body);
                  if (data['status'] == 'success') {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('✅ Pasien berhasil dihapus'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _fetchPasien();
                  } else {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('❌ ${data['message']}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (!mounted) return; 
                  messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text("Hapus", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pasien'),
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              FocusScope.of(context).requestFocus(FocusNode());
              _searchController.clear();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _bukaTambahPasien,
        backgroundColor: primaryGreen,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text(
          'Tambah Pasien',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari nama, email, atau HP...',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.tune_rounded, color: Colors.grey.shade400),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Filter belum tersedia")),
                      );
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Total Pasien
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.people, color: primaryGreen, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Total Pasien: ${_daftarPasienFiltered.length}',
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // List Pasien
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryGreen))
                : _daftarPasienFiltered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada pasien ditemukan',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _daftarPasienFiltered.length,
                    itemBuilder: (context, index) {
                      var pasien = _daftarPasienFiltered[index];
                      return _buildPasienCard(pasien);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasienCard(Map<String, dynamic> pasien) {
    final idPasien = int.tryParse(pasien['id'].toString()) ?? 0;
    final namaPasien = pasien['nama_lengkap'] ?? 'Pasien';
    final email = pasien['email'] ?? '-';
    final noTelepon = pasien['nomor_telepon'] ?? '-';
    final jenisKelamin = pasien['jenis_kelamin'] ?? '-';
    final tanggalLahir = pasien['tanggal_lahir'] ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.person, color: Colors.blue, size: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaPasien,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        noTelepon,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditPasienScreen(
                              idPasien: idPasien,
                              data: pasien,
                              onRefresh: _fetchPasien,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: Colors.green,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RekamMedisListScreen(
                              idPasien: idPasien,
                              title: 'Rekam Medis - $namaPasien',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: Colors.blue,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(height: 1, color: Colors.grey.shade200),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Jenis Kelamin', jenisKelamin),
                      const SizedBox(height: 4),
                      _buildDetailRow('Tanggal Lahir', tanggalLahir),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _hapusPasien(idPasien),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
