import 'package:flutter/material.dart';
import '../widget/app_bar.dart';
import '../widget/side_menu.dart';

class LogEntry {
  final String id;
  final String timestamp;
  final String user;
  final String description;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.user,
    required this.description,
  });
}

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<LogEntry> _logs = [
    LogEntry(
      id: "1",
      timestamp: "2026-01-13 14:23:15",
      user: "Admin",
      description: "Menambahkan user baru: John Doe (peminjam)",
    ),
    LogEntry(
      id: "2",
      timestamp: "2026-01-13 14:15:42",
      user: "Petugas 1",
      description: "Menyetujui peminjaman Laptop Dell XPS 15 oleh Jane Smith",
    ),
    LogEntry(
      id: "3",
      timestamp: "2026-01-13 14:10:33",
      user: "John Doe",
      description: "Mengajukan peminjaman Kamera DSLR Canon",
    ),
    LogEntry(
      id: "4",
      timestamp: "2026-01-13 14:05:18",
      user: "Admin",
      description: "Mengubah status alat Proyektor Epson menjadi Maintenance",
    ),
    LogEntry(
      id: "5",
      timestamp: "2026-01-13 13:58:27",
      user: "Jane Smith",
      description: "Mengembalikan Bor Listrik Bosch (Terlambat 2 hari, Denda: Rp 20.000)",
    ),
    LogEntry(
      id: "6",
      timestamp: "2026-01-13 13:45:51",
      user: "Admin",
      description: "Menghapus user: Alice Brown",
    ),
    LogEntry(
      id: "7",
      timestamp: "2026-01-13 13:30:12",
      user: "Petugas 1",
      description: "Menolak peminjaman Mikrofon Wireless oleh Bob Johnson",
    ),
    LogEntry(
      id: "8",
      timestamp: "2026-01-13 13:15:44",
      user: "John Doe",
      description: "Login ke sistem",
    ),
    LogEntry(
      id: "9",
      timestamp: "2026-01-13 12:55:33",
      user: "Admin",
      description: "Menambahkan alat baru: Tablet iPad Pro (Kategori: Elektronik)",
    ),
    LogEntry(
      id: "10",
      timestamp: "2026-01-13 12:40:21",
      user: "Petugas 1",
      description: "Memproses pengembalian Laptop Dell XPS 15 oleh John Doe (Tepat Waktu)",
    ),
  ];

  String _searchTerm = "";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filteredLogs = _logs.where((log) {
      final query = _searchTerm.toLowerCase();
      return log.user.toLowerCase().contains(query) ||
          log.description.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Log Aktivitas'),
      drawer: const SideMenu(role: 'admin'),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // SEARCH
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchTerm = value;
              });
            },
            decoration: InputDecoration(
              labelText: "Cari username atau deskripsi",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // TABLE
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: theme.colorScheme.background,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(theme.scaffoldBackgroundColor),
                  columns: const [
                    DataColumn(label: Text('Username')),
                    DataColumn(label: Text('Deskripsi')),
                    DataColumn(label: Text('Tanggal')),
                  ],
                  rows: filteredLogs.map((log) {
                    return DataRow(cells: [
                      DataCell(Text(log.user)),
                      DataCell(
                        SizedBox(
                          width: 450,
                          child: Text(
                            log.description,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(log.timestamp)),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
