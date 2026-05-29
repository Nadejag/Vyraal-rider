class HomeModel {
  const HomeModel({
    required this.todayTrips,
    required this.todayEarnings,
    required this.orders,
    required this.weeklyTotal,
    required this.weeklyGrowth,
    required this.weekRange,
    required this.weeklyEarnings,
    required this.tripHistory,
    required this.payoutStatus,
    required this.totalTrips,
    required this.hoursOnline,
    required this.detailedTrips,
    required this.profile,
    this.selectedTabIndex = 0,
    this.ordersError,
  });

  final int todayTrips;
  final String todayEarnings;
  final List<RiderOrderModel> orders;
  final String weeklyTotal;
  final String weeklyGrowth;
  final String weekRange;
  final List<WeeklyEarningModel> weeklyEarnings;
  final List<TripHistoryModel> tripHistory;
  final PayoutStatus payoutStatus;
  final int totalTrips;
  final double hoursOnline;
  final List<DetailedTripModel> detailedTrips;
  final RiderProfileModel profile;
  final int selectedTabIndex;
  final String? ordersError;

  static HomeModel empty({RiderProfileModel? profile}) {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 6));
    return HomeModel(
      todayTrips: 0,
      todayEarnings: 'Rs. 0',
      orders: const [],
      weeklyTotal: 'Rs. 0',
      weeklyGrowth: '0%',
      weekRange: '${_shortDate(start)} - ${_shortDate(now)}',
      weeklyEarnings: _emptyWeek(now),
      tripHistory: const [],
      payoutStatus: PayoutStatus.pending,
      totalTrips: 0,
      hoursOnline: 0,
      detailedTrips: const [],
      profile: profile ?? RiderProfileModel.empty(),
    );
  }

  HomeModel copyWith({
    int? todayTrips,
    String? todayEarnings,
    List<RiderOrderModel>? orders,
    String? weeklyTotal,
    String? weeklyGrowth,
    String? weekRange,
    List<WeeklyEarningModel>? weeklyEarnings,
    List<TripHistoryModel>? tripHistory,
    PayoutStatus? payoutStatus,
    int? totalTrips,
    double? hoursOnline,
    List<DetailedTripModel>? detailedTrips,
    RiderProfileModel? profile,
    int? selectedTabIndex,
    String? ordersError,
    bool clearOrdersError = false,
  }) {
    return HomeModel(
      todayTrips: todayTrips ?? this.todayTrips,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      orders: orders ?? this.orders,
      weeklyTotal: weeklyTotal ?? this.weeklyTotal,
      weeklyGrowth: weeklyGrowth ?? this.weeklyGrowth,
      weekRange: weekRange ?? this.weekRange,
      weeklyEarnings: weeklyEarnings ?? this.weeklyEarnings,
      tripHistory: tripHistory ?? this.tripHistory,
      payoutStatus: payoutStatus ?? this.payoutStatus,
      totalTrips: totalTrips ?? this.totalTrips,
      hoursOnline: hoursOnline ?? this.hoursOnline,
      detailedTrips: detailedTrips ?? this.detailedTrips,
      profile: profile ?? this.profile,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      ordersError: clearOrdersError ? null : ordersError ?? this.ordersError,
    );
  }

  static List<WeeklyEarningModel> _emptyWeek(DateTime now) {
    return List<WeeklyEarningModel>.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      return WeeklyEarningModel(
        day: _dayLabel(day),
        amount: 0,
        isToday: _isSameDay(day, now),
      );
    });
  }

  static String _dayLabel(DateTime date) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[date.weekday - 1];
  }

  static String _shortDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class WeeklyEarningModel {
  const WeeklyEarningModel({
    required this.day,
    required this.amount,
    this.isToday = false,
  });

  final String day;
  final int amount;
  final bool isToday;
}

