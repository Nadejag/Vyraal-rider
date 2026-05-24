class WithdrawModel {
  const WithdrawModel({
    this.availableBalance = 8200,
    this.withdrawalAmount = 5000,
    this.serviceFeeRate = 0.015,
    this.selectedMethod = PayoutMethod.easypaisa,
    this.payoutStatus = PayoutStatus.draft,
  });

  final int availableBalance;
  final int withdrawalAmount;
  final double serviceFeeRate;
  final PayoutMethod selectedMethod;
  final PayoutStatus payoutStatus;

  int get serviceFee => (withdrawalAmount * serviceFeeRate).round();
  int get finalAmount => withdrawalAmount - serviceFee;

  WithdrawModel copyWith({
    int? availableBalance,
    int? withdrawalAmount,
    double? serviceFeeRate,
    PayoutMethod? selectedMethod,
    PayoutStatus? payoutStatus,
  }) {
    return WithdrawModel(
      availableBalance: availableBalance ?? this.availableBalance,
      withdrawalAmount: withdrawalAmount ?? this.withdrawalAmount,
      serviceFeeRate: serviceFeeRate ?? this.serviceFeeRate,
      selectedMethod: selectedMethod ?? this.selectedMethod,
      payoutStatus: payoutStatus ?? this.payoutStatus,
    );
  }
}

enum PayoutMethod { easypaisa, jazzCash }

enum PayoutStatus { draft, pending, approved, paid }
