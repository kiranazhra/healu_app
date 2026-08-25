// ignore_for_file: avoid_print, deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'services/api_client.dart';
import 'dart:convert';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userEmail;
  const ProfileScreen({super.key, required this.userEmail});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;
  late String _currentEmail;

  @override
  void initState() {
    super.initState();
    _currentEmail = widget.userEmail;
    _fetchProfileData();
  }

  // Dipakai untuk load pertama kali (initState)
  Future<void> _fetchProfileData() async {
    final data = await _fetchProfileFresh(_currentEmail);
    if (!mounted) return;
    setState(() {
      if (data != null) _userData = data;
      _isLoading = false;
    });
  }

  // Reusable fetcher: dipakai juga oleh DataDiriScreen setelah update,
  // supaya tampilan selalu mencerminkan data ASLI dari server (bukan
  // sekadar apa yang barusan diketik user).
  Future<Map<String, dynamic>?> _fetchProfileFresh(String email) async {
    // Gunakan Uri.https/queryParameters agar email dengan karakter
    // spesial (mis. tanda '+') tidak rusak saat di-encode ke URL.
    final uri = Uri.https(
      "chump-vividness-escapable.ngrok-free.dev",
      "/healu_api/get_profile.php",
      {"email": email},
    );

    try {
      var response = await ApiClient.instance.get(uri);
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          final data = Map<String, dynamic>.from(jsonResponse['data']);
          if (mounted) {
            setState(() {
              _userData = data;
              _currentEmail = data['email'] ?? email;
            });
          }
          return data;
        } else {
          print("API Error: ${jsonResponse['message']}");
        }
      }
    } catch (e) {
      print("Error fetching profile: $e");
    }
    return null;
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDEC),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 20,
                  bottom: 24,
                ),
                child: Column(
                  children: [
                    const Text(
                      'Profil',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: Color.fromARGB(255, 182, 236, 163),
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Color.fromARGB(255, 72, 150, 87),
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userData['nama_lengkap'] ??
                                    'Nama Tidak Ditemukan',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      _userData['email'] ?? widget.userEmail,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '|',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '👤',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ID: ${_userData['id'] ?? '-'}',
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    _buildProfileMenuItem(
                      Icons.person_outline,
                      'Data Diri',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DataDiriScreen(
                              userData: _userData,
                              onRequestRefresh: _fetchProfileFresh,
                            ),
                          ),
                        ).then((_) {
                          // Refresh data profile setelah kembali dari Data Diri
                          _fetchProfileData();
                        });
                      },
                    ),
                    _buildProfileMenuItem(
                      Icons.phone_outlined,
                      'Kontak Darurat',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const KontakDaruratScreen(),
                          ),
                        );
                      },
                    ),
                    _buildProfileMenuItem(
                      Icons.notifications_none,
                      'Pengaturan Notifikasi',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PengaturanNotifikasiScreen(),
                          ),
                        );
                      },
                    ),
                    _buildProfileMenuItem(
                      Icons.help_outline,
                      'Pusat Bantuan',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PusatBantuanScreen(),
                          ),
                        );
                      },
                    ),
                    _buildProfileMenuItem(
                      Icons.info_outline,
                      'Tentang HealU',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TentangHealuScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),
                    _buildProfileMenuItem(
                      Icons.logout,
                      'Keluar',
                      () => _handleLogout(context),
                      isLogout: true,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: isLogout ? Colors.red : Colors.black54),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isLogout ? Colors.red : Colors.black87,
          ),
        ),
        trailing: isLogout
            ? null
            : const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

// =========================================================================
// 1. HALAMAN DATA DIRI (EDITABLE + GANTI EMAIL)
// =========================================================================
class DataDiriScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  // Dipanggil setelah update sukses untuk mengambil ulang data ASLI dari
  // server (bukan sekadar apa yang barusan diketik), lalu mengembalikannya.
  final Future<Map<String, dynamic>?> Function(String email) onRequestRefresh;

  const DataDiriScreen({
    super.key,
    required this.userData,
    required this.onRequestRefresh,
  });

  @override
  State<DataDiriScreen> createState() => _DataDiriScreenState();
}

