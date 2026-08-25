// ignore_for_file: avoid_print, curly_braces_in_flow_control_structures, deprecated_member_use

import 'package:flutter/material.dart';
import 'services/api_client.dart';
import 'dart:convert';

class MonitoringScreen extends StatefulWidget {
  final String userEmail; // Menerima email dari halaman login

  const MonitoringScreen({super.key, required this.userEmail});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  String _selectedSubTab = 'Mood';
  String _selectedMood = 'Biasa Saja';
  final TextEditingController _jurnalController = TextEditingController();
  bool _isSaving = false;
  bool _isLoadingJurnal = false;
  List _grafikData = [];
  List _jurnalData = [];

  double mapMoodToValue(String moodString) {
    switch (moodString) {
      case 'Sangat Baik':
        return 5.0;
      case 'Baik':
        return 4.0;
      case 'Biasa Saja':
        return 3.0;
      case 'Buruk':
        return 2.0;
      case 'Sangat Buruk':
        return 1.0;
      default:
        return 3.0;
    }
  }

  // --- API Functions ---
  Future<void> loadGrafikData() async {
    String url =
        "https://chump-vividness-escapable.ngrok-free.dev/healu_api/get_grafik_mood.php?email=${widget.userEmail}";
    try {
      var respon = await ApiClient.instance.get(Uri.parse(url));
      if (respon.statusCode == 200) {
        var jsonResponse = jsonDecode(respon.body);
        setState(() {
          _grafikData = jsonResponse['data'] ?? [];
        });
        print("Data berhasil dimuat: $_grafikData");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> loadJurnalData() async {
    if (!mounted) return;
    setState(() => _isLoadingJurnal = true);
    String url =
        "https://chump-vividness-escapable.ngrok-free.dev/healu_api/get_jurnal.php?email=${widget.userEmail}";
    try {
      var respon = await ApiClient.instance.get(Uri.parse(url));
      if (respon.statusCode == 200) {
        String body = respon.body.trim();
        var data = jsonDecode(body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _jurnalData = (data['data'] as List? ?? []).where((item) {
              return item['catatan_jurnal'] != null &&
                  item['catatan_jurnal'].toString().trim().isNotEmpty;
            }).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal memuat jurnal: $e");
    } finally {
      if (mounted) setState(() => _isLoadingJurnal = false);
    }
  }

  Future<void> simpanMoodKeDatabase(String moodName, String catatan) async {
    setState(() => _isSaving = true);
    String url =
        "https://chump-vividness-escapable.ngrok-free.dev/healu_api/save_mood.php";
    try {
      var respon = await ApiClient.instance.post(
        Uri.parse(url),
        body: {
          "email": widget.userEmail,
          "mood": moodName,
          "catatan_jurnal": catatan,
        },
      );

      try {
        var data = jsonDecode(respon.body.trim());
        if (data['status'] == 'success' && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Jurnal berhasil disimpan! 🌿"),
              backgroundColor: Color(0xFF8EB76E),
            ),
          );
          _jurnalController.clear();
          await loadGrafikData();
          await loadJurnalData();
        }
      } catch (e) {
        debugPrint("Data respons bukan JSON valid: ${respon.body}");
      }
    } catch (e) {
      debugPrint("Error request: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> deleteJurnalFromDatabase(String idJurnal) async {
    String url =
        "https://chump-vividness-escapable.ngrok-free.dev/healu_api/delete_jurnal.php";
    try {
      var respon = await ApiClient.instance.post(
        Uri.parse(url),
        body: {"id_jurnal": idJurnal},
      );

      if (respon.statusCode == 200) {
        var data = jsonDecode(respon.body);
        if (data['status'] == 'success') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Jurnal berhasil dihapus!")),
            );
          }
          await loadJurnalData();
          await loadGrafikData();
        } else {
          debugPrint("Server error: ${data['message']}");
        }
      }
    } catch (e) {
      debugPrint("Gagal koneksi ke server: $e");
    }
  }

  // --- Helper Methods (Grafik berdasarkan tanggal asli, reset otomatis tiap Senin) ---

  DateTime? _parseTanggal(dynamic item) {
    final raw = item['tanggal_input'] ??
        item['tanggal'] ??
        item['created_at'] ??
        item['waktu'];
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString());
    } catch (e) {
      return null;
    }
  }

  // index 0 = Senin ... 6 = Minggu, null = belum diisi hari itu
  List<double?> _hitungDataMingguIni() {
    List<double?> dataMinggu = List.filled(7, null);

    DateTime now = DateTime.now();
    DateTime seninAwal = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    DateTime mingguAkhir = seninAwal
        .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    for (var item in _grafikData) {
      DateTime? tgl = _parseTanggal(item);
      if (tgl == null) continue;
      if (tgl.isBefore(seninAwal) || tgl.isAfter(mingguAkhir)) continue;

      int index = tgl.weekday - 1; // Senin=1 -> index 0
      dataMinggu[index] = mapMoodToValue(item['nama_mood'] ?? '');
    }

    return dataMinggu;
  }

