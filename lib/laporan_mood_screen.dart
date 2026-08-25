import 'package:flutter/material.dart';
import 'dart:convert';
import 'laporan_menu_screen.dart' show HealUColors;
import 'laporan_mood_wellness_screen.dart';
import 'admin_bottom_nav.dart';
import 'services/api_client.dart';

enum _SortMode { tanggalTerbaru, tanggalTerlama, bulanAsc, bulanDesc }

class LaporanMoodScreen extends StatefulWidget {
  const LaporanMoodScreen({super.key});

  @override
  State<LaporanMoodScreen> createState() => _LaporanMoodScreenState();
}

class _LaporanMoodScreenState extends State<LaporanMoodScreen> {
  static const String _baseUrl =
      'https://chump-vividness-escapable.ngrok-free.dev/healu_api';
  static const List<String> _bulanPendek = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Ags',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  List<dynamic> _data = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  _SortMode _sortMode = _SortMode.tanggalTerbaru;

  // ── FILTER TANGGAL/PERIODE ──
  DateTimeRange? _filterTanggal;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.instance
          .get(Uri.parse('$_baseUrl/get_all_mood_pasien.php'))
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['status'] == 'success') {
          setState(() {
            _data = json['data'] ?? [];
            _isLoading = false;
          });
          return;
        }
      }
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error fetch mood: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  DateTime? _tanggalOf(dynamic d) =>
      DateTime.tryParse((d['tanggal'] ?? '').toString());

  List<dynamic> get _filteredData {
    List<dynamic> result = _data;

    // Filter pencarian: nama, ID, atau email
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((d) {
        final nama = (d['nama_pasien'] ?? '').toString().toLowerCase();
        final id = (d['id_pasien'] ?? '').toString().toLowerCase();
        final email = (d['email'] ?? '').toString().toLowerCase();
        return nama.contains(query) ||
            id.contains(query) ||
            email.contains(query);
      }).toList();
    }

    // Filter periode tanggal
    if (_filterTanggal != null) {
      final start = DateTime(
        _filterTanggal!.start.year,
        _filterTanggal!.start.month,
        _filterTanggal!.start.day,
      );
      final end = DateTime(
        _filterTanggal!.end.year,
        _filterTanggal!.end.month,
        _filterTanggal!.end.day,
        23,
        59,
        59,
      );
      result = result.where((d) {
        final tgl = _tanggalOf(d);
        if (tgl == null) return false;
        return !tgl.isBefore(start) && !tgl.isAfter(end);
      }).toList();
    }

    final sorted = List<dynamic>.from(result);

    switch (_sortMode) {
      case _SortMode.tanggalTerbaru:
        sorted.sort((a, b) {
          final da = _tanggalOf(a) ?? DateTime(2000);
          final db = _tanggalOf(b) ?? DateTime(2000);
          return db.compareTo(da);
        });
        break;
      case _SortMode.tanggalTerlama:
        sorted.sort((a, b) {
          final da = _tanggalOf(a) ?? DateTime(2000);
          final db = _tanggalOf(b) ?? DateTime(2000);
          return da.compareTo(db);
        });
        break;
      case _SortMode.bulanAsc:
        sorted.sort((a, b) {
          final da = _tanggalOf(a);
          final db = _tanggalOf(b);
          final ma = da?.month ?? 0;
          final mb = db?.month ?? 0;
          if (ma != mb) return ma.compareTo(mb);
          return (da ?? DateTime(2000)).compareTo(db ?? DateTime(2000));
        });
        break;
      case _SortMode.bulanDesc:
        sorted.sort((a, b) {
          final da = _tanggalOf(a);
          final db = _tanggalOf(b);
          final ma = da?.month ?? 0;
          final mb = db?.month ?? 0;
          if (ma != mb) return mb.compareTo(ma);
          return (db ?? DateTime(2000)).compareTo(da ?? DateTime(2000));
        });
        break;
    }

    return sorted;
  }

  String get _sortLabel {
    switch (_sortMode) {
      case _SortMode.tanggalTerbaru:
        return 'Tanggal Terbaru';
      case _SortMode.tanggalTerlama:
        return 'Tanggal Terlama';
      case _SortMode.bulanAsc:
        return 'Bulan (Jan → Des)';
      case _SortMode.bulanDesc:
        return 'Bulan (Des → Jan)';
    }
  }

  String _formatTanggalPendek(DateTime d) {
    return '${d.day} ${_bulanPendek[d.month - 1]} ${d.year}';
  }

  Future<void> _pilihRentangTanggal() async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _filterTanggal,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: HealUColors.primary,
                  onPrimary: Colors.white,
                  onSurface: HealUColors.textPrimary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (result != null) {
      setState(() => _filterTanggal = result);
    }
  }

  void _hapusFilterTanggal() {
    setState(() => _filterTanggal = null);
  }

  // ── BOTTOM SHEET: FILTER (Tanggal/Periode + Sortir) ──
  Future<void> _openFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const Text(
                    "Filter Periode",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      await _pilihRentangTanggal();
                      setSheetState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: HealUColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.date_range,
                            size: 18,
                            color: HealUColors.primaryDark,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _filterTanggal == null
                                  ? 'Pilih rentang tanggal'
                                  : '${_formatTanggalPendek(_filterTanggal!.start)} - ${_formatTanggalPendek(_filterTanggal!.end)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: HealUColors.primaryDark,
                              ),
                            ),
                          ),
                          if (_filterTanggal != null)
                            GestureDetector(
                              onTap: () {
                                _hapusFilterTanggal();
                                setSheetState(() {});
                              },
                              child: const Icon(
                                Icons.close,
                                size: 18,
                                color: HealUColors.primaryDark,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Sortir Laporan",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  _sortTile(
                    sheetContext,
                    setSheetState,
                    'Tanggal Terbaru',
                    Icons.arrow_downward,
                    _SortMode.tanggalTerbaru,
                  ),
                  _sortTile(
                    sheetContext,
                    setSheetState,
                    'Tanggal Terlama',
                    Icons.arrow_upward,
                    _SortMode.tanggalTerlama,
                  ),
                  _sortTile(
                    sheetContext,
                    setSheetState,
                    'Bulan (Januari → Desember)',
                    Icons.calendar_view_month,
                    _SortMode.bulanAsc,
                  ),
                  _sortTile(
                    sheetContext,
                    setSheetState,
                    'Bulan (Desember → Januari)',
                    Icons.calendar_view_month,
                    _SortMode.bulanDesc,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HealUColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text(
                        'Terapkan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    setState(() {}); // refresh list utama setelah sheet ditutup
  }

  Widget _sortTile(
    BuildContext sheetContext,
    void Function(void Function()) setSheetState,
    String title,
    IconData icon,
    _SortMode mode,
  ) {
    final aktif = _sortMode == mode;
    return InkWell(
      onTap: () {
        setState(() => _sortMode = mode);
        setSheetState(() {});
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: aktif ? HealUColors.primary : Colors.grey.shade500,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: aktif ? FontWeight.w700 : FontWeight.normal,
                  color: aktif ? HealUColors.primary : Colors.black87,
                ),
              ),
            ),
            if (aktif)
              const Icon(Icons.check, size: 18, color: HealUColors.primary),
          ],
        ),
      ),
    );
  }

  Color _warnaMood(String mood) {
    switch (mood) {
      case 'Sangat Baik':
        return const Color(0xFF2E7D32);
      case 'Baik':
        return const Color(0xFF66BB6A);
      case 'Biasa Saja':
        return const Color(0xFFFFA726);
      case 'Buruk':
        return const Color(0xFFEF6C00);
      case 'Sangat Buruk':
        return const Color(0xFFC62828);
      default:
        return HealUColors.textSecondary;
    }
  }

  IconData _iconMood(String mood) {
    switch (mood) {
      case 'Sangat Baik':
        return Icons.sentiment_very_satisfied;
      case 'Baik':
        return Icons.sentiment_satisfied;
      case 'Biasa Saja':
        return Icons.sentiment_neutral;
      case 'Buruk':
        return Icons.sentiment_dissatisfied;
      case 'Sangat Buruk':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.mood;
    }
  }

  String _formatTanggal(String tanggal) {
    try {
      final date = DateTime.parse(tanggal);
      return '${date.day} ${_bulanPendek[date.month - 1]} ${date.year}';
    } catch (_) {
      return tanggal;
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
            const SizedBox(height: 14),
            _buildSearchAndFilterRow(),
            if (_filterTanggal != null) ...[
              const SizedBox(height: 8),
              _buildFilterTanggalChip(),
            ],
            const SizedBox(height: 8),
            _buildSortChip(),
            const SizedBox(height: 8),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── HEADER GRADASI (tanpa ikon filter, sudah dipindah ke search bar) ──
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
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: HealUColors.primaryDark,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Laporan Mood Pasien',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: HealUColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_data.length} pasien tercatat',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: HealUColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SEARCH BAR + IKON FILTER DI SAMPING KANAN ──
  Widget _buildSearchAndFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: HealUColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: const InputDecoration(
                  hintText: 'Cari nama, email, atau ID pasien...',
                  hintStyle: TextStyle(
                    color: HealUColors.textSecondary,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: HealUColors.textSecondary,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _openFilterSheet,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _filterTanggal != null
                    ? HealUColors.primary
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _filterTanggal != null
                      ? HealUColors.primary
                      : HealUColors.border,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Icon(
                Icons.filter_list,
                color: _filterTanggal != null
                    ? Colors.white
                    : HealUColors.primaryDark,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CHIP PENANDA FILTER TANGGAL AKTIF ──
  Widget _buildFilterTanggalChip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: HealUColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.date_range,
                size: 14,
                color: HealUColors.primaryDark,
              ),
              const SizedBox(width: 6),
              Text(
                '${_formatTanggalPendek(_filterTanggal!.start)} - ${_formatTanggalPendek(_filterTanggal!.end)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: HealUColors.primaryDark,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _hapusFilterTanggal,
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: HealUColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── CHIP PENANDA SORTIR AKTIF, TAP UNTUK BUKA SHEET LAGI ─────────────
  Widget _buildSortChip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: _openFilterSheet,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: HealUColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.sort,
                  size: 14,
                  color: HealUColors.primaryDark,
                ),
                const SizedBox(width: 6),
                Text(
                  _sortLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: HealUColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: HealUColors.primary),
      );
    }
    if (_data.isEmpty) {
      return _buildEmptyState(
        icon: Icons.mood_outlined,
        title: 'Belum ada data mood',
        subtitle: 'Data akan muncul setelah pasien mengisi mood',
      );
    }
    if (_filteredData.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: 'Tidak ditemukan',
        subtitle: _searchQuery.isNotEmpty
            ? 'Pasien "$_searchQuery" tidak ditemukan'
            : 'Tidak ada data pada periode yang dipilih',
      );
    }
    return RefreshIndicator(
      color: HealUColors.primary,
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _filteredData.length,
        itemBuilder: (context, i) => _buildMoodCard(_filteredData[i]),
      ),
    );
  }

  Widget _buildMoodCard(dynamic d) {
    final mood = (d['mood'] ?? '-').toString();
    final idPasienStr = d['id_pasien']?.toString() ?? '-';
    final namaPasien = (d['nama_pasien'] ?? '-').toString();
    final tanggal = (d['tanggal'] ?? '').toString();
    final warna = _warnaMood(mood);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LaporanMoodWellnessScreen(
            idPasien: idPasienStr,
            namaPasien: namaPasien,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: HealUColors.border),
        ),
        child: Row(
          children: [
            _MoodAvatar(icon: _iconMood(mood), color: warna),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          namaPasien,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: HealUColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '  |  ID $idPasienStr',
                        style: const TextStyle(
                          fontSize: 12,
                          color: HealUColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _MoodBadge(label: mood, color: warna),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTanggal(tanggal),
                  style: const TextStyle(
                    fontSize: 11,
                    color: HealUColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: HealUColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: HealUColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: HealUColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: HealUColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: HealUColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return const AdminBottomNav(currentIndex: 2);
  }
}

class _MoodAvatar extends StatelessWidget {
  const _MoodAvatar({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}

class _MoodBadge extends StatelessWidget {
  const _MoodBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}