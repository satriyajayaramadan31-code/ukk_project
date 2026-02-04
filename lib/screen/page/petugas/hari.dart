import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/theme.dart';
import '../../widget/app_bar.dart';
import '../../widget/side_menu.dart';
import 'package:engine_rent_app/service/supabase_service.dart';

class HariPage extends StatefulWidget {
  const HariPage({super.key});

  @override
  State<HariPage> createState() => _HariPageState();
}

class _HariPageState extends State<HariPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => _loading = true);
    final data = await SupabaseService.fetchPemanjanganRequestsAdmin();
    if (!mounted) return;
    setState(() {
      _requests = data;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredRequests {
    final q = _searchController.text.toLowerCase().trim();
    if (q.isEmpty) return _requests;

    return _requests.where((e) {
      final alat = (e['alat']?['nama_alat'] ?? '').toString().toLowerCase();
      final peminjam = (e['user']?['username'] ?? '').toString().toLowerCase();
      return alat.contains(q) || peminjam.contains(q);
    }).toList();
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date.toString());
      return DateFormat.yMMMMd('id').format(dt);
    } catch (_) {
      return date.toString();
    }
  }

  Future<void> _handleApprove(dynamic peminjamanId) async {
    try {
      await SupabaseService.approveExtension(peminjamanId: peminjamanId);

      if (!mounted) return;
      await _loadRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menerima: $e')),
      );
    }
  }

  Future<void> _handleReject(dynamic peminjamanId) async {
    try {
      await SupabaseService.rejectExtension(peminjamanId: peminjamanId);

      if (!mounted) return;
      await _loadRequests();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menolak: $e')),
      );
    }
  }

  Future<void> _confirmApprove({
    required String alatNama,
    required String peminjamNama,
    required int tambahHari,
    required dynamic peminjamanId,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConfirmActionDialog(
        title: 'Terima Permintaan',
        message:
            'Setujui pemanjangan untuk "$alatNama" oleh $peminjamNama?\n\nTambah: $tambahHari hari.',
        confirmText: 'Setuju',
        cancelText: 'Batal',
      ),
    );

    if (ok == true) {
      await _handleApprove(peminjamanId);
    }
  }

  Future<void> _confirmReject({
    required String alatNama,
    required String peminjamNama,
    required dynamic peminjamanId,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConfirmActionDialog(
        title: 'Tolak Permintaan',
        message:
            'Tolak permintaan pemanjangan untuk "$alatNama" oleh $peminjamNama?',
        confirmText: 'Tolak',
        cancelText: 'Batal',
      ),
    );

    if (ok == true) {
      await _handleReject(peminjamanId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: const AppBarWithMenu(
        title: 'Permintaan Pemanjangan',
      ),
      drawer: const SideMenu(),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            /// SEARCH
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari alat atau peminjam',
                prefixIcon: const Icon(Icons.search),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor, width: 1.4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (_loading) ...[
              const SizedBox(height: 40),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 40),
            ] else if (_filteredRequests.isEmpty) ...[
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'Tidak ada permintaan pemanjangan',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 40),
            ] else ...[
              /// LIST PERMINTAAN
              ..._filteredRequests.map((item) {
                final alatNama = item['alat']?['nama_alat']?.toString() ?? '-';
                final peminjamNama =
                    item['user']?['username']?.toString() ?? '-';

                final pengulangan = (item['pengulangan'] ?? 0) is int
                    ? (item['pengulangan'] ?? 0)
                    : int.tryParse(item['pengulangan'].toString()) ?? 0;

                final tambahHari = (item['tambah'] ?? 0) is int
                    ? (item['tambah'] ?? 0)
                    : int.tryParse(item['tambah'].toString()) ?? 0;

                final peminjamanId = item['id'];

                // tanggal baru = tanggal_kembali + tambah
                DateTime? tanggalLama;
                DateTime? tanggalBaru;
                try {
                  tanggalLama =
                      DateTime.parse(item['tanggal_kembali'].toString());
                  tanggalBaru = tanggalLama.add(Duration(days: tambahHari));
                } catch (_) {}

                return Card(
                  color: theme.colorScheme.surface,
                  margin: const EdgeInsets.only(bottom: 14),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// HEADER
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                alatNama,
                                style: theme.textTheme.headlineSmall,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.statusPending,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Pemanjangan ke-${pengulangan + 1}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.background,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        /// DETAIL
                        _infoRow('Peminjam', peminjamNama, theme),
                        _infoRow(
                          'Tanggal Kembali',
                          tanggalLama == null
                              ? '-'
                              : _formatDate(tanggalLama.toIso8601String()),
                          theme,
                        ),
                        _infoRow(
                          'Diminta sampai',
                          tanggalBaru == null
                              ? '-'
                              : _formatDate(tanggalBaru.toIso8601String()),
                          theme,
                        ),
                        const SizedBox(height: 18),

                        /// ACTION BUTTON (SETUJU DULU, BARU TOLAK)
                        Row(
                          children: [
                            /// SETUJU
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: theme.colorScheme.onPrimary,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                onPressed: () async {
                                  await _confirmApprove(
                                    alatNama: alatNama,
                                    peminjamNama: peminjamNama,
                                    tambahHari: tambahHari,
                                    peminjamanId: peminjamanId,
                                  );
                                },
                                child: Text(
                                  'Setuju',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            /// TOLAK
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: theme.colorScheme.primary,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: () async {
                                  await _confirmReject(
                                    alatNama: alatNama,
                                    peminjamNama: peminjamNama,
                                    peminjamanId: peminjamanId,
                                  );
                                },
                                child: Text(
                                  'Tolak',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// ===================== DIALOG KOTAK (Konfirmasi) =====================
class ConfirmActionDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;

  const ConfirmActionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
  });

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
              title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                /// CONFIRM
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
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      confirmText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                /// CANCEL
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
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      cancelText,
                      style: const TextStyle(
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