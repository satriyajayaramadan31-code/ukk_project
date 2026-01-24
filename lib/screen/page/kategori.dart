import 'package:flutter/material.dart';
import '../widget/app_bar.dart';
import '../widget/side_menu.dart';
import '../widget/add_category.dart';
import '../widget/edit_category.dart';
import '../widget/delete_category.dart';

class Category {
  final String id;
  String name;
  int totalItems;

  Category({
    required this.id,
    required this.name,
    required this.totalItems,
  });
}

class KategoriPage extends StatefulWidget {
  const KategoriPage({super.key});

  @override
  State<KategoriPage> createState() => _KategoriPageState();
}

class _KategoriPageState extends State<KategoriPage> {
  final List<Category> _categories = [
    Category(id: '1', name: 'Elektronik', totalItems: 12),
    Category(id: '2', name: 'Perkakas', totalItems: 8),
    Category(id: '3', name: 'Fotografi', totalItems: 6),
    Category(id: '4', name: 'Audio', totalItems: 5),
    Category(id: '5', name: 'Presentasi', totalItems: 4),
  ];

  final TextEditingController _searchController = TextEditingController();
  List<Category> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _filteredCategories = _categories;
  }

  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCategories = query.isEmpty
          ? _categories
          : _categories
              .where((c) => c.name.toLowerCase().contains(query))
              .toList();
    });
  }

  void _addCategory(String name) {
    setState(() {
      _categories.add(
        Category(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name,
          totalItems: 0,
        ),
      );
      _filterCategories();
    });
  }

  void _editCategory(Category category, String name) {
    setState(() {
      category.name = name;
      _filterCategories();
    });
  }

  void _deleteCategory(Category category) {
    setState(() {
      _categories.remove(category);
      _filterCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Kategori Alat'),
      drawer: const SideMenu(role: 'admin'),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ===== SEARCH BAR =====
          TextField(
            controller: _searchController,
            onChanged: (_) => _filterCategories(),
            decoration: InputDecoration(
              labelText: 'Cari kategori',
              prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.4),
                ),
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
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AddCategoryDialog(
                    onSubmit: _addCategory,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // ===== DATA TABLE CARD =====
          Card(
            color: theme.colorScheme.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daftar Kategori',
                    style: theme.textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 30,
                      headingRowColor: MaterialStateProperty.all(
                        theme.colorScheme.background,
                      ),
                      columns: [
                        DataColumn(
                          label: Text(
                            'Nama',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Jumlah Alat',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        DataColumn(
                          label: Center(
                            child: Text(
                              'Aksi',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      ],
                      rows: _filteredCategories.map((category) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                category.name,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            DataCell(
                              Text(
                                '${category.totalItems} alat',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            DataCell(
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        size: 18,
                                        color: theme.colorScheme.primary,
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => EditCategoryDialog(
                                            initialName: category.name,
                                            onSubmit: (name) =>
                                                _editCategory(category, name),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: theme.colorScheme.error,
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => DeleteCategoryDialog(
                                            categoryName: category.name,
                                            onDelete: () =>
                                                _deleteCategory(category),
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
