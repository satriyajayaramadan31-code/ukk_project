import 'package:flutter/material.dart';
import '../../widget/app_bar.dart';
import '../../widget/side_menu.dart';
import '../../widget/add_category.dart';
import '../../widget/edit_category.dart';
import '../../widget/delete_category.dart';
import 'package:engine_rent_app/service/supabase_service.dart';
import 'package:engine_rent_app/models/kategori_alat.dart';

class KategoriPage extends StatefulWidget {
  const KategoriPage({super.key});

  @override
  State<KategoriPage> createState() => _KategoriPageState();
}

class _KategoriPageState extends State<KategoriPage> {
  final SupabaseService _service = SupabaseService();

  List<KategoriAlat> _categories = [];
  List<KategoriAlat> _filteredCategories = [];
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;

  // id kategori String
  final Set<String> _expandedCategoryIds = {};

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

      final updated = await Future.wait(
        categories.map((c) async {
          final count = await _service.countItemsInCategory(c.id);
          return KategoriAlat(id: c.id, name: c.name, totalItems: count);
        }),
      );

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
          : _categories
                .where((c) => c.name.toLowerCase().contains(query))
                .toList();
    });
  }

  Future<void> _addCategory(String name) async {
    try {
      final newCat = await _service.addCategory(name);
      final totalItems = await _service.countItemsInCategory(newCat.id);

      setState(() {
        _categories.add(
          KategoriAlat(
            id: newCat.id,
            name: newCat.name,
            totalItems: totalItems,
          ),
        );
        _filterCategories();
      });
    } catch (e) {
      debugPrint('❌ ADD CATEGORY ERROR: $e');
    }
  }

  Future<void> _editCategory(KategoriAlat category, String name) async {
    try {
      final edited = await _service.editCategory(category.id, name);
      final totalItems = await _service.countItemsInCategory(edited.id);

      setState(() {
        final index = _categories.indexWhere((c) => c.id == category.id);
        if (index != -1) {
          _categories[index] = KategoriAlat(
            id: edited.id,
            name: edited.name,
            totalItems: totalItems,
          );
          _filterCategories();
        }
      });
    } catch (e) {
      debugPrint('❌ EDIT CATEGORY ERROR: $e');
    }
  }

  Future<void> _deleteCategory(KategoriAlat category) async {
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

  void _toggleExpand(String categoryId) {
    setState(() {
      if (_expandedCategoryIds.contains(categoryId)) {
        _expandedCategoryIds.remove(categoryId);
      } else {
        _expandedCategoryIds.add(categoryId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ===== UI: Badge Jumlah Alat =====
  Widget _countBadge(BuildContext context, int total) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$total alat',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ===== UI: Card Kategori =====
  Widget _categoryCard(BuildContext context, KategoriAlat c) {
    final theme = Theme.of(context);
    final isExpanded = _expandedCategoryIds.contains(c.id);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black, width: 1.5),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _toggleExpand(c.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // ===== HEADER =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // name
                  Expanded(
                    child: Text(
                      c.name,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // badge + arrow
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _countBadge(context, c.totalItems),
                      const SizedBox(height: 6),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 180),
                        turns: isExpanded ? 0.5 : 0.0,
                        child: Icon(
                          Icons.expand_more,
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // ===== EXPAND =====
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: [
                      Divider(
                        height: 18,
                        thickness: 1,
                        color: theme.dividerColor.withOpacity(0.12),
                      ),

                      // action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 1.5,
                                ),
                                foregroundColor: theme.colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
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
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.delete),
                              label: const Text('Hapus'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
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
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 180),
              ),
            ],
          ),
        ),
      ),
    );
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
              padding: const EdgeInsets.all(14),
              children: [
                // SEARCH + ADD (SEBARIS)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Cari kategori',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              width: 1.5
                            ), // tebal border
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              width: 1.5,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Kategori'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) =>
                              AddCategoryDialog(onSubmit: _addCategory),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                if (_filteredCategories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Center(
                      child: Text(
                        'Kategori tidak ditemukan.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  )
                else
                  ..._filteredCategories.map((c) => _categoryCard(context, c)),
              ],
            ),
    );
  }
}
