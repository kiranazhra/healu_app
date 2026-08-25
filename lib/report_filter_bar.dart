import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportFilterBar extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onTap;

  const ReportFilterBar({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onTap,
  });

  String get _label {
    if (startDate == null || endDate == null) return "Semua Data";
    final format = DateFormat('d MMM yyyy', 'id_ID');
    return "${format.format(startDate!)} - ${format.format(endDate!)}";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 20,
              color: Color(0xFF8EB76E),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

/// Menampilkan bottom sheet filter, mengembalikan Map berisi 'start' & 'end'
/// (DateTime), atau Map kosong {} jika user pilih "Semua Data",
/// atau null jika dibatalkan (tidak ada perubahan).
Future<Map<String, DateTime>?> showReportFilterSheet(
  BuildContext context, {
  DateTime? currentStart,
  DateTime? currentEnd,
}) {
  return showModalBottomSheet<Map<String, DateTime>>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _FilterSheetContent(
        currentStart: currentStart,
        currentEnd: currentEnd,
      );
    },
  );
}

class _FilterSheetContent extends StatelessWidget {
  final DateTime? currentStart;
  final DateTime? currentEnd;

  const _FilterSheetContent({this.currentStart, this.currentEnd});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    DateTime startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);
    DateTime endOfMonth(DateTime d) =>
        DateTime(d.year, d.month + 1, 0, 23, 59, 59);

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
            "Filter Laporan",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _optionTile(context, "Semua Data", () {
            Navigator.pop(context, <String, DateTime>{});
          }),
          _optionTile(context, "Bulan Ini", () {
            Navigator.pop(context, {
              'start': startOfMonth(now),
              'end': endOfMonth(now),
            });
          }),
          _optionTile(context, "Bulan Lalu", () {
            final lastMonth = DateTime(now.year, now.month - 1, 1);
            Navigator.pop(context, {
              'start': startOfMonth(lastMonth),
              'end': endOfMonth(lastMonth),
            });
          }),
          _optionTile(context, "3 Bulan Terakhir", () {
            final threeMonthsAgo = DateTime(now.year, now.month - 2, 1);
            Navigator.pop(context, {
              'start': startOfMonth(threeMonthsAgo),
              'end': endOfMonth(now),
            });
          }),
          _optionTile(context, "Pilih Rentang Tanggal", () async {
            final navigator = Navigator.of(context);
            final range = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2023, 1, 1),
              lastDate: DateTime(now.year + 1, 12, 31),
              initialDateRange: currentStart != null && currentEnd != null
                  ? DateTimeRange(start: currentStart!, end: currentEnd!)
                  : null,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF8EB76E),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (range != null) {
              navigator.pop({
                'start': range.start,
                'end': DateTime(
                  range.end.year,
                  range.end.month,
                  range.end.day,
                  23,
                  59,
                  59,
                ),
              });
            }
          }),
        ],
      ),
    );
  }

  Widget _optionTile(BuildContext context, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFF8EB76E)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
