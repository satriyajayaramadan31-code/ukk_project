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
  final int utilizationRate;

  ReportData({
    required this.equipment,
    required this.totalLoans,
    required this.activeLoans,
    required this.completedLoans,
    required this.overdueLoans,
    required this.utilizationRate,
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
      utilizationRate: 85,
    ),
    ReportData(
      equipment: "Kamera DSLR Canon",
      totalLoans: 12,
      activeLoans: 1,
      completedLoans: 10,
      overdueLoans: 1,
      utilizationRate: 75,
    ),
    ReportData(
      equipment: "Proyektor Epson",
      totalLoans: 10,
      activeLoans: 1,
      completedLoans: 9,
      overdueLoans: 0,
      utilizationRate: 70,
    ),
    ReportData(
      equipment: "Bor Listrik Bosch",
      totalLoans: 8,
      activeLoans: 1,
      completedLoans: 7,
      overdueLoans: 0,
      utilizationRate: 60,
    ),
    ReportData(
      equipment: "Mikrofon Wireless",
      totalLoans: 6,
      activeLoans: 0,
      completedLoans: 5,
      overdueLoans: 1,
      utilizationRate: 45,
    ),
    ReportData(
      equipment: "Meteran Laser Digital",
      totalLoans: 4,
      activeLoans: 0,
      completedLoans: 4,
      overdueLoans: 0,
      utilizationRate: 30,
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

  int get averageUtilization =>
      (equipmentReports.fold(0, (sum, r) => sum + r.utilizationRate) /
              equipmentReports.length)
          .round();

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Laporan'),
      drawer: const SideMenu(role: 'petugas'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Laporan",
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Laporan dan statistik peminjaman alat",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: ElevatedButton.icon(
                      onPressed: handleExport,
                      icon: const Icon(Icons.download),
                      label: const Text("Unduh"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Filters
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: reportType,
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
                              onChanged: (value) {
                                setState(() {
                                  reportType = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: timePeriod,
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
                                  value: "quarter",
                                  child: Text("Kuartal Ini"),
                                ),
                                DropdownMenuItem(
                                  value: "year",
                                  child: Text("Tahun Ini"),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  timePeriod = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Summary (Grid seperti Dashboard)
              LayoutBuilder(builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 700 ? 3 : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.5,
                  children: [
                    _StatCard(
                      title: "Total Peminjaman",
                      value: totalLoans.toString(),
                    ),
                    _StatCard(
                      title: "Sedang Dipinjam",
                      value: activeLoans.toString(),
                    ),
                    _StatCard(
                      title: "Selesai",
                      value: completedLoans.toString(),
                    ),
                    _StatCard(
                      title: "Terlambat",
                      value: overdueLoans.toString(),
                    ),
                    _StatCard(
                      title: "Utilisasi Rata-rata",
                      value: "$averageUtilization%",
                    ),
                    _StatCard(
                      title: "Total Denda",
                      value: formatCurrency(totalFines),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 16),

              // Table
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Laporan Per Alat - Bulan Ini",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text("Nama Alat")),
                            DataColumn(label: Text("Total Pinjam")),
                            DataColumn(label: Text("Aktif")),
                            DataColumn(label: Text("Selesai")),
                            DataColumn(label: Text("Terlambat")),
                            DataColumn(label: Text("Utilisasi")),
                          ],
                          rows: equipmentReports.map((report) {
                            return DataRow(
                              cells: [
                                DataCell(Text(report.equipment)),
                                DataCell(Text(report.totalLoans.toString())),
                                DataCell(
                                  Chip(
                                    backgroundColor: Colors.grey[800],
                                    label: Text(
                                      report.activeLoans.toString(),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Chip(
                                    backgroundColor: Colors.green,
                                    label: Text(
                                      report.completedLoans.toString(),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  report.overdueLoans > 0
                                      ? Chip(
                                          backgroundColor: Colors.red,
                                          label: Text(
                                            report.overdueLoans.toString(),
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        )
                                      : const Text("0"),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: report.utilizationRate / 100,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: report.utilizationRate >= 70
                                                  ? Colors.green
                                                  : report.utilizationRate >= 50
                                                      ? Colors.orange
                                                      : Colors.red,
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text("${report.utilizationRate}%"),
                                    ],
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

              const SizedBox(height: 16),

              // Insights
              Column(
                children: [
                  _InsightCard(
                    title: "Alat Paling Populer",
                    items: equipmentReports
                        .toList()
                      ..sort((a, b) => b.totalLoans.compareTo(a.totalLoans)),
                  ),
                  const SizedBox(height: 14),
                  _InsightCard(
                    title: "Perlu Perhatian",
                    items: equipmentReports
                        .where((r) => r.overdueLoans > 0 || r.utilizationRate < 50)
                        .toList(),
                    isWarning: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final List<ReportData> items;
  final bool isWarning;

  const _InsightCard({
    required this.title,
    required this.items,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Text(title, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: items.take(3).map((report) {
                final badgeColor = report.overdueLoans > 0
                    ? Colors.red
                    : report.utilizationRate < 50
                        ? Colors.orange
                        : Colors.green;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(report.equipment,
                                style: theme.textTheme.bodyMedium),
                            Text(
                              report.overdueLoans > 0
                                  ? "${report.overdueLoans} terlambat"
                                  : "Utilisasi rendah: ${report.utilizationRate}%",
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        backgroundColor: badgeColor,
                        label: Text(
                          report.overdueLoans > 0 ? "Terlambat" : "Rendah",
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }
}
