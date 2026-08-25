import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'services/api_client.dart';
import 'laporan_screen.dart' show HealUColors;
import 'report_filter_bar.dart';

class InvoicePembayaranScreen extends StatefulWidget {
  // idPasien null = mode admin (lihat invoice semua pasien).
  // idPasien terisi = mode pasien (lihat invoice miliknya sendiri).
  final String? idPasien;
  const InvoicePembayaranScreen({super.key, this.idPasien});

  @override
  State<InvoicePembayaranScreen> createState() =>
      _InvoicePembayaranScreenState();
}

class _InvoicePembayaranScreenState extends State<InvoicePembayaranScreen> {
  bool _isLoading = true;
  List _invoiceData = [];
  DateTime? _filterStart;
  DateTime? _filterEnd;

  bool get _isAdminMode => widget.idPasien == null;

  final String _baseUrl =
      "https://chump-vividness-escapable.ngrok-free.dev/healu_api";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final body = <String, String>{};
      if (!_isAdminMode) {
        body['id_pasien'] = widget.idPasien!;
      }
      if (_filterStart != null && _filterEnd != null) {
        final fmt = DateFormat('yyyy-MM-dd');
        body['tanggal_awal'] = fmt.format(_filterStart!);
        body['tanggal_akhir'] = fmt.format(_filterEnd!);
      }

      final endpoint = _isAdminMode
          ? "$_baseUrl/get_all_invoice.php"
          : "$_baseUrl/get_invoice_pasien.php";

      final response = await ApiClient.instance.post(
        Uri.parse(endpoint),
        body: body,
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            _invoiceData = result['data'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint("Error mengambil invoice: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    _fetchData();
  }

  String _formatRupiah(dynamic value) {
    final angka = double.tryParse(value.toString()) ?? 0;
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(angka);
  }

  // ── GENERATE & UNDUH PDF UNTUK SATU INVOICE ──
  Future<void> _unduhInvoicePdf(Map inv) async {
    final noInvoice = (inv['no_invoice'] ?? '-').toString();
    final layanan = (inv['layanan'] ?? '-').toString();
    final tanggal = (inv['tanggal_bayar'] ?? '-').toString();
    final jumlah = _formatRupiah(inv['jumlah_bayar']);
    final lunas = (inv['status_bayar'] ?? '') == 'lunas';
    final status = lunas ? 'LUNAS' : 'BELUM LUNAS';
    final namaPasien = (inv['nama_pasien'] ?? '-').toString();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(36),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'HealU',
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF8EB76E),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Invoice Pembayaran',
                  style: const pw.TextStyle(
                    fontSize: 13,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 24),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 16),
                _pdfRow('No. Invoice', noInvoice),
                _pdfRow('Nama Pasien', namaPasien),
                _pdfRow('Layanan', layanan),
                _pdfRow('Tanggal', tanggal),
                _pdfRow('Status', status),
                pw.SizedBox(height: 20),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Pembayaran',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      jumlah,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 50),
                pw.Text(
                  'Dokumen ini dihasilkan otomatis oleh sistem HealU dan sah tanpa tanda tangan basah.',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '$noInvoice.pdf',
    );
  }

  pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: const pw.TextStyle(color: PdfColors.grey700),
            ),
          ),
          pw.Text(': ', style: const pw.TextStyle(color: PdfColors.grey700)),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealUColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: HealUColors.textPrimary),
        title: const Text(
          "Invoice Pembayaran",
          style: TextStyle(
            color: HealUColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ReportFilterBar(
              startDate: _filterStart,
              endDate: _filterEnd,
              onTap: _openFilter,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: HealUColors.primary,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      child: _invoiceData.isEmpty
                          ? ListView(children: [_buildEmptyState()])
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 20),
                              itemCount: _invoiceData.length,
                              itemBuilder: (context, idx) {
                                final inv = _invoiceData[idx];
                                final bool lunas =
                                    (inv['status_bayar'] ?? '') == 'lunas';
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              inv['no_invoice'] ?? '-',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color:
                                                    HealUColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: lunas
                                                  ? Colors.green.withValues(
                                                      alpha: 0.12,
                                                    )
                                                  : Colors.orange.withValues(
                                                      alpha: 0.12,
                                                    ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              lunas ? "Lunas" : "Belum Lunas",
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: lunas
                                                    ? Colors.green.shade700
                                                    : Colors.orange.shade700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        inv['layanan'] ?? '-',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      // Nama pasien hanya ditampilkan di mode admin
                                      if (_isAdminMode) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Pasien: ${inv['nama_pasien'] ?? '-'}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: HealUColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      Text(
                                        inv['tanggal_bayar'] ?? '-',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: HealUColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _formatRupiah(
                                                inv['jumlah_bayar'],
                                              ),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: HealUColors.primaryDark,
                                              ),
                                            ),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () =>
                                                _unduhInvoicePdf(inv),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(
                                                color: HealUColors.primary,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                            ),
                                            icon: const Icon(
                                              Icons.picture_as_pdf_outlined,
                                              size: 16,
                                              color: HealUColors.primaryDark,
                                            ),
                                            label: const Text(
                                              'Unduh PDF',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: HealUColors.primaryDark,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: Colors.grey.shade300,
            size: 40,
          ),
          const SizedBox(height: 10),
          Text(
            "Belum ada riwayat invoice pembayaran.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