class RiderOrderModel {
  const RiderOrderModel({
    required this.id,
    required this.storeName,
    required this.distanceKm,
    required this.estimatedEarning,
    required this.items,
    required this.itemCount,
    required this.customerArea,
    required this.shopImageAsset,
    this.orderKey,
    this.sellerId,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.sellerPhone,
    this.sellerAddress,
    this.deliveryAddress,
    this.paymentAmount,
    this.sellerLat,
    this.sellerLng,
    this.deliveryLat,
    this.deliveryLng,
    this.shopImageUrl,
    this.shopImageBase64,
    this.remainingSeconds = 60,
    this.isLocked = false,
    this.isHighlighted = false,
    this.createdAt,
    this.updatedAt,
    this.status,
    this.requestStatus,
    this.deliveryStage,
  });

  final String id;
  final String storeName;
  final double distanceKm;
  final String estimatedEarning;
  final String items;
  final int itemCount;
  final String customerArea;
  final String shopImageAsset;
  final String? orderKey;
  final String? sellerId;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? sellerPhone;
  final String? sellerAddress;
  final String? deliveryAddress;
  final String? paymentAmount;
  final double? sellerLat;
  final double? sellerLng;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? shopImageUrl;
  final String? shopImageBase64;
  final int remainingSeconds;
  final bool isLocked;
  final bool isHighlighted;
  final int? createdAt;
  final int? updatedAt;
  final String? status;
  final String? requestStatus;
  final String? deliveryStage;

  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km away';
  String get displayCustomer => customerName?.trim().isNotEmpty == true
      ? customerName!.trim()
      : 'Customer';
  String get displaySellerPhone => sellerPhone?.trim().isNotEmpty == true
      ? sellerPhone!.trim()
      : 'No seller phone';
  String get displayCustomerPhone => customerPhone?.trim().isNotEmpty == true
      ? customerPhone!.trim()
      : 'No customer phone';

  RiderOrderModel copyWith({
    String? id,
    String? storeName,
    double? distanceKm,
    String? estimatedEarning,
    String? items,
    int? itemCount,
    String? customerArea,
    String? shopImageAsset,
    String? orderKey,
    String? sellerId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? sellerPhone,
    String? sellerAddress,
    String? deliveryAddress,
    String? paymentAmount,
    double? sellerLat,
    double? sellerLng,
    double? deliveryLat,
    double? deliveryLng,
    String? shopImageUrl,
    String? shopImageBase64,
    int? remainingSeconds,
    bool? isLocked,
    bool? isHighlighted,
    int? createdAt,
    int? updatedAt,
    String? status,
    String? requestStatus,
    String? deliveryStage,
  }) {
    return RiderOrderModel(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedEarning: estimatedEarning ?? this.estimatedEarning,
      items: items ?? this.items,
      itemCount: itemCount ?? this.itemCount,
      customerArea: customerArea ?? this.customerArea,
      shopImageAsset: shopImageAsset ?? this.shopImageAsset,
      orderKey: orderKey ?? this.orderKey,
      sellerId: sellerId ?? this.sellerId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      sellerAddress: sellerAddress ?? this.sellerAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      sellerLat: sellerLat ?? this.sellerLat,
      sellerLng: sellerLng ?? this.sellerLng,
      deliveryLat: deliveryLat ?? this.deliveryLat,
      deliveryLng: deliveryLng ?? this.deliveryLng,
      shopImageUrl: shopImageUrl ?? this.shopImageUrl,
      shopImageBase64: shopImageBase64 ?? this.shopImageBase64,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isLocked: isLocked ?? this.isLocked,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      requestStatus: requestStatus ?? this.requestStatus,
      deliveryStage: deliveryStage ?? this.deliveryStage,
    );
  }
}

class TripHistoryModel {
  const TripHistoryModel({
    required this.sellerName,
    required this.customerName,
    required this.location,
    required this.dateTime,
    required this.amount,
    required this.paymentType,
  });

  final String sellerName;
  final String customerName;
  final String location;
  final String dateTime;
  final String amount;
  final PaymentType paymentType;
}

enum PaymentType { cash, online }

enum PayoutStatus { pending, approved, paid, rejected }

