import 'package:flutter/material.dart';
import '../widget/add_alat.dart';
import '../widget/edit_alat.dart';
import '../widget/delete_alat.dart';
import '../widget/app_bar.dart';
import '../widget/side_menu.dart';
import '../utils/theme.dart';
import 'package:engine_rent_app/service/supabase_service.dart';

class DaftarAlatPage extends StatefulWidget {
  const DaftarAlatPage({super.key});

  @override
  State<DaftarAlatPage> createState() => _DaftarAlatPageState();
}

class _DaftarAlatPageState extends State<DaftarAlatPage> {
  final SupabaseService _service = SupabaseService();

  List<Category> _categories = [];
  List<Alat> _alatList = [];
  List<Alat> _filteredAlat = [];

  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;

  bool _dialogOpen = false; // 🔥 prevent double open dialog

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_filterAlat);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    try {
      final cats = await _service.getCategories();
      final alat = await _service.getAlat();

      if (!mounted) return;
      setState(() {
        _categories = cats;
        _alatList = alat;
        _filteredAlat = alat;
      });
    } catch (e) {
      debugPrint('❌ Gagal load data alat: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filterAlat() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredAlat = query.isEmpty
          ? List.from(_alatList)
          : _alatList.where((a) {
              return a.namaAlat.toLowerCase().contains(query) ||
                  a.kategoriNama.toLowerCase().contains(query);
            }).toList();
    });
  }

  // ================= ADD =================
  Future<void> _addAlat() async {
    if (_dialogOpen) return;
    setState(() => _dialogOpen = true);

    try {
      final result = await showDialog<Alat>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AddAlatDialog(categories: _categories),
      );

      if (!mounted) return;

      if (result != null) {
        final exists = _alatList.any((a) => a.id == result.id);
        if (!exists) {
          setState(() {
            _alatList.insert(0, result);
          });
          _filterAlat();
        }
      }
    } catch (e) {
      debugPrint('❌ Gagal tambah alat: $e');
    } finally {
      if (mounted) setState(() => _dialogOpen = false);
    }
  }

  // ================= EDIT =================
  Future<void> _editAlat(Alat alat) async {
    if (_dialogOpen) return;
    setState(() => _dialogOpen = true);

    try {
      final result = await showDialog<Alat>(
        context: context,
        barrierDismissible: false,
        builder: (_) => EditAlatDialog(alat: alat, categories: _categories),
      );

      if (!mounted) return;

      if (result != null) {
        setState(() {
          final idx = _alatList.indexWhere((a) => a.id == result.id);
          if (idx != -1) _alatList[idx] = result;
        });
        _filterAlat();
      }
    } catch (e) {
      debugPrint('❌ Gagal edit alat: $e');
    } finally {
      if (mounted) setState(() => _dialogOpen = false);
    }
  }

  // ================= DELETE =================
  Future<void> _deleteAlat(Alat alat) async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      await _service.deleteAlat(alat.id, fotoUrl: alat.fotoUrl);

      if (!mounted) return;

      setState(() {
        _alatList.removeWhere((a) => a.id == alat.id);
      });
      _filterAlat();
    } catch (e) {
      debugPrint('❌ Gagal hapus alat: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case "Tersedia":
        return AppTheme.statusReturned;
      case "Dipinjam":
        return AppTheme.statusBorrowed;
      case "Rusak":
        return AppTheme.statusLate;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Daftar Alat'),
      drawer: const SideMenu(),
      backgroundColor: theme.colorScheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(10),
              children: [
                // SEARCH
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search alat',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ADD BUTTON
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Alat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.all(10),
                    ),
                    onPressed: (_dialogOpen) ? null : _addAlat,
                  ),
                ),

                const SizedBox(height: 10),

                // TABLE CARD
                Card(
                  color: theme.colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ JUDUL (seperti halaman lain)
                        Text(
                          'Daftar Alat',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 10),

                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 20,
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
                              DataColumn(label: Text('Nama')),
                              DataColumn(label: Text('Kategori')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Denda')),
                              DataColumn(label: Text('Perbaikan')),
                              DataColumn(label: Center(child: Text('Aksi'))),
                            ],
                            rows: _filteredAlat.map((alat) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    SizedBox(
                                      width: 180,
                                      child: Text(
                                        alat.namaAlat,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        alat.kategoriNama,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusColor(alat.status),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        alat.status,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text('Rp ${alat.denda}')),
                                  DataCell(Text('Rp ${alat.perbaikan}')),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 18),
                                          onPressed: _dialogOpen
                                              ? null
                                              : () => _editAlat(alat),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            size: 18,
                                            color: Colors.red,
                                          ),
                                          onPressed: _dialogOpen
                                              ? null
                                              : () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (_) => DeleteAlatDialog(
                                                      alatName: alat.namaAlat,
                                                      onDelete: () => _deleteAlat(alat),
                                                    ),
                                                  );
                                                },
                                        ),
                                      ],
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
