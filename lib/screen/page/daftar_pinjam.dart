import 'package:flutter/material.dart';
import '../widget/app_bar.dart';
import '../widget/side_menu.dart';
import '../widget/add_peminjaman.dart';
import '../widget/edit_peminjaman.dart';
import '../widget/delete_peminjaman.dart';
import '../widget/pinjam_card.dart';
import '../models/loan.dart';
import '../utils/theme.dart';
import 'package:intl/intl.dart';

class DaftarPinjam extends StatefulWidget {
  const DaftarPinjam({super.key});

  @override
  State<DaftarPinjam> createState() => _DaftarPinjamState();
}

class _DaftarPinjamState extends State<DaftarPinjam> {
  final List<Loan> _loans = [
    Loan(
      id: "1",
      userName: "John Doe",
      equipmentName: "Laptop Dell XPS 15",
      borrowDate: "2026-01-05",
      returnDate: "",
      dueDate: "2026-01-12",
      description: "Untuk presentasi proyek",
      status: LoanStatus.dipinjam,
    ),
    Loan(
      id: "2",
      userName: "Jane Smith",
      equipmentName: "Kamera DSLR Canon",
      borrowDate: "2026-01-01",
      returnDate: "",
      dueDate: "2026-01-08",
      description: "Pemotretan acara",
      status: LoanStatus.terlambat,
    ),
    Loan(
      id: "3",
      userName: "Bob Johnson",
      equipmentName: "Proyektor Epson",
      borrowDate: "2026-01-03",
      returnDate: "2026-01-08",
      dueDate: "2026-01-10",
      description: "Presentasi bisnis",
      status: LoanStatus.dikembalikan,
    ),
    Loan(
      id: "4",
      userName: "Alice Brown",
      equipmentName: "Mikrofon Wireless",
      borrowDate: "",
      returnDate: "",
      dueDate: "2026-01-15",
      description: "Untuk acara seminar",
      status: LoanStatus.menunggu,
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  List<Loan> _filteredLoans = [];

  @override
  void initState() {
    super.initState();
    _filteredLoans = _loans;
  }

  void _filterLoans() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLoans = query.isEmpty
          ? _loans
          : _loans.where((l) {
              return l.userName.toLowerCase().contains(query) ||
                  l.equipmentName.toLowerCase().contains(query);
            }).toList();
    });
  }

  String formatDate(String dateString) {
    if (dateString.isEmpty) return "-";
    final date = DateTime.tryParse(dateString);
    if (date == null) return "-";
    return DateFormat.yMMMMd('id').format(date);
  }

  String statusText(LoanStatus status) {
    return status.toString().split('.').last;
  }

  Color statusColor(LoanStatus status) {
    switch (status) {
      case LoanStatus.menunggu:
        return AppTheme.statusPending;
      case LoanStatus.dipinjam:
        return AppTheme.statusBorrowed;
      case LoanStatus.dikembalikan:
        return AppTheme.statusReturned;
      case LoanStatus.terlambat:
        return AppTheme.statusLate;
      case LoanStatus.diproses:
        return AppTheme.statusConfirm;
    }
  }

  void _editLoan(Loan loan) {
    setState(() {
      final index = _loans.indexWhere((l) => l.id == loan.id);
      _loans[index] = loan;
      _filterLoans();
    });
  }

  void _deleteLoan(Loan loan) {
    setState(() {
      _loans.remove(loan);
      _filterLoans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount =
        _loans.where((l) => l.status == LoanStatus.menunggu).length;
    final borrowedCount =
        _loans.where((l) => l.status == LoanStatus.dipinjam).length;
    final returnedCount =
        _loans.where((l) => l.status == LoanStatus.dikembalikan).length;
    final lateCount =
        _loans.where((l) => l.status == LoanStatus.terlambat).length;

    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppBarWithMenu(title: 'Daftar Peminjaman'),
      backgroundColor: theme.colorScheme.background,
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
                width: (MediaQuery.of(context).size.width - 42) / 2,
                child: PinjamCard(
                  title: 'Terlambat',
                  value: lateCount.toString(),
                  color: AppTheme.statusLate,
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width - 28,
                child: PinjamCard(
                  title: 'Konfirmasi',
                  value: "0",
                  color: AppTheme.statusConfirm,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ===== SEARCH + ADD =====
          Row(
            children: [
              Expanded(
                flex: 7,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _filterLoans(),
                  decoration: InputDecoration(
                    labelText: 'Cari peminjaman',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.cardColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AddPeminjamanDialog(
                          parentContext: context, // tetap
                          onAdd: (loan) {
                            // 1️⃣ tutup dialog add
                            Navigator.of(context).pop();

                            // 2️⃣ tambah data
                            setState(() {
                              _loans.add(loan);
                              _filterLoans();
                            });

                            // 3️⃣ popup success (manual close)
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Berhasil'),
                                content: const Text('Peminjaman berhasil ditambahkan'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                ),
              ),
            ],
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
                      headingRowColor:
                          WidgetStatePropertyAll(theme.scaffoldBackgroundColor),
                      columns: const [
                        DataColumn(label: Text('Peminjam')),
                        DataColumn(label: Text('Nama Alat')),
                        DataColumn(label: Text("Deskripsi")),
                        DataColumn(label: Text('Tgl Pinjam')),
                        DataColumn(label: Text('Tgl Kembali')),
                        DataColumn(label: Text('Dikembalikan')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Center(child: Text('Aksi'))),
                      ],
                      rows: _filteredLoans.map((loan) {
                        return DataRow(
                          cells: [
                            DataCell(Text(loan.userName)),
                            DataCell(Text(loan.equipmentName)),
                            DataCell(Text(loan.description)),
                            DataCell(Text(formatDate(loan.borrowDate))),
                            DataCell(Text(formatDate(loan.returnDate))),
                            DataCell(Text(formatDate(loan.dueDate))),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: statusColor(loan.status),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusText(loan.status),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => EditPeminjamanDialog(
                                            loan: loan,
                                            onEdit: _editLoan,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) =>
                                              DeletePeminjamanDialog(
                                            equipmentName: loan.equipmentName,
                                            userName: loan.userName,
                                            onDelete: () => _deleteLoan(loan),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
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
