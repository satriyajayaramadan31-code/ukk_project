import 'package:flutter/material.dart';
import '/screen/utils/theme.dart';

class ActivityItem extends StatelessWidget {
  final String item;
  final String status;
  final String time;
  final bool isLast;

  const ActivityItem({
    super.key,
    required this.item,
    required this.status,
    required this.time,
    this.isLast = false,
  });

  /// Normalisasi status dari DB (misal: "menunggu" -> "Menunggu")
  String get normalizedStatus {
    final s = status.trim().toLowerCase();

    switch (s) {
      case 'menunggu':
        return 'Menunggu';
      case 'diproses':
        return 'Diproses';
      case 'dipinjam':
        return 'Dipinjam';
      case 'dikembalikan':
        return 'Dikembalikan';
      case 'terlambat':
        return 'Terlambat';
      case 'ditolak':
        return 'Ditolak';
      default:
        // kapital huruf awal tiap kata
        if (s.isEmpty) return '-';
        return s[0].toUpperCase() + s.substring(1);
    }
  }

  Color getStatusColor() {
    switch (normalizedStatus) {
      case 'Menunggu':
        return AppTheme.statusPending;
      case 'Diproses':
        return AppTheme.statusConfirm; // boleh ganti AppTheme kalau ada
      case 'Dipinjam':
        return AppTheme.statusBorrowed;
      case 'Dikembalikan':
        return AppTheme.statusReturned;
      case 'Terlambat':
        return AppTheme.statusLate;
      case 'Ditolak':
        return AppTheme.statusLate; // pastikan ada di theme.dart
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 6,
              child: Text(
                item,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: getStatusColor(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(time, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
        if (!isLast)
          Divider(
            height: 24,
            color: theme.dividerColor,
          ),
      ],
    );
  }
}