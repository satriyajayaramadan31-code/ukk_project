import 'package:flutter/material.dart';
import '../widget/app_bar.dart';
import '../widget/side_menu.dart';
import 'package:intl/intl.dart';

class ReportData {
  final String equipment;
  final int totalLoans;
  final int activeLoans;
  final int completedLoans;
  final int overdueLoans;

  ReportData({
    required this.equipment,
    required this.totalLoans,
    required this.activeLoans,
    required this.completedLoans,
    required this.overdueLoans,
  });
}

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  String reportType = "equipment";
  String timePeriod = "month";

  final List<ReportData> equipmentReports = [
    ReportData(
      equipment: "Laptop Dell XPS 15",
      totalLoans: 15,
      activeLoans: 2,
      completedLoans: 12,
      overdueLoans: 1,
    ),
    ReportData(
      equipment: "Kamera DSLR Canon",
      totalLoans: 12,
      activeLoans: 1,
      completedLoans: 10,
      overdueLoans: 1,
    ),
    ReportData(
      equipment: "Proyektor Epson",
      totalLoans: 10,
      activeLoans: 1,
      completedLoans: 9,
      overdueLoans: 0,
    ),
    ReportData(
      equipment: "Bor Listrik Bosch",
      totalLoans: 8,
      activeLoans: 1,
      completedLoans: 7,
      overdueLoans: 0,
    ),
    ReportData(
      equipment: "Mikrofon Wireless",
      totalLoans: 6,
      activeLoans: 0,
      completedLoans: 5,
      overdueLoans: 1,
    ),
    ReportData(
      equipment: "Meteran Laser Digital",
      totalLoans: 4,
      activeLoans: 0,
      completedLoans: 4,
      overdueLoans: 0,
    ),
  ];

  int get totalLoans =>
      equipmentReports.fold(0, (sum, r) => sum + r.totalLoans);
  int get activeLoans =>
      equipmentReports.fold(0, (sum, r) => sum + r.activeLoans);
  int get completedLoans =>
      equipmentReports.fold(0, (sum, r) => sum + r.completedLoans);
  int get overdueLoans =>
      equipmentReports.fold(0, (sum, r) => sum + r.overdueLoans);

  int get totalFines => 150000;

  String formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: "id_ID",
      symbol: "Rp",
      decimalDigits: 0,
    ).format(amount);
  }

  void handleExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Laporan akan diunduh sebagai file Excel/PDF"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Laporan'),
      drawer: const SideMenu(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /* ===================== HEADER ===================== */
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Laporan",
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text(
                          "Laporan dan statistik peminjaman alat",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: handleExport,
                    icon: const Icon(Icons.download),
                    label: const Text("Unduh"),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              /* ===================== FILTER ===================== */
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
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
                          onChanged: (v) => setState(() => reportType = v!),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: timePeriod,
                          decoration: const InputDecoration(
                            labelText: "Periode",
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: "week", child: Text("Minggu Ini")),
                            DropdownMenuItem(
                                value: "month", child: Text("Bulan Ini")),
                            DropdownMenuItem(
                                value: "quarter", child: Text("Kuartal Ini")),
                            DropdownMenuItem(
                                value: "year", child: Text("Tahun Ini")),
                          ],
                          onChanged: (v) => setState(() => timePeriod = v!),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /* ===================== SUMMARY ===================== */
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 700 ? 3 : 2;
                  final spacing = 14.0;
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

              /* ===================== TABLE UTAMA ===================== */
              _MainTable(equipmentReports: equipmentReports),

              const SizedBox(height: 16),

              /* ===================== INSIGHT TABLE ===================== */
              _InsightTable(
                title: "Alat Paling Populer",
                columns: const ["Nama Alat", "Total Pinjam"],
                rows: equipmentReports
                  ..sort((a, b) => b.totalLoans.compareTo(a.totalLoans)),
                isPopular: true,
              ),
              const SizedBox(height: 14),
              _InsightTable(
                title: "Perlu Perhatian",
                columns: const ["Nama Alat", "Terlambat"],
                rows:
                    equipmentReports.where((r) => r.overdueLoans > 0).toList(),
                isPopular: false,
              ),
            ],
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

/* ===================== TABLE UTAMA ===================== */
class _MainTable extends StatelessWidget {
  final List<ReportData> equipmentReports;
  const _MainTable({required this.equipmentReports});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text("Nama Alat")),
            DataColumn(label: Text("Total Pinjam")),
            DataColumn(label: Text("Aktif")),
            DataColumn(label: Text("Selesai")),
            DataColumn(label: Text("Terlambat")),
          ],
          rows: equipmentReports
              .map((r) => DataRow(cells: [
                    DataCell(Text(r.equipment)),
                    DataCell(Text(r.totalLoans.toString())),
                    DataCell(Text(r.activeLoans.toString())),
                    DataCell(Text(r.completedLoans.toString())),
                    DataCell(Text(r.overdueLoans.toString())),
                  ]))
              .toList(),
        ),
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
    required this.title,
    required this.columns,
    required this.rows,
    required this.isPopular,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: columns.map((c) => DataColumn(label: Text(c))).toList(),
          rows: rows
              .map(
                (r) => DataRow(cells: [
                  DataCell(Text(r.equipment)),
                  DataCell(Text(
                      isPopular ? r.totalLoans.toString() : r.overdueLoans.toString())),
                ]),
              )
              .toList(),
        ),
      ),
    );
  }
}
