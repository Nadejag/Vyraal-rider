enum RiderVerificationStep { otp, profileSetup, submitted, approved }

class VerificationModel {
  static const codeLength = 6;

  const VerificationModel({
    this.phoneNumber = '',
    this.code = '',
    this.secondsRemaining = 60,
    this.step = RiderVerificationStep.otp,
    this.riderId = '',
    this.name = '',
    this.city = '',
    this.address = '',
    this.cnicNumber = '',
    this.licenseNumber = '',
    this.vehicleType = 'Bike',
    this.vehicleNumber = '',
    this.jazzCashNumber = '',
    this.easyPaisaNumber = '',
    this.profilePhotoUrl = '',
    this.cnicFrontUrl = '',
    this.cnicBackUrl = '',
    this.licenseFrontUrl = '',
    this.vehiclePhotoUrl = '',
    this.verificationStatus = 'not_submitted',
    this.workStatus = 'offline',
    this.rejectionReason = '',
  });

  final String phoneNumber;
  final String code;
  final int secondsRemaining;
  final RiderVerificationStep step;
  final String riderId;

  final String name;
  final String city;
  final String address;
  final String cnicNumber;
  final String licenseNumber;
  final String vehicleType;
  final String vehicleNumber;
  final String jazzCashNumber;
  final String easyPaisaNumber;
  final String profilePhotoUrl;
  final String cnicFrontUrl;
  final String cnicBackUrl;
  final String licenseFrontUrl;
  final String vehiclePhotoUrl;
  final String verificationStatus;
  final String workStatus;
  final String rejectionReason;

  String get formattedTimer {
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  bool get canVerify => code.length == codeLength;
  bool get canResend => secondsRemaining <= 0;

  bool get isProfileComplete =>
      name.trim().length >= 3 &&
      city.trim().isNotEmpty &&
      address.trim().length >= 6 &&
      cnicNumber.trim().length >= 13 &&
      vehicleType.trim().isNotEmpty &&
      vehicleNumber.trim().length >= 3;

  bool get hasMinimumDocuments =>
      cnicFrontUrl.trim().isNotEmpty &&
      cnicBackUrl.trim().isNotEmpty &&
      vehiclePhotoUrl.trim().isNotEmpty;

  bool get hasAllRecommendedDocuments =>
      cnicFrontUrl.trim().isNotEmpty &&
      cnicBackUrl.trim().isNotEmpty &&
      licenseFrontUrl.trim().isNotEmpty &&
      vehiclePhotoUrl.trim().isNotEmpty &&
      profilePhotoUrl.trim().isNotEmpty;

  bool get isApproved => verificationStatus == 'approved';
  bool get isPending => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';

  VerificationModel copyWith({
    String? phoneNumber,
    String? code,
    int? secondsRemaining,
    RiderVerificationStep? step,
    String? riderId,
    String? name,
    String? city,
    String? address,
    String? cnicNumber,
    String? licenseNumber,
    String? vehicleType,
    String? vehicleNumber,
    String? jazzCashNumber,
    String? easyPaisaNumber,
    String? profilePhotoUrl,
    String? cnicFrontUrl,
    String? cnicBackUrl,
    String? licenseFrontUrl,
    String? vehiclePhotoUrl,
    String? verificationStatus,
    String? workStatus,
    String? rejectionReason,
  }) {
    return VerificationModel(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      code: code ?? this.code,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      step: step ?? this.step,
      riderId: riderId ?? this.riderId,
      name: name ?? this.name,
      city: city ?? this.city,
      address: address ?? this.address,
      cnicNumber: cnicNumber ?? this.cnicNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      jazzCashNumber: jazzCashNumber ?? this.jazzCashNumber,
      easyPaisaNumber: easyPaisaNumber ?? this.easyPaisaNumber,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      cnicFrontUrl: cnicFrontUrl ?? this.cnicFrontUrl,
      cnicBackUrl: cnicBackUrl ?? this.cnicBackUrl,
      licenseFrontUrl: licenseFrontUrl ?? this.licenseFrontUrl,
      vehiclePhotoUrl: vehiclePhotoUrl ?? this.vehiclePhotoUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      workStatus: workStatus ?? this.workStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}