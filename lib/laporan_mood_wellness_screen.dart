import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // ✅ untuk inisialisasi locale id_ID
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'services/api_client.dart';
import 'laporan_screen.dart' show HealUColors;
import 'report_filter_bar.dart';

class LaporanMoodWellnessScreen extends StatefulWidget {
  final String idPasien;
  final String? namaPasien;

  const LaporanMoodWellnessScreen({
    super.key,
    required this.idPasien,
    this.namaPasien,
  });

  @override
  State<LaporanMoodWellnessScreen> createState() =>
      _LaporanMoodWellnessScreenState();
}

class _LaporanMoodWellnessScreenState extends State<LaporanMoodWellnessScreen> {
  bool _isLoading = true;
  bool _isGeneratingPdf = false;
  List _moodData = [];
  List _jurnalData = [];
  String _periodeLabel = "7 Hari Terakhir";
  DateTime? _filterStart;
  DateTime? _filterEnd;

  final String apiUrl =
      "https://chump-vividness-escapable.ngrok-free.dev/healu_api/get_laporan_mingguan.php";

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final body = <String, String>{"id_pasien": widget.idPasien};
      if (_filterStart != null && _filterEnd != null) {
        final fmt = DateFormat('yyyy-MM-dd');
        body['tanggal_awal'] = fmt.format(_filterStart!);
        body['tanggal_akhir'] = fmt.format(_filterEnd!);
      }

