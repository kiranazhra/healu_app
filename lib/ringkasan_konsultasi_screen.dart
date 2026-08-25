import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:convert';
import 'services/api_client.dart';

class RingkasanKonsultasiScreen extends StatefulWidget {
  final Map<String, dynamic> dataRiwayat;
  final String role;

  const RingkasanKonsultasiScreen({
    super.key,
    required this.dataRiwayat,
    required this.role,
  });

  @override
  State<RingkasanKonsultasiScreen> createState() =>
      _RingkasanKonsultasiScreenState();
}

class _RingkasanKonsultasiScreenState extends State<RingkasanKonsultasiScreen> {
  static const Color primaryGreen = Color(0xFF93B174);
  static const Color bgCream = Color(0xFFFFFDEC);

  final String baseUrl =
      'https://chump-vividness-escapable.ngrok-free.dev/healu_api';

  bool _isLoading = true;
  bool _belumAdaRekamMedis = false;
  Map<String, dynamic>? _rekamMedis;

  @override
  void initState() {
    super.initState();
    _fetchRekamMedis();
  }

  Future<void> _fetchRekamMedis() async {
    final idKonsultasi = widget.dataRiwayat['id']?.toString() ?? '';

    if (idKonsultasi.isEmpty) {
      setState(() {
        _isLoading = false;
        _belumAdaRekamMedis = true;
      });
      return;
    }

    try {
      final response = await ApiClient.instance
          .get(
            Uri.parse(
              '$baseUrl/get_rekam_medis_by_konsultasi.php?id_konsultasi=$idKonsultasi',
            ),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      final result = jsonDecode(response.body);

      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _rekamMedis = result['data'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _belumAdaRekamMedis = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetch rekam medis: $e');
      if (!mounted) return;
      setState(() {
        _belumAdaRekamMedis = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _generateAndPrintPDF({
    required String idKonsultasi,
    required String namaPasien,
    required String namaDokter,
    required String spesialis,
    required String tanggal,
    required String waktu,
    required String durasi,
    required String subjektif,
    required String objektif,
    required String asesmen,
    required String plan,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Center(
              child: pw.Text(
                "HEAL U APP",
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
            ),
            pw.Center(
              child: pw.Text(
                "RINGKASAN KLINIK & REKAM MEDIS SOAP",
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 16),

            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildPdfRowSimple("ID Konsultasi", idKonsultasi),
                _buildPdfRowSimple("Nama Pasien", namaPasien),
                _buildPdfRowSimple("Dokter", namaDokter),
                _buildPdfRowSimple("Spesialis", spesialis),
                _buildPdfRowSimple("Tanggal", tanggal),
                _buildPdfRowSimple("Waktu Sesi", "$waktu WIB"),
                _buildPdfRowSimple("Durasi", "$durasi Menit"),
              ],
            ),

            pw.SizedBox(height: 20),

            _buildSoapSection("SUBJEKTIF (S) - KELUHAN PASIEN", subjektif),
            pw.SizedBox(height: 12),
            _buildSoapSection("OBJEKTIF (O) - PEMERIKSAAN KLINIS", objektif),
            pw.SizedBox(height: 12),
            _buildSoapSection("ASESMEN (A) - DIAGNOSA MEDIS", asesmen),
            pw.SizedBox(height: 12),
            _buildSoapSection("PLAN (P) - RENCANA & TERAPI", plan),

            pw.SizedBox(height: 30),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 10),

            pw.Center(
              child: pw.Text(
                "Dicetak pada: ${DateTime.now().toString().substring(0, 16)}",
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Ringkasan_Konsultasi_$idKonsultasi.pdf',
    );
  }

  pw.Widget _buildPdfRowSimple(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSoapSection(String title, String content) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          content,
          style: const pw.TextStyle(fontSize: 10),
          textAlign: pw.TextAlign.justify,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final riwayat = widget.dataRiwayat;

    String idKonsultasi = riwayat['id']?.toString() ?? 'ID-0000';

    // Ambil dari rekam medis kalau ada, fallback ke data riwayat konsultasi
    String namaPasien = (_rekamMedis?['nama_pasien'] ??
            riwayat['nama_pasien'] ??
            'Pasien')
        .toString();
    String namaDokter = (_rekamMedis?['nama_dokter'] ??
            riwayat['nama_dokter'] ??
            'Dokter')
        .toString();
    String namaLawan = widget.role == 'dokter' ? namaPasien : namaDokter;
    String spesialis = (_rekamMedis?['spesialis'] ?? riwayat['spesialis'] ?? 'Umum')
        .toString();
    String tanggal = (_rekamMedis?['tanggal_jadwal'] ??
            riwayat['tanggal_jadwal'] ??
            '-')
        .toString();
    String waktu = (_rekamMedis?['waktu_jadwal'] ?? riwayat['waktu_jadwal'] ?? '-')
        .toString();
    String durasi = (_rekamMedis?['durasi'] ?? riwayat['durasi'] ?? '30')
        .toString();

    String subjektif = (_rekamMedis?['subjektif'] ?? '-').toString();
    String objektif = (_rekamMedis?['objektif'] ?? '-').toString();
    String asesmen = (_rekamMedis?['asesmen'] ?? '-').toString();
    String plan = (_rekamMedis?['plan'] ?? '-').toString();

    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Ringkasan Medis",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER LAPORAN
                        Center(
                          child: Column(
                            children: [
                              const Text(
                                "HEAL U APP",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "RINGKASAN KLINIK & REKAM MEDIS SOAP",
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              Container(height: 1, color: Colors.grey.shade300),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // INFO KONSULTASI
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow("ID Konsultasi", idKonsultasi),
                              const SizedBox(height: 12),
                              _buildInfoRow("Nama Pasien", namaLawan),
                              const SizedBox(height: 12),
                              _buildInfoRow("Dokter/Spesialis", spesialis),
                              const SizedBox(height: 12),
                              _buildInfoRow("Tanggal", tanggal),
                              const SizedBox(height: 12),
                              _buildInfoRow("Waktu Sesi", "$waktu WIB"),
                              const SizedBox(height: 12),
                              _buildInfoRow("Durasi", "$durasi Menit"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (_belumAdaRekamMedis) ...[
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.description_outlined,
                                    size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                const Text(
                                  "Rekam medis belum dibuat",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Dokter belum mengisi rekam medis SOAP untuk konsultasi ini.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          // SOAP SECTIONS - data asli dari rekam_medis
                          _buildSoapCard("SUBJEKTIF (S) - KELUHAN PASIEN", subjektif),
                          const SizedBox(height: 16),
                          _buildSoapCard("OBJEKTIF (O) - PEMERIKSAAN KLINIS", objektif),
                          const SizedBox(height: 16),
                          _buildSoapCard("ASESMEN (A) - DIAGNOSA MEDIS", asesmen),
                          const SizedBox(height: 16),
                          _buildSoapCard("PLAN (P) - RENCANA & TERAPI", plan),
                        ],
                        const SizedBox(height: 20),

                        // SUCCESS MESSAGE
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9F4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.check_circle,
                                  color: primaryGreen, size: 48),
                              SizedBox(height: 12),
                              Text(
                                "Konsultasi Selesai",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Semoga sehat selalu bersama Healu",
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // TOMBOL UNDUH PDF (disembunyikan kalau belum ada rekam medis)
                if (!_belumAdaRekamMedis)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _generateAndPrintPDF(
                          idKonsultasi: idKonsultasi,
                          namaPasien: namaPasien,
                          namaDokter: namaDokter,
                          spesialis: spesialis,
                          tanggal: tanggal,
                          waktu: waktu,
                          durasi: durasi,
                          subjektif: subjektif,
                          objektif: objektif,
                          asesmen: asesmen,
                          plan: plan,
                        ),
                        icon: const Icon(Icons.download, color: Colors.white),
                        label: const Text(
                          "Unduh Ringkasan (PDF)",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSoapCard(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.only(left: 12),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: primaryGreen, width: 4)),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            content,
            style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.6),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }
}