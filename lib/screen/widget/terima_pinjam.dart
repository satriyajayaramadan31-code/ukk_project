import 'package:flutter/material.dart';
import '../utils/theme.dart';
import 'package:intl/intl.dart';

class TerimaPinjamDialog extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const TerimaPinjamDialog({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  // ===== STATUS UI (samakan dengan yang lama) =====
  Color _statusColor(String status) {
    final s = status.toLowerCase();
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

  String _statusText(String status) {
    if (status.isEmpty) return "-";
    final s = status.toLowerCase();
    switch (s) {
      case 'menunggu':
        return "Menunggu";
      case 'diproses':
        return "Diproses";
      case 'dipinjam':
        return "Dipinjam";
      case 'dikembalikan':
        return "Dikembalikan";
      case 'ditolak':
        return "Ditolak";
      default:
        // fallback: kapital huruf pertama
        return s[0].toUpperCase() + s.substring(1);
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return "-";
    final s = value.toString();
    if (s.isEmpty) return "-";
    final dt = DateTime.tryParse(s);
    if (dt == null) return "-";
    return DateFormat.yMMMMd('id').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: theme.scaffoldBackgroundColor,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Proses Pengajuan", style: theme.textTheme.headlineSmall),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Peminjam
              Text("Peminjam", style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(
                (request['username'] ?? '-').toString(),
                style: theme.textTheme.headlineSmall,
              ),

              const SizedBox(height: 10),

              // Status (INI yang tadi hilang)
              Text("Status", style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _statusColor((request['status'] ?? '').toString()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _statusText((request['status'] ?? '').toString()),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Nama Alat
              Text("Nama Alat", style: theme.textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(
                (request['nama_alat'] ?? '-').toString(),
                style: theme.textTheme.headlineSmall,
              ),

              const SizedBox(height: 10),

              // Tanggal
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Tanggal Pinjam",
                            style: theme.textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(request['tanggal_pinjam']),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Tanggal Kembali", style: theme.textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(request['tanggal_kembali']),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Tujuan
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
                  softWrap: true,
                ),
              ),

              const SizedBox(height: 16),

              // Buttons (samakan seperti lama -> ElevatedButton)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text("Setujui"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onReject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: theme.colorScheme.primary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: BorderSide(color: theme.colorScheme.primary),
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
}
