import 'package:latlong2/latlong.dart';

enum RiderRouteStage { pickup, delivery }

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

enum RiderMapPointKind { rider, seller, customer }

class RiderNavigationSnapshot {
  const RiderNavigationSnapshot({
    required this.riderPosition,
    required this.sellerPosition,
    required this.customerPosition,
    required this.routePoints,
    this.heading = 0,
    this.distanceLabel = '1.2 km',
    this.etaLabel = '8 mins',
  });

  final LatLng riderPosition;
  final LatLng sellerPosition;
  final LatLng customerPosition;
  final List<LatLng> routePoints;
  final double heading;
  final String distanceLabel;
  final String etaLabel;

  RiderNavigationSnapshot copyWith({
    LatLng? riderPosition,
    LatLng? sellerPosition,
    LatLng? customerPosition,
    List<LatLng>? routePoints,
    double? heading,
    String? distanceLabel,
    String? etaLabel,
  }) {
    return RiderNavigationSnapshot(
      riderPosition: riderPosition ?? this.riderPosition,
      sellerPosition: sellerPosition ?? this.sellerPosition,
      customerPosition: customerPosition ?? this.customerPosition,
      routePoints: routePoints ?? this.routePoints,
      heading: heading ?? this.heading,
      distanceLabel: distanceLabel ?? this.distanceLabel,
      etaLabel: etaLabel ?? this.etaLabel,
    );
  }
}

abstract final class DemoMapPoints {
  static const rider = LatLng(31.4705, 74.4095);
  static const seller = LatLng(31.4667, 74.4131);
  static const customer = LatLng(31.4583, 74.4212);

  static const snapshot = RiderNavigationSnapshot(
    riderPosition: rider,
    sellerPosition: seller,
    customerPosition: customer,
    routePoints: [rider, seller, customer],
  );
}
