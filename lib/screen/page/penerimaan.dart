import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/theme.dart';
import '../widget/app_bar.dart';
import '../widget/side_menu.dart';
import '../widget/pinjam_card.dart';

import '../widget/detail_pinjam.dart';
import '../widget/terima_pinjam.dart';
import '../widget/konfirmasi_pinjam.dart';

import 'package:engine_rent_app/service/supabase_service.dart';

class PenerimaanPage extends StatefulWidget {
  const PenerimaanPage({super.key});

  @override
  State<PenerimaanPage> createState() => _PenerimaanPageState();
}

class _PenerimaanPageState extends State<PenerimaanPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];

  RealtimeChannel? _channel;
  Timer? _debounceReload;
  bool _isReloading = false;

  @override
  void initState() {
    super.initState();
    _load();
    _initRealtime();
    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _searchController.dispose();

    _debounceReload?.cancel();
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
    }

    super.dispose();
  }

  // ===================== LOAD DATA =====================

  Future<void> _load({bool showLoading = true}) async {
    if (_isReloading) return;
    _isReloading = true;

    if (showLoading) setState(() => _loading = true);

    try {
      final role = (await SupabaseService.getRole()) ?? 'Peminjam';
      final data = await SupabaseService.getPeminjaman(role: role);

      if (!mounted) return;
      setState(() {
        _all = data;
        _loading = false;
      });

      // re-apply filter query (biar search tetap jalan walau data berubah)
      _filter();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal load peminjaman: $e')),
      );
    } finally {
      _isReloading = false;
    }
  }

  // ===================== REALTIME =====================

  void _initRealtime() {
    final supabase = Supabase.instance.client;

    _channel = supabase
        .channel('realtime-peminjaman')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'peminjaman',
          callback: (payload) {
            // Debounce supaya tidak spam _load() kalau banyak event
            _debounceReload?.cancel();
            _debounceReload = Timer(const Duration(milliseconds: 300), () {
              if (mounted) _load(showLoading: false);
            });
          },
        )
        .subscribe();
  }

  // ===================== FILTER =====================

  void _filter() {
    final q = _searchController.text.trim().toLowerCase();

    if (!mounted) return;

    setState(() {
      if (q.isEmpty) {
        _filtered = List.from(_all);
      } else {
        _filtered = _all.where((e) {
          final username = (e['username'] ?? '').toString().toLowerCase();
          final namaAlat = (e['nama_alat'] ?? '').toString().toLowerCase();
          final status = (e['status'] ?? '').toString().toLowerCase();
          return username.contains(q) ||
              namaAlat.contains(q) ||
              status.contains(q);
        }).toList();
      }
    });
  }

  // ===================== UI HELPERS =====================

  String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu':
        return 'Menunggu';
      case 'diproses':
        return 'Diproses';
      case 'dipinjam':
        return 'Dipinjam';
      case 'dikembalikan':
        return 'Dikembalikan';
      case 'ditolak':
        return 'Ditolak';
      default:
        return status;
    }
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

  String _formatDate(dynamic value) {
    if (value == null) return "-";
    final s = value.toString();
    if (s.isEmpty) return "-";
    final dt = DateTime.tryParse(s);
    if (dt == null) return "-";
    return DateFormat.yMMMMd('id').format(dt);
  }

  // ===================== ACTION =====================

  Future<void> _openDialog(Map<String, dynamic> row) async {
    final status = (row['status'] ?? '').toString().toLowerCase();

    if (status == 'menunggu') {
      showDialog(
        context: context,
        builder: (_) => TerimaPinjamDialog(
          request: row,
          onApprove: () async {
            await SupabaseService.editPeminjaman(
              id: row['id'],
              userId: row['user_id'],
              alatId: row['alat_id'],
              tanggalPinjam: row['tanggal_pinjam'] ?? '',
              tanggalKembali: row['tanggal_kembali'] ?? '',
              tanggalPengembalian: row['tanggal_pengembalian'],
              alasan: row['alasan'] ?? '',
              status: 'dipinjam',
            );
            if (mounted) Navigator.pop(context);
            // tidak perlu refresh manual, realtime akan update otomatis
          },
          onReject: () async {
            await SupabaseService.editPeminjaman(
              id: row['id'],
              userId: row['user_id'],
              alatId: row['alat_id'],
              tanggalPinjam: row['tanggal_pinjam'] ?? '',
              tanggalKembali: row['tanggal_kembali'] ?? '',
              tanggalPengembalian: row['tanggal_pengembalian'],
              alasan: row['alasan'] ?? '',
              status: 'ditolak',
            );
            if (mounted) Navigator.pop(context);
          },
        ),
      );
      return;
    }

    if (status == 'diproses') {
      showDialog(
        context: context,
        builder: (_) => KonfirmasiPinjamDialog(
          request: row,
          onConfirm: () async {
            final now = DateTime.now().toIso8601String();

            await SupabaseService.editPeminjaman(
              id: row['id'],
              userId: row['user_id'],
              alatId: row['alat_id'],
              tanggalPinjam: row['tanggal_pinjam'] ?? '',
              tanggalKembali: row['tanggal_kembali'] ?? '',
              tanggalPengembalian: now,
              alasan: row['alasan'] ?? '',
              status: 'dikembalikan',
              rusak: row['rusak'] ?? false,
            );

            if (mounted) Navigator.pop(context);
          },
          onReject: () async {
            await SupabaseService.editPeminjaman(
              id: row['id'],
              userId: row['user_id'],
              alatId: row['alat_id'],
              tanggalPinjam: row['tanggal_pinjam'] ?? '',
              tanggalKembali: row['tanggal_kembali'] ?? '',
              tanggalPengembalian: row['tanggal_pengembalian'],
              alasan: row['alasan'] ?? '',
              status: 'dipinjam',
              rusak: false,
            );

            if (mounted) Navigator.pop(context);
          },
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => DetailPinjamDialog(
        request: row,
        statusText: _statusText(status),
        statusColor: _statusColor(status),
      ),
    );
  }

  // ===================== COUNT =====================

  int _countStatus(String status) => _all
      .where((e) => (e['status'] ?? '').toString().toLowerCase() == status)
      .length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final pendingCount = _countStatus('menunggu');
    final inProcessCount = _countStatus('diproses');
    final borrowedCount = _countStatus('dipinjam');
    final returnedCount = _countStatus('dikembalikan');
    final rejectedCount = _countStatus('ditolak');

    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Managemen Peminjaman'),
      backgroundColor: theme.colorScheme.background,
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
                  value: inProcessCount.toString(),
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

          // ===== DATA TABLE =====
          Card(
            color: theme.scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daftar Peminjaman',
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 12),

                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Data peminjaman kosong.'),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 28,
                        headingRowColor: WidgetStatePropertyAll(
                            theme.scaffoldBackgroundColor),
                        headingTextStyle: theme.textTheme.bodyMedium,
                        dataTextStyle: theme.textTheme.bodyMedium,
                        dividerThickness: 0,
                        border: const TableBorder(
                          bottom: BorderSide(color: Colors.black, width: 1),
                          horizontalInside:
                              BorderSide(color: Colors.black, width: 1),
                        ),
                        columns: const [
                          DataColumn(label: Text('Peminjam')),
                          DataColumn(label: Text('Nama Alat')),
                          DataColumn(label: Text('Tgl Pinjam')),
                          DataColumn(label: Text('Tgl Kembali')),
                          DataColumn(label: Text('Dikembalikan')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Center(child: Text('Aksi'))),
                        ],
                        rows: _filtered.map((r) {
                          final status = (r['status'] ?? '').toString();
                          final statusText = _statusText(status);

                          return DataRow(
                            cells: [
                              DataCell(Text((r['username'] ?? '-').toString())),
                              DataCell(Text((r['nama_alat'] ?? '-').toString())),
                              DataCell(Text(_formatDate(r['tanggal_pinjam']))),
                              DataCell(Text(_formatDate(r['tanggal_kembali']))),
                              DataCell(Text(_formatDate(
                                  r['tanggal_pengembalian']))),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    statusText,
                                    style:
                                        theme.textTheme.bodyMedium?.copyWith(
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
                                      textStyle: theme.textTheme.bodyMedium,
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      minimumSize: const Size(0, 32),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: Text(
                                      status.toLowerCase() == 'menunggu'
                                          ? "Proses"
                                          : status.toLowerCase() == 'diproses'
                                              ? "Konfirmasi"
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
