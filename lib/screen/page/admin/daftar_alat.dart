import 'package:flutter/material.dart';
import '../../widget/add_alat.dart';
import '../../widget/edit_alat.dart';
import '../../widget/delete_alat.dart';
import '../../widget/app_bar.dart';
import '../../widget/side_menu.dart';
import '../../utils/theme.dart';
import 'package:engine_rent_app/service/supabase_service.dart';

import 'package:engine_rent_app/models/kategori_alat.dart';
import 'package:engine_rent_app/models/alat.dart';

class DaftarAlatPage extends StatefulWidget {
  const DaftarAlatPage({super.key});

  @override
  State<DaftarAlatPage> createState() => _DaftarAlatPageState();
}

class _DaftarAlatPageState extends State<DaftarAlatPage> {
  final SupabaseService _service = SupabaseService();

  List<KategoriAlat> _categories = [];
  List<Alat> _alatList = [];
  List<Alat> _filteredAlat = [];

  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  bool _dialogOpen = false;

  // expand state per alat id
  final Set<dynamic> _expandedAlatIds = {};

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
        _expandedAlatIds.remove(alat.id);
      });
      _filterAlat();
    } catch (e) {
      debugPrint('❌ Gagal hapus alat: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleExpand(dynamic alatId) {
    setState(() {
      if (_expandedAlatIds.contains(alatId)) {
        _expandedAlatIds.remove(alatId);
      } else {
        _expandedAlatIds.add(alatId);
      }
    });
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

  Widget _statusBadge(BuildContext context, String status) {
    final theme = Theme.of(context);
    final bg = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: theme.textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ===== UI: Card alat (FIXED layout) =====
  Widget _alatCard(BuildContext context, Alat alat) {
    final theme = Theme.of(context);
    final isExpanded = _expandedAlatIds.contains(alat.id);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withOpacity(0.12)),
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
        onTap: () => _toggleExpand(alat.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== HEADER (nama + icon expand)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT: nama + status (VERTIKAL FIX)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alat.namaAlat,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _statusBadge(context, alat.status),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // RIGHT: expand icon
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: isExpanded ? 0.5 : 0.0,
                    child: Icon(
                      Icons.expand_more,
                      size: 26,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.75),
                    ),
                  ),
                ],
              ),

              // ===== EXPANDED CONTENT
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(
                        height: 18,
                        thickness: 1,
                        color: theme.dividerColor.withOpacity(0.12),
                      ),

                      _infoRow(context, Icons.category_outlined, "Kategori", alat.kategoriNama),
                      _infoRow(context, Icons.payments_outlined, "Denda", "Rp ${alat.denda}"),
                      _infoRow(context, Icons.build_outlined, "Perbaikan", "Rp ${alat.perbaikan}"),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: theme.colorScheme.primary.withOpacity(0.35),
                                ),
                                foregroundColor: theme.colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: _dialogOpen ? null : () => _editAlat(alat),
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
                                padding: const EdgeInsets.symmetric(vertical: 12),
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
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
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
      appBar: const AppBarWithMenu(title: 'Daftar Alat'),
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
                          labelText: 'Cari alat',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Alat'),
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
                      onPressed: (_dialogOpen) ? null : _addAlat,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                if (_filteredAlat.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Center(
                      child: Text(
                        'Alat tidak ditemukan.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  )
                else
                  ..._filteredAlat.map((alat) => _alatCard(context, alat)),
              ],
            ),
    );
  }
}
