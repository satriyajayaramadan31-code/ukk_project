import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/theme.dart';
import '../widget/app_bar.dart';
import '../widget/side_menu.dart';
import 'package:engine_rent_app/service/supabase_service.dart';

class PemanjanganPage extends StatefulWidget {
  const PemanjanganPage({super.key});

  @override
  State<PemanjanganPage> createState() => _PemanjanganPageState();
}

class _PemanjanganPageState extends State<PemanjanganPage> {
  final TextEditingController _searchController = TextEditingController();

  // controller khusus untuk input tanggal (biar tidak crop & tidak bikin controller baru tiap build)
  final TextEditingController _dateController = TextEditingController();

  int? _expandedIndex;
  DateTime? _selectedDate;

  bool _loading = false;
  List<Map<String, dynamic>> _loans = [];

  @override
  void initState() {
    super.initState();
    _fetchLoans();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  // ===================== FETCH DATA =====================
  Future<void> _fetchLoans() async {
    setState(() => _loading = true);

    try {
      final list = await SupabaseService.fetchPemanjanganLoans();
      setState(() => _loans = list);
    } catch (e) {
      debugPrint('❌ FETCH PEMANJANGAN ERROR: $e');
      setState(() => _loans = []);
    } finally {
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

  void _resetDateField() {
    _selectedDate = null;
    _dateController.text = '';
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
      if (tanggalKembali == null) return;

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

      // pindah ke SupabaseService
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
        _expandedIndex = null;
        _resetDateField();
      });

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
      setState(() => _loading = false);
    }
  }

  // ===================== UI CARD =====================
  Widget _buildCard(Map<String, dynamic> item, ThemeData theme, int index) {
    final expanded = _expandedIndex == index;

    final alat = item['alat'] as Map<String, dynamic>?;
    final namaAlat = alat?['nama_alat']?.toString() ?? '-';

    final tanggalKembali = _parseDate(item['tanggal_kembali']);
    final pengulangan = (item['pengulangan'] ?? 0) as int;
    final maksimal = pengulangan >= 2;

    // ===== border dibuat konsisten untuk semua state =====
    final OutlineInputBorder enabledBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      gapPadding: 0,
      borderSide: BorderSide(
        color: theme.dividerColor,
        width: 1.4, // <-- samakan dengan focused biar tidak kelihatan kepotong
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
      clipBehavior: Clip.antiAlias, // <-- FIX penting agar border tidak ke-crop
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
                        _expandedIndex = expanded ? null : index;
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
                  if (maksimal) Icon(Icons.block, color: AppTheme.statusLate),
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
                  onTap: (tanggalKembali == null) ? null : () => _pickDate(tanggalKembali),
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

                    // === semua border disamakan supaya tidak ada yang "kepotong" ===
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
                      .difference(DateTime(tanggalKembali.year, tanggalKembali.month, tanggalKembali.day))
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
                  child: Text('Ajukan Perpanjangan', style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  )),
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
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Cari alat',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
                    title: Text(nama, style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                    )),
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

            ...List.generate(
              _filteredAktif.length,
              (i) => _buildCard(_filteredAktif[i], theme, i),
            ),
          ],
        ),
      ),
    );
  }
}
