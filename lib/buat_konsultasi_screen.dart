import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/api_client.dart';

class BuatKonsultasiScreen extends StatefulWidget {
  final String idAdmin;

  const BuatKonsultasiScreen({super.key, required this.idAdmin});

  @override
  State<BuatKonsultasiScreen> createState() => _BuatKonsultasiScreenState();
}

class _BuatKonsultasiScreenState extends State<BuatKonsultasiScreen> {
  final String baseUrl =
      "https://chump-vividness-escapable.ngrok-free.dev/healu_api";
  final Color primaryGreen = const Color(0xFF8EB76E);
  final Color bgCream = const Color(0xFFFFFDEC);

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isLoadingDokter = true;
  bool _isLoadingPasien = true;

  List<dynamic> _daftarDokter = [];
  List<dynamic> _daftarPasien = [];
  List<dynamic> _daftarPasienFiltered = [];
  List<dynamic> _daftarDokterFiltered = [];

  Map<String, dynamic>? _selectedPasien;
  Map<String, dynamic>? _selectedDokter;

  final _catatanController = TextEditingController();
  String _jenisSesi = 'Chat';
  DateTime? _selectedTanggal;
  TimeOfDay? _selectedJam;

  final TextEditingController _searchPasienController = TextEditingController();
  final TextEditingController _searchDokterController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDokter();
    _fetchPasien();
  }

  @override
  void dispose() {
    _catatanController.dispose();
    _searchPasienController.dispose();
    _searchDokterController.dispose();
    super.dispose();
  }

  Future<void> _fetchDokter() async {
    try {
      final res = await ApiClient.instance
          .get(Uri.parse("$baseUrl/get_dokters.php"))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _daftarDokter = data['data'] ?? [];
            _daftarDokterFiltered = _daftarDokter;
          });
        }
      }
    } catch (e) {
      debugPrint("fetchDokter error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingDokter = false);
    }
  }

  Future<void> _fetchPasien() async {
    try {
      final res = await ApiClient.instance
          .get(Uri.parse("$baseUrl/get_pasien.php"))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _daftarPasien = data['data'] ?? [];
            _daftarPasienFiltered = _daftarPasien;
          });
        }
      }
    } catch (e) {
      debugPrint("fetchPasien error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingPasien = false);
    }
  }

  Future<void> _pickTanggal() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: ColorScheme.light(primary: primaryGreen)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTanggal = picked);
  }

  Future<void> _pickJam() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: ColorScheme.light(primary: primaryGreen)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedJam = picked);
  }

  String get _tanggalDisplay {
    if (_selectedTanggal == null) return 'Pilih tanggal';
    return "${_selectedTanggal!.day.toString().padLeft(2, '0')}/"
        "${_selectedTanggal!.month.toString().padLeft(2, '0')}/"
        "${_selectedTanggal!.year}";
  }

  String get _jamDisplay {
    if (_selectedJam == null) return 'Pilih jam';
    final h = _selectedJam!.hour.toString().padLeft(2, '0');
    final m = _selectedJam!.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  void _showPilihPasien() {
    _searchPasienController.clear();
    setState(() => _daftarPasienFiltered = _daftarPasien);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            maxChildSize: 0.9,
            builder: (_, scrollCtrl) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Pilih Pasien',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchPasienController,
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau email...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (q) {
                      setModalState(() {
                        _daftarPasienFiltered = _daftarPasien
                            .where(
                              (p) =>
                                  p['nama_lengkap']
                                      .toString()
                                      .toLowerCase()
                                      .contains(q.toLowerCase()) ||
                                  p['email'].toString().toLowerCase().contains(
                                    q.toLowerCase(),
                                  ),
                            )
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _isLoadingPasien
                        ? Center(
                            child: CircularProgressIndicator(
                              color: primaryGreen,
                            ),
                          )
                        : ListView.builder(
                            controller: scrollCtrl,
                            itemCount: _daftarPasienFiltered.length,
                            itemBuilder: (_, i) {
                              final p = _daftarPasienFiltered[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.orange.shade100,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.orange.shade600,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  p['nama_lengkap'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  p['email'] ?? '-',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onTap: () {
                                  setState(() => _selectedPasien = p);
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPilihDokter() {
    _searchDokterController.clear();
    setState(() => _daftarDokterFiltered = _daftarDokter);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.75,
            maxChildSize: 0.9,
            builder: (_, scrollCtrl) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Pilih Dokter',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchDokterController,
                    decoration: InputDecoration(
                      hintText: 'Cari nama dokter...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (q) {
                      setModalState(() {
                        _daftarDokterFiltered = _daftarDokter
                            .where(
                              (d) => d['nama_lengkap']
                                  .toString()
                                  .toLowerCase()
                                  .contains(q.toLowerCase()),
                            )
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _isLoadingDokter
                        ? Center(
                            child: CircularProgressIndicator(
                              color: primaryGreen,
                            ),
                          )
                        : ListView.builder(
                            controller: scrollCtrl,
                            itemCount: _daftarDokterFiltered.length,
                            itemBuilder: (_, i) {
                              final d = _daftarDokterFiltered[i];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Icon(
                                    Icons.medical_services_outlined,
                                    color: Colors.blue.shade600,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  d['nama_lengkap'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  d['spesialis'] ?? '-',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Text(
                                  'Rp${_formatBiaya(d['harga_konsultasi'])}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () {
                                  setState(() => _selectedDokter = d);
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatBiaya(dynamic biaya) {
    if (biaya == null) return '0';
    final num = int.tryParse(biaya.toString()) ?? 0;
    return num.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  Future<void> _buatKonsultasi() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPasien == null) {
      _showValidationSnack('Pilih pasien terlebih dahulu');
      return;
    }
    if (_selectedDokter == null) {
      _showValidationSnack('Pilih dokter terlebih dahulu');
      return;
    }
    if (_selectedTanggal == null) {
      _showValidationSnack('Pilih tanggal konsultasi');
      return;
    }
    if (_selectedJam == null) {
      _showValidationSnack('Pilih jam konsultasi');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tanggalStr =
          "${_selectedTanggal!.year}-${_selectedTanggal!.month.toString().padLeft(2, '0')}-${_selectedTanggal!.day.toString().padLeft(2, '0')}";
      final jamStr =
          "${_selectedJam!.hour.toString().padLeft(2, '0')}:${_selectedJam!.minute.toString().padLeft(2, '0')}:00";

      final response = await http
          .post(
            Uri.parse("$baseUrl/buat_konsultasi.php"),
            body: {
              'id_pasien': _selectedPasien!['id'].toString(),
              'id_dokter': _selectedDokter!['id_dokter'].toString(),
              'id_admin': widget.idAdmin,
              'jenis_sesi': _jenisSesi,
              'tanggal_konsultasi': tanggalStr,
              'jam_konsultasi': jamStr,
              'catatan': _catatanController.text.trim(),
            },
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Konsultasi berhasil dibuat'),
            backgroundColor: primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      } else {
        _showErrorSnack(data['message'] ?? 'Gagal membuat konsultasi');
      }
    } catch (e) {
      if (mounted) _showErrorSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showValidationSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ $msg'),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $msg'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Buat Konsultasi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionLabel('Pilih Pasien'),
              const SizedBox(height: 10),
              _buildSelectorCard(
                selected: _selectedPasien != null,
                label: _selectedPasien != null
                    ? _selectedPasien!['nama_lengkap'] ?? '-'
                    : 'Tap untuk pilih pasien',
                sublabel: _selectedPasien?['email'],
                icon: Icons.person_outline,
                iconColor: Colors.orange.shade400,
                iconBgColor: Colors.orange.shade50,
                onTap: _showPilihPasien,
              ),

              const SizedBox(height: 20),
              _buildSectionLabel('Pilih Dokter'),
              const SizedBox(height: 10),
              _buildSelectorCard(
                selected: _selectedDokter != null,
                label: _selectedDokter != null
                    ? _selectedDokter!['nama_lengkap'] ?? '-'
                    : 'Tap untuk pilih dokter',
                sublabel: _selectedDokter != null
                    ? '${_selectedDokter!['spesialis']} · Rp${_formatBiaya(_selectedDokter!['harga_konsultasi'])}'
                    : null,
                icon: Icons.medical_services_outlined,
                iconColor: Colors.blue.shade400,
                iconBgColor: Colors.blue.shade50,
                onTap: _showPilihDokter,
              ),

              const SizedBox(height: 20),
              _buildSectionLabel('Jadwal Konsultasi'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTapField(
                      icon: Icons.calendar_today_outlined,
                      label: 'Tanggal',
                      value: _tanggalDisplay,
                      isSet: _selectedTanggal != null,
                      onTap: _pickTanggal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTapField(
                      icon: Icons.access_time_outlined,
                      label: 'Jam',
                      value: _jamDisplay,
                      isSet: _selectedJam != null,
                      onTap: _pickJam,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _buildSectionLabel('Jenis Sesi'),
              const SizedBox(height: 10),
              Row(
                children: ['Chat', 'Video Call', 'Tatap Muka'].map((jenis) {
                  final isSelected = _jenisSesi == jenis;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _jenisSesi = jenis),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryGreen : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? primaryGreen
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          jenis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              _buildSectionLabel('Catatan (opsional)'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _catatanController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tuliskan keluhan atau catatan...',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryGreen, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),

              const SizedBox(height: 28),

              if (_selectedPasien != null &&
                  _selectedDokter != null &&
                  _selectedTanggal != null)
                _buildRingkasan(),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _buatKonsultasi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Buat Konsultasi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: primaryGreen,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _buildSelectorCard({
    required bool selected,
    required String label,
    String? sublabel,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? primaryGreen.withValues(alpha: 0.5)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: selected
                    ? iconColor.withValues(alpha: 0.15)
                    : iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: selected ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  if (sublabel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      sublabel,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.chevron_right,
              color: selected ? primaryGreen : Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTapField({
    required IconData icon,
    required String label,
    required String value,
    required bool isSet,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSet
                ? primaryGreen.withValues(alpha: 0.5)
                : Colors.grey.shade300,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSet ? primaryGreen : Colors.grey.shade400,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSet ? FontWeight.w600 : FontWeight.normal,
                      color: isSet ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRingkasan() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),
          const SizedBox(height: 8),
          _ringkasanRow('Pasien', _selectedPasien?['nama_lengkap'] ?? '-'),
          _ringkasanRow('Dokter', _selectedDokter?['nama_lengkap'] ?? '-'),
          _ringkasanRow('Jadwal', '$_tanggalDisplay · $_jamDisplay'),
          _ringkasanRow('Sesi', _jenisSesi),
          if (_selectedDokter != null)
            _ringkasanRow(
              'Biaya',
              'Rp${_formatBiaya(_selectedDokter!['harga_konsultasi'])}',
            ),
        ],
      ),
    );
  }

  Widget _ringkasanRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const Text(' : ', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}