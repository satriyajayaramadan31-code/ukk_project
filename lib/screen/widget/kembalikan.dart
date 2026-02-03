import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:engine_rent_app/service/supabase_service.dart';

import '../utils/theme.dart';

class KembalikanDialog extends StatefulWidget {
  final Map<String, dynamic> request;
  final VoidCallback onSuccess;

  const KembalikanDialog({
    super.key,
    required this.request,
    required this.onSuccess,
  });

  @override
  State<KembalikanDialog> createState() => _KembalikanDialogState();
}

class _KembalikanDialogState extends State<KembalikanDialog> {
  bool isBroken = false;
  bool loading = false;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  int _calculateLateDays(String dueDate) {
    final due = DateTime.tryParse(dueDate);
    if (due == null) return 0;

    final today = _dateOnly(DateTime.now());
    final dueOnly = _dateOnly(due);

    final diff = today.difference(dueOnly).inDays;
    return diff > 0 ? diff : 0;
  }

  int _getInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? fallback;
  }

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

  int _calculateFineUI({
    required int lateDays,
    required int dendaPerHari,
    required int biayaPerbaikan,
    required bool rusak,
  }) {
    final dendaTerlambat = lateDays * dendaPerHari;
    final dendaRusak = rusak ? biayaPerbaikan : 0;
    return dendaTerlambat + dendaRusak;
  }

  Future<void> _confirmReturn() async {
    try {
      setState(() => loading = true);

      final peminjamanId = widget.request['id'];
      final tanggalKembali = (widget.request['tanggal_kembali'] ?? '').toString();

      if (peminjamanId == null || tanggalKembali.isEmpty) {
        throw Exception("Data tidak lengkap (id / tanggal_kembali null)");
      }

      final lateDays = _calculateLateDays(tanggalKembali);

      // ambil dari alat
      final dendaPerHari = _getInt(widget.request['denda_alat']);
      final perbaikanAlat = _getInt(widget.request['perbaikan_alat']);

      final totalDenda = _calculateFineUI(
        lateDays: lateDays,
        dendaPerHari: dendaPerHari,
        biayaPerbaikan: perbaikanAlat,
        rusak: isBroken,
      );

      await SupabaseService.updatePengembalianUI(
        peminjamanId: int.parse(peminjamanId.toString()),
        rusak: isBroken,
        terlambat: lateDays,
        denda: totalDenda,
      );

      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("❌ Return error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal mengembalikan: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final due = (widget.request['tanggal_kembali'] ?? '').toString();
    final lateDays = _calculateLateDays(due);

    // ambil dari alat
    final dendaPerHari = _getInt(widget.request['denda_alat']);
    final perbaikanAlat = _getInt(widget.request['perbaikan_alat']);

    final fine = _calculateFineUI(
      lateDays: lateDays,
      dendaPerHari: dendaPerHari,
      biayaPerbaikan: perbaikanAlat,
      rusak: isBroken,
    );

    final isLate = lateDays > 0;
    final hasFine = fine > 0;

    // warna highlight selaras theme
    final infoBg = hasFine
        ? scheme.error.withOpacity(0.08)
        : scheme.primary.withOpacity(0.08);

    final infoIconColor = hasFine ? scheme.error : scheme.primary;

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
            Center(
              child: Text(
                "Konfirmasi Pengembalian",
                style: theme.textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 16),

            Text("Nama Alat", style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              (widget.request['nama_alat'] ?? '-').toString(),
              style: theme.textTheme.headlineSmall,
            ),

            const SizedBox(height: 12),

            _infoRow(
              context,
              "Tanggal Pinjam",
              _formatDate((widget.request['tanggal_pinjam'] ?? '').toString()),
            ),
            _infoRow(
              context,
              "Tanggal Kembali",
              _formatDate((widget.request['tanggal_kembali'] ?? '').toString()),
            ),
            _infoRow(
              context,
              "Dikembalikan",
              _formatDate(DateTime.now().toIso8601String()),
            ),
            _infoRow(
              context,
              "Keterlambatan",
              "$lateDays hari",
              valueColor: isLate ? scheme.error : scheme.onSurface,
            ),

            const SizedBox(height: 6),

            // detail perhitungan
            _infoRow(context, "Denda / Hari", _formatCurrency(dendaPerHari)),
            _infoRow(
              context,
              "Biaya Perbaikan",
              _formatCurrency(isBroken ? perbaikanAlat : 0),
            ),
            _infoRow(
              context,
              "Total Denda",
              _formatCurrency(fine),
              valueColor: hasFine ? scheme.error : scheme.onSurface,
            ),

            const SizedBox(height: 16),

            Text(
              "Apakah alat rusak?",
              style: theme.textTheme.bodyMedium,
            ),
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

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: infoBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: infoIconColor.withOpacity(0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasFine ? Icons.error : Icons.check_circle,
                    color: infoIconColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasFine
                          ? "Denda ${_formatCurrency(fine)} akan dikenakan."
                          : "Tidak ada denda.",
                      style: theme.textTheme.bodyMedium
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: loading ? null : _confirmReturn,
                    child: loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Konfirmasi"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: loading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: scheme.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      foregroundColor: scheme.primary,
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

  Widget _infoRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.headlineSmall
          ),
        ],
      ),
    );
  }
}

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

    final borderColor = selected ? scheme.primary : AppTheme.card;
    final bgColor = selected ? scheme.primary.withOpacity(0.08) : Colors.transparent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1.5),
          color: bgColor,
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.headlineSmall
          ),
        ),
      ),
    );
  }
}