  String _hitungKesimpulanMood(List<double?> dataMinggu) {
    final terisi = dataMinggu.whereType<double>().toList();
    if (terisi.isEmpty) return "Belum ada riwayat emosi tercatat minggu ini.";
    double rataRata = terisi.reduce((a, b) => a + b) / terisi.length;
    if (rataRata >= 4.5) {
      return "Luar biasa! Kondisi emosionalmu sangat stabil dan bahagia. 🌿";
    }
    if (rataRata >= 3.5) {
      return "Mood kamu pekan ini tergolong baik dan cukup stabil. ✨";
    }
    if (rataRata >= 2.5) {
      return "Pekan ini emosimu tampak fluktuatif. Luangkan waktu untuk istirahat. 💛";
    }
    return "Grafik menunjukkan penurunan emosional, jangan ragu untuk berbagi cerita. ❤️";
  }

  @override
  void initState() {
    super.initState();
    loadGrafikData();
    loadJurnalData();
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDEC),
      appBar: AppBar(
        title: const Text(
          'Monitoring',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _toggleSubTab('Mood'),
                  const SizedBox(width: 10),
                  _toggleSubTab('Jurnal'),
                  const SizedBox(width: 10),
                  _toggleSubTab('Grafik'),
                ],
              ),
              const SizedBox(height: 28),
              if (_selectedSubTab == 'Mood') _buildMoodSection(),
              if (_selectedSubTab == 'Jurnal') _buildJurnalSection(),
              if (_selectedSubTab == 'Grafik') _buildGrafikSection(),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildMoodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bagaimana perasaanmu hari ini?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _moodClickableItem('🟢', 'Sangat Baik'),
              _moodClickableItem('🟡', 'Baik'),
              _moodClickableItem('⚪', 'Biasa Saja'),
              _moodClickableItem('🟠', 'Buruk'),
              _moodClickableItem('🔴', 'Sangat Buruk'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Catatan Jurnal',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _jurnalController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Ceritakan hari ini...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8EB76E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: _isSaving
                ? null
                : () => simpanMoodKeDatabase(
                    _selectedMood,
                    _jurnalController.text,
                  ),
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Simpan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildJurnalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jurnal Saya 📔',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        _isLoadingJurnal
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: _jurnalData.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildAddJournalCard();
                  }

                  final item = _jurnalData[index - 1];
                  return _buildJournalCard(
                    item['hari'] ?? '',
                    item['catatan_jurnal'] ?? '',
                    item['nama_mood'] ?? '',
                    item['id'].toString(),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildAddJournalCard() {
    return GestureDetector(
      onTap: () => _tampilkanDialogInput(context),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBF0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFC8D5B9), width: 2),
        ),
        child: const Center(
          child: Icon(Icons.add_rounded, color: Color(0xFF8EB76E), size: 50),
        ),
      ),
    );
  }

  void _tampilkanDialogInput(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Jurnal"),
        content: TextField(
          controller: _jurnalController,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Apa yang kamu rasakan hari ini?",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _jurnalController.clear();
              Navigator.pop(context);
            },
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8EB76E),
            ),
            onPressed: () {
              simpanMoodKeDatabase(_selectedMood, _jurnalController.text);
              Navigator.pop(context);
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildGrafikSection() {
    final List<String> labels = [
      'Sen',
      'Sel',
      'Rab',
      'Kam',
      'Jum',
      'Sab',
      'Min',
    ];

    List<double?> dataMingguIni = _hitungDataMingguIni();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riwayat Mood Mingguan 📊',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 220,
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: MoodBarChartPainter(dataMingguIni),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: labels
                    .map(
                      (l) => Text(
                        l,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _hitungKesimpulanMood(dataMingguIni),
          style: const TextStyle(
            fontSize: 14,
            color: Color.fromARGB(188, 0, 0, 0),
          ),
        ),
      ],
    );
  }

  Widget _toggleSubTab(String tabName) {
    bool isActive = _selectedSubTab == tabName;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSubTab = tabName),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF8EB76E)
                : Colors.grey.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              tabName,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _moodClickableItem(String emoji, String moodName) {
    bool isCurrent = _selectedMood == moodName;
    return GestureDetector(
      onTap: () => setState(() => _selectedMood = moodName),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isCurrent
              ? const Color(0xFF8EB76E).withValues(alpha: 0.2)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 32)),
      ),
    );
  }

  Widget _buildJournalCard(String hari, String isi, String mood, String id) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  hari,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  mood,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              radius: const Radius.circular(8),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  isi,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
              onPressed: () => deleteJurnalFromDatabase(id),
            ),
          ),
        ],
      ),
    );
  }
}

class MoodBarChartPainter extends CustomPainter {
  final List<double?> data;

  MoodBarChartPainter(this.data);

  Color getColorForMood(double mood) {
    if (mood >= 4.5) return const Color(0xFF8BC34A);
    if (mood >= 3.5) return const Color(0xFFFFEB3B);
    if (mood >= 2.5) return const Color(0xFFE0E0E0);
    if (mood >= 1.5) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  void paint(Canvas canvas, Size size) {
    double barWidth = (size.width / 7) * 0.4;
    double spacing = size.width / 7;
    double dy = size.height / 5.5;

    for (int i = 0; i < 7; i++) {
      double x = (i * spacing) + (spacing - barWidth) / 2;
      final nilai = data[i];

      if (nilai == null) {
        final placeholderPaint = Paint()
          ..color = Colors.grey.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, size.height - 6, barWidth, 6),
            const Radius.circular(6),
          ),
          placeholderPaint,
        );
        continue;
      }

      double barHeight = nilai * dy;
      double y = size.height - barHeight;

      final paint = Paint()
        ..color = getColorForMood(nilai)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(10),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MoodBarChartPainter oldDelegate) =>
      oldDelegate.data != data;
}