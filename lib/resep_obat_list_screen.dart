import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'services/api_client.dart';
import 'report_filter_bar.dart';
import 'resep_obat_detail_screen.dart';
import 'resep_obat_form_screen.dart';

class ResepObatListScreen extends StatefulWidget {
  final int? idDokter;
  final int? idPasien;
  final int? idKonsultasi;
  final String? title;
  final bool isReadOnly; // true = pasien, false = dokter (bisa CRUD)

  const ResepObatListScreen({
    super.key,
    this.idDokter,
    this.idPasien,
    this.idKonsultasi,
    this.title,
    this.isReadOnly = false,
  });

  @override
  State<ResepObatListScreen> createState() => _ResepObatListScreenState();
}

class _ResepObatListScreenState extends State<ResepObatListScreen> {
  static const Color primaryGreen = Color(0xFF8EB76E);
  static const Color bgCream = Color(0xFFFFFDEC);

  late Future<List<dynamic>> _futureResep;
  DateTime? _filterStart;
  DateTime? _filterEnd;

  final String baseUrl =
      'https://chump-vividness-escapable.ngrok-free.dev/healu_api';

  @override
  void initState() {
    super.initState();
    _futureResep = _fetchResep();
  }

  Future<List<dynamic>> _fetchResep() async {
    try {
      final queryParams = <String, String>{};
      if (widget.idDokter != null) {
        queryParams['id_dokter'] = widget.idDokter.toString();
      }
      if (widget.idPasien != null) {
        queryParams['id_pasien'] = widget.idPasien.toString();
      }
      if (_filterStart != null && _filterEnd != null) {
        final fmt = DateFormat('yyyy-MM-dd HH:mm:ss');
        queryParams['tanggal_awal'] = fmt.format(_filterStart!);
        queryParams['tanggal_akhir'] = fmt.format(_filterEnd!);
      }

      final uri = Uri.parse('$baseUrl/get_resep_obat.php')
          .replace(queryParameters: queryParams);

      final response =
          await ApiClient.instance.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          return result['data'] ?? [];
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error: $e');
      return [];
    }
  }

  void _refreshList() {
    setState(() => _futureResep = _fetchResep());
  }

  Future<void> _openFilter() async {
    final result = await showReportFilterSheet(
      context,
      currentStart: _filterStart,
      currentEnd: _filterEnd,
    );
    if (result == null) return;
    setState(() {
      if (result.isEmpty) {
        _filterStart = null;
        _filterEnd = null;
      } else {
        _filterStart = result['start'];
        _filterEnd = result['end'];
      }
    });
    _refreshList();
  }

  Future<void> _hapusResep(int idResep) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Resep'),
        content: const Text('Yakin ingin menghapus resep ini? Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final response = await ApiClient.instance.post(
        Uri.parse('$baseUrl/hapus_resep_obat.php'),
        body: {'id_resep': idResep.toString()},
      );
      final result = jsonDecode(response.body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Selesai')),
      );
      if (result['success'] == true) _refreshList();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        title: Text(
          widget.title ?? 'Resep Obat Digital',
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      floatingActionButton: widget.isReadOnly
          ? null
          : FloatingActionButton.extended(
              backgroundColor: primaryGreen,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Buat Resep', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                final result = await Navigator.push<bool?>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResepObatFormScreen(
                      idPasien: widget.idPasien,
                      idDokter: widget.idDokter,
                      idKonsultasi: widget.idKonsultasi,
                    ),
                  ),
                );
                if (result == true) _refreshList();
              },
            ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReportFilterBar(
              startDate: _filterStart,
              endDate: _filterEnd,
              onTap: _openFilter,
            ),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _futureResep,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: primaryGreen));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medication_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada resep obat',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: list.length,
                    itemBuilder: (context, index) => _buildCard(list[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> r) {
    final String status = (r['status_resep'] ?? '-').toString();
    final statusColor = status == 'aktif'
        ? primaryGreen
        : status == 'selesai'
            ? Colors.blueGrey
            : status == 'dibatalkan'
                ? Colors.redAccent
                : Colors.orange;

    final idResep = int.tryParse(r['id_resep'].toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          if (widget.isReadOnly) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResepObatDetailScreen(idResep: idResep, isReadOnly: true),
              ),
            );
          } else {
            final result = await Navigator.push<bool?>(
              context,
              MaterialPageRoute(builder: (context) => ResepObatDetailScreen(idResep: idResep)),
            );
            if (result == true) _refreshList();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (r['nomor_resep'] ?? '-').toString(),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryGreen),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                      if (!widget.isReadOnly) ...[
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                          onSelected: (value) {
                            if (value == 'hapus') _hapusResep(idResep);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF2F2F2)),
              const SizedBox(height: 10),
              Text('Pasien: ${r['nama_pasien'] ?? '-'}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('Dokter: ${r['nama_dokter'] ?? '-'}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.medication, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text('${r['jumlah_obat'] ?? 0} jenis obat',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const Spacer(),
                  Text(_formatTanggal((r['tanggal_dibuat'] ?? '').toString()),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTanggal(String tanggal) {
    if (tanggal.isEmpty) return '-';
    try {
      final date = DateTime.parse(tanggal);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return tanggal;
    }
  }
}