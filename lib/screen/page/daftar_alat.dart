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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final cats = await _service.getCategories();
      final alat = await _service.getAlat();
      setState(() {
        _categories = cats;
        _alatList = alat;
        _filteredAlat = alat;
      });
    } catch (e) {
      debugPrint('❌ Gagal load data alat: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _filterAlat() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAlat = query.isEmpty
          ? _alatList
          : _alatList.where((a) {
              return a.namaAlat.toLowerCase().contains(query) ||
                  a.kategoriNama.toLowerCase().contains(query);
            }).toList();
    });
  }

  Future<void> _addAlat() async {
    final result = await showDialog<Alat>(
      context: context,
      builder: (_) => AddAlatDialog(categories: _categories),
    );

    if (result != null) {
      setState(() => _loading = true);
      try {
        String imageUrl = result.fotoUrl;

        // Hanya untuk Web: jika foto ada, upload
        if (result.bytes != null) {
          imageUrl = await SupabaseService.uploadFoto(result.bytes!, result.namaAlat);
        }

        final alat = await _service.addAlat(
          namaAlat: result.namaAlat,
          status: result.status,
          kategoriId: result.kategoriId,
          denda: result.denda,
          perbaikan: result.perbaikan,
        );

        await _service.editAlat(
          id: alat.id,
          namaAlat: alat.namaAlat,
          status: alat.status,
          kategoriId: alat.kategoriId,
          image: imageUrl,
          denda: alat.denda,
          perbaikan: alat.perbaikan,
        );

        await _loadData();
      } catch (e) {
        debugPrint('❌ Gagal tambah alat: $e');
      }
    }
  }

  Future<void> _editAlat(Alat alat) async {
    final result = await showDialog<Alat>(
      context: context,
      builder: (_) => EditAlatDialog(alat: alat, categories: _categories),
    );

    if (result != null) {
      setState(() => _loading = true);
      try {
        String imageUrl = result.fotoUrl;

        // Hanya untuk Web: jika bytes baru ada, upload
        if (result.bytes != null) {
          if (alat.fotoUrl.isNotEmpty) {
            await _service.deleteFoto(alat.fotoUrl);
          }
          imageUrl = await SupabaseService.uploadFoto(result.bytes!, result.namaAlat);
        }

        await _service.editAlat(
          id: result.id,
          namaAlat: result.namaAlat,
          status: result.status,
          kategoriId: result.kategoriId,
          image: imageUrl,
          denda: result.denda,
          perbaikan: result.perbaikan,
        );

        await _loadData();
      } catch (e) {
        debugPrint('❌ Gagal edit alat: $e');
      }
    }
  }

  Future<void> _deleteAlat(Alat alat) async {
    setState(() => _loading = true);
    try {
      await _service.deleteAlat(alat.id, fotoUrl: alat.fotoUrl);
      await _loadData();
    } catch (e) {
      debugPrint('❌ Gagal hapus alat: $e');
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
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _filterAlat(),
                  decoration: InputDecoration(
                    labelText: 'Search alat',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
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
                    onPressed: _addAlat,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  color: theme.scaffoldBackgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20,
                        headingRowColor:
                            MaterialStateProperty.all(theme.scaffoldBackgroundColor),
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
                              DataCell(SizedBox(
                                  width: 180,
                                  child: Text(
                                    alat.namaAlat,
                                    overflow: TextOverflow.ellipsis,
                                  ))),
                              DataCell(SizedBox(
                                  width: 120,
                                  child: Text(
                                    alat.kategoriNama,
                                    overflow: TextOverflow.ellipsis,
                                  ))),
                              DataCell(Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _statusColor(alat.status),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  alat.status,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(color: Colors.white),
                                ),
                              )),
                              DataCell(Text('Rp ${alat.denda}')),
                              DataCell(Text('Rp ${alat.perbaikan}')),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    onPressed: () => _editAlat(alat),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        size: 18, color: Colors.red),
                                    onPressed: () {
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
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
