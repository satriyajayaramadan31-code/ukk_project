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