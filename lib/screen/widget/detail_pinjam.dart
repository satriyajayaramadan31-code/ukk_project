import 'package:flutter/material.dart';
import '../models/loan_request.dart';

class DetailPinjamDialog extends StatelessWidget {
  final LoanRequest request;
  final String statusText;
  final Color statusColor;

  const DetailPinjamDialog({
    super.key,
    required this.request,
    required this.statusText,
    required this.statusColor,
  });

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
            // Header (CENTER)
            Center(
              child: Text(
                "Detail Pengajuan",
                style: theme.textTheme.headlineSmall,
              ),
            ),

            const SizedBox(height: 16),

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
                color: statusColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
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
                Text(_formatDate(request.borrowDate),
                    style: theme.textTheme.bodyMedium),

                const SizedBox(height: 8),

                Text("Tanggal Kembali", style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(_formatDate(request.dueDate),
                    style: theme.textTheme.bodyMedium),

                const SizedBox(height: 8),

                Text("Dikembalikan", style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(_formatDate(request.returnDate),
                    style: theme.textTheme.bodyMedium),
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
                color: theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(request.purpose),
            ),

            const SizedBox(height: 16),

            // Button Tutup
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.colorScheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Tutup"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
