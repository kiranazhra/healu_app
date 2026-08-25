import 'dart:convert';
import 'package:flutter/material.dart';
import 'services/api_client.dart';

class RiwayatKonsultasi {
  final String id;
  final String namaDokter;
  final String namaPasien; // TAMBAHAN: Agar Dokter bisa melihat nama pasiennya
  final String spesialis;
  final String tanggal;
  final String waktu;
  final String durasi;
  final String totalHarga;
  final String status;
  final String alasanBatal;
  final String fotoDokter;

  // --- 7 FIELD REKAM MEDIS ---
  final String keluhanUtama;
  final String alergiObat;
  final String diagnosa;
  final String saranTerapi;
  final String pantangan;
  final String resepObat;
  final String tindakLanjut;

  RiwayatKonsultasi({
    required this.id,
    required this.namaDokter,
    required this.namaPasien,
    required this.spesialis,
    required this.tanggal,
    required this.waktu,
    required this.durasi,
    required this.totalHarga,
    required this.status,
    required this.alasanBatal,
    required this.fotoDokter,
    required this.keluhanUtama,
    required this.alergiObat,
    required this.diagnosa,
    required this.saranTerapi,
    required this.pantangan,
    required this.resepObat,
    required this.tindakLanjut,
  });

  factory RiwayatKonsultasi.fromJson(Map<String, dynamic> json) {
    // Gunakan `?.toString()` pada field angka/ID agar Flutter tidak crash saat menerima tipe data int/double dari PHP
    return RiwayatKonsultasi(
      id: json['id_konsultasi']?.toString() ?? json['id']?.toString() ?? '',
      namaDokter: json['nama_dokter']?.toString() ?? 'Dokter Healu',
      namaPasien: json['nama_pasien']?.toString() ?? 'Pasien Healu',
      spesialis: json['spesialis']?.toString() ?? 'Umum',
      tanggal:
          json['tanggal_jadwal']?.toString() ??
          json['tanggal']?.toString() ??
          '-',
      waktu:
          json['waktu_jadwal']?.toString() ?? json['waktu']?.toString() ?? '-',
      durasi: json['durasi']?.toString() ?? '30 Menit',
      totalHarga: json['total_harga']?.toString() ?? '-',
      status:
          json['status_konsultasi']?.toString() ??
          json['status']?.toString() ??
          'menunggu_pembayaran',
      alasanBatal: json['alasan_batal']?.toString() ?? '',
      fotoDokter:
          json['foto_dokter']?.toString() ??
          'https://cdn-icons-png.flaticon.com/512/3774/3774299.png',

      // PARSING DATA REKAM MEDIS (Sifatnya Null-Safe)
      keluhanUtama:
          json['keluhan_utama']?.toString() ??
          json['keluhan']?.toString() ??
          '-',
      alergiObat: json['alergi_obat']?.toString() ?? '-',
      diagnosa: json['diagnosa']?.toString() ?? '-',
      saranTerapi: json['saran_terapi']?.toString() ?? '-',
      pantangan: json['pantangan']?.toString() ?? '-',
      resepObat: json['resep_obat']?.toString() ?? '-',
      tindakLanjut: json['tindak_lanjut']?.toString() ?? '-',
    );
  }

  // Helper method untuk mengubah object kembali ke Map/JSON jika dibutuhkan di layar lain
  Map<String, dynamic> toMap() {
    return {
      'id_konsultasi': id,
      'nama_dokter': namaDokter,
      'nama_pasien': namaPasien,
      'spesialis': spesialis,
      'tanggal_jadwal': tanggal,
      'waktu_jadwal': waktu,
      'durasi': durasi,
      'total_harga': totalHarga,
      'status_konsultasi': status,
      'alasan_batal': alasanBatal,
      'foto_dokter': fotoDokter,
      'keluhan_utama': keluhanUtama,
      'alergi_obat': alergiObat,
      'diagnosa': diagnosa,
      'saran_terapi': saranTerapi,
      'pantangan': pantangan,
      'resep_obat': resepObat,
      'tindak_lanjut': tindakLanjut,
    };
  }
}

class ApiService {
  static const String baseUrl =
      'https://chump-vividness-escapable.ngrok-free.dev/healu_api';

  // 1. AMBIL RIWAYAT KONSULTASI (Mendukung Multi-Role Pasien & Dokter)
  Future<List<RiwayatKonsultasi>> getRiwayat(String idUser, String role) async {
    try {
      // Mengubah parameter query secara dinamis berdasarkan role akun yang login
      final String endpoint = role == 'dokter'
          ? '$baseUrl/get_riwayat_konsultasi.php?id_dokter_user=$idUser'
          : '$baseUrl/get_riwayat_konsultasi.php?id_pasien_user=$idUser';

      final response = await ApiClient.instance.get(Uri.parse(endpoint));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          List<dynamic> body = responseData['data'];
          return body
              .map((dynamic item) => RiwayatKonsultasi.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error Get Riwayat: $e");
      return [];
    }
  }

  // 2. LOGIKA TAMBAH KONSULTASI BARU
  Future<Map<String, dynamic>> buatKonsultasi({
    required String idPasien,
    required String idDokter,
    required String keluhanUtama,
    required String totalHarga,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        Uri.parse('$baseUrl/buat_konsultasi.php'),
        body: {
          'id_pasien': idPasien,
          'id_dokter': idDokter,
          'keluhan_utama': keluhanUtama,
          'total_harga': totalHarga,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {
        "status": "error",
        "message": "Gagal terhubung ke server (${response.statusCode})",
      };
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  // 3. LOGIKA UPDATE STATUS (Selesai Bayar & Akhiri Chat)
  // Diubah mengembalikan Map<String, dynamic> agar UI bisa membaca pesan "sudah selesai" dari server
  Future<Map<String, dynamic>> updateStatusKonsultasi(
    String idKonsultasi,
    String statusBaru,
  ) async {
    try {
      final response = await ApiClient.instance.post(
        Uri.parse('$baseUrl/update_status_konsultasi.php'),
        body: {'id': idKonsultasi, 'status_baru': statusBaru},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {"status": "error", "message": "Koneksi backend bermasalah"};
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }
}
