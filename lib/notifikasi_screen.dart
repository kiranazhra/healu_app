import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'laporan_menu_screen.dart' show HealUColors;

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  bool _notifKonsultasiBaru = true;
  bool _notifPasienBaru = true;
  bool _notifJadwalDokter = true;
  bool _notifSistem = true;
  bool _isLoading = true;

  static const _keyKonsultasi = 'notif_konsultasi_baru';
  static const _keyPasien = 'notif_pasien_baru';
  static const _keyJadwal = 'notif_jadwal_dokter';
  static const _keySistem = 'notif_sistem';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notifKonsultasiBaru = prefs.getBool(_keyKonsultasi) ?? true;
      _notifPasienBaru = prefs.getBool(_keyPasien) ?? true;
      _notifJadwalDokter = prefs.getBool(_keyJadwal) ?? true;
      _notifSistem = prefs.getBool(_keySistem) ?? true;
      _isLoading = false;
    });
  }

  Future<void> _updatePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HealUColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: HealUColors.primary,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _buildSwitchTile(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Konsultasi Baru',
                          subtitle: 'Notifikasi saat ada konsultasi baru masuk',
                          value: _notifKonsultasiBaru,
                          onChanged: (v) {
                            setState(() => _notifKonsultasiBaru = v);
                            _updatePref(_keyKonsultasi, v);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildSwitchTile(
                          icon: Icons.person_add_alt_1_rounded,
                          title: 'Pasien Baru',
                          subtitle: 'Notifikasi saat ada pasien baru terdaftar',
                          value: _notifPasienBaru,
                          onChanged: (v) {
                            setState(() => _notifPasienBaru = v);
                            _updatePref(_keyPasien, v);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildSwitchTile(
                          icon: Icons.calendar_today_rounded,
                          title: 'Perubahan Jadwal Dokter',
                          subtitle: 'Notifikasi saat jadwal dokter berubah',
                          value: _notifJadwalDokter,
                          onChanged: (v) {
                            setState(() => _notifJadwalDokter = v);
                            _updatePref(_keyJadwal, v);
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildSwitchTile(
                          icon: Icons.info_outline_rounded,
                          title: 'Notifikasi Sistem',
                          subtitle: 'Pembaruan dan informasi penting aplikasi',
                          value: _notifSistem,
                          onChanged: (v) {
                            setState(() => _notifSistem = v);
                            _updatePref(_keySistem, v);
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HealUColors.primary.withValues(alpha: 0.55),
            HealUColors.background,
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 20, 22),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: HealUColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 4),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Notifikasi",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: HealUColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Atur preferensi notifikasi Anda",
                  style: TextStyle(
                    fontSize: 12,
                    color: HealUColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: HealUColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: HealUColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: HealUColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: HealUColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: HealUColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: HealUColors.primary,
          ),
        ],
      ),
    );
  }
}