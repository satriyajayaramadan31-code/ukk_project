enum LoanStatus {
  menunggu,
  diproses,
  dipinjam,
  dikembalikan,
  ditolak,
}

class LoanRequest {
  final String id;
  final String userName;
  final String equipmentName;
  final String borrowDate;
  final String dueDate;
  final String purpose;
  LoanStatus status;

  LoanRequest({
    required this.id,
    required this.userName,
    required this.equipmentName,
    required this.borrowDate,
    required this.dueDate,
    required this.purpose,
    required this.status,
  });
}
