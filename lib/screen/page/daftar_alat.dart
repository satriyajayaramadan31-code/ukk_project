import 'package:flutter/material.dart';
import '../widget/add_alat.dart';
import '../widget/edit_alat.dart';
import '../widget/app_bar.dart';
import '../widget/side_menu.dart';
import '../utils/models.dart';
import '../widget/delete_alat.dart';
import '../utils/theme.dart'; // <- penting

class DaftarAlatPage extends StatefulWidget {
  const DaftarAlatPage({super.key});

  @override
  State<DaftarAlatPage> createState() => _DaftarAlatPageState();
}

class _DaftarAlatPageState extends State<DaftarAlatPage> {
  final List<String> _categories = [
    'Elektronik',
    'Fotografi',
    'Presentasi',
    'Lainnya',
  ];

  final List<Alat> _alatList = [
    Alat(
      id: "1",
      name: "Laptop Dell XPS 15",
      category: "Elektronik",
      description: "Laptop performa tinggi untuk pengolahan data",
      image:
          "https://images.unsplash.com/photo-1762117666457-919e7345bd90?w=400",
      status: "Tersedia",
    ),
    Alat(
      id: "2",
      name: "Kamera DSLR Canon",
      category: "Fotografi",
      description: "Kamera DSLR profesional untuk dokumentasi",
      image:
          "https://images.unsplash.com/photo-1764557359097-f15dd0c0a17b?w=400",
      status: "Dipinjam",
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  List<Alat> _filteredAlat = [];

  @override
  void initState() {
    super.initState();
    _filteredAlat = _alatList;
  }

  void _filterAlat() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAlat = query.isEmpty
          ? _alatList
          : _alatList.where((a) {
              return a.name.toLowerCase().contains(query) ||
                  a.category.toLowerCase().contains(query);
            }).toList();
    });
  }

  void _addAlat() async {
    final result = await showDialog<Alat>(
      context: context,
      builder: (_) => AddAlatDialog(categories: _categories),
    );

    if (result != null) {
      setState(() {
        _alatList.add(result);
        _filterAlat();
      });
    }
  }

  void _editAlat(Alat alat) async {
    final result = await showDialog<Alat>(
      context: context,
      builder: (_) => EditAlatDialog(
        alat: alat,
        categories: _categories,
      ),
    );

    if (result != null) {
      setState(() {
        final index =
            _alatList.indexWhere((element) => element.id == alat.id);
        _alatList[index] = result;
        _filterAlat();
      });
    }
  }

  void _deleteAlat(Alat alat) {
    setState(() {
      _alatList.remove(alat);
      _filterAlat();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case "Tersedia":
        return AppTheme.statusReturned; // hijau
      case "Dipinjam":
        return AppTheme.statusBorrowed; // abu gelap
      case "Rusak":
        return AppTheme.statusLate;    // merah
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Daftar Alat'),
      drawer: const SideMenu(role: 'admin'),
      body: ListView(
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
                borderSide: BorderSide(color: theme.cardColor),
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
            color: theme.scaffoldBackgroundColor, // <-- warna background list
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daftar Alat',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 32,
                      headingRowColor: MaterialStateProperty.all(theme.scaffoldBackgroundColor),
                      columns: const [
                        DataColumn(label: Text('Nama')),
                        DataColumn(label: Text('Kategori')),
                        DataColumn(label: Text('Deskripsi')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Center(child: Text('Aksi'))),
                      ],
                      rows: _filteredAlat.map((alat) {
                        return DataRow(
                          cells: [
                            DataCell(Text(alat.name)),
                            DataCell(Text(alat.category)),
                            DataCell(
                              SizedBox(
                                width: 220,
                                child: Text(
                                  alat.description,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
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
                            DataCell(
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () => _editAlat(alat),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => DeleteAlatDialog(
                                            alatName: alat.name,
                                            onDelete: () => _deleteAlat(alat),
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
