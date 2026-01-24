import 'package:flutter/material.dart';
import '../models/loan_request.dart';

class KonfirmasiPinjamDialog extends StatelessWidget {
  final LoanRequest request;
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  const KonfirmasiPinjamDialog({
    super.key,
    required this.request,
    required this.onConfirm,
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
                Text(
                  "Konfirmasi Peminjaman",
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
                color: _statusColor(request.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _statusText(request.status),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Tanggal Pinjam", style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  _formatDate(request.borrowDate),
                  style: theme.textTheme.bodyMedium,
                ),

                const SizedBox(height: 8),

                Text("Tanggal Kembali", style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  _formatDate(request.dueDate),
                  style: theme.textTheme.bodyMedium,
                ),

                const SizedBox(height: 8),

                Text("Dikembalikan", style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  _formatDate(request.returnDate),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Keterlambatan & Kondisi
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Keterlambatan",
                          style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text("0 hari", style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Kondisi Alat",
                          style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text("Rusak", style: theme.textTheme.bodyMedium),
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
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(request.purpose),
            ),

            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Dikembalikan"),
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
                      side: const BorderSide(color: Color(0xFF374151)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Tolak"),
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
