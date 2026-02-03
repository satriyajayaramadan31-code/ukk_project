import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../utils/theme.dart';
import '../widget/app_bar.dart';
import '../widget/side_menu.dart';
import 'package:engine_rent_app/service/supabase_service.dart';

/* ===================== MODEL ===================== */
class ReportData {
  final String id;
  final String label;
  final int totalLoans;
  final int activeLoans;
  final int completedLoans;
  final int rejectedLoans;
  final int overdueLoans; // total hari keterlambatan
  final int overdueCount; // jumlah peminjaman terlambat

  const ReportData({
    required this.id,
    required this.label,
    required this.totalLoans,
    required this.activeLoans,
    required this.completedLoans,
    required this.rejectedLoans,
    required this.overdueLoans,
    this.overdueCount = 0,
  });

  ReportData copyWith({
    int? totalLoans,
    int? activeLoans,
    int? completedLoans,
    int? rejectedLoans,
    int? overdueLoans,
    int? overdueCount,
  }) {
    return ReportData(
      id: id,
      label: label,
      totalLoans: totalLoans ?? this.totalLoans,
      activeLoans: activeLoans ?? this.activeLoans,
      completedLoans: completedLoans ?? this.completedLoans,
      rejectedLoans: rejectedLoans ?? this.rejectedLoans,
      overdueLoans: overdueLoans ?? this.overdueLoans,
      overdueCount: overdueCount ?? this.overdueCount,
    );
  }
}

