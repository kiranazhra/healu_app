import 'package:flutter/material.dart';
import 'dart:convert';
import 'tambah_dokter_screen.dart';
import 'edit_dokter_screen.dart';
import 'services/api_client.dart';

class AdminDokterScreen extends StatefulWidget {
  final String idUser;
  // Jika true, halaman ini otomatis membuka form "Tambah Dokter"
  // begitu halaman tampil (dipakai oleh tombol "Tambah Dokter" di
  // Aksi Cepat dashboard admin).
  final bool autoOpenAddForm;

  const AdminDokterScreen({
    super.key,
    required this.idUser,
    this.autoOpenAddForm = false,
  });

  @override
  State<AdminDokterScreen> createState() => _AdminDokterScreenState();
}

class _AdminDokterScreenState extends State<AdminDokterScreen> {
  final String baseUrl =
      "https://chump-vividness-escapable.ngrok-free.dev/healu_api";
  final Color primaryGreen = const Color(0xFF8EB76E);
  final Color bgCream = const Color(0xFFFFFDEC);

  List<dynamic> _listDokter = [];
  bool _isLoading = true;

  // Filter status: 'semua' | 'online' | 'offline'
  String _statusFilter = 'semua';

  List<dynamic> get _listDokterFiltered {
    if (_statusFilter == 'semua') return _listDokter;
    return _listDokter.where((d) {
      final status = d['status']?.toString().toLowerCase() ?? 'offline';
      return status == _statusFilter;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchDokter();

    if (widget.autoOpenAddForm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openTambahDokter();
      });
    }
  }

  Future<void> _fetchDokter() async {
    try {
      var response = await ApiClient.instance
          .get(Uri.parse("$baseUrl/get_dokters.php"))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        var json = jsonDecode(response.body);
        if (json['status'] == 'success' && mounted) {
          setState(() {
            _listDokter = json['data'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("fetchDokter error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openTambahDokter() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            TambahDokterScreen(baseUrl: baseUrl, onRefresh: _fetchDokter),
      ),
    );
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Filter Status Dokter",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                _buildFilterOption('semua', 'Semua Dokter'),
                _buildFilterOption('online', 'Online'),
                _buildFilterOption('offline', 'Offline'),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String value, String label) {
    final selected = _statusFilter == value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? primaryGreen : Colors.black87,
        ),
      ),
      trailing: selected ? Icon(Icons.check_circle, color: primaryGreen) : null,
      onTap: () {
        setState(() => _statusFilter = value);
        Navigator.pop(context);
      },
    );
  }

  Future<void> _deleteDokter(String idDokter) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Dokter?"),
        content: const Text(
          "Apakah Anda yakin ingin menghapus dokter ini? Data tidak dapat dipulihkan.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);

              try {
                var response = await ApiClient.instance
                    .post(
                      Uri.parse("$baseUrl/delete_dokter.php"),
                      body: {'id_dokter': idDokter},
                    )
                    .timeout(const Duration(seconds: 10));

                if (response.statusCode == 200) {
                  var json = jsonDecode(response.body);

                  if (json['status'] == 'success') {
                    if (!mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text("✅ Dokter berhasil dihapus"),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _fetchDokter();
                  } else {
                    _showError(json['message'] ?? 'Gagal menghapus dokter');
                  }
                }
              } catch (e) {
                _showError('Error: $e');
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Kelola Dokter",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.black87),
            onPressed: _openFilterSheet,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : Column(
              children: [
                // Summary Card
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Total Dokter",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${_listDokter.length} Dokter",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.medical_information_outlined,
                        color: Colors.white,
                        size: 48,
                      ),
                    ],
                  ),
                ),

                // List Dokter
                Expanded(
                  child: _listDokterFiltered.isEmpty
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
                                _listDokter.isEmpty
                                    ? "Belum ada dokter"
                                    : "Tidak ada dokter untuk filter ini",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _listDokterFiltered.length,
                          itemBuilder: (context, index) {
                            var dokter = _listDokterFiltered[index];
                            return _buildDokterCard(dokter);
                          },
                        ),
                ),

                // Tombol Tambah Dokter (sticky full width, bukan FAB)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _openTambahDokter,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        "Tambah Dokter",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDokterCard(Map<String, dynamic> dokter) {
    String nama = dokter['nama_lengkap'] ?? 'Dokter';
    String spesialis = dokter['spesialis'] ?? 'Umum';
    String harga = dokter['harga_konsultasi']?.toString() ?? '0';
    double rating = double.tryParse(dokter['rating']?.toString() ?? "0") ?? 0.0;
    String status = dokter['status']?.toString().toLowerCase() ?? 'offline';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: primaryGreen.withValues(alpha: 0.1),
                child: Icon(Icons.person, size: 32, color: primaryGreen),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      spesialis,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: status == 'online'
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status == 'online' ? "Online" : "Offline",
                          style: TextStyle(
                            fontSize: 11,
                            color: status == 'online'
                                ? Colors.green
                                : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Kebab menu (⋯) seperti di mockup
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditDokterScreen(
                          dataDokter: dokter,
                          baseUrl: baseUrl,
                          onRefresh: _fetchDokter,
                        ),
                      ),
                    );
                  } else if (value == 'hapus') {
                    _deleteDokter(dokter['id_dokter'].toString());
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                ],
              ),
            ],
          ),
          const Divider(height: 16, thickness: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Biaya Konsultasi",
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Rp$harga",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildPillButton(
                    label: "Edit",
                    color: primaryGreen,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditDokterScreen(
                            dataDokter: dokter,
                            baseUrl: baseUrl,
                            onRefresh: _fetchDokter,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildPillButton(
                    label: "Hapus",
                    color: Colors.redAccent,
                    onTap: () => _deleteDokter(dokter['id_dokter'].toString()),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
