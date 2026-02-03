import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widget/app_bar.dart';
import '../widget/side_menu.dart';
import '../widget/detail_pinjam.dart';
import '../widget/pinjam_card.dart';
import '../widget/kembalikan.dart';
import '../utils/theme.dart';
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

    // kalau ada channel lama, hapus dulu biar ga dobel
    await _unsubscribeRealtime();

    // channel dibuat unik biar aman
    final channelName = 'realtime-peminjaman-page-${DateTime.now().millisecondsSinceEpoch}';

    _channel = client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'peminjaman',
          callback: (payload) {
            // debounce supaya ga spam load
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

      // ✅ ambil data sudah difilter sesuai role & userId (peminjam)
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
                      borderSide: BorderSide(color: theme.cardColor),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ===== TABLE =====
                Card(
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daftar Peminjaman',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),

                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 28,
                            headingTextStyle: theme.textTheme.bodyMedium,
                            dataTextStyle: theme.textTheme.bodyMedium,
                            dividerThickness: 0,
                            border: const TableBorder(
                              bottom: BorderSide(color: Colors.black, width: 1),
                              horizontalInside: BorderSide(
                                color: Colors.black,
                                width: 1,
                              ),
                            ),
                            columns: const [
                              DataColumn(label: Text('Nama Alat')),
                              DataColumn(label: Text('Tgl Pinjam')),
                              DataColumn(label: Text('Tgl Kembali')),
                              DataColumn(label: Text('Dikembalikan')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Center(child: Text('Aksi'))),
                            ],
                            rows: _filteredRequests.map((r) {
                              final status = (r['status'] ?? '').toString();

                              return DataRow(
                                cells: [
                                  DataCell(
                                    SizedBox(
                                      width: 180,
                                      child: Text(
                                        (r['nama_alat'] ?? '-').toString(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(_formatDate(r['tanggal_pinjam']))),
                                  DataCell(Text(_formatDate(r['tanggal_kembali']))),
                                  DataCell(Text(_formatDate(r['tanggal_pengembalian']))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _capitalize(status),
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: ElevatedButton(
                                        onPressed: () => _openDialog(r),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme.colorScheme.primary,
                                          textStyle: theme.textTheme.bodyMedium,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          minimumSize: const Size(0, 32),
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
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