/* ===================== PAGE ===================== */
class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  String reportType = "equipment"; // equipment | user | category
  String timePeriod = "month"; // week | month | year
  bool loading = true;

  List<Map<String, dynamic>> rawLoans = [];
  List<ReportData> mainReports = [];
  List<ReportData> popularEquipment = [];
  List<ReportData> needAttention = [];

  int totalLoans = 0;
  int activeLoans = 0;
  int completedLoans = 0;
  int rejectedLoans = 0;
  int overdueLoans = 0; // jumlah peminjaman terlambat
  int totalFines = 0;

  String formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: "id_ID",
      symbol: "Rp",
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      final res = await SupabaseService.getLaporanRaw(timePeriod: timePeriod);
      rawLoans = res;

      // ===== tabel bawah (alat) =====
      final equipmentAgg = _aggregateByEquipment(rawLoans);
      popularEquipment = [...equipmentAgg]
        ..sort((a, b) => b.totalLoans.compareTo(a.totalLoans));

      // Untuk tabel “Perlu Perhatian” pakai overdueCount
      needAttention = equipmentAgg.where((r) => r.overdueCount > 0).toList()
        ..sort((a, b) => b.overdueCount.compareTo(a.overdueCount));

      // ===== tabel utama sesuai pilihan =====
      if (reportType == "equipment") {
        mainReports = equipmentAgg;
      } else if (reportType == "user") {
        mainReports = _aggregateByUser(rawLoans);
      } else {
        mainReports = _aggregateByCategory(rawLoans);
      }

      // ===== summary global =====
      totalLoans = rawLoans.length;
      activeLoans = rawLoans.where((e) {
        final s = (e['status'] ?? '').toString().toLowerCase();
        return s == 'dipinjam';
      }).length;

      completedLoans = rawLoans.where((e) {
        final s = (e['status'] ?? '').toString().toLowerCase();
        return s == 'dikembalikan';
      }).length;

      rejectedLoans = rawLoans.where((e) {
        final s = (e['status'] ?? '').toString().toLowerCase();
        return s == 'ditolak';
      }).length;

      // overdueLoans untuk summary: jumlah peminjaman terlambat
      overdueLoans = rawLoans.where((e) {
        final t = e['terlambat'];
        final int terlambat = t is int ? t : int.tryParse(t.toString()) ?? 0;
        return terlambat > 0;
      }).length;

      totalFines = rawLoans.fold(0, (sum, e) {
        final d = e['denda'];
        if (d == null) return sum;
        if (d is int) return sum + d;
        return sum + (int.tryParse(d.toString()) ?? 0);
      });
    } catch (e) {
      debugPrint("❌ LOAD REPORT ERROR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat laporan: $e")),
        );
      }
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  /* ===================== AGGREGATE ===================== */
  List<ReportData> _aggregateByEquipment(List<Map<String, dynamic>> loans) {
    final Map<String, ReportData> map = {};
    for (final row in loans) {
      final alat = row['alat'];
      final alatId = alat?['id']?.toString() ?? 'unknown';
      final namaAlat = alat?['nama_alat']?.toString() ?? 'Tidak diketahui';

      map.putIfAbsent(
        alatId,
        () => ReportData(
          id: alatId,
          label: namaAlat,
          totalLoans: 0,
          activeLoans: 0,
          completedLoans: 0,
          rejectedLoans: 0,
          overdueLoans: 0,
          overdueCount: 0,
        ),
      );

      final current = map[alatId]!;
      final status = (row['status'] ?? '').toString().toLowerCase();
      final t = row['terlambat'];
      final int terlambat = t is int ? t : int.tryParse(t.toString()) ?? 0;

      map[alatId] = current.copyWith(
        totalLoans: current.totalLoans + 1,
        activeLoans: current.activeLoans +
            ((status == 'dipinjam' || status == 'menunggu') ? 1 : 0),
        completedLoans: current.completedLoans +
            ((status == 'dikembalikan' || status == 'selesai') ? 1 : 0),
        rejectedLoans: current.rejectedLoans + (status == 'ditolak' ? 1 : 0),
        overdueLoans: current.overdueLoans + terlambat,
        overdueCount: current.overdueCount + (terlambat > 0 ? 1 : 0),
      );
    }
    return map.values.toList();
  }

  List<ReportData> _aggregateByUser(List<Map<String, dynamic>> loans) {
    final Map<String, ReportData> map = {};
    for (final row in loans) {
      final user = row['user'];
      final userId = user?['id']?.toString() ?? 'unknown';
      final username = user?['username']?.toString() ?? 'Tidak diketahui';

      map.putIfAbsent(
          userId,
          () => ReportData(
                id: userId,
                label: username,
                totalLoans: 0,
                activeLoans: 0,
                completedLoans: 0,
                rejectedLoans: 0,
                overdueLoans: 0,
                overdueCount: 0,
              ));

      final current = map[userId]!;
      final status = (row['status'] ?? '').toString().toLowerCase();
      final t = row['terlambat'];
      final int terlambat = t is int ? t : int.tryParse(t.toString()) ?? 0;

      map[userId] = current.copyWith(
        totalLoans: current.totalLoans + 1,
        activeLoans: current.activeLoans +
            ((status == 'dipinjam' || status == 'menunggu') ? 1 : 0),
        completedLoans: current.completedLoans +
            ((status == 'dikembalikan' || status == 'selesai') ? 1 : 0),
        rejectedLoans: current.rejectedLoans + (status == 'ditolak' ? 1 : 0),
        overdueLoans: current.overdueLoans + terlambat,
        overdueCount: current.overdueCount + (terlambat > 0 ? 1 : 0),
      );
    }
    return map.values.toList()
      ..sort((a, b) => b.totalLoans.compareTo(a.totalLoans));
  }

  List<ReportData> _aggregateByCategory(List<Map<String, dynamic>> loans) {
    final Map<String, ReportData> map = {};
    for (final row in loans) {
      final alat = row['alat'];
      final kategoriObj = alat?['kategori_alat'];
      final catId =
          kategoriObj?['id']?.toString() ?? alat?['kategori']?.toString() ?? 'unknown';
      final catName = kategoriObj?['kategori']?.toString() ?? 'Tidak diketahui';

      map.putIfAbsent(
          catId,
          () => ReportData(
                id: catId,
                label: catName,
                totalLoans: 0,
                activeLoans: 0,
                completedLoans: 0,
                rejectedLoans: 0,
                overdueLoans: 0,
                overdueCount: 0,
              ));

      final current = map[catId]!;
      final status = (row['status'] ?? '').toString().toLowerCase();
      final t = row['terlambat'];
      final int terlambat = t is int ? t : int.tryParse(t.toString()) ?? 0;

      map[catId] = current.copyWith(
        totalLoans: current.totalLoans + 1,
        activeLoans: current.activeLoans +
            ((status == 'dipinjam' || status == 'menunggu') ? 1 : 0),
        completedLoans: current.completedLoans +
            ((status == 'dikembalikan' || status == 'selesai') ? 1 : 0),
        rejectedLoans: current.rejectedLoans + (status == 'ditolak' ? 1 : 0),
        overdueLoans: current.overdueLoans + terlambat,
        overdueCount: current.overdueCount + (terlambat > 0 ? 1 : 0),
      );
    }
    return map.values.toList()
      ..sort((a, b) => b.totalLoans.compareTo(a.totalLoans));
  }

  /* ===================== EXPORT PDF ===================== */
  Future<void> handleExport() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Header(level: 0, text: "Laporan Peminjaman Alat"),
          pw.Text("Periode: $timePeriod"),
          pw.SizedBox(height: 10),

          pw.Table.fromTextArray(
            headers: ["Total", "Aktif", "Selesai", "Ditolak", "Terlambat", "Total Denda"],
            data: [
              [
                totalLoans.toString(),
                activeLoans.toString(),
                completedLoans.toString(),
                rejectedLoans.toString(),
                overdueLoans.toString(),
                formatCurrency(totalFines),
              ]
            ],
          ),
          pw.SizedBox(height: 10),

          pw.Text("Laporan Utama"),
          pw.Table.fromTextArray(
            headers: [_mainTitle(), "Total", "Aktif", "Selesai", "Ditolak", "Terlambat"],
            data: mainReports
                .map((r) => [
                      r.label,
                      r.totalLoans.toString(),
                      r.activeLoans.toString(),
                      r.completedLoans.toString(),
                      r.rejectedLoans.toString(),
                      r.overdueCount.toString()
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 10),

          pw.Text("Alat Paling Populer"),
          pw.Table.fromTextArray(
            headers: ["Nama Alat", "Total Pinjam"],
            data: popularEquipment.map((r) => [r.label, r.totalLoans.toString()]).toList(),
          ),
          pw.SizedBox(height: 10),

          pw.Text("Perlu Perhatian"),
          pw.Table.fromTextArray(
            headers: ["Nama Alat", "Terlambat"],
            data: needAttention.map((r) => [r.label, r.overdueCount.toString()]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  String _mainTitle() {
    if (reportType == 'equipment') return "Nama Alat";
    if (reportType == 'user') return "Nama Pengguna";
    return "Kategori";
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Laporan'),
      drawer: const SideMenu(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Laporan", style: text.headlineLarge),
                        const SizedBox(height: 4),
                        Text(
                          "Laporan dan statistik peminjaman alat",
                          style: text.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: handleExport,
                    icon: const Icon(Icons.download),
                    label: const Text("Unduh"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: text.bodyLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filter
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          style: text.bodyMedium,
                          initialValue: reportType,
                          decoration: const InputDecoration(
                            labelText: "Jenis Laporan",
                            
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: "equipment", child: Text("Alat")),
                            DropdownMenuItem(value: "user", child: Text("Pengguna")),
                            DropdownMenuItem(value: "category", child: Text("Kategori")),
                          ],
                          onChanged: (v) async {
                            if (v == null) return;
                            setState(() => reportType = v);
                            await _loadReport();
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          style: text.bodyMedium,
                          initialValue: timePeriod,
                          decoration: const InputDecoration(
                            labelText: "Periode",
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: "week", child: Text("Minggu Ini")),
                            DropdownMenuItem(value: "month", child: Text("Bulan Ini")),
                            DropdownMenuItem(value: "year", child: Text("Tahun Ini")),
                          ],
                          onChanged: (v) async {
                            if (v == null) return;
                            setState(() => timePeriod = v);
                            await _loadReport();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Summary
              if (loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 700 ? 3 : 2;
                    final spacing = 14.0;
                    final width = constraints.maxWidth;
                    double span(int s) =>
                        ((width - spacing * (crossAxisCount - 1)) / crossAxisCount * s) +
                        spacing * (s - 1);

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        _box(span(1), "Total Peminjaman", totalLoans.toString()),
                        _box(span(1), "Sedang Dipinjam", activeLoans.toString()),
                        _box(span(1), "Dikembalikan", completedLoans.toString()),
                        _box(span(1), "Terlambat", overdueLoans.toString()),
                        _box(
                          span(crossAxisCount >= 3 ? 2 : crossAxisCount),
                          "Total Denda",
                          formatCurrency(totalFines),
                        ),
                      ],
                    );
                  },
                ),

              const SizedBox(height: 16),

              // Main Table
              _MainTable(titleCol: _mainTitle(), data: mainReports),
              const SizedBox(height: 16),

              // Insight Tables
              _InsightTable(
                title: "Alat Paling Populer",
                columns: const ["Nama Alat", "Total Pinjam"],
                rows: popularEquipment,
                isPopular: true,
              ),
              const SizedBox(height: 14),
              _InsightTable(
                title: "Perlu Perhatian",
                columns: const ["Nama Alat", "Terlambat"],
                rows: needAttention,
                isPopular: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _box(double width, String t, String v) =>
      SizedBox(width: width, child: _StatCard(title: t, value: v));
}

/* ===================== TABLE UTAMA ===================== */
class _MainTable extends StatelessWidget {
  final List<ReportData> data;
  final String titleCol;
  const _MainTable({super.key, required this.data, required this.titleCol});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingTextStyle: text.bodyMedium,
            dataTextStyle: text.bodyMedium,
            columnSpacing: 24,
            columns: [
              DataColumn(label: Text(titleCol)),
              const DataColumn(label: Text("Total")),
              const DataColumn(label: Text("Aktif")),
              const DataColumn(label: Text("Selesai")),
              const DataColumn(label: Text("Ditolak")),
              const DataColumn(label: Text("Terlambat")),
            ],
            rows: data
                .map((r) => DataRow(cells: [
                      DataCell(Text(r.label)),
                      DataCell(Text(r.totalLoans.toString())),
                      DataCell(Text(r.activeLoans.toString())),
                      DataCell(Text(r.completedLoans.toString())),
                      DataCell(Text(r.rejectedLoans.toString())),
                      DataCell(Text(r.overdueCount.toString())),
                    ]))
                .toList(),
          ),
        ),
      ),
    );
  }
}

/* ===================== STAT CARD ===================== */
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: text.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: text.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/* ===================== INSIGHT TABLE ===================== */
class _InsightTable extends StatelessWidget {
  final String title;
  final List<String> columns;
  final List<ReportData> rows;
  final bool isPopular;
  const _InsightTable({
    super.key,
    required this.title,
    required this.columns,
    required this.rows,
    required this.isPopular,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: text.headlineSmall),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: text.bodyMedium,
                dataTextStyle: text.bodyMedium,
                columnSpacing: 24,
                columns: columns.map((c) => DataColumn(label: Text(c))).toList(),
                rows: rows
                    .map((r) => DataRow(cells: [
                          DataCell(Text(r.label)),
                          DataCell(
                            Text(isPopular ? r.totalLoans.toString() : r.overdueCount.toString()),
                          ),
                        ]))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
