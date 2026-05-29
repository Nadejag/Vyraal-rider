import 'package:latlong2/latlong.dart';

enum RiderRouteStage { pickup, delivery }

enum RiderMapPointKind { rider, seller, customer }

class RiderMapPoint {
  const RiderMapPoint({
    required this.position,
    required this.label,
    required this.kind,
  });

  final LatLng position;
  final String label;
  final RiderMapPointKind kind;
}

class RiderNavigationSnapshot {
  const RiderNavigationSnapshot({
    required this.riderPosition,
    required this.sellerPosition,
    required this.customerPosition,
    required this.routePoints,
    this.hasLiveLocation = false,
    this.hasSellerLocation = false,
    this.hasCustomerLocation = false,
    this.locationStatus = 'Waiting for live GPS',
    this.heading = 0,
    this.distanceLabel = '--',
    this.etaLabel = 'GPS needed',
    this.sellerName = 'Seller',
    this.sellerPhone = '',
    this.sellerAddress = '',
    this.sellerImageUrl,
    this.sellerImageBase64,
    this.customerName = 'Customer',
    this.customerAddress = '',
  });

  final LatLng riderPosition;
  final LatLng sellerPosition;
  final LatLng customerPosition;
  final List<LatLng> routePoints;
  final bool hasLiveLocation;
  final bool hasSellerLocation;
  final bool hasCustomerLocation;
  final String locationStatus;
  final double heading;
  final String distanceLabel;
  final String etaLabel;
  final String sellerName;
  final String sellerPhone;
  final String sellerAddress;
  final String? sellerImageUrl;
  final String? sellerImageBase64;
  final String customerName;
  final String customerAddress;

  bool hasDestinationFor(RiderRouteStage stage) {
    return stage == RiderRouteStage.pickup
        ? hasSellerLocation
        : hasCustomerLocation;
  }

  RiderNavigationSnapshot copyWith({
    LatLng? riderPosition,
    LatLng? sellerPosition,
    LatLng? customerPosition,
    List<LatLng>? routePoints,
    bool? hasLiveLocation,
    bool? hasSellerLocation,
    bool? hasCustomerLocation,
    String? locationStatus,
    double? heading,
    String? distanceLabel,
    String? etaLabel,
    String? sellerName,
    String? sellerPhone,
    String? sellerAddress,
    String? sellerImageUrl,
    String? sellerImageBase64,
    String? customerName,
    String? customerAddress,
  }) {
    return RiderNavigationSnapshot(
      riderPosition: riderPosition ?? this.riderPosition,
      sellerPosition: sellerPosition ?? this.sellerPosition,
      customerPosition: customerPosition ?? this.customerPosition,
      routePoints: routePoints ?? this.routePoints,
      hasLiveLocation: hasLiveLocation ?? this.hasLiveLocation,
      hasSellerLocation: hasSellerLocation ?? this.hasSellerLocation,
      hasCustomerLocation: hasCustomerLocation ?? this.hasCustomerLocation,
      locationStatus: locationStatus ?? this.locationStatus,
      heading: heading ?? this.heading,
      distanceLabel: distanceLabel ?? this.distanceLabel,
      etaLabel: etaLabel ?? this.etaLabel,
      sellerName: sellerName ?? this.sellerName,
      sellerPhone: sellerPhone ?? this.sellerPhone,
      sellerAddress: sellerAddress ?? this.sellerAddress,
      sellerImageUrl: sellerImageUrl ?? this.sellerImageUrl,
      sellerImageBase64: sellerImageBase64 ?? this.sellerImageBase64,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
    );
  }
}

/// Safe map fallback only. This is not used as a fake rider/seller/customer.
/// The real rider position is taken from the mobile GPS.
abstract final class RiderMapFallback {
  static const pakistanCenter = LatLng(30.3753, 69.3451);

  static const snapshot = RiderNavigationSnapshot(
    riderPosition: pakistanCenter,
    sellerPosition: pakistanCenter,
    customerPosition: pakistanCenter,
    routePoints: <LatLng>[],
    hasLiveLocation: false,
    hasSellerLocation: false,
    hasCustomerLocation: false,
    locationStatus: 'Turn on location to show your real rider position',
  );
}

/// Kept only for old imports/references in your project.
/// Values are a neutral Pakistan center, not a dummy Lahore delivery.
@Deprecated('Use RiderMapFallback instead')
abstract final class DemoMapPoints {
  static const rider = RiderMapFallback.pakistanCenter;
  static const seller = RiderMapFallback.pakistanCenter;
  static const customer = RiderMapFallback.pakistanCenter;
  static const snapshot = RiderMapFallback.snapshot;
}