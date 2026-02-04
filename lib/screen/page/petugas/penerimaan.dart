import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../utils/theme.dart';
import '../../widget/app_bar.dart';
import '../../widget/side_menu.dart';
import '../../widget/pinjam_card.dart';

import '../../widget/detail_pinjam.dart';
import '../../widget/terima_pinjam.dart';
import '../../widget/konfirmasi_pinjam.dart';

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

  // expand state per peminjaman id
  final Set<dynamic> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
    _initRealtime();
    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filter);
    _searchController.dispose();

    _debounceReload?.cancel();
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
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

      // re-apply filter query
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

  Widget _statusBadge({
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
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

  void _toggleExpand(dynamic id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
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

  // ===================== CARD ITEM =====================

  Widget _loanCard(BuildContext context, Map<String, dynamic> row) {
    final theme = Theme.of(context);

    final id = row['id'];
    final isExpanded = _expandedIds.contains(id);

    final peminjam = (row['username'] ?? '-').toString();
    final alat = (row['nama_alat'] ?? '-').toString();

    final statusRaw = (row['status'] ?? '').toString();
    final statusText = _statusText(statusRaw);
    final statusColor = _statusColor(statusRaw);

    final alasan = (row['alasan'] ?? '-').toString();

    final btnText = statusRaw.toLowerCase() == 'menunggu'
        ? "Proses"
        : statusRaw.toLowerCase() == 'diproses'
            ? "Konfirmasi"
            : "Detail";

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _toggleExpand(id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== HEADER: Peminjam kiri | Status kanan
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      peminjam,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _statusBadge(text: statusText, color: statusColor),
                ],
              ),

              const SizedBox(height: 10),

              // ===== Nama alat
              Text(
                alat,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isExpanded ? "Tutup detail" : "Lihat detail",
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: isExpanded ? 0.5 : 0.0,
                      child: Icon(
                        Icons.expand_more,
                        size: 24,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),

              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(
                        height: 18,
                        thickness: 1,
                        color: theme.dividerColor.withOpacity(0.12),
                      ),

                      _infoRow(
                        context,
                        icon: Icons.notes_outlined,
                        label: "Alasan",
                        value: alasan,
                      ),
                      _infoRow(
                        context,
                        icon: Icons.calendar_month_outlined,
                        label: "Tgl Pinjam",
                        value: _formatDate(row['tanggal_pinjam']),
                      ),
                      _infoRow(
                        context,
                        icon: Icons.event_outlined,
                        label: "Tgl Kembali",
                        value: _formatDate(row['tanggal_kembali']),
                      ),
                      _infoRow(
                        context,
                        icon: Icons.assignment_turned_in_outlined,
                        label: "Dikembalikan",
                        value: _formatDate(row['tanggal_pengembalian']),
                      ),

                      const SizedBox(height: 6),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _openDialog(row),
                          style: ElevatedButton.styleFrom(
                            textStyle: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            minimumSize: const Size(0, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(btnText),
                        ),
                      ),
                    ],
                  ),
                ),
                crossFadeState:
                    isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== BUILD =====================

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

          // ===== LIST CARD =====
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
            ..._filtered.map((r) => _loanCard(context, r)),
        ],
      ),
    );
  }
}
