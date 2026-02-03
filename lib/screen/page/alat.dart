import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widget/app_bar.dart';
import '../widget/side_menu.dart';
import '../utils/theme.dart';
import '../widget/borrow_request.dart';
import 'package:engine_rent_app/service/supabase_service.dart';

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

  factory Equipment.fromAlat(Alat a) {
    return Equipment(
      id: a.id,
      name: a.namaAlat,
      category: a.kategoriNama,
      image: a.fotoUrl,
      status: a.status,
    );
  }
}

class AlatPage extends StatefulWidget {
  const AlatPage({super.key});

  @override
  State<AlatPage> createState() => _AlatPageState();
}

class _AlatPageState extends State<AlatPage> {
  String searchTerm = "";
  bool isLoading = true;

  final SupabaseService service = SupabaseService();
  List<Equipment> equipmentList = [];

  RealtimeChannel? _alatChannel;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadAlat();
    _setupRealtime();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (_alatChannel != null) {
      Supabase.instance.client.removeChannel(_alatChannel!);
    }
    super.dispose();
  }

  void _setupRealtime() {
    final supabase = Supabase.instance.client;

    _alatChannel = supabase.channel('realtime-alat');

    _alatChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'alat',
          callback: (payload) {
            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(milliseconds: 250), () async {
              await _loadAlat(showLoading: false);
            });
          },
        )
        .subscribe();
  }

  Future<void> _loadAlat({bool showLoading = true}) async {
    if (showLoading) {
      setState(() => isLoading = true);
    }

    final alatList = await service.getAlat();
    final mapped = alatList.map((a) => Equipment.fromAlat(a)).toList();

    if (!mounted) return;
    setState(() {
      equipmentList = mapped;
      isLoading = false;
    });
  }

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
      case "Rusak":
        return AppTheme.statusLate;
      default:
        return Colors.grey;
    }
  }

  int getColumnCount(double width) {
    if (width < 500) return 1;
    if (width < 900) return 2;
    return 3;
  }

  /// SOLUSI 2: tinggi card fix.
  /// Dibuat lebih tinggi supaya Row status+tombol tidak ketutup.
  double getCardHeight(double width) {
    if (width < 500) return 420; // 1 kolom (mobile)
    if (width < 900) return 400; // 2 kolom
    return 390; // 3 kolom
  }

  Widget _buildImage(String url) {
    if (url.isEmpty) {
      return const Center(child: Icon(Icons.image_not_supported));
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) {
        return const Center(child: Icon(Icons.broken_image));
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
    );
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
            TextField(
              onChanged: (value) => setState(() => searchTerm = value),
              decoration: const InputDecoration(
                hintText: "Cari alat atau kategori...",
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () => _loadAlat(showLoading: false),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = getColumnCount(constraints.maxWidth);
                          final cardHeight = getCardHeight(constraints.maxWidth);

                          if (filteredEquipment.isEmpty) {
                            return ListView(
                              children: const [
                                SizedBox(height: 80),
                                Center(child: Text("Data alat tidak ditemukan")),
                              ],
                            );
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              mainAxisExtent: cardHeight,
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
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AspectRatio(
                                      aspectRatio: 4 / 3,
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: AppTheme.card,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: _buildImage(item.image),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // 🔥 ini penting: Expanded biar bagian bawah pasti kebagian ruang
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              item.category,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),

                                            const Spacer(), // dorong tombol ke bawah

                                            Row(
                                              children: [
                                                // STATUS
                                                SizedBox(
                                                  height: 36,
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 12,
                                                    ),
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      color: getStatusColor(
                                                          item.status),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: Text(
                                                      item.status,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const Spacer(),

                                                // PINJAM
                                                SizedBox(
                                                  height: 36,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 14,
                                                      ),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                    ),
                                                    onPressed:
                                                        item.status == "Tersedia"
                                                            ? () {
                                                                showDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (context) {
                                                                    return BorrowRequest(
                                                                      equipment:
                                                                          item,
                                                                      onSubmit:
                                                                          () async {
                                                                        await _loadAlat(
                                                                            showLoading:
                                                                                false);
                                                                      },
                                                                    );
                                                                  },
                                                                );
                                                              }
                                                            : null,
                                                    child: const Text("Pinjam"),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
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
            ),
          ],
        ),
      ),
    );
  }
}
