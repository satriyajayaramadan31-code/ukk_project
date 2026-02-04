import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/theme.dart';
import '../../widget/activity_item.dart';
import '../../widget/stat_card.dart';
import '../../widget/app_bar.dart';
import '../../widget/side_menu.dart';
import 'package:engine_rent_app/service/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPage extends StatefulWidget {
  final String role;

  const DashboardPage({
    super.key,
    required this.role,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _loading = true;
  String? _error;

  Map<String, int> _stats = const {
    'totalEquipment': 0,
    'activeLoans': 0,
    'pendingApprovals': 0,
    'overdueReturns': 0,
  };

  List<Map<String, dynamic>> _activities = const [];

  // ===== REALTIME =====
  RealtimeChannel? _loanChannel;
  RealtimeChannel? _equipmentChannel;

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _initRealtime();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (_loanChannel != null) {
      Supabase.instance.client.removeChannel(_loanChannel!);
    }
    if (_equipmentChannel != null) {
      Supabase.instance.client.removeChannel(_equipmentChannel!);
    }
    super.dispose();
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  void _scheduleReload() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _loadDashboard(silent: true);
    });
  }

  void _initRealtime() {
    final client = Supabase.instance.client;

    _loanChannel = client
        .channel('dashboard-peminjaman')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'peminjaman',
          callback: (payload) => _scheduleReload(),
        )
        .subscribe();

    _equipmentChannel = client
        .channel('dashboard-alat')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'alat',
          callback: (payload) => _scheduleReload(),
        )
        .subscribe();
  }

  Future<void> _loadDashboard({bool silent = false}) async {
    if (!mounted) return;

    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final statsRaw = await SupabaseService.getDashboardStats(role: widget.role);
      final activitiesRaw = await SupabaseService.getDashboardActivities(role: widget.role);

      if (!mounted) return;

      setState(() {
        _stats = {
          'totalEquipment': _toInt(statsRaw['totalEquipment']),
          'activeLoans': _toInt(statsRaw['activeLoans']),
          'pendingApprovals': _toInt(statsRaw['pendingApprovals']),
          'overdueReturns': _toInt(statsRaw['overdueReturns']),
        };
        _activities = List<Map<String, dynamic>>.from(activitiesRaw);
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ================= HELPERS =================

  String _getItemName(Map<String, dynamic> row) {
    if (row['nama_alat'] != null) return row['nama_alat'].toString();
    final alat = row['alat'];
    if (alat is Map && alat['nama_alat'] != null) {
      return alat['nama_alat'].toString();
    }
    return '-';
  }

  String _getStatus(Map<String, dynamic> row) {
    final raw = (row['status'] ?? '').toString().trim().toLowerCase();
    switch (raw) {
      case 'menunggu': return 'Menunggu';
      case 'diproses': return 'Diproses';
      case 'dipinjam': return 'Dipinjam';
      case 'dikembalikan': return 'Dikembalikan';
      case 'terlambat': return 'Terlambat';
      case 'ditolak': return 'Ditolak';
      default:
        if (raw.isEmpty) return '-';
        return raw[0].toUpperCase() + raw.substring(1);
    }
  }

  String _getTimeAgo(Map<String, dynamic> row) {
    final createdAt = row['created_at'];
    if (createdAt == null) return '-';
    final dt = DateTime.tryParse(createdAt.toString());
    if (dt == null) return '-';
    return SupabaseService.timeAgo(dt.toLocal());
  }

  // ================= UI COMPONENTS =================

  Widget _buildStatsGrid() {
    if (_loading && _stats['totalEquipment'] == 0) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.6,
        ),
        itemBuilder: (context, index) => Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    final cards = [
      StatCard(
        title: 'Alat',
        value: _stats['totalEquipment'].toString(),
        icon: Icons.inventory_2,
        iconColor: AppTheme.statusReturned,
      ),
      StatCard(
        title: 'Dipinjam',
        value: _stats['activeLoans'].toString(),
        icon: Icons.assignment,
        iconColor: AppTheme.statusBorrowed,
      ),
      StatCard(
        title: 'Menunggu',
        value: _stats['pendingApprovals'].toString(),
        icon: Icons.hourglass_top,
        iconColor: AppTheme.statusPending,
      ),
      StatCard(
        title: 'Terlambat',
        value: _stats['overdueReturns'].toString(),
        icon: Icons.warning_amber,
        iconColor: AppTheme.statusLate,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.6,
      children: cards,
    );
  }

  Widget _buildActivityList(ThemeData theme) {
    if (_loading && _activities.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_activities.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Belum ada aktivitas.'),
        ),
      );
    }

    // Menggunakan asMap() untuk memastikan isLast akurat
    return Column(
      children: _activities.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final isLastItem = index == _activities.length - 1;

        return ActivityItem(
          item: _getItemName(data),
          status: _getStatus(data),
          time: _getTimeAgo(data),
          isLast: isLastItem,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: const AppBarWithMenu(title: 'Dashboard'),
      drawer: SideMenu(),
      body: RefreshIndicator(
        onRefresh: () => _loadDashboard(silent: false),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsGrid(),
              
              if (_error != null) ...[
                const SizedBox(height: 16),
                _buildErrorCard(theme),
              ],

              const SizedBox(height: 24),

              Card(
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aktivitas Terkini', style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 16),
                      _buildActivityList(theme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme) {
    return Card(
      color: Colors.red.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Gagal memuat data: $_error',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: () => _loadDashboard(silent: false),
              child: const Text('Coba lagi'),
            )
          ],
        ),
      ),
    );
  }
}