class WithdrawModel {
  const WithdrawModel({
    this.availableBalance = 0,
    this.withdrawalAmount = 0,
    this.serviceFeeRate = 0.015,
    this.selectedMethod = PayoutMethod.easypaisa,
    this.payoutStatus = PayoutStatus.draft,
    this.easypaisaNumber = '',
    this.jazzCashNumber = '',
    this.accountTitle = '',
    this.totalEarned = 0,
    this.pendingAmount = 0,
    this.paidAmount = 0,
    this.approvedAmount = 0,
    this.todayEarnings = 0,
    this.completedTrips = 0,
    this.history = const [],
    this.isLoading = true,
    this.errorMessage,
  });

  final int availableBalance;
  final int withdrawalAmount;
  final double serviceFeeRate;
  final PayoutMethod selectedMethod;
  final PayoutStatus payoutStatus;
  final String easypaisaNumber;
  final String jazzCashNumber;
  final String accountTitle;
  final int totalEarned;
  final int pendingAmount;
  final int paidAmount;
  final int approvedAmount;
  final int todayEarnings;
  final int completedTrips;
  final List<WithdrawalRequestModel> history;
  final bool isLoading;
  final String? errorMessage;

  int get serviceFee => withdrawalAmount <= 0
      ? 0
      : (withdrawalAmount * serviceFeeRate).round();

  int get finalAmount {
    final value = withdrawalAmount - serviceFee;
    return value < 0 ? 0 : value;
  }

  String get selectedAccountNumber => selectedMethod == PayoutMethod.easypaisa
      ? easypaisaNumber
      : jazzCashNumber;

  bool get hasAccountNumber => selectedAccountNumber.trim().length >= 10;

  bool get canRequest =>
      !isLoading &&
      withdrawalAmount > 0 &&
      withdrawalAmount <= availableBalance &&
      finalAmount > 0 &&
      hasAccountNumber;