class _DataDiriScreenState extends State<DataDiriScreen> {
  bool _isEditing = false;
  bool _isLoading = false;

  late TextEditingController _namaController;
  late TextEditingController _emailController;
  late TextEditingController _teleponController;
  late TextEditingController _tglLahirController;
  String _jenisKelamin = "Perempuan";

  // Menyimpan nilai awal supaya tombol "Batal" bisa mengembalikan tampilan
  // ke kondisi sebelum diedit tanpa perlu fetch ulang.
  late String _namaAwal, _emailAwal, _teleponAwal, _tglLahirAwal, _genderAwal;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(
      text: widget.userData['nama_lengkap'] ?? "",
    );
    _emailController = TextEditingController(
      text: widget.userData['email'] ?? "",
    );
    _teleponController = TextEditingController(
      text: widget.userData['nomor_telepon']?.toString() ?? "",
    );
    _tglLahirController = TextEditingController(
      text: widget.userData['tanggal_lahir']?.toString() ?? "",
    );

    if (widget.userData['jenis_kelamin'] != null &&
        widget.userData['jenis_kelamin'].toString().isNotEmpty) {
      _jenisKelamin = widget.userData['jenis_kelamin'];
    }

    _namaAwal = _namaController.text;
    _emailAwal = _emailController.text;
    _teleponAwal = _teleponController.text;
    _tglLahirAwal = _tglLahirController.text;
    _genderAwal = _jenisKelamin;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _teleponController.dispose();
    _tglLahirController.dispose();
    super.dispose();
  }

  void _batalEdit() {
    setState(() {
      _namaController.text = _namaAwal;
      _emailController.text = _emailAwal;
      _teleponController.text = _teleponAwal;
      _tglLahirController.text = _tglLahirAwal;
      _jenisKelamin = _genderAwal;
      _isEditing = false;
    });
  }

  Future<void> _updateProfileData() async {
    setState(() => _isLoading = true);

    // Simpan apa yang baru saja diketik user, untuk dibandingkan dengan
    // data hasil refetch nanti (deteksi jika server gagal menyimpan).
    final teleponDikirim = _teleponController.text;
    final tglLahirDikirim = _tglLahirController.text;

    const String url =
        "https://chump-vividness-escapable.ngrok-free.dev/healu_api/update_profile.php";
    try {
      var response = await ApiClient.instance
          .post(
            Uri.parse(url),
            body: {
              "old_email": widget.userData['email'] ?? "",
              "new_email": _emailController.text,
              "nama_lengkap": _namaController.text,
              "nomor_telepon": _teleponController.text,
              "tanggal_lahir": _tglLahirController.text,
              "jenis_kelamin": _jenisKelamin,
            },
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          final emailBerubah =
              widget.userData['email'] != _emailController.text;

          if (emailBerubah) {
            // Kalau email berubah, sesi lama sudah tidak valid -> logout.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Email diubah. Silakan login kembali."),
              ),
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
            return;
          }

          // Ambil ulang data ASLI dari server, supaya tampilan "setelah
          // diedit" benar-benar mencerminkan apa yang tersimpan di DB.
          final freshData =
              await widget.onRequestRefresh(_emailController.text);

          if (!mounted) return;

          if (freshData != null) {
            setState(() {
              _namaController.text = freshData['nama_lengkap'] ?? _namaController.text;
              _emailController.text = freshData['email'] ?? _emailController.text;
              _teleponController.text =
                  freshData['nomor_telepon']?.toString() ?? "";
              _tglLahirController.text =
                  freshData['tanggal_lahir']?.toString() ?? "";
              if (freshData['jenis_kelamin'] != null &&
                  freshData['jenis_kelamin'].toString().isNotEmpty) {
                _jenisKelamin = freshData['jenis_kelamin'];
              }

              // Update nilai "awal" supaya tombol Batal berikutnya benar.
              _namaAwal = _namaController.text;
              _emailAwal = _emailController.text;
              _teleponAwal = _teleponController.text;
              _tglLahirAwal = _tglLahirController.text;
              _genderAwal = _jenisKelamin;

              _isEditing = false;
            });

            // Deteksi kalau server ternyata TIDAK menyimpan telepon/tgl lahir
            // walau responsnya "success" (indikasi bug di update_profile.php).
            final teleponGagalTersimpan =
                teleponDikirim.isNotEmpty && _teleponController.text != teleponDikirim;
            final tglGagalTersimpan =
                tglLahirDikirim.isNotEmpty && _tglLahirController.text != tglLahirDikirim;

            if (teleponGagalTersimpan || tglGagalTersimpan) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Profil tersimpan, tapi Nomor Telepon/Tanggal Lahir "
                    "tidak berubah di server. Cek update_profile.php.",
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Profil berhasil diperbarui!")),
              );
            }
          } else {
            setState(() => _isEditing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Profil berhasil diperbarui!")),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal: ${jsonResponse['message']}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Gagal terhubung ke server (${response.statusCode})",
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      print("Error updating profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Terjadi kesalahan pada server!")),
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDEC),
      appBar: AppBar(
        title: const Text(
          "Data Diri",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color.fromARGB(255, 182, 236, 163),
              child: Icon(
                Icons.person,
                size: 60,
                color: Color.fromARGB(255, 72, 150, 87),
              ),
            ),
            const SizedBox(height: 30),

            _buildEditableField(
              "Nama Lengkap",
              _namaController,
              Icons.badge_outlined,
            ),
            _buildEditableField(
              "Email",
              _emailController,
              Icons.email_outlined,
            ),
            _buildEditableField(
              "Nomor Telepon",
              _teleponController,
              Icons.phone_android_outlined,
              isNumber: true,
            ),
            _buildEditableField(
              "Tanggal Lahir",
              _tglLahirController,
              Icons.calendar_today_outlined,
            ),
            _buildGenderDropdown(),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEditing
                      ? const Color(0xFF489657)
                      : const Color(0xFF8EB76E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_isEditing) {
                          _updateProfileData();
                        } else {
                          setState(() => _isEditing = true);
                        }
                      },
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        _isEditing ? "Simpan Perubahan" : "Edit Profil",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            if (_isEditing && !_isLoading) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _batalEdit,
                  child: const Text(
                    "Batal",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isNumber = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        // Beda warna latar antara mode lihat & mode edit, agar terlihat
        // jelas kapan field bisa diubah.
        color: _isEditing ? Colors.white : const Color(0xFFF5F4E6),
        borderRadius: BorderRadius.circular(16),
        border: _isEditing
            ? Border.all(color: const Color(0xFF8EB76E), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: _isEditing ? const Color(0xFF8EB76E) : Colors.grey,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: _isEditing,
              keyboardType: isNumber
                  ? TextInputType.phone
                  : TextInputType.emailAddress,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                labelText: label,
                hintText: "Belum diisi",
                labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: _isEditing ? Colors.white : const Color(0xFFF5F4E6),
        borderRadius: BorderRadius.circular(16),
        border: _isEditing
            ? Border.all(color: const Color(0xFF8EB76E), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.wc_outlined,
            color: _isEditing ? const Color(0xFF8EB76E) : Colors.grey,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _jenisKelamin,
                isExpanded: true,
                iconEnabledColor: const Color(0xFF8EB76E),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                onChanged: _isEditing
                    ? (String? newValue) {
                        setState(() {
                          _jenisKelamin = newValue!;
                        });
                      }
                    : null,
                items: <String>['Laki-laki', 'Perempuan']
                    .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    })
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// 2. HALAMAN KONTAK DARURAT
// =========================================================================
class KontakDaruratScreen extends StatelessWidget {
  const KontakDaruratScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDEC),
      appBar: AppBar(
        title: const Text(
          "Kontak Darurat",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Jika Anda merasa dalam kondisi darurat atau butuh teman bicara secepatnya, hubungi kontak di bawah ini.",
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 20),
            _buildContactCard(
              "Layanan Sejiwa (Kemenkes)",
              "119 (Ekstensi 8)",
              Icons.local_hospital_outlined,
            ),
            _buildContactCard(
              "Keluarga / Wali",
              "+62 853-1111-2222",
              Icons.family_restroom,
            ),
            _buildContactCard(
              "Psikolog Pribadi",
              "+62 811-3333-4444",
              Icons.medical_services_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(String title, String number, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF8EB76E).withValues(alpha: 0.2),
          child: Icon(icon, color: const Color(0xFF8EB76E)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(number, style: const TextStyle(color: Colors.grey)),
        trailing: IconButton(
          icon: const Icon(Icons.call, color: Color(0xFF8EB76E)),
          onPressed: () {},
        ),
      ),
    );
  }
}

