import 'package:flutter/material.dart';
import '../widget/app_bar.dart';
import '../widget/side_menu.dart';
import '../utils/theme.dart';
import '../widget/borrow_request.dart';

class Equipment {
  final String id;
  final String name;
  final String category;
  final String image;
  final String status;

  Equipment({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    required this.status,
  });
}

class AlatPage extends StatefulWidget {
  const AlatPage({super.key});

  @override
  State<AlatPage> createState() => _AlatPageState();
}

class _AlatPageState extends State<AlatPage> {
  String searchTerm = "";

  final List<Equipment> equipmentList = [
    Equipment(
      id: "1",
      name: "Laptop Dell XPS 15",
      category: "Elektronik",
      image:
          "https://images.unsplash.com/photo-1762117666457-919e7345bd90?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxsYXB0b3AlMjBjb21wdXRlciUyMGRldmljZXxlbnwxfHx8fDE3Njc5MTkwNzh8MA&ixlib=rb-4.1.0&q=80&w=1080",
      status: "Tersedia",
    ),
    Equipment(
      id: "2",
      name: "Kamera DSLR Canon",
      category: "Fotografi",
      image:
          "https://images.unsplash.com/photo-1764557359097-f15dd0c0a17b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjYW1lcmElMjBwaG90b2dyYXBoeSUyMGVxdWlwbWVudHxlbnwxfHx8fDE3Njc4MzY2Mjh8MA&ixlib=rb-4.1.0&q=80&w=1080",
      status: "Tersedia",
    ),
    Equipment(
      id: "3",
      name: "Proyektor Epson",
      category: "Presentasi",
      image:
          "https://images.unsplash.com/photo-1761388559873-40bfb05f39e8?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwcm9qZWN0b3IlMjBwcmVzZW50YXRpb24lMjBlcXVpcG1lbnR8ZW58MXx8fHwxNzY3OTE5MDc4fDA&ixlib=rb-4.1.0&q=80&w=1080",
      status: "Dipinjam",
    ),
    Equipment(
      id: "4",
      name: "Bor Listrik Bosch",
      category: "Perkakas",
      image:
          "https://images.unsplash.com/photo-1593307315564-c96172dc89dc?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwb3dlciUyMGRyaWxsJTIwdG9vbHxlbnwxfHx8fDE3Njc5MTAwOTN8MA&ixlib=rb-4.1.0&q=80&w=1080",
      status: "Tersedia",
    ),
    Equipment(
      id: "5",
      name: "Meteran Laser Digital",
      category: "Perkakas",
      image:
          "https://images.unsplash.com/photo-1651004926916-b4e92f4df1ca?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtZWFzdXJpbmclMjB0YXBlJTIwdG9vbHN8ZW58MXx8fHwxNzY3OTE2MzAwfDA&ixlib=rb-4.1.0&q=80&w=1080",
      status: "Tersedia",
    ),
    Equipment(
      id: "6",
      name: "Mikrofon Wireless Shure",
      category: "Audio",
      image:
          "https://images.unsplash.com/photo-1764557206659-1def036068ef?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtaWNyb3Bob25lJTIwYXVkaW8lMjBlcXVpcG1lbnR8ZW58MXx8fHwxNzY3OTE5MDc5fDA&ixlib=rb-4.1.0&q=80&w=1080",
      status: "Maintenance",
    ),
  ];

  List<Equipment> get filteredEquipment {
    if (searchTerm.isEmpty) return equipmentList;

    return equipmentList.where((item) {
      final term = searchTerm.toLowerCase();
      return item.name.toLowerCase().contains(term) ||
          item.category.toLowerCase().contains(term);
    }).toList();
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "Tersedia":
        return AppTheme.statusReturned;
      case "Dipinjam":
        return AppTheme.statusBorrowed;
      case "Maintenance":
        return AppTheme.statusPending;
      default:
        return Colors.grey;
    }
  }

  int getColumnCount(double width) {
    if (width < 500) return 1;
    if (width < 900) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Daftar Alat'),
      backgroundColor: theme.colorScheme.background,
      drawer: const SideMenu(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search
            TextField(
              onChanged: (value) {
                setState(() {
                  searchTerm = value;
                });
              },
              decoration: const InputDecoration(
                hintText: "Cari alat atau kategori...",
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),

            // Grid Alat (Responsive)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = getColumnCount(constraints.maxWidth);

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      childAspectRatio: 0.82,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: filteredEquipment.length,
                    itemBuilder: (context, index) {
                      final item = filteredEquipment[index];

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: AppTheme.card,
                            width: 1.2,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias, // biar rounded rapi
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ====== IMAGE WITH BORDER ======
                            AspectRatio(
                              aspectRatio: 4 / 3,
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.card,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      item.image,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.category,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: getStatusColor(item.status),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          item.status,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),

                                      // ========== PINJAM BUTTON ==========
                                      ElevatedButton(
                                        onPressed: item.status == "Tersedia"
                                            ? () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return BorrowRequest(
                                                      equipment: item,
                                                      onSubmit: () {},
                                                    );
                                                  },
                                                );
                                              }
                                            : null,
                                        child: const Text("Pinjam"),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