  WithdrawModel copyWith({
    int? availableBalance,
    int? withdrawalAmount,
    double? serviceFeeRate,
    PayoutMethod? selectedMethod,
    PayoutStatus? payoutStatus,
    String? easypaisaNumber,
    String? jazzCashNumber,
    String? accountTitle,
    int? totalEarned,
    int? pendingAmount,
    int? paidAmount,
    int? approvedAmount,
    int? todayEarnings,
    int? completedTrips,
    List<WithdrawalRequestModel>? history,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WithdrawModel(
      availableBalance: availableBalance ?? this.availableBalance,
      withdrawalAmount: withdrawalAmount ?? this.withdrawalAmount,
      serviceFeeRate: serviceFeeRate ?? this.serviceFeeRate,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      payoutStatus: payoutStatus ?? this.payoutStatus,
      easypaisaNumber: easypaisaNumber ?? this.easypaisaNumber,
      jazzCashNumber: jazzCashNumber ?? this.jazzCashNumber,
      accountTitle: accountTitle ?? this.accountTitle,
      totalEarned: totalEarned ?? this.totalEarned,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      approvedAmount: approvedAmount ?? this.approvedAmount,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      completedTrips: completedTrips ?? this.completedTrips,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  WithdrawModel applySummary(WithdrawalSummary summary) {
    final safeAmount = withdrawalAmount.clamp(0, summary.availableBalance).toInt();
    return copyWith(
      availableBalance: summary.availableBalance,
      withdrawalAmount: safeAmount,
      totalEarned: summary.totalEarned,
      pendingAmount: summary.pendingAmount,
      paidAmount: summary.paidAmount,
      approvedAmount: summary.approvedAmount,
      todayEarnings: summary.todayEarnings,
      completedTrips: summary.completedTrips,
      payoutStatus: summary.latestStatus,
      history: summary.history,
      easypaisaNumber: easypaisaNumber.trim().isEmpty
          ? summary.easypaisaNumber
          : easypaisaNumber,
      jazzCashNumber: jazzCashNumber.trim().isEmpty
          ? summary.jazzCashNumber
          : jazzCashNumber,
      accountTitle: accountTitle.trim().isEmpty
          ? summary.accountTitle
          : accountTitle,
      isLoading: false,
      clearError: true,
    );
  }
}

class WithdrawalSummary {
  const WithdrawalSummary({
    required this.availableBalance,
    required this.totalEarned,
    required this.pendingAmount,
    required this.approvedAmount,
    required this.paidAmount,
    required this.todayEarnings,
    required this.completedTrips,
    required this.history,
    required this.latestStatus,
    this.easypaisaNumber = '',
    this.jazzCashNumber = '',
    this.accountTitle = '',
  });

  final int availableBalance;
  final int totalEarned;
  final int pendingAmount;
  final int approvedAmount;
  final int paidAmount;
  final int todayEarnings;
  final int completedTrips;
  final List<WithdrawalRequestModel> history;
  final PayoutStatus latestStatus;
  final String easypaisaNumber;
  final String jazzCashNumber;
  final String accountTitle;

  factory WithdrawalSummary.empty() => const WithdrawalSummary(
        availableBalance: 0,
        totalEarned: 0,
        pendingAmount: 0,
        approvedAmount: 0,
        paidAmount: 0,
        todayEarnings: 0,
        completedTrips: 0,
        history: [],
        latestStatus: PayoutStatus.draft,
      );
}

class WithdrawalRequestModel {
  const WithdrawalRequestModel({
    required this.id,
    required this.riderId,
    required this.amount,
    required this.serviceFee,
    required this.finalAmount,
    required this.method,
    required this.accountTitle,
    required this.accountNumber,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.note,
    this.adminNote,
  });

  final String id;
  final String riderId;
  final int amount;
  final int serviceFee;
  final int finalAmount;
  final PayoutMethod method;
  final String accountTitle;
  final String accountNumber;
  final PayoutStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? note;
  final String? adminNote;

  bool get isActive =>
      status == PayoutStatus.pending || status == PayoutStatus.approved;

  factory WithdrawalRequestModel.fromJson(
    Map<String, dynamic> json,
    String fallbackId,
  ) {
    return WithdrawalRequestModel(
      id: (json['id'] ?? fallbackId).toString(),
      riderId: (json['riderId'] ?? json['userId'] ?? '').toString(),
      amount: _intValue(json['amount']),
      serviceFee: _intValue(json['serviceFee']),
      finalAmount: _intValue(json['finalAmount'] ?? json['netAmount']),
      method: PayoutMethodX.fromValue(json['method']?.toString()),
      accountTitle: (json['accountTitle'] ?? '').toString(),
      accountNumber: (json['accountNumber'] ?? '').toString(),
      status: PayoutStatusX.fromValue(json['status']?.toString()),
      createdAt: _dateValue(json['createdAt']),
      updatedAt: _dateValue(json['updatedAt']),
      note: json['note']?.toString(),
      adminNote: json['adminNote']?.toString(),
    );
  }
}

enum PayoutMethod { easypaisa, jazzCash }

enum PayoutStatus { draft, pending, approved, rejected, paid }

extension PayoutMethodX on PayoutMethod {
  String get label => switch (this) {
        PayoutMethod.easypaisa => 'EasyPaisa',
        PayoutMethod.jazzCash => 'JazzCash',
      };

  String get shortLabel => switch (this) {
        PayoutMethod.easypaisa => 'Easypaisa',
        PayoutMethod.jazzCash => 'JazzCash',
      };

  static PayoutMethod fromValue(String? value) {
    final normalized = (value ?? '').toLowerCase().replaceAll(' ', '');
    if (normalized.contains('jazz')) return PayoutMethod.jazzCash;
    return PayoutMethod.easypaisa;
  }
}

extension PayoutStatusX on PayoutStatus {
  String get label => switch (this) {
        PayoutStatus.draft => 'Draft',
        PayoutStatus.pending => 'Pending',
        PayoutStatus.approved => 'Approved',
        PayoutStatus.rejected => 'Rejected',
        PayoutStatus.paid => 'Paid',
      };

  static PayoutStatus fromValue(String? value) {
    final normalized = (value ?? '').toLowerCase();
    if (normalized.contains('paid')) return PayoutStatus.paid;
    if (normalized.contains('reject') || normalized.contains('cancel')) {
      return PayoutStatus.rejected;
    }
    if (normalized.contains('approve')) return PayoutStatus.approved;
    if (normalized.contains('pending')) return PayoutStatus.pending;
    return PayoutStatus.draft;
  }
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.-]'), '');
    return double.tryParse(cleaned)?.round() ?? 0;
  }
  return 0;
}

DateTime? _dateValue(Object? value) {
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.round());
  if (value is String) return DateTime.tryParse(value);
  return null;
}