// =========================================================================
// 3. HALAMAN PENGATURAN NOTIFIKASI
// =========================================================================
class PengaturanNotifikasiScreen extends StatefulWidget {
  const PengaturanNotifikasiScreen({super.key});

  @override
  State<PengaturanNotifikasiScreen> createState() =>
      _PengaturanNotifikasiScreenState();
}

class _PengaturanNotifikasiScreenState
    extends State<PengaturanNotifikasiScreen> {
  bool _pengingatObat = true;
  bool _pengingatJurnal = true;
  bool _notifikasiPromo = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDEC),
      appBar: AppBar(
        title: const Text(
          "Notifikasi",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSwitchCard(
              "Pengingat Minum Obat",
              "Ingatkan saya saat waktunya minum obat",
              _pengingatObat,
              (val) {
                setState(() => _pengingatObat = val);
              },
            ),
            _buildSwitchCard(
              "Pengingat Jurnal",
              "Ingatkan saya untuk mengisi jurnal harian",
              _pengingatJurnal,
              (val) {
                setState(() => _pengingatJurnal = val);
              },
            ),
            _buildSwitchCard(
              "Info & Promo HealU",
              "Dapatkan info terbaru terkait layanan kami",
              _notifikasiPromo,
              (val) {
                setState(() => _notifikasiPromo = val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchCard(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        activeColor: const Color(0xFF8EB76E),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

// =========================================================================
// 4. HALAMAN PUSAT BANTUAN
// =========================================================================
class PusatBantuanScreen extends StatelessWidget {
  const PusatBantuanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDEC),
      appBar: AppBar(
        title: const Text(
          "Pusat Bantuan",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pertanyaan yang Sering Diajukan (FAQ)",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              "Bagaimana cara mengubah profil?",
              "Anda dapat mengubah profil Anda melalui menu Data Diri, lalu menekan tombol Edit Profil.",
            ),
            _buildFaqItem(
              "Bagaimana jika saya lupa kata sandi?",
              "Anda bisa menekan tombol 'Lupa Password' di halaman login untuk mengatur ulang kata sandi melalui email Anda.",
            ),
            _buildFaqItem(
              "Apakah data jurnal saya aman?",
              "Tentu. Semua data jurnal pribadi dan mood Anda dienkripsi dan hanya Anda yang bisa melihatnya.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: const Color(0xFF8EB76E),
          collapsedIconColor: Colors.grey,
          title: Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Text(
                answer,
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// 5. HALAMAN TENTANG HEALU
// =========================================================================
class TentangHealuScreen extends StatelessWidget {
  const TentangHealuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDEC),
      appBar: AppBar(
        title: const Text(
          "Tentang HealU",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF8EB76E).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 80,
                  color: Color(0xFF8EB76E),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "HealU",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8EB76E),
                ),
              ),
              const Text("Versi 1.0.0", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              const Text(
                "HealU adalah aplikasi pendamping kesehatan mental yang dirancang untuk membantu Anda memantau suasana hati, kepatuhan terapi obat, dan mencatat perjalanan emosional Anda setiap hari.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                "© 2026 HealU Indonesia.\nAll rights reserved.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}