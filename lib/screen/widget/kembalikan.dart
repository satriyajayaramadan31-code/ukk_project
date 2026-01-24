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
  final TextEditingController brokenNoteController = TextEditingController();

  int _calculateLateDays(String dueDate) {
    final today = DateTime.now();
    final due = DateTime.tryParse(dueDate);
    if (due == null) return 0;

    final diff = today.difference(due).inDays;
    return diff > 0 ? diff : 0;
  }

  int _calculateFine(int lateDays) {
    return lateDays * 10000; // Rp 10.000 per hari
  }

  String _formatDate(String dateString) {
    final date = DateTime.tryParse(dateString);
    if (date == null) return "-";
    return DateFormat.yMMMMd('id').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final lateDays = _calculateLateDays(widget.request.dueDate);
    final fine = _calculateFine(lateDays);
    final isLate = lateDays > 0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Text(
                "Konfirmasi Pengembalian",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),

            const SizedBox(height: 16),

            // ===== INFO ALAT =====
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[200],
                  ),
                  child: const Icon(Icons.devices, size: 34),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.request.equipmentName,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Dipinjam: ${_formatDate(widget.request.borrowDate)}",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ===== DETAIL =====
            _infoRow("Jatuh Tempo", _formatDate(widget.request.dueDate)),
            const Divider(),

            _infoRow(
              "Tanggal Pengembalian",
              _formatDate(DateTime.now().toString()),
            ),
            const Divider(),

            _infoRow(
              "Hari Keterlambatan",
              "$lateDays hari",
              valueColor: isLate ? Colors.red : null,
            ),
            const Divider(),

            _infoRow(
              "Denda",
              "Rp ${fine.toString()}",
              valueColor: isLate ? Colors.red : null,
            ),

            const SizedBox(height: 14),

            // ===== RUSAK YA/TIDAK =====
            Text("Apakah alat rusak?", style: Theme.of(context).textTheme.bodySmall),
            Row(
              children: [
                Radio<bool>(
                  value: false,
                  groupValue: isBroken,
                  onChanged: (v) => setState(() => isBroken = v!),
                ),
                const Text("Tidak"),
                Radio<bool>(
                  value: true,
                  groupValue: isBroken,
                  onChanged: (v) => setState(() => isBroken = v!),
                ),
                const Text("Ya"),
              ],
            ),

            if (isBroken) ...[
              const SizedBox(height: 8),
              Text("Keterangan kerusakan", style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              TextField(
                controller: brokenNoteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Jelaskan kerusakan alat",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            // ===== STATUS ALERT =====
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isLate ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                border: Border.all(
                  color: isLate ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    isLate ? Icons.error : Icons.check_circle,
                    color: isLate ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isLate
                          ? "Terlambat $lateDays hari. Denda ${_formatCurrency(fine)} akan dikenakan."
                          : "Tepat waktu. Tidak ada denda keterlambatan.",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ===== BUTTON =====
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // disini kamu bisa kirim data rusak + keterangan ke backend
                      widget.onReturn();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Konfirmasi Pengembalian"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    final format = NumberFormat.currency(
      locale: "id_ID",
      symbol: "Rp ",
      decimalDigits: 0,
    );
    return format.format(amount);
  }
}
