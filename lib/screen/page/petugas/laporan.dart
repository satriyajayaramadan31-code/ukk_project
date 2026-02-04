import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../widget/app_bar.dart';
import '../../widget/side_menu.dart';
import 'package:engine_rent_app/service/supabase_service.dart';
import 'package:engine_rent_app/models/report_data.dart';

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

  bool _isMobile(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w < 600;
  }

  Future<void> _loadReport() async {
    if (!mounted) return;
    setState(() => loading = true);

    try {
      final res = await SupabaseService.getLaporanRaw(timePeriod: timePeriod);
      rawLoans = res;

      final equipmentAgg = _aggregateByEquipment(rawLoans);

      popularEquipment = [...equipmentAgg]
        ..sort((a, b) => b.totalLoans.compareTo(a.totalLoans));

      needAttention = equipmentAgg.where((r) => r.overdueCount > 0).toList()
        ..sort((a, b) => b.overdueCount.compareTo(a.overdueCount));

      if (reportType == "equipment") {
        mainReports = equipmentAgg;
      } else if (reportType == "user") {
        mainReports = _aggregateByUser(rawLoans);
      } else {
        mainReports = _aggregateByCategory(rawLoans);
      }

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
        activeLoans:
            current.activeLoans +
            ((status == 'dipinjam' || status == 'menunggu') ? 1 : 0),
        completedLoans:
            current.completedLoans +
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
        ),
      );

      final current = map[userId]!;
      final status = (row['status'] ?? '').toString().toLowerCase();
      final t = row['terlambat'];
      final int terlambat = t is int ? t : int.tryParse(t.toString()) ?? 0;

      map[userId] = current.copyWith(
        totalLoans: current.totalLoans + 1,
        activeLoans:
            current.activeLoans +
            ((status == 'dipinjam' || status == 'menunggu') ? 1 : 0),
        completedLoans:
            current.completedLoans +
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
          kategoriObj?['id']?.toString() ??
          alat?['kategori']?.toString() ??
          'unknown';
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
        ),
      );

      final current = map[catId]!;
      final status = (row['status'] ?? '').toString().toLowerCase();
      final t = row['terlambat'];
      final int terlambat = t is int ? t : int.tryParse(t.toString()) ?? 0;

      map[catId] = current.copyWith(
        totalLoans: current.totalLoans + 1,
        activeLoans:
            current.activeLoans +
            ((status == 'dipinjam' || status == 'menunggu') ? 1 : 0),
        completedLoans:
            current.completedLoans +
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
          pw.TableHelper.fromTextArray(
            headers: [
              "Total",
              "Aktif",
              "Selesai",
              "Ditolak",
              "Terlambat",
              "Total Denda",
            ],
            data: [
              [
                totalLoans.toString(),
                activeLoans.toString(),
                completedLoans.toString(),
                rejectedLoans.toString(),
                overdueLoans.toString(),
                formatCurrency(totalFines),
              ],
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text("Laporan Utama"),
          pw.TableHelper.fromTextArray(
            headers: [
              _mainTitle(),
              "Total",
              "Aktif",
              "Selesai",
              "Ditolak",
              "Terlambat",
            ],
            data: mainReports
                .map(
                  (r) => [
                    r.label,
                    r.totalLoans.toString(),
                    r.activeLoans.toString(),
                    r.completedLoans.toString(),
                    r.rejectedLoans.toString(),
                    r.overdueCount.toString(),
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 10),
          pw.Text("Alat Paling Populer"),
          pw.TableHelper.fromTextArray(
            headers: ["Nama Alat", "Total Pinjam"],
            data: popularEquipment
                .map((r) => [r.label, r.totalLoans.toString()])
                .toList(),
          ),
          pw.SizedBox(height: 10),
          pw.Text("Perlu Perhatian"),
          pw.TableHelper.fromTextArray(
            headers: ["Nama Alat", "Terlambat"],
            data: needAttention
                .map((r) => [r.label, r.overdueCount.toString()])
                .toList(),
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
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final isMobile = _isMobile(context);

    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Laporan'),
      drawer: const SideMenu(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadReport,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===================== HEADER =====================
                _SimpleCard(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Laporan", style: text.headlineSmall),
                              const SizedBox(height: 4),
                              Text(
                                "Laporan dan statistik peminjaman alat",
                                style: text.bodyMedium,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: handleExport,
                                  icon: const Icon(Icons.download),
                                  label: const Text("Unduh PDF"),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                      horizontal: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Laporan", style: text.headlineSmall),
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 14),

                // ===================== FILTER =====================
                _SimpleCard(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: isMobile
                        ? Column(
                            children: [
                              DropdownButtonFormField<String>(
                                style: text.bodyMedium,
                                initialValue: reportType,
                                decoration: const InputDecoration(
                                  labelText: "Jenis Laporan",
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: "equipment",
                                    child: Text("Alat"),
                                  ),
                                  DropdownMenuItem(
                                    value: "user",
                                    child: Text("Pengguna"),
                                  ),
                                  DropdownMenuItem(
                                    value: "category",
                                    child: Text("Kategori"),
                                  ),
                                ],
                                onChanged: (v) async {
                                  if (v == null) return;
                                  setState(() => reportType = v);
                                  await _loadReport();
                                },
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                style: text.bodyMedium,
                                initialValue: timePeriod,
                                decoration: const InputDecoration(
                                  labelText: "Periode",
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: "week",
                                    child: Text("Minggu Ini"),
                                  ),
                                  DropdownMenuItem(
                                    value: "month",
                                    child: Text("Bulan Ini"),
                                  ),
                                  DropdownMenuItem(
                                    value: "year",
                                    child: Text("Tahun Ini"),
                                  ),
                                ],
                                onChanged: (v) async {
                                  if (v == null) return;
                                  setState(() => timePeriod = v);
                                  await _loadReport();
                                },
                              ),
                            ],
                          )
                        : Row(
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
                                    DropdownMenuItem(
                                      value: "equipment",
                                      child: Text("Alat"),
                                    ),
                                    DropdownMenuItem(
                                      value: "user",
                                      child: Text("Pengguna"),
                                    ),
                                    DropdownMenuItem(
                                      value: "category",
                                      child: Text("Kategori"),
                                    ),
                                  ],
                                  onChanged: (v) async {
                                    if (v == null) return;
                                    setState(() => reportType = v);
                                    await _loadReport();
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  style: text.bodyMedium,
                                  initialValue: timePeriod,
                                  decoration: const InputDecoration(
                                    labelText: "Periode",
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: "week",
                                      child: Text("Minggu Ini"),
                                    ),
                                    DropdownMenuItem(
                                      value: "month",
                                      child: Text("Bulan Ini"),
                                    ),
                                    DropdownMenuItem(
                                      value: "year",
                                      child: Text("Tahun Ini"),
                                    ),
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

                const SizedBox(height: 14),

                // ===================== SUMMARY =====================
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
                      final crossAxisCount = constraints.maxWidth > 900
                          ? 5
                          : constraints.maxWidth > 700
                              ? 3
                              : 2;
                      final spacing = 12.0;
                      final width = constraints.maxWidth;

                      double span(int s) =>
                          ((width - spacing * (crossAxisCount - 1)) /
                                  crossAxisCount *
                                  s) +
                              spacing * (s - 1);

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          _box(span(1), "Total", totalLoans.toString()),
                          _box(span(1), "Dipinjam", activeLoans.toString()),
                          _box(span(1), "Selesai", completedLoans.toString()),
                          _box(span(1), "Terlambat", overdueLoans.toString()),
                          _box(
                            span(crossAxisCount >= 4 ? 2 : crossAxisCount),
                            "Total Denda",
                            formatCurrency(totalFines),
                          ),
                        ],
                      );
                    },
                  ),

                const SizedBox(height: 16),

                // ===================== MAIN REPORT =====================
                const _SectionTitle(title: "Laporan Utama"),
                const SizedBox(height: 8),
                if (isMobile)
                  _MobileReportList(titleCol: _mainTitle(), data: mainReports)
                else
                  _MainTable(titleCol: _mainTitle(), data: mainReports),

                const SizedBox(height: 16),

                // ===================== INSIGHTS =====================
                const _SectionTitle(title: "Alat Paling Populer"),
                const SizedBox(height: 8),
                if (isMobile)
                  _MobileInsightList(rows: popularEquipment, isPopular: true)
                else
                  _InsightTable(
                    title: "Alat Paling Populer",
                    columns: const ["Nama Alat", "Total Pinjam"],
                    rows: popularEquipment,
                    isPopular: true,
                  ),

                const SizedBox(height: 14),

                const _SectionTitle(title: "Perlu Perhatian"),
                const SizedBox(height: 8),
                if (isMobile)
                  _MobileInsightList(rows: needAttention, isPopular: false)
                else
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
      ),
    );
  }

  Widget _box(double width, String t, String v) => SizedBox(
        width: width,
        child: _StatCard(title: t, value: v),
      );
}

