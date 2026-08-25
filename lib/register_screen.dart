// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'services/api_client.dart';
import 'dart:convert';
import 'package:healu_app/login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _namaController = TextEditingController();

  String _selectedRole = 'pasien';
  final List<String> _roles = ['pasien', 'dokter'];
  bool _isLoading = false;

  Future<void> prosesDaftarAkun() async {
    setState(() => _isLoading = true);
    try {
      var url = Uri.parse("https://chump-vividness-escapable.ngrok-free.dev/healu_api/register.php");
      var response = await ApiClient.instance.post(
        url,
        body: {
          "email": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
          "nama_lengkap": _namaController.text.trim(),
          "role": _selectedRole,
        },
      );

      var data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        if (!mounted) return;

        // Daftar berhasil -> arahkan ke halaman Login supaya user login ulang
        // dan mendapatkan id yang valid & benar dari login.php (bukan ditebak
        // di sisi Flutter, yang sebelumnya menyebabkan id_pasien terkirim
        // sebagai string "null" ke backend).
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pendaftaran berhasil! Silakan login.'),
            backgroundColor: Color(0xFF8EB76E),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDEC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Buat Akun Baru\ndi HealU 🌿',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),

              _buildAuthTabs(context),

              const SizedBox(height: 30),
              _inputField('Nama Lengkap', _namaController),
              const SizedBox(height: 16),
              _inputField('Email Address', _emailController),
              const SizedBox(height: 16),
              _inputField('Password', _passwordController, isPassword: true),
              const SizedBox(height: 16),
              // Dropdown UI yang serasi dengan TextField
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: _roles
                    .map(
                      (role) =>
                          DropdownMenuItem(value: role, child: Text(role)),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedRole = val!),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : prosesDaftarAkun,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8EB76E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Daftar Sekarang',
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
        ),
      ),
    );
  }

  Widget _buildAuthTabs(BuildContext context) {
    return Row(
      children: [
        // TOMBOL LOGIN (PASIF - WARNA ABU-ABU)
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: const Center(
                child: Text(
                  'Login',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // TOMBOL REGISTER (AKTIF - WARNA HIJAU)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF8EB76E), // Hijau Aktif
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'Register',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _inputField(
    String hint,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}