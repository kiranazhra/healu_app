import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'edit_rekam_medis_screen.dart';
import 'dart:typed_data';

class RekamMedisDetailScreen extends StatefulWidget {
  final int idRekam;
  final String nomorRekam;
  final String namaPasien;
  final String namaDokter;
  final String? spesialis;
  final String? tanggalJadwal;
  final String? waktuJadwal;
  final int? durasi;
  final String subjektif;
  final String objektif;
  final String asesmen;
  final String plan;

  // Opsional: kirim role user yang sedang login ('pasien' | 'admin' | 'dokter')
  // supaya tombol edit hanya muncul untuk dokter/admin. Default null = tampil semua.
  final String? role;

  const RekamMedisDetailScreen({
    super.key,
    required this.idRekam,
    required this.nomorRekam,
    required this.namaPasien,
    required this.namaDokter,
    this.spesialis,
    this.tanggalJadwal,
    this.waktuJadwal,
    this.durasi,
    required this.subjektif,
    required this.objektif,
    required this.asesmen,
    required this.plan,
    this.role,
  });

  @override
  State<RekamMedisDetailScreen> createState() => _RekamMedisDetailScreenState();
}

class _RekamMedisDetailScreenState extends State<RekamMedisDetailScreen> {
  static const Color primaryGreen = Color(0xFF8EB76E);
  static const Color bgCream = Color(0xFFFFFDEC);

  bool _isGeneratingPdf = false;

