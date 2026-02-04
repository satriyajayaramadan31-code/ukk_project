import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widget/app_bar.dart';
import '../../widget/side_menu.dart';
import '../../widget/detail_pinjam.dart';
import '../../widget/pinjam_card.dart';
import '../../widget/kembalikan.dart';
import '../../utils/theme.dart';
import 'package:engine_rent_app/service/supabase_service.dart';

class PeminjamanPage extends StatefulWidget {
  const PeminjamanPage({super.key});

  @override
  State<PeminjamanPage> createState() => _PeminjamanPageState();
}

class _PeminjamanPageState extends State<PeminjamanPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;

  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _filteredRequests = [];

  RealtimeChannel? _channel;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _listenRealtime();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _unsubscribeRealtime();
    super.dispose();
  }

  // ================= REALTIME =================

  Future<void> _listenRealtime() async {
    final client = Supabase.instance.client;

    await _unsubscribeRealtime();

    final channelName =
        'realtime-peminjaman-page-${DateTime.now().millisecondsSinceEpoch}';

    _channel = client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'peminjaman',
          callback: (payload) {
            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
              if (!mounted) return;
              await _load(silent: true);
            });
          },
        )
        .subscribe((status, error) {
          debugPrint("📡 Realtime status: $status");
          if (error != null) debugPrint("❌ Realtime error: $error");
        });
  }

  Future<void> _unsubscribeRealtime() async {
    try {
      if (_channel != null) {
        await Supabase.instance.client.removeChannel(_channel!);
        _channel = null;
      }
    } catch (e) {
      debugPrint("❌ Unsubscribe realtime error: $e");
    }
  }

  // ================= LOAD DATA =================

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);

    try {
      final role = await SupabaseService.getRole() ?? 'Peminjam';
      final data = await SupabaseService.getPeminjaman(role: role);

      if (!mounted) return;

      setState(() {
        _requests = data;
        _applyFilter();
      });
    } catch (e) {
      debugPrint("❌ Load peminjaman error: $e");
    } finally {
      if (!silent && mounted) setState(() => _loading = false);
      if (silent && mounted && _loading) setState(() => _loading = false);
    }
  }

  // ================= FILTER =================

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();

    _filteredRequests = query.isEmpty
        ? List.from(_requests)
        : _requests.where((r) {
            final username = (r['username'] ?? '').toString().toLowerCase();
            final namaAlat = (r['nama_alat'] ?? '').toString().toLowerCase();
            final status = (r['status'] ?? '').toString().toLowerCase();
            return username.contains(query) ||
                namaAlat.contains(query) ||
                status.contains(query);
          }).toList();
  }

  void _filterRequests() {
    setState(() => _applyFilter());
  }

  // ================= UI HELPERS =================

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu':
        return AppTheme.statusPending;
      case 'diproses':
        return AppTheme.statusConfirm;
      case 'dipinjam':
        return AppTheme.statusBorrowed;
      case 'dikembalikan':
        return AppTheme.statusReturned;
      case 'ditolak':
        return AppTheme.statusLate;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null) return "-";
    final s = dateString.toString();
    if (s.isEmpty) return "-";
    final date = DateTime.tryParse(s);
    if (date == null) return "-";
    return DateFormat.yMMMMd('id').format(date);
  }

  int _countStatus(String status) =>
      _requests.where((r) => (r['status'] ?? '') == status).length;

  Future<void> _openDialog(Map<String, dynamic> request) async {
    final status = (request['status'] ?? '').toString();

    if (status.toLowerCase() == 'dipinjam') {
      showDialog(
        context: context,
        builder: (_) => KembalikanDialog(
          request: request,
          onSuccess: () async {
            await _load(silent: true);
          },
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => DetailPinjamDialog(
          request: request,
          statusText: status,
          statusColor: _statusColor(status),
        ),
      );
    }
  }

  // ================= WIDGET HELPERS =================

  Widget _infoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
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

  Widget _statusBadge(String status, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _statusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _capitalize(status),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final pendingCount = _countStatus('menunggu');
    final confirmCount = _countStatus('diproses');
    final borrowedCount = _countStatus('dipinjam');
    final returnedCount = _countStatus('dikembalikan');
    final rejectedCount = _countStatus('ditolak');

    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Peminjaman Saya'),
      drawer: const SideMenu(),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // ===== STATUS GRID =====
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              SizedBox(
                width: (MediaQuery.of(context).size.width - 42) / 2,
                child: PinjamCard(
                  title: 'Menunggu',
                  value: pendingCount.toString(),
                  color: AppTheme.statusPending,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 42) / 2,
                child: PinjamCard(
                  title: 'Diproses',
                  value: confirmCount.toString(),
                  color: AppTheme.statusConfirm,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 42) / 2,
                child: PinjamCard(
                  title: 'Dipinjam',
                  value: borrowedCount.toString(),
                  color: AppTheme.statusBorrowed,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 42) / 2,
                child: PinjamCard(
                  title: 'Dikembalikan',
                  value: returnedCount.toString(),
                  color: AppTheme.statusReturned,
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width - 28,
                child: PinjamCard(
                  title: 'Ditolak',
                  value: rejectedCount.toString(),
                  color: AppTheme.statusLate,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ===== SEARCH =====
          TextField(
            controller: _searchController,
            onChanged: (_) => _filterRequests(),
            decoration: InputDecoration(
              labelText: 'Cari peminjaman',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ===== TITLE SECTION =====
          _sectionTitle("Daftar Peminjaman", theme),

          // ===== CONTENT =====
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredRequests.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Data peminjaman kosong.',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredRequests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final r = _filteredRequests[index];

                final status = (r['status'] ?? '-').toString().trim();
                final namaAlat = (r['nama_alat'] ?? '-').toString();
                final tglKembali = _formatDate(r['tanggal_kembali']);

                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.7),
                      width: 1,
                    ),
                  ),
                  child: Theme(
                    // HILANGKAN efek focus/hover/expand bawaan ExpansionTile
                    data: theme.copyWith(
                      dividerColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      // Hilangkan border bawaan expanded/collapsed
                      shape: const RoundedRectangleBorder(
                        side: BorderSide(color: Colors.transparent, width: 0),
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                      collapsedShape: const RoundedRectangleBorder(
                        side: BorderSide(color: Colors.transparent, width: 0),
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),

                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),

                      // ===== HEADER =====
                      title: Text(
                        namaAlat,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      // Tanggal kembali dulu, status di bawahnya
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Kembali: $tglKembali",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _statusBadge(status, theme),
                          ],
                        ),
                      ),

                      // ===== EXPAND CONTENT =====
                      children: [
                        const SizedBox(height: 10),
                        _infoRow(
                          "Tanggal Pinjam",
                          _formatDate(r['tanggal_pinjam']),
                          theme,
                        ),
                        _infoRow(
                          "Tanggal Kembali",
                          _formatDate(r['tanggal_kembali']),
                          theme,
                        ),
                        _infoRow(
                          "Tanggal Pengembalian",
                          _formatDate(r['tanggal_pengembalian']),
                          theme,
                        ),
                        _infoRow(
                          "Alasan",
                          (r['alasan'] ?? '-').toString(),
                          theme,
                        ),
                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () => _openDialog(r),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              textStyle: theme.textTheme.bodyMedium,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              minimumSize: const Size(0, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              status.toLowerCase() == 'dipinjam'
                                  ? "Kembalikan"
                                  : "Detail",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
