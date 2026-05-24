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
    );
  }
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
    this.remainingSeconds = 60,
    this.isLocked = false,
    this.isHighlighted = false,
  });

  final String id;
  final String storeName;
  final double distanceKm;
  final String estimatedEarning;
  final String items;
  final int itemCount;
  final String customerArea;
  final String shopImageAsset;
  final int remainingSeconds;
  final bool isLocked;
  final bool isHighlighted;

  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km away';

  RiderOrderModel copyWith({
    String? id,
    String? storeName,
    double? distanceKm,
    String? estimatedEarning,
    String? items,
    int? itemCount,
    String? customerArea,
    String? shopImageAsset,
    int? remainingSeconds,
    bool? isLocked,
    bool? isHighlighted,
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
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isLocked: isLocked ?? this.isLocked,
      isHighlighted: isHighlighted ?? this.isHighlighted,
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

enum PayoutStatus { pending, approved, paid }

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
    this.isOnline = true,
    this.hasProfilePhoto = true,
    this.language = 'English',
    this.alertsEnabled = true,
    this.cnicStatus = DocumentReviewStatus.approved,
    this.bikeDocsStatus = DocumentReviewStatus.approved,
  });

  final String fullName;
  final String phoneNumber;
  final String cnic;
  final String bikeRegistrationNumber;
  final String vehicleName;
  final String memberSince;
  final bool isOnline;
  final bool hasProfilePhoto;
  final String language;
  final bool alertsEnabled;
  final DocumentReviewStatus cnicStatus;
  final DocumentReviewStatus bikeDocsStatus;

  bool get isApproved =>
      cnicStatus == DocumentReviewStatus.approved &&
      bikeDocsStatus == DocumentReviewStatus.approved;

  RiderProfileModel copyWith({
    String? fullName,
    String? phoneNumber,
    String? cnic,
    String? bikeRegistrationNumber,
    String? vehicleName,
    String? memberSince,
    bool? isOnline,
    bool? hasProfilePhoto,
    String? language,
    bool? alertsEnabled,
    DocumentReviewStatus? cnicStatus,
    DocumentReviewStatus? bikeDocsStatus,
  }) {
    return RiderProfileModel(
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      cnic: cnic ?? this.cnic,
      bikeRegistrationNumber:
          bikeRegistrationNumber ?? this.bikeRegistrationNumber,
      vehicleName: vehicleName ?? this.vehicleName,
      memberSince: memberSince ?? this.memberSince,
      isOnline: isOnline ?? this.isOnline,
      hasProfilePhoto: hasProfilePhoto ?? this.hasProfilePhoto,
      language: language ?? this.language,
      alertsEnabled: alertsEnabled ?? this.alertsEnabled,
      cnicStatus: cnicStatus ?? this.cnicStatus,
      bikeDocsStatus: bikeDocsStatus ?? this.bikeDocsStatus,
    );
  }
}

enum DocumentReviewStatus { missing, pending, approved }
