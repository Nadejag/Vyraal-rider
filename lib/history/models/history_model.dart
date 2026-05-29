enum RiderHistoryFilter { all, completed, cancelled }

enum RiderHistoryStatus { completed, cancelled }

class RiderHistoryModel {
  const RiderHistoryModel({
    required this.totalTrips,
    required this.completedTrips,
    required this.cancelledTrips,
    required this.totalEarnings,
    required this.availableBalance,
    required this.hoursOnline,
    required this.trips,
    this.filter = RiderHistoryFilter.all,
    this.error,
  });

  final int totalTrips;
  final int completedTrips;
  final int cancelledTrips;
  final double totalEarnings;
  final double availableBalance;
  final double hoursOnline;
  final List<RiderHistoryTrip> trips;
  final RiderHistoryFilter filter;
  final String? error;

  List<RiderHistoryTrip> get visibleTrips {
    switch (filter) {
      case RiderHistoryFilter.completed:
        return trips
            .where((trip) => trip.status == RiderHistoryStatus.completed)
            .toList();
      case RiderHistoryFilter.cancelled:
        return trips
            .where((trip) => trip.status == RiderHistoryStatus.cancelled)
            .toList();
      case RiderHistoryFilter.all:
        return trips;
    }
  }

  String get totalEarningsLabel => 'Rs. ${totalEarnings.round()}';

  String get availableBalanceLabel => 'Rs. ${availableBalance.round()}';

  RiderHistoryModel copyWith({
    int? totalTrips,
    int? completedTrips,
    int? cancelledTrips,
    double? totalEarnings,
    double? availableBalance,
    double? hoursOnline,
    List<RiderHistoryTrip>? trips,
    RiderHistoryFilter? filter,
    String? error,
    bool clearError = false,
  }) {
    return RiderHistoryModel(
      totalTrips: totalTrips ?? this.totalTrips,
      completedTrips: completedTrips ?? this.completedTrips,
      cancelledTrips: cancelledTrips ?? this.cancelledTrips,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      availableBalance: availableBalance ?? this.availableBalance,
      hoursOnline: hoursOnline ?? this.hoursOnline,
      trips: trips ?? this.trips,
      filter: filter ?? this.filter,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class RiderHistoryTrip {
  const RiderHistoryTrip({
    required this.id,
    required this.orderKey,
    required this.storeName,
    required this.customerName,
    required this.pickupAddress,
    required this.dropOffAddress,
    required this.itemSummary,
    required this.earning,
    required this.orderAmount,
    required this.paymentMethod,
    required this.status,
    required this.dateLabel,
    required this.timestamp,
    this.distanceKm,
    this.rating,
  });

  final String id;
  final String orderKey;
  final String storeName;
  final String customerName;
  final String pickupAddress;
  final String dropOffAddress;
  final String itemSummary;
  final double earning;
  final double orderAmount;
  final String paymentMethod;
  final RiderHistoryStatus status;
  final String dateLabel;
  final int timestamp;
  final double? distanceKm;
  final double? rating;

  String get earningLabel => 'Rs. ${earning.round()}';

  String get orderAmountLabel => 'Rs. ${orderAmount.round()}';

  String get statusLabel =>
      status == RiderHistoryStatus.completed ? 'Completed' : 'Cancelled';
}
