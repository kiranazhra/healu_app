// ignore_for_file: avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'services/api_client.dart';
import 'dart:convert';
import 'tambah_obat_screen.dart';
import 'notification_helper.dart';
import 'tombol_status_obat.dart';

class ReminderObatScreen extends StatefulWidget {
  final String idUser; // ID Pasien yang sedang login

  const ReminderObatScreen({super.key, required this.idUser});

  @override
  State<ReminderObatScreen> createState() => _ReminderObatScreenState();
}

class _ReminderObatScreenState extends State<ReminderObatScreen> {
  List _listObat = [];
  bool _isLoading = true;

  // Fungsi untuk mengambil data dari database
  Future<void> fetchReminders() async {
    String url =
        "https://chump-vividness-escapable.ngrok-free.dev/healu_api/get_reminders.php?id_pasien=${widget.idUser}";

    try {
      final response = await ApiClient.instance.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _listObat = data['data'] ?? [];
            _isLoading = false;
          });

          // === MULAI SETTING ALARM NOTIFIKASI ===
          for (int i = 0; i < _listObat.length; i++) {
            var item = _listObat[i];
            String waktuMinum =
                item['waktu_minum'] ??
                '00:00'; // Contoh format dari DB: "08:30"
            String namaObat = item['nama_obat'] ?? 'Obat';

            // Pecah String "08:30" menjadi jam dan menit
            List<String> waktuSplit = waktuMinum.split(':');
            if (waktuSplit.length >= 2) {
              int jam = int.tryParse(waktuSplit[0]) ?? 0;
              int menit = int.tryParse(waktuSplit[1]) ?? 0;

              // Jadwalkan Notifikasi
              NotificationHelper.scheduleDailyNotification(
                id: i, // ID unik agar alarm tidak saling tumpuk
                title: 'Waktunya Minum Obat! 💊',
                body: 'Jangan lupa minum $namaObat sekarang ya.',
                hour: jam,
                minute: menit,
              );
            }
          }
          // === SELESAI SETTING ALARM ===
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print("Error mengambil data: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchReminders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDEC), // Warna background krem HealU
      appBar: AppBar(
        title: const Text(
          "Reminder Obat",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header Judul Kecil Pengganti Tab (Lebih Bersih & Sesuai Saran)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Daftar Obat Aktif",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          // Daftar Obat
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF8EB76E)),
                  )
                : _listObat.isEmpty
                ? const Center(
                    child: Text(
                      "Belum ada pengingat obat.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _listObat.length,
                    itemBuilder: (context, index) {
                      final item = _listObat[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.medication,
                              color: Colors.redAccent,
                              size: 35,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['nama_obat'] ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Setiap hari - ${item['waktu_minum'] ?? '-'}",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    "Dosis: ${item['dosis'] ?? '-'}",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TombolStatusObat(
                              // Kita gunakan nama obat sebagai ID unik agar statusnya tidak tertukar
                              idObat:
                                  item['nama_obat'] ?? 'obat_default_$index',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Tombol Tambah Obat
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8EB76E),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                // Menunggu halaman tambah obat ditutup, lalu refresh data
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TambahObatScreen(idUser: widget.idUser),
                  ),
                );
                // Refresh daftar setelah kembali
                setState(() {
                  _isLoading = true;
                });
                fetchReminders();
              },
              child: const Text(
                "+ Tambah Obat",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
