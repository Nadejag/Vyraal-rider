class RiderUserModel {
  final String id;
  final String phone;
  final String name;
  final String? email;
  final String? avatarUrl;
  final String? status;
  final String role;
  final bool isOnline;
  final bool isVerified;
  final String workStatus;
  final String verificationStatus;
  final String rejectionReason;
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
  final bool emailNotificationsEnabled;
  final int createdAt;
  final int updatedAt;

  const RiderUserModel({
    required this.id,
    required this.phone,
    required this.name,
    this.email,
    this.avatarUrl,
    this.status = 'active',
    this.role = 'rider',
    this.isOnline = false,
    this.isVerified = false,
    this.workStatus = 'offline',
    this.verificationStatus = 'not_submitted',
    this.rejectionReason = '',
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
    this.emailNotificationsEnabled = true,
    this.createdAt = 0,
    this.updatedAt = 0,
  });

  RiderUserModel copyWith({
    String? id,
    String? phone,
    String? name,
    String? email,
    String? avatarUrl,
    String? status,
    String? role,
    bool? isOnline,
    bool? isVerified,
    String? workStatus,
    String? verificationStatus,
    String? rejectionReason,
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
    bool? emailNotificationsEnabled,
    int? createdAt,
    int? updatedAt,
  }) {
    return RiderUserModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      status: status ?? this.status,
      role: role ?? this.role,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified ?? this.isVerified,
      workStatus: workStatus ?? this.workStatus,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rejectionReason: rejectionReason ?? this.rejectionReason,
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
      emailNotificationsEnabled:
          emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'uid': id,
    'phone': phone,
    'name': name,
    'email': email,
    'avatarUrl': avatarUrl,
    'status': status,
    'role': role,
    'isOnline': isOnline,
    'isVerified': isVerified,
    'workStatus': workStatus,
    'verificationStatus': verificationStatus,
    'rejectionReason': rejectionReason,
    'city': city,
    'address': address,
    'cnicNumber': cnicNumber,
    'licenseNumber': licenseNumber,
    'vehicleType': vehicleType,
    'vehicleNumber': vehicleNumber,
    'jazzCashNumber': jazzCashNumber,
    'easyPaisaNumber': easyPaisaNumber,
    'profilePhotoUrl': profilePhotoUrl,
    'cnicFrontUrl': cnicFrontUrl,
    'cnicBackUrl': cnicBackUrl,
    'licenseFrontUrl': licenseFrontUrl,
    'vehiclePhotoUrl': vehiclePhotoUrl,
    'emailNotificationsEnabled': emailNotificationsEnabled,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory RiderUserModel.fromJson(Map<String, dynamic> json) => RiderUserModel(
    id: _asString(json['id'] ?? json['uid']),
    phone: _asString(json['phone']),
    name: _asString(json['name']).isEmpty ? 'Rider' : _asString(json['name']),
    email: _nullableString(json['email']),
    avatarUrl: _nullableString(json['avatarUrl']),
    status: _asString(json['status']).isEmpty
        ? 'active'
        : _asString(json['status']),
    role: _asString(json['role']).isEmpty ? 'rider' : _asString(json['role']),
    isOnline: _asBool(json['isOnline']),
    isVerified: _asBool(json['isVerified']),
    workStatus: _asString(json['workStatus']).isEmpty
        ? 'offline'
        : _asString(json['workStatus']),
    verificationStatus: _asString(json['verificationStatus']).isEmpty
        ? 'not_submitted'
        : _asString(json['verificationStatus']),
    rejectionReason: _asString(json['rejectionReason']),
    city: _asString(json['city']),
    address: _asString(json['address']),
    cnicNumber: _asString(json['cnicNumber']),
    licenseNumber: _asString(json['licenseNumber']),
    vehicleType: _asString(json['vehicleType']).isEmpty
        ? 'Bike'
        : _asString(json['vehicleType']),
    vehicleNumber: _asString(json['vehicleNumber']),
    jazzCashNumber: _asString(json['jazzCashNumber']),
    easyPaisaNumber: _asString(json['easyPaisaNumber']),
    profilePhotoUrl: _asString(
      json['profilePhotoUrl'] ??
          json['profilePhotoBase64'] ??
          json['avatarUrl'] ??
          json['photoUrl'] ??
          json['profileImageUrl'] ??
          json['profileImageBase64'],
    ),
    cnicFrontUrl: _asString(
      json['cnicFrontUrl'] ?? json['cnicFrontBase64'] ?? json['cnicFrontImage'],
    ),
    cnicBackUrl: _asString(
      json['cnicBackUrl'] ?? json['cnicBackBase64'] ?? json['cnicBackImage'],
    ),
    licenseFrontUrl: _asString(
      json['licenseFrontUrl'] ??
          json['licenseFrontBase64'] ??
          json['licenseImage'],
    ),
    vehiclePhotoUrl: _asString(
      json['vehiclePhotoUrl'] ??
          json['vehiclePhotoBase64'] ??
          json['vehicleImage'],
    ),
    emailNotificationsEnabled: json['emailNotificationsEnabled'] is bool
        ? json['emailNotificationsEnabled'] as bool
        : _asBool(json['emailNotificationsEnabled'] ?? true),
    createdAt: _asInt(json['createdAt']),
    updatedAt: _asInt(json['updatedAt']),
  );

  static String _asString(Object? value) => value?.toString().trim() ?? '';
  static String? _nullableString(Object? value) {
    final text = _asString(value);
    return text.isEmpty ? null : text;
  }

  static bool _asBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
