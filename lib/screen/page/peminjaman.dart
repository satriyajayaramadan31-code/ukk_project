import 'package:flutter/material.dart';
import '../widget/app_bar.dart';
import '../widget/side_menu.dart';
import '../models/loan_request.dart';
import '../widget/detail_pinjam.dart';
import '../widget/pinjam_card.dart';
import '../widget/kembalikan.dart'; // <- popup kembalikan
import '../utils/theme.dart';
import 'package:intl/intl.dart';

class PeminjamanPage extends StatefulWidget {
  const PeminjamanPage({super.key});

  @override
  State<PeminjamanPage> createState() => _PeminjamanPageState();
}

class _PeminjamanPageState extends State<PeminjamanPage> {
  final TextEditingController _searchController = TextEditingController();
  List<LoanRequest> _filteredRequests = [];

  final List<LoanRequest> _requests = [
    LoanRequest(
      id: "1",
      userName: "John Doe",
      equipmentName: "Laptop Dell XPS 15",
      borrowDate: "2026-01-10",
      dueDate: "2026-01-17",
      purpose: "Presentasi proyek akhir",
      status: LoanStatus.menunggu,
    ),
    LoanRequest(
      id: "2",
      userName: "Jane Smith",
      equipmentName: "Kamera DSLR Canon",
      borrowDate: "2026-01-11",
      dueDate: "2026-01-15",
      purpose: "Dokumentasi acara kampus",
      status: LoanStatus.dipinjam,
    ),
    LoanRequest(
      id: "3",
      userName: "Bob Johnson",
      equipmentName: "Proyektor Epson",
      borrowDate: "2026-01-09",
      dueDate: "2026-01-12",
      purpose: "Seminar departemen",
      status: LoanStatus.dikembalikan,
    ),
    LoanRequest(
      id: "4",
      userName: "Alice Brown",
      equipmentName: "Mikrofon Wireless",
      borrowDate: "2026-01-08",
      dueDate: "2026-01-10",
      purpose: "Podcast mahasiswa",
      status: LoanStatus.ditolak,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _filteredRequests = _requests;
  }

  void _filterRequests() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRequests = query.isEmpty
          ? _requests
          : _requests.where((r) {
              return r.userName.toLowerCase().contains(query) ||
                  r.equipmentName.toLowerCase().contains(query) ||
                  _statusText(r.status).toLowerCase().contains(query);
            }).toList();
    });
  }

  Color _statusColor(LoanStatus status) {
    switch (status) {
      case LoanStatus.menunggu:
        return AppTheme.statusPending;
      case LoanStatus.diproses:
        return AppTheme.statusConfirm;
      case LoanStatus.dipinjam:
        return AppTheme.statusBorrowed;
      case LoanStatus.dikembalikan:
        return AppTheme.statusReturned;
      case LoanStatus.ditolak:
        return AppTheme.statusLate;
    }
  }

  String _statusText(LoanStatus status) {
    return status.toString().split('.').last;
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return "-";
    final date = DateTime.tryParse(dateString);
    if (date == null) return "-";
    return DateFormat.yMMMMd('id').format(date);
  }

  void _openDialog(LoanRequest request) {
    if (request.status == LoanStatus.dipinjam) {
      showDialog(
        context: context,
        builder: (_) => KembalikanDialog(
          request: request,
          onReturn: () {
            setState(() {
              request.status = LoanStatus.dikembalikan;
              _filterRequests();
            });
          },
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => DetailPinjamDialog(
          request: request,
          statusText: _statusText(request.status),
          statusColor: _statusColor(request.status),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount =
        _requests.where((r) => r.status == LoanStatus.menunggu).length;
    final borrowedCount =
        _requests.where((r) => r.status == LoanStatus.dipinjam).length;
    final confirmCount =
        _requests.where((r) => r.status == LoanStatus.diproses).length;
    final returnedCount =
        _requests.where((r) => r.status == LoanStatus.dikembalikan).length;
    final rejectedCount =
        _requests.where((r) => r.status == LoanStatus.ditolak).length;

    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Peminjaman Saya'),
      drawer: const SideMenu(role: 'peminjam'),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // ===== STATUS GRID =====
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              SizedBox(
                width: (MediaQuery.of(context).size.width - 42) / 2,
                child: PinjamCard(
                  title: 'Menunggu',
                  value: pendingCount.toString(),
                  color: AppTheme.statusPending,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 42) / 2,
                child: PinjamCard(
                  title: 'Diproses',
                  value: confirmCount.toString(),
                  color: AppTheme.statusConfirm,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 42) / 2,
                child: PinjamCard(
                  title: 'Dipinjam',
                  value: borrowedCount.toString(),
                  color: AppTheme.statusBorrowed,
                ),
              ),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 42) / 2,
                child: PinjamCard(
                  title: 'Dikembalikan',
                  value: returnedCount.toString(),
                  color: AppTheme.statusReturned,
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width - 28,
                child: PinjamCard(
                  title: 'Ditolak',
                  value: rejectedCount.toString(),
                  color: AppTheme.statusLate,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ===== SEARCH =====
          TextField(
            controller: _searchController,
            onChanged: (_) => _filterRequests(),
            decoration: InputDecoration(
              labelText: 'Cari peminjaman',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.cardColor),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ===== DATA TABLE =====
          Card(
            color: theme.scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daftar Peminjaman',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 28,
                      headingRowColor: WidgetStatePropertyAll(
                          theme.scaffoldBackgroundColor),
                      columns: const [
                        DataColumn(label: Text('Nama Alat')),
                        DataColumn(label: Text('Tgl Pinjam')),
                        DataColumn(label: Text('Jatuh Tempo')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Center(child: Text('Aksi'))),
                      ],
                      rows: _filteredRequests.map((r) {
                        return DataRow(
                          cells: [
                            DataCell(Text(r.equipmentName)),
                            DataCell(Text(_formatDate(r.borrowDate))),
                            DataCell(Text(_formatDate(r.dueDate))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _statusColor(r.status),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _statusText(r.status),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Center(
                                child: ElevatedButton(
                                  onPressed: () => _openDialog(r),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                  ),
                                  child: Text(
                                    r.status == LoanStatus.dipinjam
                                        ? "Kembalikan"
                                        : "Detail",
                                  ),
                                ),
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
        ],
      ),
    );
  }
}
