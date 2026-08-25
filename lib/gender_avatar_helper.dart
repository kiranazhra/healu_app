import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Helper untuk menampilkan avatar dokter yang konsisten di semua layar:
/// gambar menyesuaikan gender dokter (perempuan/laki-laki), diambil dari
/// field 'jenis_kelamin' backend kalau ada, atau ditebak dari nama kalau
/// field itu belum tersedia.
///
/// Gambar dipakai dari asset SVG lokal (bukan gambar dari internet lagi),
/// supaya tidak tergantung koneksi dan tidak bisa diblokir hotlink.
///
/// PENTING - Setup yang perlu dilakukan sekali:
/// 1. Taruh 'doctor_male.svg' & 'doctor_female.svg' di 'assets/images/'
///    (sejajar dengan folder 'lib/').
/// 2. Tambahkan dependency di pubspec.yaml:
///      dependencies:
///        flutter_svg: ^2.0.10
/// 3. Daftarkan folder asset di pubspec.yaml:
///      flutter:
///        assets:
///          - assets/images/
/// 4. Jalankan `flutter pub get`.
class GenderAvatarHelper {
  static const String _assetDokterLakiLaki = 'assets/images/doctor_male.svg';
  static const String _assetDokterPerempuan =
      'assets/images/doctor_female.svg';

  static const List<String> _kataKunciPerempuan = [
    'siti', 'aminah', 'fatimah', 'dewi', 'sri', 'ayu', 'putri', 'wulan',
    'indah', 'nita', 'rina', 'yuni', 'dian', 'maya', 'lestari', 'wati',
    'ningsih', 'zahra', 'aulia', 'nur', 'fitri', 'indri', 'ratna', 'melati',
    'anisa', 'salsa', 'diah', 'yani', 'endang', 'hana', 'nadia',
  ];
  static const List<String> _kataKunciLakiLaki = [
    'andi', 'budi', 'joko', 'agus', 'dedi', 'hendra', 'rizky', 'fajar',
    'yusuf', 'ahmad', 'muhammad', 'rahman', 'hasan', 'husein', 'eko',
    'bayu', 'dimas', 'arif', 'fauzi', 'irfan', 'wahyu', 'taufik', 'imam',
  ];

  /// Tentukan apakah dokter perempuan. Prioritas: field 'jenis_kelamin'
  /// dari backend kalau tersedia, baru fallback tebak dari nama.
  static bool isPerempuan(String nama, {String? jenisKelamin}) {
    final jk = jenisKelamin?.toLowerCase();
    if (jk != null && jk.isNotEmpty) {
      return jk.startsWith('p'); // "Perempuan"
    }

    final n = nama.toLowerCase();
    for (final kata in _kataKunciPerempuan) {
      if (n.contains(kata)) return true;
    }
    for (final kata in _kataKunciLakiLaki) {
      if (n.contains(kata)) return false;
    }
    // Fallback kasar: nama berakhiran huruf "a" lebih sering nama perempuan
    // di Indonesia (mis. "Aminah", "Sinta"). Tidak sempurna tapi lebih baik
    // dari selalu default laki-laki.
    return n.trim().endsWith('a');
  }

  /// Bangun widget CircleAvatar berisi ilustrasi dokter (SVG lokal) sesuai
  /// gender. Dipakai supaya tampilan dokter konsisten di semua layar
  /// (Konsultasi, Sesi Konsultasi, Chat, Riwayat).
  static Widget buildAvatar(
    String nama, {
    String? jenisKelamin,
    double radius = 24,
  }) {
    final perempuan = isPerempuan(nama, jenisKelamin: jenisKelamin);
    final asset = perempuan ? _assetDokterPerempuan : _assetDokterLakiLaki;

    return CircleAvatar(
      radius: radius,
      backgroundColor: perempuan ? Colors.pink.shade50 : Colors.blue.shade50,
      child: ClipOval(
        child: SvgPicture.asset(
          asset,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholderBuilder: (_) => Icon(
            perempuan ? Icons.woman : Icons.man,
            size: radius * 1.15,
            color: perempuan ? Colors.pink.shade300 : Colors.blue.shade400,
          ),
        ),
      ),
    );
  }
}