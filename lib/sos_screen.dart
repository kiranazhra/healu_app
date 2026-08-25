// ignore_for_file: avoid_print, curly_braces_in_flow_control_structures, deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/api_client.dart';

class SosScreen extends StatefulWidget {
  final String idPasien;
  const SosScreen({super.key, required this.idPasien});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  bool _isLoadingMap = false;
  bool _isLoadingKontak = true;
  List kontakList = [];

  final String baseUrl =
      "https://chump-vividness-escapable.ngrok-free.dev/healu_api";

  @override
  void initState() {
    super.initState();
    _fetchKontak();
  }

  Future<void> _fetchKontak() async {
    if (!mounted) return;
    setState(() => _isLoadingKontak = true);
    try {
      final response = await ApiClient.instance.post(
        Uri.parse("$baseUrl/get_kontak.php"),
        body: {"id_pasien": widget.idPasien},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          kontakList = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint("Error ambil data: $e");
    } finally {
      if (mounted) setState(() => _isLoadingKontak = false);
    }
  }

  Future<void> _tambahKontak(String nama, String nomor) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final response = await ApiClient.instance.post(
        Uri.parse("$baseUrl/tambah_kontak.php"),
        body: {
          "id_pasien": widget.idPasien,
          "nama_kontak": nama,
          "nomor_telepon": nomor,
        },
      );

      if (!mounted) return;

      if (jsonDecode(response.body)['status'] == 'success') {
        _fetchKontak();
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              "Kontak berhasil ditambahkan",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error tambah data: $e");
    }
  }

  Future<void> _hapusKontak(String id) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final response = await ApiClient.instance.post(
        Uri.parse("$baseUrl/hapus_kontak.php"),
        body: {"id": id},
      );

      if (!mounted) return;

      if (jsonDecode(response.body)['status'] == 'success') {
        _fetchKontak();
        messenger.showSnackBar(const SnackBar(content: Text("Kontak dihapus")));
      }
    } catch (e) {
      debugPrint("Error hapus data: $e");
    }
  }

  Future<void> _kirimSosKeWhatsApp() async {
    if (kontakList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tambahkan kontak darurat terlebih dahulu!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoadingMap = true);

    final messenger = ScaffoldMessenger.of(context);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'GPS mati. Tolong nyalakan dulu.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Izin lokasi ditolak.';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'Izin lokasi diblokir permanen.';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      String googleMapsUrl =
          "http://maps.google.com/?q=${position.latitude},${position.longitude}";
      String pesan =
          "🚨 DARURAT! 🚨\nSaya butuh bantuan sekarang. Ini lokasi terakhir saya:\n$googleMapsUrl";

      String nomorTujuan = kontakList[0]['nomor_telepon'];

      if (nomorTujuan.startsWith('0')) {
        nomorTujuan = "62${nomorTujuan.substring(1)}";
      }

      Uri waUrl = Uri.parse(
        "whatsapp://send?phone=$nomorTujuan&text=${Uri.encodeComponent(pesan)}",
      );
      if (await canLaunchUrl(waUrl)) {
        await launchUrl(waUrl);
      } else {
        throw 'Gagal membuka WhatsApp.';
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoadingMap = false);
    }
  }

  void _showTambahKontakDialog() {
    TextEditingController namaController = TextEditingController();
    TextEditingController nomorController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Tambah Kontak Darurat"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(
                labelText: "Nama Kontak",
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nomorController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Nomor Telepon",
                prefixIcon: Icon(Icons.phone),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              if (namaController.text.isNotEmpty &&
                  nomorController.text.isNotEmpty) {
                _tambahKontak(namaController.text, nomorController.text);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDEC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Emergency SOS",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _isLoadingMap ? null : _kirimSosKeWhatsApp,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isLoadingMap ? Colors.grey : const Color(0xFFE53935),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoadingMap)
                      const CircularProgressIndicator(color: Colors.white)
                    else ...[
                      const Text(
                        "SOS",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "TEKAN UNTUK\nMINTA BANTUAN",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Kontak Darurat",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 15),

            if (_isLoadingKontak)
              const CircularProgressIndicator(color: Colors.green)
            else if (kontakList.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  "Belum ada kontak darurat.",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: kontakList.length,
                itemBuilder: (context, index) {
                  var kontak = kontakList[index];
                  return _buildContactCard(kontak);
                },
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8EB76E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Tambah Kontak Baru",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _showTambahKontakDialog,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(dynamic kontak) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
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
          const CircleAvatar(
            backgroundColor: Color(0xFFF0E5D8),
            radius: 25,
            child: Icon(Icons.person, color: Colors.brown),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kontak['nama_kontak'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  kontak['nomor_telepon'],
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone, color: Colors.green),
            onPressed: () async {
              String nomor = kontak['nomor_telepon'];
              Uri phoneUrl = Uri.parse("tel:$nomor");
              if (await canLaunchUrl(phoneUrl)) {
                await launchUrl(phoneUrl);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _hapusKontak(kontak['id'].toString()),
          ),
        ],
      ),
    );
  }
}