      final response = await ApiClient.instance.post(
        Uri.parse(apiUrl),
        body: body,
      );
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            _moodData = result['data']['mood'] ?? [];
            _jurnalData = result['data']['jurnal'] ?? [];
            _periodeLabel = result['periode'] ?? "7 Hari Terakhir";
          });
        }
      }
    } catch (e) {
      debugPrint("Error mengambil laporan mood: $e");
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

  double _mapMoodToValue(String mood) {
    switch (mood.toLowerCase()) {
      case 'sangat baik':
        return 5.0;
      case 'baik':
        return 4.0;
      case 'biasa saja':
        return 3.0;
      case 'buruk':
        return 2.0;
      case 'sangat buruk':
        return 1.0;
      default:
        return 3.0;
    }
  }

  PdfColor _pdfColorForMood(String mood) {
    switch (mood.toLowerCase()) {
      case 'sangat baik':
        return PdfColors.green600;
      case 'baik':
        return PdfColors.lightGreen600;
      case 'biasa saja':
        return PdfColors.grey400;
      case 'buruk':
        return PdfColors.orange600;
      case 'sangat buruk':
        return PdfColors.red600;
      default:
        return PdfColors.grey400;
    }
  }

  int get _totalEntriMood {
    int total = 0;
    for (var m in _moodData) {
      total += int.tryParse(m['jumlah'].toString()) ?? 0;
    }
    return total;
  }

  double get _rataRataSkorMood {
    if (_moodData.isEmpty) return 0;
    double totalSkor = 0;
    int totalJumlah = 0;
    for (var m in _moodData) {
      int jumlah = int.tryParse(m['jumlah'].toString()) ?? 0;
      totalSkor += _mapMoodToValue(m['mood'].toString()) * jumlah;
      totalJumlah += jumlah;
    }
    if (totalJumlah == 0) return 0;
    return totalSkor / totalJumlah;
  }

  Future<void> _generateAndDownloadPdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      await initializeDateFormatting('id_ID', null);

      final pdf = pw.Document();
      final String tanggalCetak = DateFormat(
        'dd MMMM yyyy',
        'id_ID',
      ).format(DateTime.now());
      final String namaPasien =
          widget.namaPasien ?? "Pasien #${widget.idPasien}";
      final double rataRataSkor = _rataRataSkorMood;
      final int totalEntri = _totalEntriMood;

      // ✅ Pakai MultiPage supaya kalau jurnal panjang, otomatis lanjut ke halaman berikutnya
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (pw.Context context) {
            // Header cuma dicetak sekali di halaman pertama lewat build(),
            // supaya tidak berulang tiap halaman gunakan cek context.pageNumber
            if (context.pageNumber != 1) return pw.SizedBox();
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        "HEAL U APP",
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "LAPORAN ANALISIS MOOD & WELLNESS",
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  height: 2,
                  width: double.infinity,
                  color: PdfColors.green,
                ),
                pw.SizedBox(height: 18),
              ],
            );
          },
          footer: (pw.Context context) {
            return pw.Column(
              children: [
                pw.SizedBox(height: 8),
                pw.Divider(color: PdfColors.grey300),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    "Dokumen Resmi Heal U - Dicetak $tanggalCetak - Halaman ${context.pageNumber} dari ${context.pagesCount}",
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
                  ),
                ),
              ],
            );
          },
          build: (pw.Context context) => [
            // Info box
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _infoRow("Nama Pasien", namaPasien),
                  pw.SizedBox(height: 6),
                  _infoRow("Periode Laporan", _periodeLabel),
                  pw.SizedBox(height: 6),
                  _infoRow(
                    "Metode Input",
                    "Fitur Tracker Harian Aplikasi Pasien Heal U",
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 22),

            // Statistik Utama
            _sectionHeader("STATISTIK & METRIK UTAMA KESEJAHTERAAN"),
            pw.SizedBox(height: 10),
            _statRow(
              "Rata-rata Suasana Hati",
              totalEntri == 0
                  ? "Belum ada data"
                  : "${rataRataSkor.toStringAsFixed(1)} / 5",
              totalEntri == 0
                  ? ""
                  : (rataRataSkor >= 3.5
                      ? "Cenderung Positif"
                      : rataRataSkor >= 2.5
                      ? "Stabil"
                      : "Perlu Perhatian"),
            ),
            pw.SizedBox(height: 8),
            _statRow("Jumlah Entri Tercatat", "$totalEntri Entri", ""),
            pw.SizedBox(height: 22),

            // Distribusi Emosi
            _sectionHeader("GRAFIK DISTRIBUSI EMOSI"),
            pw.SizedBox(height: 6),
            pw.Text(
              "Distribusi emosi yang diinput pasien sepanjang periode:",
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 10),
            _moodData.isEmpty
                ? pw.Text(
                    "Tidak ada data mood pada periode ini.",
                    style: pw.TextStyle(
                      fontStyle: pw.FontStyle.italic,
                      fontSize: 10,
                    ),
                  )
                : pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: _moodData.map((m) {
                      final jumlah = int.tryParse(m['jumlah'].toString()) ?? 0;
                      final persen = totalEntri == 0
                          ? 0
                          : ((jumlah / totalEntri) * 100).round();
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 6),
                        child: pw.Row(
                          children: [
                            pw.Container(
                              width: 10,
                              height: 10,
                              color: _pdfColorForMood(m['mood'].toString()),
                            ),
                            pw.SizedBox(width: 8),
                            pw.Expanded(
                              child: pw.Text(
                                m['mood'].toString().toUpperCase(),
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ),
                            pw.Text(
                              "$persen% ($jumlah kali)",
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
            pw.SizedBox(height: 22),

            // ✅ RIWAYAT JURNAL & KELUHAN (baru ditambahkan, mengikuti tampilan aplikasi)
            _sectionHeader("RIWAYAT JURNAL & KELUHAN"),
            pw.SizedBox(height: 6),
            pw.Text(
              "Catatan jurnal dan keluhan yang ditulis pasien sepanjang periode:",
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 10),
            _jurnalData.isEmpty
                ? pw.Text(
                    "Tidak ada jurnal pada periode ini.",
                    style: pw.TextStyle(
                      fontStyle: pw.FontStyle.italic,
                      fontSize: 10,
                    ),
                  )
                : pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: _jurnalData.map((j) {
                      return pw.Container(
                        width: double.infinity,
                        margin: const pw.EdgeInsets.only(bottom: 10),
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: pw.BorderRadius.circular(6),
                          border: pw.Border.all(
                            color: PdfColors.grey300,
                            width: 0.5,
                          ),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              (j['tanggal'] ?? '').toString(),
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.green800,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              (j['catatan'] ?? '').toString(),
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.grey800,
                                lineSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
            pw.SizedBox(height: 22),

            // Blok tanda tangan digital (kanan, stacked, sesuai referensi)
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    "Manajemen Data Medis,",
                    style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                  ),
                  pw.SizedBox(height: 6),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    // QR code berisi identifier unik laporan untuk validasi.
                    data: "healu-laporan:${widget.idPasien}:$tanggalCetak",
                    width: 55,
                    height: 55,
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    "Heal U Sistem Analitik",
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.Text(
                    "[ID: ${widget.idPasien} / VALID]",
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Laporan_Mood_Wellness_${widget.idPasien}.pdf',
      );
    } catch (e) {
      debugPrint("Error membuat PDF: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal membuat PDF. Coba lagi.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ),
        pw.Text(": ", style: const pw.TextStyle(fontSize: 10)),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }

  pw.Widget _sectionHeader(String title) {
    return pw.Row(
      children: [
        pw.Container(width: 4, height: 14, color: PdfColors.green),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
          ),
        ),
      ],
    );
  }

  pw.Widget _statRow(String label, String value, String note) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        pw.Row(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            if (note.isNotEmpty) ...[
              pw.SizedBox(width: 6),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  note,
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.green800),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  BoxDecoration get _softWhiteDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 15,
        spreadRadius: 1,
        offset: const Offset(0, 4),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final String appBarTitle = widget.namaPasien != null
        ? "Mood & Wellness - ${widget.namaPasien}"
        : "Mood & Wellness";

    return Scaffold(
      backgroundColor: HealUColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: HealUColors.textPrimary),
        title: Text(
          appBarTitle,
          style: const TextStyle(
            color: HealUColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: HealUColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  ReportFilterBar(
                    startDate: _filterStart,
                    endDate: _filterEnd,
                    onTap: _openFilter,
                  ),
                  _buildSectionTitle("Kesimpulan Mood", Icons.insights),
                  const SizedBox(height: 12),
                  _moodData.isEmpty
                      ? _buildEmptyState(
                          "Belum ada data mood pada periode ini.",
                        )
                      : Container(
                          decoration: _softWhiteDecoration,
                          clipBehavior: Clip.antiAlias,
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _moodData.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: Colors.black12),
                            itemBuilder: (context, idx) => ListTile(
                              leading: const Icon(
                                Icons.emoji_emotions,
                                color: Colors.amber,
                              ),
                              title: Text(
                                _moodData[idx]['mood'].toString().toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: Text(
                                "${_moodData[idx]['jumlah']} Kali",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 25),
                  _buildSectionTitle("Riwayat Jurnal & Keluhan", Icons.book),
                  const SizedBox(height: 12),
                  _jurnalData.isEmpty
                      ? _buildEmptyState("Belum ada jurnal pada periode ini.")
                      : Column(
                          children: _jurnalData.map<Widget>((j) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: _softWhiteDecoration,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    j['tanggal'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    j['catatan'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B9455),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: _isGeneratingPdf
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download, color: Colors.white),
                      label: Text(
                        _isGeneratingPdf
                            ? "Membuat PDF..."
                            : "Unduh Laporan PDF",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _isGeneratingPdf
                          ? null
                          : _generateAndDownloadPdf,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: HealUColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: HealUColors.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _softWhiteDecoration,
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, color: Colors.grey.shade300, size: 40),
          const SizedBox(height: 10),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}