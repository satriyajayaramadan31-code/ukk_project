import 'package:engine_rent_app/screen/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailPinjamDialog extends StatelessWidget {
  final Map<String, dynamic> request;
  final String statusText;
  final Color statusColor;

  const DetailPinjamDialog({
    super.key,
    required this.request,
    required this.statusText,
    required this.statusColor,
  });

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  String _formatDate(dynamic value) {
    final dt = _parseDate(value);
    if (dt == null) return "-";
    return DateFormat.yMMMMd('id').format(dt);
  }

  int _calcLateDays() {
    final due = _parseDate(request['tanggal_kembali']);
    final returned = _parseDate(request['tanggal_pengembalian']);

    // kalau belum ada tanggal kembali atau belum dikembalikan => tidak terlambat (0)
    if (due == null || returned == null) return 0;

    // biar hitungannya bersih per-hari (tanpa jam)
    final dueDate = DateTime(due.year, due.month, due.day);
    final returnedDate = DateTime(returned.year, returned.month, returned.day);

    final diff = returnedDate.difference(dueDate).inDays;
    return diff > 0 ? diff : 0;
  }

  bool _isBroken() {
    final rusak = request['rusak'];
    if (rusak is bool) return rusak;
    // jaga-jaga kalau datangnya "true"/"false" string
    return rusak.toString().toLowerCase() == 'true';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final lateDays = _calcLateDays();
    final isBroken = _isBroken();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Text(
                  "Detail Peminjaman",
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 16),

              // ===== PEMINJAM =====
              Text("Peminjam", style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(
                (request['username'] ?? '-').toString(),
                style: theme.textTheme.headlineSmall,
              ),

              const SizedBox(height: 10),

              // ===== STATUS =====
              Text("Status", style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _capitalize(statusText),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ===== NAMA ALAT =====
              Text("Nama Alat", style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(
                (request['nama_alat'] ?? '-').toString(),
                style: theme.textTheme.headlineSmall,
              ),

              const SizedBox(height: 10),

              // ===== TANGGAL =====
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Tanggal Pinjam", style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(request['tanggal_pinjam']),
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),

                  Text("Tanggal Kembali", style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(request['tanggal_kembali']),
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),

                  Text("Dikembalikan", style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(request['tanggal_pengembalian']),
                    style: theme.textTheme.headlineSmall,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ===== TERLAMBAT & KONDISI (YANG HILANG) =====
              Row(
                children: [
                  Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Keterlambatan", style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 6),
                          Text(
                            "$lateDays Hari",
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Kondisi Alat", style: theme.textTheme.bodyMedium),
                          const SizedBox(height: 6),
                          Text(
                            isBroken ? "Rusak" : "Baik",
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ===== TUJUAN =====
              Text("Tujuan Peminjaman", style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary),
                ),
                child: Text(
                  (request['alasan'] ?? '-').toString(),
                  style: theme.textTheme.headlineSmall,
                ),
              ),

              const SizedBox(height: 16),

              // ===== BUTTON =====
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "Tutup", 
                    style: theme.textTheme.bodyLarge),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
