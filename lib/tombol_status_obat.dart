import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TombolStatusObat extends StatefulWidget {
  final String idObat;

  const TombolStatusObat({super.key, required this.idObat});

  @override
  State<TombolStatusObat> createState() => _TombolStatusObatState();
}

class _TombolStatusObatState extends State<TombolStatusObat> {
  bool _isTaken = false;

  @override
  void initState() {
    super.initState();
    _cekStatusObat();
  }

  Future<void> _cekStatusObat() async {
    final prefs = await SharedPreferences.getInstance();
    String tanggalHariIni = DateTime.now().toIso8601String().split('T')[0];
    String? tanggalTerakhirMinum = prefs.getString(
      'tanggal_minum_${widget.idObat}',
    );

    if (tanggalTerakhirMinum == tanggalHariIni) {
      setState(() {
        _isTaken = prefs.getBool('status_minum_${widget.idObat}') ?? false;
      });
    } else {
      setState(() {
        _isTaken = false;
      });
      await prefs.setBool('status_minum_${widget.idObat}', false);
    }
  }

  Future<void> _tandaiSudahMinum() async {
    // Jika sudah diminum, jangan lakukan apa-apa saat diklik lagi
    if (_isTaken) return;

    final prefs = await SharedPreferences.getInstance();
    String tanggalHariIni = DateTime.now().toIso8601String().split('T')[0];

    setState(() {
      _isTaken = true;
    });

    await prefs.setBool('status_minum_${widget.idObat}', true);
    await prefs.setString('tanggal_minum_${widget.idObat}', tanggalHariIni);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _tandaiSudahMinum,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          // Jika sudah diminum warna hijau, jika belum warna orange
          color: _isTaken
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          _isTaken ? "Sudah" : "Belum",
          style: TextStyle(
            color: _isTaken ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
