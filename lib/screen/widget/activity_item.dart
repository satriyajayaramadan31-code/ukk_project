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

  Color getStatusColor() {
    switch (status) {
      case 'Menunggu':
        return AppTheme.statusPending;
      case 'Dipinjam':
        return AppTheme.statusBorrowed;
      case 'Dikembalikan':
        return AppTheme.statusReturned;
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
            // BAGIAN KIRI
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    item,
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // BAGIAN KANAN
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: getStatusColor(),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: theme.textTheme.bodySmall,
                  ),
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
