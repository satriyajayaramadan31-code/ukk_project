import 'package:flutter/material.dart';
import '../widget/add_alat.dart';
import '../utils/models.dart';
import '../widget/app_bar.dart';
import '../widget/side_menu.dart';

class DaftarAlatPage extends StatefulWidget {
  const DaftarAlatPage({super.key});

  @override
  State<DaftarAlatPage> createState() => _DaftarAlatPageState();
}

class _DaftarAlatPageState extends State<DaftarAlatPage> {
  List<Alat> daftarAlatList = [
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
    Alat(
      id: "3",
      name: "Proyektor Epson",
      category: "Presentasi",
      description: "Proyektor HD untuk presentasi dan seminar",
      image:
          "https://images.unsplash.com/photo-1761388559873-40bfb05f39e8?w=400",
      status: "Tersedia",
    ),
  ];

  List<Alat> filteredAlatList = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredAlatList = daftarAlatList;
  }

  void handleAdd() async {
    final newAlat = await showDialog<Alat>(
      context: context,
      builder: (context) => const AddAlatDialog(),
    );

    if (newAlat != null) {
      setState(() {
        daftarAlatList.add(newAlat);
        applySearch(searchController.text);
      });
    }
  }

  void handleEdit(Alat alat) async {
    final updatedAlat = await showDialog<Alat>(
      context: context,
      builder: (context) => AddAlatDialog(alat: alat),
    );

    if (updatedAlat != null) {
      setState(() {
        final index =
            daftarAlatList.indexWhere((element) => element.id == alat.id);
        daftarAlatList[index] = updatedAlat;
        applySearch(searchController.text);
      });
    }
  }

  void handleDelete(String id) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Alat"),
        content: const Text("Yakin ingin menghapus alat ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        setState(() {
          daftarAlatList.removeWhere((e) => e.id == id);
          applySearch(searchController.text);
        });
      }
    });
  }

  void applySearch(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) {
      filteredAlatList = daftarAlatList;
    } else {
      filteredAlatList = daftarAlatList.where((alat) {
        final name = alat.name.toLowerCase();
        final category = alat.category.toLowerCase();
        return name.contains(q) || category.contains(q);
      }).toList();
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "Tersedia":
        return Colors.green;
      case "Dipinjam":
        return Colors.grey;
      case "Maintenance":
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Alat'),
      drawer: const SideMenu(role: "admin"),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // HEADER + SEARCH + BUTTON
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        applySearch(value);
                      });
                    },
                    decoration: InputDecoration(
                      hintText: "Cari nama alat atau kategori...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: handleAdd,
                  icon: const Icon(Icons.add),
                  label: const Text("Tambah Alat"),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // TABLE CARD
            Expanded(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text("Nama Alat")),
                        DataColumn(label: Text("Kategori")),
                        DataColumn(label: Text("Deskripsi")),
                        DataColumn(label: Text("Status")),
                        DataColumn(label: Text("Aksi")),
                      ],
                      rows: filteredAlatList.map((alat) {
                        return DataRow(cells: [
                          DataCell(Text(alat.name)),
                          DataCell(Text(alat.category)),
                          DataCell(
                            SizedBox(
                              width: 250,
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
                                color: getStatusColor(alat.status),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                alat.status,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => handleEdit(alat),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => handleDelete(alat.id),
                                ),
                              ],
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
