import '../../domain/entities/agency_withdrawal.dart';

class AgencyWithdrawalDto extends AgencyWithdrawal {
  const AgencyWithdrawalDto({
    required super.id,
    required super.agencyId,
    required super.requestedBy,
    required super.amount,
    required super.bankName,
    required super.accountName,
    required super.accountNumber,
    required super.status,
    required super.createdAt,
    super.agencyName,
    super.reviewedBy,
    super.reviewedAt,
    super.rejectionReason,
  });

  factory AgencyWithdrawalDto.fromJson(Map<String, dynamic> json) {
    final agency = json['agencies'];
    Map<String, dynamic>? agencyMap;
    if (agency is Map<String, dynamic>) {
      agencyMap = agency;
    } else if (agency is List && agency.isNotEmpty) {
      agencyMap = agency.first as Map<String, dynamic>;
    }

    return AgencyWithdrawalDto(
      id: json['id'] as String,
      agencyId: json['agency_id'] as String,
      requestedBy: json['requested_by'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      bankName: json['bank_name'] as String? ?? '',
      accountName: json['account_name'] as String? ?? '',
      accountNumber: json['account_number'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'].toString()),
      agencyName: agencyMap?['name'] as String?,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: DateTime.tryParse(json['reviewed_at']?.toString() ?? ''),
      rejectionReason: json['rejection_reason'] as String?,
    );
  }
}
