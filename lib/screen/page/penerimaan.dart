import 'package:flutter/material.dart';
import '../widget/app_bar.dart';
import '../widget/side_menu.dart';
import '../models/loan_request.dart';
import '../widget/detail_pinjam.dart';
import '../widget/terima_pinjam.dart';
import '../widget/pinjam_card.dart';
import '../widget/konfirmasi_pinjam.dart';
import '../utils/theme.dart';
import 'package:intl/intl.dart';

class PenerimaanPage extends StatefulWidget {
  const PenerimaanPage({super.key});

  @override
  State<PenerimaanPage> createState() => _PenerimaanPageState();
}

class _PenerimaanPageState extends State<PenerimaanPage> {
  final TextEditingController _searchController = TextEditingController();
  List<LoanRequest> _filteredRequests = [];

  final List<LoanRequest> _requests = [
    LoanRequest(
      id: "1",
      userName: "John Doe",
      equipmentName: "Laptop Dell XPS 15",
      borrowDate: "2026-01-10",
      dueDate: "2026-01-17",
      returnDate: "2026-01-12",
      purpose: "Presentasi proyek akhir",
      status: LoanStatus.menunggu,
    ),
    LoanRequest(
      id: "2",
      userName: "Jane Smith",
      equipmentName: "Kamera DSLR Canon",
      borrowDate: "2026-01-11",
      dueDate: "2026-01-15",
      returnDate: "2026-01-12",
      purpose: "Dokumentasi acara kampus",
      status: LoanStatus.menunggu,
    ),
    LoanRequest(
      id: "3",
      userName: "Bob Johnson",
      equipmentName: "Proyektor Epson",
      borrowDate: "2026-01-09",
      dueDate: "2026-01-12",
      returnDate: "2026-01-12",
      purpose: "Seminar departemen",
      status: LoanStatus.diproses,
    ),
    LoanRequest(
      id: "4",
      userName: "Alice Brown",
      equipmentName: "Mikrofon Wireless",
      borrowDate: "2026-01-08",
      dueDate: "2026-01-10",
      returnDate: "2026-01-12",
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
    if (request.status == LoanStatus.menunggu) {
      showDialog(
        context: context,
        builder: (_) => TerimaPinjamDialog(
          request: request,
          onApprove: () {
            setState(() {
              request.status = LoanStatus.dipinjam;
              _filterRequests();
            });
            Navigator.pop(context);
          },
          onReject: () {
            setState(() {
              request.status = LoanStatus.ditolak;
              _filterRequests();
            });
            Navigator.pop(context);
          },
        ),
      );
    } else if (request.status == LoanStatus.diproses) {
      showDialog(
        context: context,
        builder: (_) => KonfirmasiPinjamDialog(
          request: request,
          onConfirm: () {
            setState(() {
              request.status = LoanStatus.dikembalikan;
              _filterRequests();
            });
            Navigator.pop(context);
          },
          onReject: () {
            setState(() {
              request.status = LoanStatus.dipinjam;
              _filterRequests();
            });
            Navigator.pop(context);
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
    final inProcessCount =
        _requests.where((r) => r.status == LoanStatus.diproses).length;
    final borrowedCount =
        _requests.where((r) => r.status == LoanStatus.dipinjam).length;
    final returnedCount =
        _requests.where((r) => r.status == LoanStatus.dikembalikan).length;
    final rejectedCount =
        _requests.where((r) => r.status == LoanStatus.ditolak).length;

    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Persetujuan Peminjaman'),
      drawer: const SideMenu(),
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
                  value: inProcessCount.toString(),
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
                        DataColumn(label: Text('Peminjam')),
                        DataColumn(label: Text('Nama Alat')),
                        DataColumn(label: Text('Tgl Pinjam')),
                        DataColumn(label: Text('Tgl Kembali')),
                        DataColumn(label: Text('Dikembalikan')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Center(child: Text('Aksi'))),
                      ],
                      rows: _filteredRequests.map((r) {
                        return DataRow(
                          cells: [
                            DataCell(Text(r.userName)),
                            DataCell(Text(r.equipmentName)),
                            DataCell(Text(_formatDate(r.borrowDate))),
                            DataCell(Text(_formatDate(r.dueDate))),
                            DataCell(Text(_formatDate(r.returnDate))),
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
                                    r.status == LoanStatus.menunggu
                                        ? "Proses"
                                        : r.status == LoanStatus.diproses
                                            ? "Konfirmasi"
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
