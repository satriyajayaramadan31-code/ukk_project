import 'package:flutter/material.dart';
import '../models/loan_request.dart';
import 'package:intl/intl.dart';

class KembalikanDialog extends StatefulWidget {
  final LoanRequest request;
  final VoidCallback onReturn;

  const KembalikanDialog({
    super.key,
    required this.request,
    required this.onReturn,
  });

  @override
  State<KembalikanDialog> createState() => _KembalikanDialogState();
}

class _KembalikanDialogState extends State<KembalikanDialog> {
  bool isBroken = false;

  int _calculateLateDays(String dueDate) {
    final today = DateTime.now();
    final due = DateTime.tryParse(dueDate);
    if (due == null) return 0;

    final diff = today.difference(due).inDays;
    return diff > 0 ? diff : 0;
  }

  int _calculateFine(int lateDays) => lateDays * 10000;

  String _formatDate(String dateString) {
    final date = DateTime.tryParse(dateString);
    if (date == null) return "-";
    return DateFormat.yMMMMd('id').format(date);
  }

  String _formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: "id_ID",
      symbol: "Rp ",
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final lateDays = _calculateLateDays(widget.request.dueDate);
    final fine = _calculateFine(lateDays);
    final isLate = lateDays > 0;

    return Dialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ===== TITLE =====
            Center(
              child: Text(
                "Konfirmasi Pengembalian",
                style: theme.textTheme.headlineSmall,
              ),
            ),

            const SizedBox(height: 16),

            /// ===== INFO ALAT =====
            Text("Nama Alat", style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              widget.request.equipmentName,
              style: theme.textTheme.bodyMedium,
            ),

            const SizedBox(height: 12),

            _infoRow("Tanggal Pinjam",
                _formatDate(widget.request.borrowDate)),
            _infoRow("Tanggal Kembali",
                _formatDate(widget.request.dueDate)),
            _infoRow("Dikembalikan",
                _formatDate(DateTime.now().toString())),
            _infoRow(
              "Keterlambatan",
              "$lateDays hari",
              valueColor: isLate ? scheme.error : null,
            ),
            _infoRow(
              "Denda",
              _formatCurrency(fine),
              valueColor: isLate ? scheme.error : null,
            ),

            const SizedBox(height: 16),

            /// ===== KONDISI ALAT =====
            Text("Apakah alat rusak?",
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _SelectBox(
                    label: "Tidak",
                    selected: !isBroken,
                    onTap: () => setState(() => isBroken = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SelectBox(
                    label: "Ya",
                    selected: isBroken,
                    onTap: () => setState(() => isBroken = true),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// ===== ALERT STATUS =====
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLate
                    ? scheme.error.withOpacity(0.08)
                    : Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isLate ? Icons.error : Icons.check_circle,
                    color: isLate ? scheme.error : Colors.green,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isLate
                          ? "Terlambat $lateDays hari. Denda ${_formatCurrency(fine)} dikenakan."
                          : "Pengembalian tepat waktu. Tidak ada denda.",
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            /// ===== BUTTON =====
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onReturn();
                      Navigator.pop(context);
                    },
                    child: const Text("Konfirmasi"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: scheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Batal"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// ===== SELECT BOX (YA / TIDAK) =====
class _SelectBox extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectBox({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? scheme.primary : Colors.grey.shade300,
            width: 1.5,
          ),
          color: selected
              ? scheme.primary.withOpacity(0.08)
              : Colors.transparent,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? scheme.primary : scheme.onBackground,
            ),
          ),
        ),
      ),
    );
  }
}
