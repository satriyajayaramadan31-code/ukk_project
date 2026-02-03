import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'package:intl/intl.dart';

class KonfirmasiPinjamDialog extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onConfirm; // set status -> dikembalikan
  final VoidCallback onReject; // set status -> ditolak / dll

  const KonfirmasiPinjamDialog({
    super.key,
    required this.request,
    required this.onConfirm,
    required this.onReject,
  });

  String _formatDate(dynamic value) {
    if (value == null) return "-";
    final s = value.toString().trim();
    if (s.isEmpty) return "-";
    final dt = DateTime.tryParse(s);
    if (dt == null) return "-";
    return DateFormat.yMMMMd('id').format(dt);
  }

  String _capitalize(String s) {
    final t = s.trim();
    if (t.isEmpty) return "-";
    return t[0].toUpperCase() + t.substring(1).toLowerCase();
  }

  String _statusText(dynamic statusValue) {
    final s = (statusValue ?? '').toString().trim().toLowerCase();
    if (s.isEmpty) return "-";

    switch (s) {
      case 'menunggu':
        return 'Menunggu';
      case 'diproses':
        return 'Diproses';
      case 'dipinjam':
        return 'Dipinjam';
      case 'dikembalikan':
        return 'Dikembalikan';
      case 'ditolak':
        return 'Ditolak';
      default:
        return _capitalize(s);
    }
  }

  Color _statusColor(dynamic statusValue) {
    final s = (statusValue ?? '').toString().trim().toLowerCase();
    switch (s) {
      case 'menunggu':
        return AppTheme.statusPending;
      case 'diproses':
        return AppTheme.statusConfirm;
      case 'dipinjam':
        return AppTheme.statusBorrowed;
      case 'dikembalikan':
        return AppTheme.statusReturned;
      case 'ditolak':
        return AppTheme.statusLate;
      default:
        return Colors.grey;
    }
  }

  int _calcLateDays(dynamic dueDateValue) {
    if (dueDateValue == null) return 0;
    final s = dueDateValue.toString().trim();
    if (s.isEmpty) return 0;

    final due = DateTime.tryParse(s);
    if (due == null) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueOnly = DateTime(due.year, due.month, due.day);

    final diff = today.difference(dueOnly).inDays;
    return diff > 0 ? diff : 0;
  }

  bool _isBroken(dynamic rusakValue) {
    if (rusakValue == null) return false;
    if (rusakValue is bool) return rusakValue;
    final s = rusakValue.toString().trim().toLowerCase();
    return s == 'true' || s == '1' || s == 'ya' || s == 'yes';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final statusText = _statusText(request['status']);
    final statusColor = _statusColor(request['status']);

    final lateDays = _calcLateDays(request['tanggal_kembali']);
    final isBroken = _isBroken(request['rusak']);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 520,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= HEADER =================
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Konfirmasi Peminjaman",
                      style: theme.textTheme.headlineSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ================= CONTENT =================
              Text("Peminjam", style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(
                (request['username'] ?? '-').toString(),
                style: theme.textTheme.headlineSmall,
              ),

              const SizedBox(height: 12),

              Text("Status", style: theme.textTheme.bodyMedium),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Text("Nama Alat", style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(
                (request['nama_alat'] ?? '-').toString(),
                style: theme.textTheme.headlineSmall,
              ),

              const SizedBox(height: 14),

              _infoBlock(
                theme: theme,
                label: "Tanggal Pinjam",
                value: _formatDate(request['tanggal_pinjam']),
              ),
              _infoBlock(
                theme: theme,
                label: "Tanggal Kembali",
                value: _formatDate(request['tanggal_kembali']),
              ),
              _infoBlock(
                theme: theme,
                label: "Dikembalikan",
                value: _formatDate(request['tanggal_pengembalian']),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _infoMini(
                      theme: theme,
                      label: "Keterlambatan",
                      value: "$lateDays hari",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoMini(
                      theme: theme,
                      label: "Kondisi Alat",
                      value: isBroken ? "Rusak" : "Baik",
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Text("Tujuan Peminjaman", style: theme.textTheme.bodyMedium),
              const SizedBox(height: 6),
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
                  softWrap: true,
                ),
              ),

              const SizedBox(height: 16),

              // ================= ACTION BUTTONS (SCROLLABLE) =================
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: theme.textTheme.bodyMedium,
                      ),
                      child: const Text("Dikembalikan"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        side: BorderSide(color: theme.colorScheme.primary),
                        textStyle: theme.textTheme.bodyMedium,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text("Tolak"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBlock({
    required ThemeData theme,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.headlineSmall),
        ],
      ),
    );
  }

  Widget _infoMini({
    required ThemeData theme,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          )),
        ],
      ),
    );
  }
}
