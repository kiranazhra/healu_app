import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'services/api_client.dart';
import 'resep_obat_form_screen.dart';

class ResepObatDetailScreen extends StatefulWidget {
  final int idResep;
  final bool isReadOnly; // true untuk pasien, false untuk dokter

  const ResepObatDetailScreen({
    super.key,
    required this.idResep,
    this.isReadOnly = false,
  });

  @override
  State<ResepObatDetailScreen> createState() => _ResepObatDetailScreenState();
}

class _ResepObatDetailScreenState extends State<ResepObatDetailScreen> {
  static const Color primaryGreen = Color(0xFF8EB76E);
  static const Color bgCream = Color(0xFFFFFDEC);

  final String baseUrl =
      'https://chump-vividness-escapable.ngrok-free.dev/healu_api';

  bool _isLoading = true;
  bool _isGeneratingPdf = false;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse('$baseUrl/get_resep_obat_by_id.php')
          .replace(queryParameters: {'id_resep': widget.idResep.toString()});
      final response = await ApiClient.instance.get(uri);
      final result = jsonDecode(response.body);
      if (result['success'] == true) {
        setState(() => _data = result['data']);
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _hapus() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Resep'),
        content: const Text('Yakin ingin menghapus resep ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
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
        body: {'id_resep': widget.idResep.toString()},
      );
      final result = jsonDecode(response.body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? '')));
      if (result['success'] == true) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _toggleReminder(int idDetail, bool aktifkan) async {
    try {
      final response = await ApiClient.instance.post(
        Uri.parse('$baseUrl/toggle_reminder_obat.php'),
        body: {
          'id': idDetail.toString(),
          'status_reminder': aktifkan ? 'aktif' : 'nonaktif',
        },
      );
      final result = jsonDecode(response.body);
      if (result['success'] == true) {
        _fetchDetail();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Gagal mengubah pengingat')),
        );
      }
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
        title: const Text('Resep Obat Digital',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: _data == null
            ? []
            : [
                IconButton(
                  icon: _isGeneratingPdf
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: primaryGreen))
                      : const Icon(Icons.picture_as_pdf_outlined, color: primaryGreen),
                  onPressed: _isGeneratingPdf ? null : _handleDownloadPdf,
                ),
                if (!widget.isReadOnly) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, color: primaryGreen),
                    onPressed: () async {
                      final result = await Navigator.push<bool?>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResepObatFormScreen(
                            idResep: widget.idResep,
                            existingData: _data,
                          ),
                        ),
                      );
                      if (result == true) _fetchDetail();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: _hapus,
                  ),
                ],
              ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryGreen))
          : _data == null
              ? const Center(child: Text('Resep tidak ditemukan'))
              : _buildContent(_data!),
    );
  }

  Widget _buildContent(Map<String, dynamic> data) {
    final obatList = (data['obat'] as List?) ?? [];
    final riwayatAlergi = (data['riwayat_alergi'] ?? '').toString();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Icon(Icons.local_pharmacy, size: 32, color: primaryGreen),
                  const SizedBox(height: 8),
                  const Text('HEAL U APP',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: primaryGreen)),
                  const SizedBox(height: 4),
                  Text('LAPORAN RESEP OBAT DIGITAL (E-PRESCRIPTION)',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(height: 12),
                  Container(height: 1, color: primaryGreen),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('No. Resep Digital', (data['nomor_resep'] ?? '-').toString()),
                  _infoRow('Nama Pasien', (data['nama_pasien'] ?? '-').toString()),
                  _infoRow('Dokter Penulis', (data['nama_dokter'] ?? '-').toString()),
                  _infoRow(
                    'Riwayat Alergi',
                    riwayatAlergi.isEmpty ? 'Tidak ada riwayat alergi' : riwayatAlergi,
                    valueColor: riwayatAlergi.isEmpty ? null : Colors.redAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('DAFTAR OBAT TERKUNCI SISTEM',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryGreen)),
            const SizedBox(height: 10),
            for (final o in obatList) _buildObatCard(o),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildObatCard(Map<String, dynamic> o) {
    final idDetail = int.tryParse(o['id'].toString()) ?? 0;
    final bool reminderAktif = (o['status_reminder'] ?? 'aktif') == 'aktif';
    final bool adaJadwal = o['waktu_minum'] != null && o['waktu_minum'].toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${o['nama_obat'] ?? '-'}${(o['dosis'] ?? '').toString().isNotEmpty ? ' ${o['dosis']}' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Text('${o['jumlah']} ${o['satuan'] ?? ''}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryGreen)),
              ),
            ],
          ),
          Text('${o['sediaan'] ?? ''}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('${o['aturan_pakai'] ?? '-'}', style: const TextStyle(fontSize: 12, height: 1.5)),
          if ((o['catatan'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Catatan: ${o['catatan']}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
          ],
          if (adaJadwal) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications_active_outlined,
                        size: 14, color: reminderAktif ? primaryGreen : Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Pengingat pukul ${o['waktu_minum']}',
                      style: TextStyle(fontSize: 11, color: reminderAktif ? primaryGreen : Colors.grey),
                    ),
                  ],
                ),
                // Pasien boleh nyalakan/matikan pengingat, isi resep tetap terkunci
                if (widget.isReadOnly)
                  Switch(
                    value: reminderAktif,
                    activeThumbColor: primaryGreen,
                    onChanged: (v) => _toggleReminder(idDetail, v),
                  )
                else
                  Text(
                    reminderAktif ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: reminderAktif ? primaryGreen : Colors.grey,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleDownloadPdf() async {
    if (_data == null) return;
    setState(() => _isGeneratingPdf = true);
    try {
      final pdfData = await _buildPdf(_data!);
      await Printing.layoutPdf(
        onLayout: (format) async => pdfData,
        name: 'Resep_${_data!['nomor_resep']}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuat PDF: $e')));
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<Uint8List> _buildPdf(Map<String, dynamic> data) async {
    final doc = pw.Document();
    final pdfGreen = PdfColor.fromInt(primaryGreen.toARGB32());
    final pdfGrey = PdfColor.fromInt(Colors.grey.shade600.toARGB32());
    final riwayatAlergi = (data['riwayat_alergi'] ?? '').toString();
    final obatList = (data['obat'] as List?) ?? [];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Center(
            child: pw.Column(children: [
              pw.Text('HEAL U APP',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: pdfGreen)),
              pw.SizedBox(height: 4),
              pw.Text('LAPORAN RESEP OBAT DIGITAL (E-PRESCRIPTION)',
                  style: pw.TextStyle(fontSize: 10, color: pdfGrey)),
              pw.SizedBox(height: 10),
              pw.Container(height: 1, color: pdfGreen),
            ]),
          ),
          pw.SizedBox(height: 16),
          _pdfRow('No. Resep Digital', (data['nomor_resep'] ?? '-').toString(), pdfGrey),
          _pdfRow('Nama Pasien', (data['nama_pasien'] ?? '-').toString(), pdfGrey),
          _pdfRow('Dokter Penulis', (data['nama_dokter'] ?? '-').toString(), pdfGrey),
          _pdfRow('Riwayat Alergi', riwayatAlergi.isEmpty ? 'Tidak ada riwayat alergi' : riwayatAlergi, pdfGrey),
          pw.SizedBox(height: 16),
          pw.Text('DAFTAR OBAT TERKUNCI SISTEM',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: pdfGreen)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColor.fromInt(Colors.grey.shade300.toARGB32())),
            columnWidths: const {0: pw.FlexColumnWidth(2.5), 1: pw.FlexColumnWidth(1), 2: pw.FlexColumnWidth(2.5)},
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: pdfGreen),
                children: [
                  _pdfCell('Nama Obat & Sediaan', bold: true, white: true),
                  _pdfCell('Jumlah', bold: true, white: true),
                  _pdfCell('Aturan & Cara Pakai', bold: true, white: true),
                ],
              ),
              for (final o in obatList)
                pw.TableRow(children: [
                  _pdfCell('${o['nama_obat'] ?? ''} ${o['dosis'] ?? ''}\n${o['sediaan'] ?? ''}'),
                  _pdfCell('${o['jumlah'] ?? ''} ${o['satuan'] ?? ''}'),
                  _pdfCell('${o['aturan_pakai'] ?? ''}'),
                ]),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Dokter Penanggung Jawab,', style: const pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 30),
                pw.Text('${data['nama_dokter'] ?? ''}',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text('[TERVERIFIKASI DIGITAL]',
                    style: pw.TextStyle(fontSize: 8, color: pdfGreen, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _pdfRow(String label, String value, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(children: [
        pw.SizedBox(width: 120, child: pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color))),
        pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
      ]),
    );
  }

  pw.Widget _pdfCell(String text, {bool bold = false, bool white = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: white ? PdfColors.white : PdfColors.black,
        ),
      ),
    );
  }
}