  @override
  Widget build(BuildContext context) {
    final bool canEdit = widget.role == null ||
        widget.role == 'dokter' ||
        widget.role == 'admin';

    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        title: const Text(
          'Rekam Medis',
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
        actions: [
          // Tombol Unduh PDF — tersedia untuk semua role (pasien, admin, dokter)
          IconButton(
            icon: _isGeneratingPdf
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: primaryGreen,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_outlined, color: primaryGreen),
            tooltip: 'Unduh sebagai PDF',
            onPressed: _isGeneratingPdf ? null : _handleDownloadPdf,
          ),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit, color: primaryGreen),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final result = await navigator.push<bool?>(
                  MaterialPageRoute(
                    builder: (context) => EditRekamMedisScreen(
                      idRekam: widget.idRekam,
                      nomorRekam: widget.nomorRekam,
                      namaPasien: widget.namaPasien,
                      namaDokter: widget.namaDokter,
                      subjektif: widget.subjektif,
                      objektif: widget.objektif,
                      asesmen: widget.asesmen,
                      plan: widget.plan,
                      statusRekam: 'final',
                    ),
                  ),
                );

                if (!mounted) return;
                if (result == true) {
                  navigator.pop(true);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header seperti PDF
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.local_pharmacy, size: 32, color: primaryGreen),
                    const SizedBox(height: 8),
                    const Text(
                      'HEAL U APP',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RINGKASAN KLINIS & REKAM MEDIS SOAP',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      color: primaryGreen,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Info Header
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    _buildInfoRow('ID Konsultasi', widget.nomorRekam),
                    _buildInfoRow('Nama Pasien', widget.namaPasien),
                    _buildInfoRow('Dokter Pemeriksa', widget.namaDokter),
                    if (widget.tanggalJadwal != null)
                      _buildInfoRow(
                        'Waktu Sesi',
                        '${_formatTanggal(widget.tanggalJadwal!)} | ${widget.waktuJadwal}',
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // SUBJEKTIF
              _buildSOAPSection(
                title: 'SUBJEKTIF (S) - KELUHAN PASIEN',
                content: widget.subjektif,
              ),
              const SizedBox(height: 16),

              // OBJEKTIF
              _buildSOAPSection(
                title: 'OBJEKTIF (O) - PEMERIKSAAN KLINIS',
                content: widget.objektif,
              ),
              const SizedBox(height: 16),

              // ASESMEN
              _buildSOAPSection(
                title: 'ASESMEN (A) - DIAGNOSA MEDIS',
                content: widget.asesmen,
              ),
              const SizedBox(height: 16),

              // PLAN
              _buildSOAPSection(
                title: 'PLAN (P) - RENCANA & TERAPI',
                content: widget.plan,
              ),
              const SizedBox(height: 24),

              // Footer
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Dokter Pemeriksa,',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.namaDokter,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.spesialis != null)
                      Text(
                        widget.spesialis!,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    const SizedBox(height: 4),
                    const Text(
                      '[TERVERIFIKASI DIGITAL]',
                      style: TextStyle(
                        fontSize: 10,
                        color: primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Tombol besar unduh PDF di bawah, opsional selain ikon di AppBar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingPdf ? null : _handleDownloadPdf,
                  icon: _isGeneratingPdf
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_rounded, color: Colors.white),
                  label: Text(
                    _isGeneratingPdf ? 'Membuat PDF...' : 'Unduh Rekam Medis (PDF)',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOAPSection({
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: primaryGreen.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: const Border(
              left: BorderSide(color: primaryGreen, width: 4),
            ),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: primaryGreen,
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTanggal(String tanggal) {
    try {
      final date = DateTime.parse(tanggal);
      const bulan = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

      return '${hari[date.weekday - 1]}, ${date.day} ${bulan[date.month - 1]} ${date.year}';
    } catch (e) {
      return tanggal;
    }
  }

  // ==========================================================
  //  BAGIAN PDF
  // ==========================================================

  Future<void> _handleDownloadPdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final pdfData = await _buildPdfDocument();

      // Printing.layoutPdf akan:
      // - Web: langsung memicu unduhan / preview print browser
      // - Android/iOS/Desktop: membuka preview, user bisa "Save to file" / "Share"
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfData,
        name: 'RekamMedis_${widget.nomorRekam}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<Uint8List> _buildPdfDocument() async {
    final doc = pw.Document();

    final pdfGreen = PdfColor.fromInt(primaryGreen.toARGB32());
    final pdfGrey600 = PdfColor.fromInt(Colors.grey.shade600.toARGB32());
    final pdfGrey200 = PdfColor.fromInt(Colors.grey.shade200.toARGB32());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'HEAL U APP',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: pdfGreen,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'RINGKASAN KLINIS & REKAM MEDIS SOAP',
                  style: pw.TextStyle(fontSize: 10, color: pdfGrey600),
                ),
                pw.SizedBox(height: 10),
                pw.Container(height: 1, color: pdfGreen),
              ],
            ),
          ),
          pw.SizedBox(height: 16),

          _pdfInfoRow('ID Konsultasi', widget.nomorRekam, pdfGrey600),
          _pdfInfoRow('Nama Pasien', widget.namaPasien, pdfGrey600),
          _pdfInfoRow('Dokter Pemeriksa', widget.namaDokter, pdfGrey600),
          if (widget.tanggalJadwal != null)
            _pdfInfoRow(
              'Waktu Sesi',
              '${_formatTanggal(widget.tanggalJadwal!)} | ${widget.waktuJadwal ?? '-'}',
              pdfGrey600,
            ),
          pw.SizedBox(height: 16),

          _pdfSoapSection('SUBJEKTIF (S) - KELUHAN PASIEN', widget.subjektif, pdfGreen, pdfGrey200),
          pw.SizedBox(height: 12),
          _pdfSoapSection('OBJEKTIF (O) - PEMERIKSAAN KLINIS', widget.objektif, pdfGreen, pdfGrey200),
          pw.SizedBox(height: 12),
          _pdfSoapSection('ASESMEN (A) - DIAGNOSA MEDIS', widget.asesmen, pdfGreen, pdfGrey200),
          pw.SizedBox(height: 12),
          _pdfSoapSection('PLAN (P) - RENCANA & TERAPI', widget.plan, pdfGreen, pdfGrey200),
          pw.SizedBox(height: 24),

          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: pdfGrey200),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Dokter Pemeriksa,', style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 30),
                pw.Text(
                  widget.namaDokter,
                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                ),
                if (widget.spesialis != null)
                  pw.Text(widget.spesialis!, style: pw.TextStyle(fontSize: 9, color: pdfGrey600)),
                pw.SizedBox(height: 4),
                pw.Text(
                  '[TERVERIFIKASI DIGITAL]',
                  style: pw.TextStyle(fontSize: 8, color: pdfGreen, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _pdfInfoRow(String label, String value, PdfColor labelColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: labelColor),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSoapSection(String title, String content, PdfColor titleColor, PdfColor borderColor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(left: pw.BorderSide(color: titleColor, width: 3)),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: titleColor),
          ),
        ),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: borderColor)),
          child: pw.Text(content, style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }
}