import 'package:flutter/material.dart';
import 'dart:convert';
import 'services/api_client.dart';

class _ObatItem {
  final TextEditingController namaObat;
  final TextEditingController sediaan;
  final TextEditingController dosis;
  final TextEditingController jumlah;
  final TextEditingController satuan;
  final TextEditingController aturanPakai;
  final TextEditingController catatan;
  TimeOfDay? waktuMinum;
  bool statusReminderAktif;

  _ObatItem({
    String namaObat = '',
    String sediaan = 'Tablet',
    String dosis = '',
    String jumlah = '1',
    String satuan = 'Tablet',
    String aturanPakai = '',
    String catatan = '',
    this.waktuMinum,
    this.statusReminderAktif = true,
  }) : namaObat = TextEditingController(text: namaObat),
       sediaan = TextEditingController(text: sediaan),
       dosis = TextEditingController(text: dosis),
       jumlah = TextEditingController(text: jumlah),
       satuan = TextEditingController(text: satuan),
       aturanPakai = TextEditingController(text: aturanPakai),
       catatan = TextEditingController(text: catatan);

  void dispose() {
    namaObat.dispose();
    sediaan.dispose();
    dosis.dispose();
    jumlah.dispose();
    satuan.dispose();
    aturanPakai.dispose();
    catatan.dispose();
  }

  Map<String, dynamic> toJson() => {
    'nama_obat': namaObat.text.trim(),
    'sediaan': sediaan.text.trim(),
    'dosis': dosis.text.trim(),
    'jumlah': int.tryParse(jumlah.text.trim()) ?? 1,
    'satuan': satuan.text.trim(),
    'aturan_pakai': aturanPakai.text.trim(),
    'catatan': catatan.text.trim(),
    'waktu_minum': waktuMinum == null
        ? null
        : '${waktuMinum!.hour.toString().padLeft(2, '0')}:${waktuMinum!.minute.toString().padLeft(2, '0')}:00',
    'status_reminder': statusReminderAktif ? 'aktif' : 'nonaktif',
  };
}

class ResepObatFormScreen extends StatefulWidget {
  final int? idPasien;
  final int? idDokter;
  final int? idKonsultasi;
  final int? idResep; // isi jika mode edit
  final Map<String, dynamic>? existingData; // header + obat[] jika mode edit

  const ResepObatFormScreen({
    super.key,
    this.idPasien,
    this.idDokter,
    this.idKonsultasi,
    this.idResep,
    this.existingData,
  });

  @override
  State<ResepObatFormScreen> createState() => _ResepObatFormScreenState();
}

class _ResepObatFormScreenState extends State<ResepObatFormScreen> {
  static const Color primaryGreen = Color(0xFF8EB76E);
  static const Color bgCream = Color(0xFFFFFDEC);

  final String baseUrl =
      'https://chump-vividness-escapable.ngrok-free.dev/healu_api';

  final _formKey = GlobalKey<FormState>();
  final _riwayatAlergiController = TextEditingController();
  String _statusResep = 'aktif';
  final List<_ObatItem> _items = [];
  bool _isSaving = false;

