class AgencyWithdrawal {
  const AgencyWithdrawal({
    required this.id,
    required this.agencyId,
    required this.requestedBy,
    required this.amount,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.status,
    required this.createdAt,
    this.agencyName,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
  });

  final String id;
  final String agencyId;
  final String requestedBy;
  final double amount;
  final String bankName;
  final String accountName;
  final String accountNumber;
  final String status;
  final DateTime createdAt;
  final String? agencyName;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;

  AgencyWithdrawal copyWith({
    String? id,
    String? agencyId,
    String? requestedBy,
    double? amount,
    String? bankName,
    String? accountName,
    String? accountNumber,
    String? status,
    DateTime? createdAt,
    String? agencyName,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? rejectionReason,
  }) {
    return AgencyWithdrawal(
      id: id ?? this.id,
      agencyId: agencyId ?? this.agencyId,
      requestedBy: requestedBy ?? this.requestedBy,
      amount: amount ?? this.amount,
      bankName: bankName ?? this.bankName,
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      agencyName: agencyName ?? this.agencyName,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  String get statusLabel {
    return switch (status) {
      'approved' => 'Disetujui',
      'rejected' => 'Ditolak',
      'paid' => 'Dibayar',
      _ => 'Menunggu',
    };
  }
}