class RiderNotificationModel {
  const RiderNotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timeLabel,
    this.isUnread = true,
    this.isUrgent = false,
    this.showPopup = false,
  });

  final String id;
  final RiderNotificationType type;
  final String title;
  final String message;
  final String timeLabel;
  final bool isUnread;
  final bool isUrgent;
  final bool showPopup;

  RiderNotificationModel copyWith({
    String? id,
    RiderNotificationType? type,
    String? title,
    String? message,
    String? timeLabel,
    bool? isUnread,
    bool? isUrgent,
    bool? showPopup,
  }) {
    return RiderNotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      timeLabel: timeLabel ?? this.timeLabel,
      isUnread: isUnread ?? this.isUnread,
      isUrgent: isUrgent ?? this.isUrgent,
      showPopup: showPopup ?? this.showPopup,
    );
  }
}

enum RiderNotificationType {
  orderRequest,
  orderAccepted,
  payoutApproved,
  adminMessage,
  announcement,
}

class DetailedTripModel {
  const DetailedTripModel({
    required this.dateTime,
    required this.id,
    required this.pickup,
    required this.dropOff,
    required this.amount,
    required this.paymentType,
    required this.status,
  });

  final String dateTime;
  final String id;
  final String pickup;
  final String dropOff;
  final String amount;
  final PaymentType paymentType;
  final TripStatus status;
}

enum TripStatus { completed, canceled }

class RiderProfileModel {
  const RiderProfileModel({
    required this.fullName,
    required this.phoneNumber,
    required this.cnic,
    required this.bikeRegistrationNumber,
    required this.vehicleName,
    required this.memberSince,
    this.email = '',
    this.isOnline = false,
    this.isBusy = false,
    this.hasProfilePhoto = false,
    this.language = 'English',
    this.alertsEnabled = true,
    this.emailNotificationsEnabled = true,
    this.cnicStatus = DocumentReviewStatus.missing,
    this.bikeDocsStatus = DocumentReviewStatus.missing,
    this.profilePhotoUrl,
    this.verificationStatus = 'incomplete',
  });

  final String fullName;
  final String phoneNumber;
  final String cnic;
  final String bikeRegistrationNumber;
  final String vehicleName;
  final String memberSince;
  final String email;
  final bool isOnline;
  final bool isBusy;
  final bool hasProfilePhoto;
  final String language;
  final bool alertsEnabled;
  final bool emailNotificationsEnabled;
  final DocumentReviewStatus cnicStatus;
  final DocumentReviewStatus bikeDocsStatus;
  final String? profilePhotoUrl;
  final String verificationStatus;

  static RiderProfileModel empty() => const RiderProfileModel(
    fullName: 'Rider',
    phoneNumber: '',
    cnic: '',
    bikeRegistrationNumber: '',
    vehicleName: '',
    memberSince: '',
    email: '',
    isOnline: false,
    isBusy: false,
    hasProfilePhoto: false,
    emailNotificationsEnabled: true,
    cnicStatus: DocumentReviewStatus.missing,
    bikeDocsStatus: DocumentReviewStatus.missing,
  );

  bool get isApproved =>
      cnicStatus == DocumentReviewStatus.approved &&
      bikeDocsStatus == DocumentReviewStatus.approved;

  String get displayStatus {
    if (isBusy) return 'Busy';
    return isOnline ? 'Online' : 'Offline';
  }

