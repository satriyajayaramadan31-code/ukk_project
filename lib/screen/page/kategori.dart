import 'package:flutter/material.dart';
import '../widget/app_bar.dart';
import '../widget/side_menu.dart';
import '../widget/add_category.dart';
import '../widget/edit_category.dart';
import '../widget/delete_category.dart';
import 'package:engine_rent_app/service/supabase_service.dart'; // pastikan ini path benar

class KategoriPage extends StatefulWidget {
  const KategoriPage({super.key});

  @override
  State<KategoriPage> createState() => _KategoriPageState();
}

class _KategoriPageState extends State<KategoriPage> {
  final SupabaseService _service = SupabaseService();

  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _searchController.addListener(_filterCategories);
  }

  Future<void> _fetchCategories() async {
    setState(() => _loading = true);

    try {
      final categories = await _service.getCategories();

      final updated = await Future.wait(categories.map((c) async {
        final count = await _service.countItemsInCategory(c.id);
        return Category(id: c.id, name: c.name, totalItems: count);
      }));

      setState(() {
        _categories = updated;
        _filteredCategories = updated;
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ FETCH CATEGORIES ERROR: $e');
      setState(() => _loading = false);
    }
  }

  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCategories = query.isEmpty
          ? _categories
          : _categories.where((c) => c.name.toLowerCase().contains(query)).toList();
    });
  }

  Future<void> _addCategory(String name) async {
    try {
      final newCat = await _service.addCategory(name);
      final totalItems = await _service.countItemsInCategory(newCat.id);

      setState(() {
        _categories.add(Category(id: newCat.id, name: newCat.name, totalItems: totalItems));
        _filterCategories();
      });
    } catch (e) {
      debugPrint('❌ ADD CATEGORY ERROR: $e');
    }
  }

  Future<void> _editCategory(Category category, String name) async {
    try {
      final edited = await _service.editCategory(category.id, name);
      final totalItems = await _service.countItemsInCategory(edited.id);

      setState(() {
        final index = _categories.indexWhere((c) => c.id == category.id);
        if (index != -1) {
          _categories[index] = Category(id: edited.id, name: edited.name, totalItems: totalItems);
          _filterCategories();
        }
      });
    } catch (e) {
      debugPrint('❌ EDIT CATEGORY ERROR: $e');
    }
  }

  Future<void> _deleteCategory(Category category) async {
    try {
      await _service.deleteCategory(category.id);
      setState(() {
        _categories.removeWhere((c) => c.id == category.id);
        _filterCategories();
      });
    } catch (e) {
      debugPrint('❌ DELETE CATEGORY ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Kategori Alat'),
      drawer: const SideMenu(),
      backgroundColor: theme.colorScheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // ===== SEARCH BAR =====
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Cari kategori',
                    prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(0.4),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ===== ADD BUTTON =====
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Kategori'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AddCategoryDialog(onSubmit: _addCategory),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // ===== DATA TABLE =====
                Card(
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daftar Kategori',
                          style: theme.textTheme.titleMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            dividerThickness: 1,
                            columnSpacing: 30,
                            headingRowColor: MaterialStateProperty.all(theme.colorScheme.surface),
                            border: TableBorder.all(
                              color: Theme.of(context).dividerColor.withOpacity(0.2), // warna garis
                              width: 1, // ketebalan
                            ),
                            columns: [
                              DataColumn(label: Text('Nama', style: theme.textTheme.bodyMedium)),
                              DataColumn(label: Text('Jumlah Alat', style: theme.textTheme.bodyMedium)),
                              DataColumn(label: Center(child: Text('Aksi', style: theme.textTheme.bodyMedium))),
                            ],
                            rows: _filteredCategories.map((c) {
                              return DataRow(cells: [
                                DataCell(Text(c.name, style: theme.textTheme.bodyMedium)),
                                DataCell(Text('${c.totalItems} alat', style: theme.textTheme.bodyMedium)),
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit, size: 18, color: theme.colorScheme.primary),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => EditCategoryDialog(
                                            initialName: c.name,
                                            onSubmit: (name) => _editCategory(c, name),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, size: 18, color: theme.colorScheme.error),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => DeleteCategoryDialog(
                                            categoryName: c.name,
                                            onDelete: () => _deleteCategory(c),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                )),
                              ]);
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
