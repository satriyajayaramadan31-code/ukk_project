enum LoanStatus { menunggu, dipinjam, dikembalikan, terlambat , diproses}

class Loan {
  final String id;
  String userName;
  String equipmentName;
  String borrowDate;
  String returnDate;
  String dueDate;
  String description;
  LoanStatus status;

  Loan({
    required this.id,
    required this.userName,
    required this.equipmentName,
    required this.borrowDate,
    required this.returnDate,
    required this.dueDate,
    required this.description,
    required this.status,
  });
}
