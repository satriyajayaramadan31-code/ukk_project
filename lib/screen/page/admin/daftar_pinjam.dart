import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widget/app_bar.dart';
import '../../widget/side_menu.dart';
import '../../widget/add_peminjaman.dart';
import '../../widget/edit_peminjaman.dart';
import '../../widget/delete_peminjaman.dart';
import '../../widget/pinjam_card.dart';
import '../../utils/theme.dart';
import 'package:engine_rent_app/service/supabase_service.dart';

class DaftarPinjam extends StatefulWidget {
  const DaftarPinjam({super.key});

  @override
  State<DaftarPinjam> createState() => _DaftarPinjamState();
}

class _DaftarPinjamState extends State<DaftarPinjam> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _loans = [];
  List<Map<String, dynamic>> _filteredLoans = [];

  bool _loading = true;
  String? _role;

  RealtimeChannel? _channel;

  // expand state per peminjaman id
  final Set<dynamic> _expandedLoanIds = {};

  @override
  void initState() {
    super.initState();
    _init();
    _searchController.addListener(_filterLoans);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterLoans);
    _searchController.dispose();

    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
      _channel = null;
    }

    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _loading = true);

    _role = await SupabaseService.getRole() ?? 'Admin';
    await _fetchLoans();

    _setupRealtime(); // start realtime

    if (!mounted) return;
    setState(() => _loading = false);
  }

  // =================== REALTIME ===================
  void _setupRealtime() {
    final client = Supabase.instance.client;

    // pastikan ga double subscribe
    if (_channel != null) {
      client.removeChannel(_channel!);
      _channel = null;
    }

    _channel = client.channel('public:peminjaman');

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'peminjaman',
          callback: (payload) async {
            debugPrint('🔥 REALTIME PEMINJAMAN: ${payload.eventType}');
            await _fetchLoans();
          },
        )
        .subscribe((status, error) async {
      debugPrint('📡 Realtime subscribe status: $status');
      if (error != null) debugPrint('❌ Realtime error: $error');

      if (status == RealtimeSubscribeStatus.subscribed) {
        await _fetchLoans();
      }
    });
  }

  Future<void> _fetchLoans() async {
    try {
      final data = await SupabaseService.getPeminjaman(role: _role ?? 'Admin');

      if (!mounted) return;
      setState(() {
        _loans = data;
        _filteredLoans = data;
      });

      _filterLoans();
    } catch (e) {
      debugPrint('❌ FETCH PEMINJAMAN ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data peminjaman: $e')),
      );
    }
  }

  void _filterLoans() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLoans = query.isEmpty
          ? _loans
          : _loans.where((l) {
              final user = (l['username'] ?? '').toString().toLowerCase();
              final alat = (l['nama_alat'] ?? '').toString().toLowerCase();
              return user.contains(query) || alat.contains(query);
            }).toList();
    });
  }

  String formatDate(dynamic dateValue) {
    if (dateValue == null) return "-";
    final str = dateValue.toString();
    if (str.isEmpty) return "-";

    final dt = DateTime.tryParse(str);
    if (dt == null) return "-";
    return DateFormat.yMMMMd('id').format(dt);
  }

  // ===== status text capitalize =====
  String statusText(dynamic status) {
    if (status == null) return '-';

    final s = status.toString().trim();
    if (s.isEmpty) return '-';

    final lower = s.toLowerCase();
    switch (lower) {
      case 'menunggu':
        return 'Menunggu';
      case 'dipinjam':
        return 'Dipinjam';
      case 'dikembalikan':
        return 'Dikembalikan';
      case 'terlambat':
        return 'Terlambat';
      case 'ditolak':
        return 'Ditolak';
      case 'diproses':
        return 'Diproses';
      default:
        return lower[0].toUpperCase() + lower.substring(1);
    }
  }

  Color statusColor(dynamic status) {
    final s = (status ?? '').toString().toLowerCase();

    switch (s) {
      case 'menunggu':
        return AppTheme.statusPending;
      case 'dipinjam':
        return AppTheme.statusBorrowed;
      case 'dikembalikan':
        return AppTheme.statusReturned;
      case 'terlambat':
        return AppTheme.statusLate;
      case 'ditolak':
        return AppTheme.statusLate;
      case 'diproses':
        return AppTheme.statusConfirm;
      default:
        return Colors.grey;
    }
  }

  // =================== COUNT ===================
  int _countStatus(String status) {
    final target = status.toLowerCase();
    return _loans.where((l) {
      final s = (l['status'] ?? '').toString().toLowerCase();
      return s == target;
    }).length;
  }

  int _countOverdue() {
    return _loans.where((l) {
      final terlambat = int.tryParse((l['terlambat'] ?? 0).toString()) ?? 0;
      return terlambat != 0;
    }).length;
  }

  int _countDiproses() {
    return _loans.where((l) {
      final s = (l['status'] ?? '').toString().toLowerCase();
      return s == 'diproses';
    }).length;
  }

  Future<void> _handleDelete(Map<String, dynamic> loan) async {
    try {
      await SupabaseService.deletePeminjaman(id: loan['id']);
      // realtime update otomatis
    } catch (e) {
      debugPrint('❌ DELETE LOAN ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal hapus peminjaman: $e')),
      );
    }
  }

  void _toggleExpand(dynamic id) {
    setState(() {
      if (_expandedLoanIds.contains(id)) {
        _expandedLoanIds.remove(id);
      } else {
        _expandedLoanIds.add(id);
      }
    });
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

  // =================== UI: CARD PEMINJAMAN ===================
  Widget _loanCard(BuildContext context, Map<String, dynamic> loan) {
    final theme = Theme.of(context);

    final id = loan['id'];
    final isExpanded = _expandedLoanIds.contains(id);

    final peminjam = (loan['username'] ?? '-').toString();
    final alat = (loan['nama_alat'] ?? '-').toString();

    final statusRaw = (loan['status'] ?? '').toString();
    final status = statusText(statusRaw);
    final statusBg = statusColor(statusRaw);

    final alasan = (loan['alasan'] ?? '-').toString();

    final terlambat = int.tryParse((loan['terlambat'] ?? 0).toString()) ?? 0;
    final statusLower = statusRaw.toLowerCase();
    final terlambatText =
        terlambat != 0 ? '$terlambat hari' : (statusLower == 'dikembalikan' ? '0' : '-');

    final rusak = (loan['rusak'] == true);

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
              // ===== HEADER: Peminjam (kiri) | Status (kanan)
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
                  _statusBadge(text: status, color: statusBg),
                ],
              ),

              const SizedBox(height: 10),

              // ===== Nama alat di bawah
              Text(
                alat,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              // ===== Expand indicator
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

              // ===== EXPAND CONTENT
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
                        value: formatDate(loan['tanggal_pinjam']),
                      ),
                      _infoRow(
                        context,
                        icon: Icons.event_outlined,
                        label: "Tgl Kembali",
                        value: formatDate(loan['tanggal_kembali']),
                      ),
                      _infoRow(
                        context,
                        icon: Icons.assignment_turned_in_outlined,
                        label: "Pengembalian",
                        value: formatDate(loan['tanggal_pengembalian']),
                      ),
                      _infoRow(
                        context,
                        icon: Icons.timelapse_outlined,
                        label: "Terlambat",
                        value: terlambatText,
                      ),
                      _infoRow(
                        context,
                        icon: Icons.build_circle_outlined,
                        label: "Kondisi",
                        value: rusak ? "Rusak" : "Baik",
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: theme.colorScheme.primary.withOpacity(0.35),
                                ),
                                foregroundColor: theme.colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () async {
                                showDialog(
                                  context: context,
                                  builder: (_) => EditPeminjamanDialog(
                                    loan: loan,
                                    onEdit: (updated) {},
                                    parentContext: context,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.delete),
                              label: const Text('Hapus'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => DeletePeminjamanDialog(
                                    equipmentName: alat,
                                    userName: peminjam,
                                    onDelete: () => _handleDelete(loan),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final pendingCount = _countStatus('menunggu');
    final borrowedCount = _countStatus('dipinjam');
    final returnedCount = _countStatus('dikembalikan');
    final lateCount = _countOverdue();
    final processCount = _countDiproses();

    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Daftar Peminjaman'),
      backgroundColor: theme.colorScheme.background,
      drawer: const SideMenu(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(14),
              children: [
                // ===== SUMMARY CARDS =====
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
                      width: (MediaQuery.of(context).size.width - 42) / 2,
                      child: PinjamCard(
                        title: 'Terlambat',
                        value: lateCount.toString(),
                        color: AppTheme.statusLate,
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 28,
                      child: PinjamCard(
                        title: 'Konfirmasi',
                        value: processCount.toString(),
                        color: AppTheme.statusConfirm,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ===== SEARCH + ADD =====
                Row(
                  children: [
                    Expanded(
                      flex: 7,
                      child: TextField(
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () async {
                          showDialog(
                            context: context,
                            builder: (_) => AddPeminjamanDialog(
                              parentContext: context,
                              onAdd: (_) async {},
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ===== LIST CARD =====
                if (_filteredLoans.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Center(
                      child: Text(
                        'Data peminjaman tidak ditemukan.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  )
                else
                  ..._filteredLoans.map((loan) => _loanCard(context, loan)),
              ],
            ),
    );
  }
}
