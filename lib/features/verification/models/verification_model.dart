class VerificationModel {
  const VerificationModel({
    this.phoneNumber = '',
    this.code = '',
    this.secondsRemaining = 60,
  });

  final String phoneNumber;
  final String code;
  final int secondsRemaining;

  String get formattedTimer {
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  bool get canVerify => code.length == 4;

  VerificationModel copyWith({
    String? phoneNumber,
    String? code,
    int? secondsRemaining,
  }) {
    return VerificationModel(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      code: code ?? this.code,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
    );
  }
}
