import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widget/app_bar.dart';
import '../widget/side_menu.dart';
import '../widget/add_peminjaman.dart';
import '../widget/edit_peminjaman.dart';
import '../widget/delete_peminjaman.dart';
import '../widget/pinjam_card.dart';
import '../utils/theme.dart';
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

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
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

  // =================== REALTIME (FIX) ===================
  void _setupRealtime() {
    final client = Supabase.instance.client;

    // pastikan ga double subscribe
    if (_channel != null) {
      client.removeChannel(_channel!);
      _channel = null;
    }

    // channel name disarankan pakai schema:table biar aman
    _channel = client.channel('public:peminjaman');

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'peminjaman',
          callback: (payload) async {
            debugPrint('🔥 REALTIME PEMINJAMAN: ${payload.eventType}');
            debugPrint('payload.newRecord = ${payload.newRecord}');
            debugPrint('payload.oldRecord = ${payload.oldRecord}');

            // cara paling aman: fetch ulang
            await _fetchLoans();
          },
        )
        .subscribe((status, error) async {
      debugPrint('📡 Realtime subscribe status: $status');
      if (error != null) debugPrint('❌ Realtime error: $error');

      // kalau baru subscribe, refresh 1x
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
      // realtime akan update otomatis
    } catch (e) {
      debugPrint('❌ DELETE LOAN ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal hapus peminjaman: $e')),
      );
    }
  }

  Widget _statusBadge({
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white),
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

                Row(
                  children: [
                    Expanded(
                      flex: 7,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => _filterLoans(),
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
                            headingRowColor: WidgetStatePropertyAll(
                              theme.scaffoldBackgroundColor,
                            ),
                            headingTextStyle: theme.textTheme.bodyMedium,
                            dataTextStyle: theme.textTheme.bodyMedium,
                            dividerThickness: 0,
                            border: const TableBorder(
                              bottom: BorderSide(
                                color: Colors.black,
                                width: 1,
                              ),
                              horizontalInside: BorderSide(
                                color: Colors.black,
                                width: 1,
                              ),
                            ),
                            columns: const [
                              DataColumn(label: Text('Peminjam')),
                              DataColumn(label: Text('Nama Alat')),
                              DataColumn(label: Text("Alasan/Deskripsi")),
                              DataColumn(label: Text('Tgl Pinjam')),
                              DataColumn(label: Text('Tgl Kembali')),
                              DataColumn(label: Text('Pengembalian')),
                              DataColumn(label: Text('Terlambat')),
                              DataColumn(label: Text('Kondisi')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Center(child: Text('Aksi'))),
                            ],
                            rows: _filteredLoans.map((loan) {
                              final status =
                                  (loan['status'] ?? '').toString().toLowerCase();

                              final terlambat =
                                  int.tryParse((loan['terlambat'] ?? 0).toString()) ??
                                      0;

                              final rusak = (loan['rusak'] == true);

                              return DataRow(
                                cells: [
                                  DataCell(Text((loan['username'] ?? '-').toString())),
                                  DataCell(
                                    SizedBox(
                                      width: 160,
                                      child: Text(
                                        (loan['nama_alat'] ?? '-').toString(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        softWrap: false,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 200,
                                      child: Text(
                                        (loan['alasan'] ?? '-').toString(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(formatDate(loan['tanggal_pinjam']))),
                                  DataCell(Text(formatDate(loan['tanggal_kembali']))),
                                  DataCell(Text(formatDate(loan['tanggal_pengembalian']))),
                                  DataCell(
                                    Text(
                                      terlambat != 0
                                          ? '$terlambat hari'
                                          : (status == 'dikembalikan' ? '0' : '-'),
                                    ),
                                  ),
                                  DataCell(Text(rusak ? 'Rusak' : 'Baik')),
                                  DataCell(
                                    _statusBadge(
                                      text: statusText(loan['status']),
                                      color: statusColor(loan['status']),
                                    ),
                                  ),
                                  DataCell(
                                    Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 18),
                                            onPressed: () async {
                                              showDialog(
                                                context: context,
                                                builder: (_) => EditPeminjamanDialog(
                                                  loan: loan,
                                                  onEdit: (_) async {},
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              size: 18,
                                              color: Colors.red,
                                            ),
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (_) => DeletePeminjamanDialog(
                                                  equipmentName:
                                                      (loan['nama_alat'] ?? '-')
                                                          .toString(),
                                                  userName:
                                                      (loan['username'] ?? '-')
                                                          .toString(),
                                                  onDelete: () => _handleDelete(loan),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
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
