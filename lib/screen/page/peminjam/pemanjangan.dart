import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utils/theme.dart';
import '../../widget/app_bar.dart';
import '../../widget/side_menu.dart';
import 'package:engine_rent_app/service/supabase_service.dart';

// realtime
import 'package:supabase_flutter/supabase_flutter.dart';

class PemanjanganPage extends StatefulWidget {
  const PemanjanganPage({super.key});

  @override
  State<PemanjanganPage> createState() => _PemanjanganPageState();
}

class _PemanjanganPageState extends State<PemanjanganPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _loading = false;
  List<Map<String, dynamic>> _loans = [];

  // Expand berdasarkan ID agar tidak error saat filter berubah
  int? _expandedLoanId;

  // input tanggal khusus untuk card yang sedang expand
  final TextEditingController _dateController = TextEditingController();
  DateTime? _selectedDate;

  // ===================== REALTIME =====================
  RealtimeChannel? _channel;
  bool _isRealtimeReady = false;

  @override
  void initState() {
    super.initState();
    _fetchLoans();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dateController.dispose();
    _unsubscribeRealtime();
    super.dispose();
  }

  // ===================== REALTIME SUBSCRIBE =====================
  void _subscribeRealtime() {
    try {
      final supabase = Supabase.instance.client;

      // Hindari double subscribe
      _channel?.unsubscribe();

      _channel = supabase.channel('pemanjangan_realtime');

      // LISTEN perubahan tabel peminjaman
      _channel!
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'peminjaman', // <- ganti kalau nama tabel beda
            callback: (payload) async {
              if (!mounted) return;

              // refresh data realtime
              await _fetchLoans();

              // kalau card yang expand sudah tidak ada, tutup
              if (_expandedLoanId != null) {
                final exists = _loans.any((e) => e['id'] == _expandedLoanId);
                if (!exists) {
                  setState(() {
                    _expandedLoanId = null;
                    _resetDateField();
                  });
                }
              }
            },
          )
          .subscribe((status, error) {
            if (!mounted) return;

            if (status == RealtimeSubscribeStatus.subscribed) {
              setState(() => _isRealtimeReady = true);
            }
          });
    } catch (e) {
      debugPrint('❌ REALTIME SUBSCRIBE ERROR: $e');
    }
  }

  Future<void> _unsubscribeRealtime() async {
    try {
      if (_channel != null) {
        await _channel!.unsubscribe();
        _channel = null;
      }
    } catch (e) {
      debugPrint('❌ REALTIME UNSUBSCRIBE ERROR: $e');
    }
  }

  // ===================== FETCH DATA =====================
  Future<void> _fetchLoans() async {
    if (!mounted) return;

    setState(() => _loading = true);

    try {
      final list = await SupabaseService.fetchPemanjanganLoans();
      if (!mounted) return;
      setState(() => _loans = list);
    } catch (e) {
      debugPrint('❌ FETCH PEMANJANGAN ERROR: $e');
      if (!mounted) return;
      setState(() => _loans = []);
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ===================== HELPERS =====================
  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date.toString());
      return DateFormat.yMMMMd('id').format(dt);
    } catch (_) {
      return date.toString();
    }
  }

  DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    try {
      return DateTime.parse(date.toString());
    } catch (_) {
      return null;
    }
  }

  void _resetDateField() {
    _selectedDate = null;
    _dateController.text = '';
  }

  // ===================== FILTER =====================
  List<Map<String, dynamic>> get _filteredAktif {
    final q = _searchController.text.toLowerCase().trim();
    return _loans.where((e) {
      final minta = (e['minta'] ?? false) == true;
      if (minta) return false;

      final alat = e['alat'] as Map<String, dynamic>?;
      final nama = (alat?['nama_alat'] ?? '').toString().toLowerCase();
      return nama.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredProses {
    final q = _searchController.text.toLowerCase().trim();
    return _loans.where((e) {
      final minta = (e['minta'] ?? false) == true;
      if (!minta) return false;

      final alat = e['alat'] as Map<String, dynamic>?;
      final nama = (alat?['nama_alat'] ?? '').toString().toLowerCase();
      return nama.contains(q);
    }).toList();
  }

  // ===================== PICK DATE =====================
  Future<void> _pickDate(DateTime tanggalKembali) async {
    final now = DateTime.now();

    final first = DateTime(tanggalKembali.year, tanggalKembali.month, tanggalKembali.day)
        .add(const Duration(days: 1));

    final initial = first.isAfter(now) ? first : now.add(const Duration(days: 1));

    final result = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: first.add(const Duration(days: 30)),
    );

    if (result != null) {
      setState(() {
        _selectedDate = result;
        _dateController.text = DateFormat.yMMMMd('id').format(result);
      });
    }
  }

  // ===================== SUBMIT EXTENSION =====================
  Future<void> _submitExtension(Map<String, dynamic> item) async {
    try {
      if (_selectedDate == null) return;

      final peminjamanId = item['id'];
      final pengulangan = (item['pengulangan'] ?? 0) as int;

      if (pengulangan >= 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perpanjangan sudah maksimal (2x).')),
        );
        return;
      }

      final tanggalKembali = _parseDate(item['tanggal_kembali']);
      if (tanggalKembali == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tanggal kembali tidak valid.')),
        );
        return;
      }

      final diff = _selectedDate!.difference(
        DateTime(tanggalKembali.year, tanggalKembali.month, tanggalKembali.day),
      ).inDays;

      if (diff <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tanggal perpanjangan harus setelah jatuh tempo.')),
        );
        return;
      }

      setState(() => _loading = true);

      await SupabaseService.requestExtension(
        peminjamanId: peminjamanId,
        tambahHari: diff,
      );

      final alat = item['alat'] as Map<String, dynamic>?;
      final namaAlat = alat?['nama_alat']?.toString() ?? 'Alat';

      await SupabaseService.insertLog(
        description: 'Mengajukan pemanjangan $namaAlat (+$diff hari)',
      );

      setState(() {
        _expandedLoanId = null;
        _resetDateField();
      });

      // Realtime akan update otomatis, tapi fetch manual biar respons cepat
      await _fetchLoans();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permintaan pemanjangan sedang diproses')),
      );
    } catch (e) {
      debugPrint('❌ SUBMIT EXTENSION ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengajukan pemanjangan: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ===================== UI CARD =====================
  Widget _buildCard(Map<String, dynamic> item, ThemeData theme) {
    final int loanId = item['id'] as int;
    final bool expanded = _expandedLoanId == loanId;

    final alat = item['alat'] as Map<String, dynamic>?;
    final namaAlat = alat?['nama_alat']?.toString() ?? '-';

    final tanggalKembali = _parseDate(item['tanggal_kembali']);
    final pengulangan = (item['pengulangan'] ?? 0) as int;
    final maksimal = pengulangan >= 2;

    final OutlineInputBorder enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      gapPadding: 0,
      borderSide: BorderSide(
        color: theme.dividerColor,
        width: 1.4,
      ),
    );

    final OutlineInputBorder focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      gapPadding: 0,
      borderSide: BorderSide(
        color: theme.colorScheme.primary,
        width: 1.4,
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: maksimal
                  ? null
                  : () {
                      setState(() {
                        if (expanded) {
                          _expandedLoanId = null;
                          _resetDateField();
                          return;
                        }

                        _expandedLoanId = loanId;
                        _resetDateField();
                      });
                    },
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          namaAlat,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tanggal Kembali: ${_formatDate(item['tanggal_kembali'])}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Perpanjangan: $pengulangan / 2',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: maksimal ? AppTheme.statusLate : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (maksimal)
                    Icon(Icons.block, color: AppTheme.statusLate)
                  else
                    Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.black54,
                    ),
                ],
              ),
            ),

            if (expanded && !maksimal) ...[
              const Divider(height: 24),
              const Text('Pilih tanggal perpanjangan'),
              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  minLines: 1,
                  maxLines: 1,
                  textAlignVertical: TextAlignVertical.center,
                  onTap: (tanggalKembali == null)
                      ? null
                      : () => _pickDate(tanggalKembali),
                  decoration: InputDecoration(
                    hintText: 'Tanggal perpanjangan',
                    filled: true,
                    fillColor: AppTheme.background,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    suffixIcon: const Icon(Icons.date_range),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    border: enabledBorder,
                    enabledBorder: enabledBorder,
                    disabledBorder: enabledBorder,
                    focusedBorder: focusedBorder,
                    errorBorder: enabledBorder,
                    focusedErrorBorder: focusedBorder,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              if (_selectedDate != null && tanggalKembali != null) ...[
                Builder(builder: (_) {
                  final diff = _selectedDate!
                      .difference(DateTime(
                        tanggalKembali.year,
                        tanggalKembali.month,
                        tanggalKembali.day,
                      ))
                      .inDays;

                  return Text(
                    diff > 0 ? 'Tambah: $diff hari' : 'Tanggal tidak valid',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: diff > 0 ? AppTheme.primary : AppTheme.statusLate,
                    ),
                  );
                }),
                const SizedBox(height: 10),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_selectedDate == null || _loading)
                      ? null
                      : () => _submitExtension(item),
                  child: Text(
                    'Ajukan Perpanjangan',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===================== BUILD =====================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Pemanjangan Peminjaman'),
      backgroundColor: AppTheme.background,
      drawer: const SideMenu(),
      body: RefreshIndicator(
        onRefresh: _fetchLoans,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Cari alat',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Tooltip(
                  message: _isRealtimeReady ? 'Realtime aktif' : 'Realtime belum tersambung',
                  child: Icon(
                    _isRealtimeReady ? Icons.wifi : Icons.wifi_off,
                    color: _isRealtimeReady ? AppTheme.primary : Colors.grey,
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),

            if (_loading) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
            ],

            // ===================== PROSES =====================
            if (_filteredProses.isNotEmpty) ...[
              Text('Meminta Persetujuan', style: theme.textTheme.bodyLarge),
              const SizedBox(height: 8),
              ..._filteredProses.map((e) {
                final alat = e['alat'] as Map<String, dynamic>?;
                final nama = alat?['nama_alat']?.toString() ?? '-';
                final tambah = (e['tambah'] ?? 0).toString();

                return Card(
                  color: AppTheme.statusPending,
                  child: ListTile(
                    leading: const Icon(Icons.hourglass_top),
                    iconColor: Colors.white,
                    title: Text(
                      nama,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      'Menunggu persetujuan petugas (+$tambah Hari)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],

            // ===================== AKTIF =====================
            Text('Peminjaman Aktif', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),

            if (!_loading && _filteredAktif.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Tidak ada peminjaman aktif.'),
              ),

            ..._filteredAktif.map((e) => _buildCard(e, theme)).toList(),
          ],
        ),
      ),
    );
  }
}
