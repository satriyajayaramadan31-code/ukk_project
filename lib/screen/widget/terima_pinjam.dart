import 'package:flutter/material.dart';
import '../models/loan_request.dart';

class TerimaPinjamDialog extends StatelessWidget {
  final LoanRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const TerimaPinjamDialog({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  Color _statusColor(LoanStatus status) {
    switch (status) {
      case LoanStatus.menunggu:
        return Colors.amber;
      case LoanStatus.diproses:
        return Colors.blue;
      case LoanStatus.dipinjam:
        return Colors.green;
      case LoanStatus.dikembalikan:
        return Colors.teal;
      case LoanStatus.ditolak:
        return Colors.red;
    }
  }

  String _statusText(LoanStatus status) {
    switch (status) {
      case LoanStatus.menunggu:
        return "Menunggu";
      case LoanStatus.diproses:
        return "Diproses";
      case LoanStatus.dipinjam:
        return "Dipinjam";
      case LoanStatus.dikembalikan:
        return "Dikembalikan";
      case LoanStatus.ditolak:
        return "Ditolak";
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.tryParse(dateString);
    if (date == null) return "-";
    return "${date.day}-${date.month}-${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Proses Pengajuan",
                  style: theme.textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Peminjam
            Text("Peminjam", style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(request.userName, style: theme.textTheme.bodyMedium),

            const SizedBox(height: 10),

            // Status
            Text("Status", style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _statusColor(request.status), // solid color
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _statusText(request.status),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white, // teks putih
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Nama Alat
            Text("Nama Alat", style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(request.equipmentName, style: theme.textTheme.bodyMedium),

            const SizedBox(height: 10),

            // Tanggal
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Tanggal Pinjam", style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(_formatDate(request.borrowDate),
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Jatuh Tempo", style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(_formatDate(request.dueDate),
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Tujuan
            Text("Tujuan Peminjaman", style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(request.purpose),
            ),

            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                    ),
                    child: const Text("Setujui"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(color: theme.colorScheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Tolak"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
