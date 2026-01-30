import 'package:flutter/material.dart';
import '../utils/theme.dart';

class DeletePeminjamanDialog extends StatelessWidget {
  final String equipmentName;
  final String userName;

  // IMPORTANT: harus async supaya bisa await delete supabase
  final Future<void> Function() onDelete;

  const DeletePeminjamanDialog({
    super.key,
    required this.equipmentName,
    required this.userName,
    required this.onDelete,
  });

  void _showPopup({
    required NavigatorState nav,
    required IconData icon,
    required String text,
    required Color color,
  }) {
    showDialog(
      context: nav.context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      if (nav.canPop()) nav.pop();
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Icon(icon, size: 72, color: color),
                const SizedBox(height: 16),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (nav.canPop()) nav.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: AppTheme.background,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Hapus Peminjaman',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              'Yakin ingin menghapus peminjaman "$equipmentName" milik "$userName"?',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                // HAPUS
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final nav = Navigator.of(context);

                      // tutup dialog konfirmasi dulu
                      nav.pop();

                      try {
                        await onDelete();

                        _showPopup(
                          nav: nav,
                          icon: Icons.check_circle,
                          text: 'Peminjaman Berhasil\nDihapus',
                          color: Colors.green,
                        );
                      } catch (e) {
                        _showPopup(
                          nav: nav,
                          icon: Icons.error,
                          text: 'Gagal menghapus peminjaman',
                          color: Colors.red,
                        );
                      }
                    },
                    child: Text(
                      'Hapus',
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // BATAL
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Batal',
                      style: theme.textTheme.bodyMedium!.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
