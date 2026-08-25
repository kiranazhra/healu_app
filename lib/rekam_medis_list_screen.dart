import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'services/api_client.dart';
import 'dart:convert';
import 'rekam_medis_detail_screen.dart';
import 'rekam_medis_view_screen.dart';
import 'report_filter_bar.dart';

class RekamMedisListScreen extends StatefulWidget {
  final int? idDokter;
  final int? idPasien;
  final String? title;
  final bool isReadOnly; // true = pasien/admin, false = dokter

  const RekamMedisListScreen({
    super.key,
    this.idDokter,
    this.idPasien,
    this.title,
    this.isReadOnly = false,
  });

  @override
  State<RekamMedisListScreen> createState() => _RekamMedisListScreenState();
}

class _RekamMedisListScreenState extends State<RekamMedisListScreen> {
  static const Color primaryGreen = Color(0xFF8EB76E);
  static const Color bgCream = Color(0xFFFFFDEC);

  late Future<List<dynamic>> _futureRekamMedis;

  DateTime? _filterStart;
  DateTime? _filterEnd;

  final String baseUrl =
      'https://chump-vividness-escapable.ngrok-free.dev/healu_api';

  @override
  void initState() {
    super.initState();
    _futureRekamMedis = _fetchRekamMedis();
  }

  Future<List<dynamic>> _fetchRekamMedis() async {
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

      final uri = Uri.parse(
        '$baseUrl/get_rekam_medis.php',
      ).replace(queryParameters: queryParams);

      final response = await ApiClient.instance
          .get(uri)
          .timeout(const Duration(seconds: 10));

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
    setState(() {
      _futureRekamMedis = _fetchRekamMedis();
    });
  }

  Future<void> _openFilter() async {
    final result = await showReportFilterSheet(
      context,
      currentStart: _filterStart,
      currentEnd: _filterEnd,
    );
    if (result == null) return; // dibatalkan
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        title: Text(
          widget.title ?? 'Rekam Medis',
          style: const TextStyle(
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
                future: _futureRekamMedis,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: primaryGreen),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final rekamMedisList = snapshot.data ?? [];

                  if (rekamMedisList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 64,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada rekam medis',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: rekamMedisList.length,
                    itemBuilder: (context, index) {
                      final rm = rekamMedisList[index];
                      return _buildRekamMedisCard(rm);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRekamMedisCard(Map<String, dynamic> rm) {
    final String statusRekam = (rm['status_rekam'] ?? '-').toString();

    final statusColor = statusRekam == 'final'
        ? primaryGreen
        : statusRekam == 'draft'
        ? Colors.orange
        : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (widget.isReadOnly) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RekamMedisViewScreen(
                  nomorRekam: (rm['nomor_rekam'] ?? '-').toString(),
                  namaPasien: (rm['nama_pasien'] ?? '-').toString(),
                  namaDokter: (rm['nama_dokter'] ?? '-').toString(),
                  spesialis: (rm['spesialis'] ?? '-').toString(),
                  tanggalJadwal: (rm['tanggal_jadwal'] ?? '-').toString(),
                  waktuJadwal: (rm['waktu_jadwal'] ?? '-').toString(),
                  durasi: int.tryParse(rm['durasi']?.toString() ?? ''),
                  subjektif: (rm['subjektif'] ?? '-').toString(),
                  objektif: (rm['objektif'] ?? '-').toString(),
                  asesmen: (rm['asesmen'] ?? '-').toString(),
                  plan: (rm['plan'] ?? '-').toString(),
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RekamMedisDetailScreen(
                  idRekam: int.tryParse(rm['id_rekam'].toString()) ?? 0,
                  nomorRekam: (rm['nomor_rekam'] ?? '-').toString(),
                  namaPasien: (rm['nama_pasien'] ?? '-').toString(),
                  namaDokter: (rm['nama_dokter'] ?? '-').toString(),
                  spesialis: (rm['spesialis'] ?? '-').toString(),
                  tanggalJadwal: (rm['tanggal_jadwal'] ?? '-').toString(),
                  waktuJadwal: (rm['waktu_jadwal'] ?? '-').toString(),
                  durasi: int.tryParse(rm['durasi']?.toString() ?? ''),
                  subjektif: (rm['subjektif'] ?? '-').toString(),
                  objektif: (rm['objektif'] ?? '-').toString(),
                  asesmen: (rm['asesmen'] ?? '-').toString(),
                  plan: (rm['plan'] ?? '-').toString(),
                ),
              ),
            ).then((result) {
              if (result == true) {
                _refreshList();
              }
            });
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
                    (rm['nomor_rekam'] ?? '-').toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusRekam.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF2F2F2)),
              const SizedBox(height: 10),
              Text(
                'Pasien: ${rm['nama_pasien'] ?? '-'}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                'Dokter: ${rm['nama_dokter'] ?? '-'}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 6),
              Text(
                'Dibuat: ${_formatTanggal((rm['tanggal_dibuat'] ?? '').toString())}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return tanggal;
    }
  }
}