/* ===================== SIMPLE CARD WRAPPER ===================== */
class _SimpleCard extends StatelessWidget {
  final Widget child;
  const _SimpleCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.45)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/* ===================== SECTION TITLE ===================== */
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Text(title, style: text.titleLarge);
  }
}

/* ===================== MOBILE LIST (MAIN REPORT) ===================== */
class _MobileReportList extends StatelessWidget {
  final List<ReportData> data;
  final String titleCol;

  const _MobileReportList({
    required this.data,
    required this.titleCol,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    if (data.isEmpty) {
      return _SimpleCard(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text("Tidak ada data.", style: text.bodyMedium),
        ),
      );
    }

    return Column(
      children: data.map((r) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _SimpleCard(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.label, style: text.titleMedium),
                  const SizedBox(height: 10),
                  _kv("Total", r.totalLoans.toString(), text),
                  _kv("Aktif", r.activeLoans.toString(), text),
                  _kv("Selesai", r.completedLoans.toString(), text),
                  _kv("Ditolak", r.rejectedLoans.toString(), text),
                  _kv("Terlambat", r.overdueCount.toString(), text),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _kv(String k, String v, TextTheme text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(k, style: text.bodyMedium)),
          Expanded(
            child: Text(
              v,
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/* ===================== MOBILE LIST (INSIGHT) ===================== */
class _MobileInsightList extends StatelessWidget {
  final List<ReportData> rows;
  final bool isPopular;

  const _MobileInsightList({
    required this.rows,
    required this.isPopular,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    if (rows.isEmpty) {
      return _SimpleCard(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text("Tidak ada data.", style: text.bodyMedium),
        ),
      );
    }

    return Column(
      children: rows.map((r) {
        final value = isPopular ? r.totalLoans : r.overdueCount;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _SimpleCard(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      r.label,
                      style:
                          text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      value.toString(),
                      style: text.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/* ===================== TABLE UTAMA (DESKTOP/TABLET) ===================== */
class _MainTable extends StatelessWidget {
  final List<ReportData> data;
  final String titleCol;
  const _MainTable({required this.data, required this.titleCol});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    final borderColor = theme.dividerColor.withOpacity(0.55);
    const radius = 14.0;

    return _SimpleCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingTextStyle: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    dataTextStyle: text.bodyMedium,
                    headingRowHeight: 48,
                    dataRowMinHeight: 46,
                    dataRowMaxHeight: 56,
                    columnSpacing: 24,
                    dividerThickness: 1,
                    border: TableBorder(
                      horizontalInside: BorderSide(color: borderColor, width: 1),
                      bottom: BorderSide(color: borderColor, width: 1),
                    ),
                    columns: [
                      DataColumn(label: Text(titleCol)),
                      const DataColumn(label: Text("Total")),
                      const DataColumn(label: Text("Aktif")),
                      const DataColumn(label: Text("Selesai")),
                      const DataColumn(label: Text("Ditolak")),
                      const DataColumn(label: Text("Terlambat")),
                    ],
                    rows: data
                        .map(
                          (r) => DataRow(
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: 260,
                                  child: Text(
                                    r.label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              DataCell(Text(r.totalLoans.toString())),
                              DataCell(Text(r.activeLoans.toString())),
                              DataCell(Text(r.completedLoans.toString())),
                              DataCell(Text(r.rejectedLoans.toString())),
                              DataCell(Text(r.overdueCount.toString())),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/* ===================== STAT CARD ===================== */
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    return _SimpleCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: text.bodyMedium?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===================== INSIGHT TABLE (DESKTOP/TABLET) ===================== */
class _InsightTable extends StatelessWidget {
  final String title;
  final List<String> columns;
  final List<ReportData> rows;
  final bool isPopular;
  const _InsightTable({
    required this.title,
    required this.columns,
    required this.rows,
    required this.isPopular,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    final borderColor = theme.dividerColor.withOpacity(0.55);
    const radius = 14.0;

    return _SimpleCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                    child: Text(title, style: text.titleLarge),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        headingTextStyle: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        dataTextStyle: text.bodyMedium,
                        headingRowHeight: 48,
                        dataRowMinHeight: 46,
                        dataRowMaxHeight: 56,
                        columnSpacing: 24,
                        dividerThickness: 1,
                        border: TableBorder(
                          horizontalInside:
                              BorderSide(color: borderColor, width: 1),
                          bottom: BorderSide(color: borderColor, width: 1),
                        ),
                        columns: columns
                            .map((c) => DataColumn(label: Text(c)))
                            .toList(),
                        rows: rows
                            .map(
                              (r) => DataRow(
                                cells: [
                                  DataCell(
                                    SizedBox(
                                      width: 320,
                                      child: Text(
                                        r.label,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      isPopular
                                          ? r.totalLoans.toString()
                                          : r.overdueCount.toString(),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