  bool get _isEdit => widget.idResep != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit && widget.existingData != null) {
      final data = widget.existingData!;
      _riwayatAlergiController.text = (data['riwayat_alergi'] ?? '').toString();
      _statusResep = (data['status_resep'] ?? 'aktif').toString();
      final obatList = (data['obat'] as List?) ?? [];
      for (final o in obatList) {
        TimeOfDay? jam;
        final jamStr = o['waktu_minum']?.toString();
        if (jamStr != null && jamStr.isNotEmpty && jamStr != 'null') {
          final parts = jamStr.split(':');
          if (parts.length >= 2) {
            jam = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 0,
              minute: int.tryParse(parts[1]) ?? 0,
            );
          }
        }
        _items.add(
          _ObatItem(
            namaObat: (o['nama_obat'] ?? '').toString(),
            sediaan: (o['sediaan'] ?? 'Tablet').toString(),
            dosis: (o['dosis'] ?? '').toString(),
            jumlah: (o['jumlah'] ?? 1).toString(),
            satuan: (o['satuan'] ?? 'Tablet').toString(),
            aturanPakai: (o['aturan_pakai'] ?? '').toString(),
            catatan: (o['catatan'] ?? '').toString(),
            waktuMinum: jam,
            statusReminderAktif: (o['status_reminder'] ?? 'aktif') == 'aktif',
          ),
        );
      }
    }
    if (_items.isEmpty) _items.add(_ObatItem());
  }

  @override
  void dispose() {
    _riwayatAlergiController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _tambahItem() => setState(() => _items.add(_ObatItem()));

  void _hapusItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  Future<void> _pilihJam(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _items[index].waktuMinum ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _items[index].waktuMinum = picked);
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final itemsJson = jsonEncode(_items.map((e) => e.toJson()).toList());
      final url = _isEdit
          ? '$baseUrl/update_resep_obat.php'
          : '$baseUrl/tambah_resep_obat.php';

      final body = <String, String>{
        'riwayat_alergi': _riwayatAlergiController.text.trim(),
        'status_resep': _statusResep,
        'items': itemsJson,
      };
      if (_isEdit) {
        body['id_resep'] = widget.idResep.toString();
      } else {
        body['id_pasien'] = (widget.idPasien ?? 0).toString();
        body['id_dokter'] = (widget.idDokter ?? 0).toString();
        if (widget.idKonsultasi != null) {
          body['id_konsultasi'] = widget.idKonsultasi.toString();
        }
      }

      final response = await ApiClient.instance.post(
        Uri.parse(url),
        body: body,
      );
      final result = jsonDecode(response.body);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Selesai')));
      if (result['success'] == true) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Resep Obat' : 'Buat Resep Obat',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildCardWrapper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Riwayat Alergi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _riwayatAlergiController,
                    decoration: _inputDecoration(
                      'Contoh: Alergi Golongan Penisilin (kosongkan jika tidak ada)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Status Resep',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _statusResep,
                    decoration: _inputDecoration(null),
                    items: const [
                      DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                      DropdownMenuItem(
                        value: 'selesai',
                        child: Text('Selesai'),
                      ),
                      DropdownMenuItem(
                        value: 'dibatalkan',
                        child: Text('Dibatalkan'),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => _statusResep = v ?? 'aktif'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Obat',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                TextButton.icon(
                  onPressed: _tambahItem,
                  icon: const Icon(Icons.add, color: primaryGreen),
                  label: const Text(
                    'Tambah Obat',
                    style: TextStyle(color: primaryGreen),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < _items.length; i++) _buildItemCard(i),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _simpan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _isEdit ? 'Simpan Perubahan' : 'Simpan Resep',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCardWrapper({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _inputDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
      filled: true,
      fillColor: bgCream,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildItemCard(int index) {
    final item = _items[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _buildCardWrapper(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Obat #${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                  ),
                ),
                if (_items.length > 1)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    onPressed: () => _hapusItem(index),
                  ),
              ],
            ),
            TextFormField(
              controller: item.namaObat,
              decoration: _inputDecoration('Nama obat, mis. Sertraline HCl'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Nama obat wajib diisi'
                  : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item.dosis,
                    decoration: _inputDecoration('Dosis, mis. 50 mg'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: item.sediaan,
                    decoration: _inputDecoration('Sediaan, mis. Tablet'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: item.jumlah,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Jumlah'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: item.satuan,
                    decoration: _inputDecoration('Satuan, mis. Tablet'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: item.aturanPakai,
              maxLines: 2,
              decoration: _inputDecoration(
                'Aturan & cara pakai, mis. 1 kali sehari 1 tablet setelah makan',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Aturan pakai wajib diisi'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: item.catatan,
              decoration: _inputDecoration('Catatan tambahan (opsional)'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: () => _pilihJam(index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: bgCream,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: primaryGreen,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.waktuMinum == null
                                  ? 'Jam minum (opsional)'
                                  : item.waktuMinum!.format(context),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 12,
                                color: item.waktuMinum == null
                                    ? Colors.grey.shade500
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          'Pengingat',
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      Switch(
                        value: item.statusReminderAktif,
                        activeThumbColor: primaryGreen,
                        onChanged: (v) =>
                            setState(() => item.statusReminderAktif = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}