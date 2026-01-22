import 'package:flutter/material.dart';
import '../widget/app_bar.dart';
import '../widget/side_menu.dart';

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

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  Category? _editingCategory;
  List<Category> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _filteredCategories = _categories;
  }

  void _openForm({Category? category}) {
    _editingCategory = category;
    _nameController.text = category?.name ?? '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(category == null ? 'Tambah Kategori' : 'Edit Kategori'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Nama Kategori'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: _saveCategory,
            child: Text(category == null ? 'Tambah' : 'Simpan'),
          ),
        ],
      ),
    );
  }

  void _saveCategory() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      if (_editingCategory != null) {
        _editingCategory!.name = name;
      } else {
        _categories.add(
          Category(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: name,
            totalItems: 0,
          ),
        );
      }

      _filterCategories();
    });

    Navigator.pop(context);
  }

  void _deleteCategory(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: const Text('Yakin ingin menghapus kategori ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _categories.remove(category);
        _filterCategories();
      });
    }
  }

  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = _categories;
      } else {
        _filteredCategories = _categories
            .where((c) => c.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Kategori Alat'),
      drawer: SideMenu(role: 'admin'),

      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          // SEARCH FIELD
          TextField(
            controller: _searchController,
            onChanged: (value) => _filterCategories(),
            decoration: const InputDecoration(
              labelText: 'Search kategori',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 10),

          // TOMBOL TAMBAH DI BAWAH SEARCH
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Kategori'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // TABLE
          Card(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('Nama')),
                  DataColumn(label: Text('Jumlah Alat')),

                  DataColumn(
                    label: SizedBox(
                      width: 140,
                      child: Center(child: Text('Aksi')),
                    ),
                  ),
                ],
                rows: _filteredCategories.map((category) {
                  return DataRow(
                    cells: [
                      DataCell(Text(category.name)),
                      DataCell(Text('${category.totalItems} alat')),

                      DataCell(
                        SizedBox(
                          width: 140,
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _openForm(category: category),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                  onPressed: () => _deleteCategory(category),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
