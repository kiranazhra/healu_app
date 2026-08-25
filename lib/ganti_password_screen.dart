import 'package:flutter/material.dart';
import 'dart:convert';
import 'laporan_menu_screen.dart' show HealUColors;
import 'services/api_client.dart';

class GantiPasswordScreen extends StatefulWidget {
  final String? idUser;

  const GantiPasswordScreen({super.key, this.idUser});

  @override
  State<GantiPasswordScreen> createState() => _GantiPasswordScreenState();
}

class _GantiPasswordScreenState extends State<GantiPasswordScreen> {
  static const String _baseUrl =
      'https://chump-vividness-escapable.ngrok-free.dev/healu_api';

  final _formKey = GlobalKey<FormState>();
  final _passwordLamaController = TextEditingController();
  final _passwordBaruController = TextEditingController();
  final _konfirmasiController = TextEditingController();

  bool _obscureLama = true;
  bool _obscureBaru = true;
  bool _obscureKonfirmasi = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordLamaController.dispose();
    _passwordBaruController.dispose();
    _konfirmasiController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.idUser == null) {
      _showSnackbar('Sesi tidak ditemukan, silakan login ulang.', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiClient.instance
          .post(
            Uri.parse('$_baseUrl/ubah_password.php'),
            body: {
              'id_user': widget.idUser!,
              'password_lama': _passwordLamaController.text,
              'password_baru': _passwordBaruController.text,
            },
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['status'] == 'success') {
          _showSnackbar('Kata sandi berhasil diubah', HealUColors.primary);
          Navigator.pop(context);
        } else {
          _showSnackbar(
            json['message'] ?? 'Gagal mengubah kata sandi',
            Colors.red,
          );
        }
      } else {
        _showSnackbar(
          'Gagal terhubung ke server (${res.statusCode})',
          Colors.red,
        );
      }
    } catch (e) {
      _showSnackbar('Error koneksi: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPasswordField(
                        controller: _passwordLamaController,
                        label: 'Kata Sandi Lama',
                        obscure: _obscureLama,
                        onToggle: () =>
                            setState(() => _obscureLama = !_obscureLama),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Kata sandi lama wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        controller: _passwordBaruController,
                        label: 'Kata Sandi Baru',
                        obscure: _obscureBaru,
                        onToggle: () =>
                            setState(() => _obscureBaru = !_obscureBaru),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Kata sandi baru wajib diisi';
                          }
                          if (v.length < 6) {
                            return 'Minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildPasswordField(
                        controller: _konfirmasiController,
                        label: 'Konfirmasi Kata Sandi Baru',
                        obscure: _obscureKonfirmasi,
                        onToggle: () => setState(
                          () => _obscureKonfirmasi = !_obscureKonfirmasi,
                        ),
                        validator: (v) {
                          if (v != _passwordBaruController.text) {
                            return 'Konfirmasi tidak cocok';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: HealUColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Simpan Perubahan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                  "Ubah Kata Sandi",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: HealUColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Perbarui kata sandi akun Anda",
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: HealUColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: HealUColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: HealUColors.primary),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey,
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}