  RiderProfileModel copyWith({
    String? fullName,
    String? phoneNumber,
    String? cnic,
    String? bikeRegistrationNumber,
    String? vehicleName,
    String? memberSince,
    String? email,
    bool? isOnline,
    bool? isBusy,
    bool? hasProfilePhoto,
    String? language,
    bool? alertsEnabled,
    bool? emailNotificationsEnabled,
    DocumentReviewStatus? cnicStatus,
    DocumentReviewStatus? bikeDocsStatus,
    String? profilePhotoUrl,
    String? verificationStatus,
  }) {
    return RiderProfileModel(
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      cnic: cnic ?? this.cnic,
      bikeRegistrationNumber:
          bikeRegistrationNumber ?? this.bikeRegistrationNumber,
      vehicleName: vehicleName ?? this.vehicleName,
      memberSince: memberSince ?? this.memberSince,
      email: email ?? this.email,
      isOnline: isOnline ?? this.isOnline,
      isBusy: isBusy ?? this.isBusy,
      hasProfilePhoto: hasProfilePhoto ?? this.hasProfilePhoto,
      language: language ?? this.language,
      alertsEnabled: alertsEnabled ?? this.alertsEnabled,
      emailNotificationsEnabled:
          emailNotificationsEnabled ?? this.emailNotificationsEnabled,
      cnicStatus: cnicStatus ?? this.cnicStatus,
      bikeDocsStatus: bikeDocsStatus ?? this.bikeDocsStatus,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  factory RiderProfileModel.fromJson(Map<String, dynamic> json) {
    final cnicStatus = _docStatus(
      json['cnicStatus'] ??
          json['cnicVerificationStatus'] ??
          json['cnicReviewStatus'],
    );
    final bikeStatus = _docStatus(
      json['bikeDocsStatus'] ??
          json['vehicleDocsStatus'] ??
          json['bikeVerificationStatus'] ??
          json['licenseStatus'],
    );
    final photo = _string(
      json['profilePhotoUrl'] ??
          json['profilePhotoBase64'] ??
          json['avatarUrl'] ??
          json['photoUrl'] ??
          json['profileImageUrl'] ??
          json['profileImageBase64'],
    );
    return RiderProfileModel(
      fullName: _string(
        json['fullName'] ?? json['name'] ?? json['riderName'],
        fallback: 'Rider',
      ),
      phoneNumber: _string(json['phoneNumber'] ?? json['phone']),
      cnic: _string(json['cnic']),
      bikeRegistrationNumber: _string(
        json['bikeRegistrationNumber'] ??
            json['bikeNumber'] ??
            json['vehicleNumber'],
      ),
      vehicleName: _string(
        json['vehicleName'] ?? json['bikeName'] ?? json['vehicleType'],
      ),
      memberSince: _memberSince(json['createdAt'] ?? json['joinedAt']),
      email: _string(json['email']),
      isOnline: _bool(json['isOnline'] ?? json['online']),
      isBusy: _bool(json['isBusy'] ?? json['busy']),
      hasProfilePhoto: photo.isNotEmpty,
      language: _string(json['language'], fallback: 'English'),
      alertsEnabled: json['alertsEnabled'] is bool
          ? json['alertsEnabled'] as bool
          : true,
      emailNotificationsEnabled: json['emailNotificationsEnabled'] is bool
          ? json['emailNotificationsEnabled'] as bool
          : (json['emailNotificationsEnabled'] != null
                ? _bool(json['emailNotificationsEnabled'])
                : true),
      cnicStatus: cnicStatus,
      bikeDocsStatus: bikeStatus,
      profilePhotoUrl: photo.isEmpty ? null : photo,
      verificationStatus: _string(
        json['verificationStatus'],
        fallback: _verificationLabel(cnicStatus, bikeStatus),
      ),
    );
  }

  static String _string(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static bool _bool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().toLowerCase().trim() ?? '';
    return text == 'true' || text == 'online' || text == '1';
  }

  static DocumentReviewStatus _docStatus(Object? value) {
    final text = value?.toString().toLowerCase().trim() ?? '';
    if (text == 'approved' || text == 'verified') {
      return DocumentReviewStatus.approved;
    }
    if (text == 'pending' || text == 'submitted' || text == 'under_review') {
      return DocumentReviewStatus.pending;
    }
    if (text == 'rejected' || text == 'declined') {
      return DocumentReviewStatus.rejected;
    }
    return DocumentReviewStatus.missing;
  }

  static String _verificationLabel(
    DocumentReviewStatus cnic,
    DocumentReviewStatus bike,
  ) {
    if (cnic == DocumentReviewStatus.approved &&
        bike == DocumentReviewStatus.approved) {
      return 'approved';
    }
    if (cnic == DocumentReviewStatus.rejected ||
        bike == DocumentReviewStatus.rejected) {
      return 'rejected';
    }
    if (cnic == DocumentReviewStatus.pending ||
        bike == DocumentReviewStatus.pending) {
      return 'pending';
    }
    return 'incomplete';
  }

  static String _memberSince(Object? value) {
    final millis = _toMillis(value);
    if (millis == null) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  static int? _toMillis(Object? value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

enum DocumentReviewStatus { missing, pending, approved, rejected }
