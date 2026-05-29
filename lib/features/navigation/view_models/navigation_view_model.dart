import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/base/base_view_model.dart';
import '../../../core/maps/osrm_route_service.dart';
import '../../../core/maps/rider_live_location_repository.dart';
import '../../../core/maps/rider_location_service.dart';
import '../../../core/maps/rider_map_models.dart';
import '../../../core/realtime/rider_active_delivery_store.dart';
import '../../../core/realtime/rider_delivery_repository.dart';
import '../../../core/realtime/rider_realtime_service.dart';
import '../../home/models/home_model.dart';
import '../models/navigation_model.dart';

class PickupNavigationViewModel extends BaseViewModel {
  PickupNavigationViewModel({
    RiderRealtimeService? realtimeService,
    RiderLocationService locationService = const RiderLocationService(),
    OsrmRouteService routeService = const OsrmRouteService(),
    RiderLiveLocationRepository? liveLocationRepository,
    RiderDeliveryRepository? deliveryRepository,
  }) : _realtimeService = realtimeService ?? RiderRealtimeService.instance,
       _locationService = locationService,
       _routeService = routeService,
       _liveLocationRepository =
           liveLocationRepository ?? RiderLiveLocationRepository(),
       _deliveryRepository = deliveryRepository ?? RiderDeliveryRepository() {
    final order = RiderActiveDeliveryStore.instance.activeOrder;
    if (order != null) {
      final hasShopLocation = order.sellerLat != null && order.sellerLng != null;
      model = PickupNavigationModel(
        orderId: order.id,
        sellerName: order.storeName,
        sellerPhone: order.sellerPhone ?? '',
        estimatedEarning: order.estimatedEarning,
        itemsCount: order.itemCount,
        address: order.sellerAddress ??
            (hasShopLocation ? 'Pinned seller shop location' : 'Seller pickup location not set'),
        sellerImageUrl: order.shopImageUrl,
        sellerImageBase64: order.shopImageBase64,
        hasShopLocation: hasShopLocation,
      );
      _navigationSnapshot = _snapshotForOrder(order).copyWith(
        locationStatus: hasShopLocation
            ? 'Getting rider GPS…'
            : 'Seller shop GPS missing. Ask seller to set Store Profile location.',
      );
      unawaited(_deliveryRepository.markHeadingToSeller(order));
    }
    _startTracking();
  }

  final RiderRealtimeService _realtimeService;
  final RiderLocationService _locationService;
  final OsrmRouteService _routeService;
  final RiderLiveLocationRepository _liveLocationRepository;
  final RiderDeliveryRepository _deliveryRepository;
  StreamSubscription<RiderLocationReading>? _locationSubscription;
  LatLng? _lastLivePosition;
  var _refreshingRoute = false;

  PickupNavigationModel model = const PickupNavigationModel();
  RiderNavigationSnapshot _navigationSnapshot = DemoMapPoints.snapshot;

  RiderNavigationSnapshot get navigationSnapshot => _navigationSnapshot;

  void markPickedUp() {
    final order = RiderActiveDeliveryStore.instance.activeOrder;
    if (order != null) {
      unawaited(_deliveryRepository.markPickedUp(order));
    }
    _realtimeService.orderPickedUp(model.orderId);
  }

  void _startTracking() {
    _locationSubscription = _locationService.liveLocationStream().listen(
      (reading) => unawaited(_applyLocationReading(reading)),
      onError: (_) => _markLocationUnavailable(),
      onDone: _markLocationUnavailable,
    );
  }

  Future<void> _applyLocationReading(RiderLocationReading reading) async {
    if (_refreshingRoute) return;
    _refreshingRoute = true;
    try {
      final order = RiderActiveDeliveryStore.instance.activeOrder;
      if (order == null) return;
      final heading = _headingFor(reading, _lastLivePosition);
      _lastLivePosition = reading.position;
      final destination = _navigationSnapshot.sellerPosition;
      final route = await _routeService.route([reading.position, destination]);
      _navigationSnapshot = _navigationSnapshot.copyWith(
        riderPosition: reading.position,
        hasLiveLocation: true,
        locationStatus: 'Live GPS active',
        heading: heading,
        routePoints: route.points,
        distanceLabel: route.distanceLabel,
        etaLabel: route.etaLabel,
      );
      model = PickupNavigationModel(
        orderId: model.orderId,
        sellerName: model.sellerName,
        sellerPhone: model.sellerPhone,
        estimatedEarning: model.estimatedEarning,
        itemsCount: model.itemsCount,
        timeAway: route.etaLabel,
        address: model.address,
        sellerImageUrl: model.sellerImageUrl,
        sellerImageBase64: model.sellerImageBase64,
        hasShopLocation: model.hasShopLocation,
      );
      await _liveLocationRepository.saveLocation(
        riderId: _riderId,
        orderId: model.orderId,
        position: reading.position,
        heading: heading,
      );
      notifyListeners();
    } finally {
      _refreshingRoute = false;
    }
  }

  void _markLocationUnavailable() {
    _navigationSnapshot = _navigationSnapshot.copyWith(
      hasLiveLocation: false,
      locationStatus: 'Turn on location to start live tracking',
      routePoints: [_navigationSnapshot.sellerPosition],
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}

class DeliveryNavigationViewModel extends BaseViewModel {
  DeliveryNavigationViewModel({
    RiderRealtimeService? realtimeService,
    RiderLocationService locationService = const RiderLocationService(),
    OsrmRouteService routeService = const OsrmRouteService(),
    RiderLiveLocationRepository? liveLocationRepository,
    RiderDeliveryRepository? deliveryRepository,
  }) : _realtimeService = realtimeService ?? RiderRealtimeService.instance,
       _locationService = locationService,
       _routeService = routeService,
       _liveLocationRepository =
           liveLocationRepository ?? RiderLiveLocationRepository(),
       _deliveryRepository = deliveryRepository ?? RiderDeliveryRepository() {
    final order = RiderActiveDeliveryStore.instance.activeOrder;
    if (order != null && order.customerName != null) {
      _model = DeliveryNavigationModel(
        orderId: order.id,
        customerName: order.customerName ?? 'Customer',
        customerPhone: order.customerPhone ?? '',
        address: order.deliveryAddress ?? order.customerArea,
        paymentAmount: order.paymentAmount ?? 'Rs. 0',
        items: order.items,
      );
      _navigationSnapshot = _snapshotForOrder(order);
      unawaited(_deliveryRepository.markHeadingToCustomer(order));
    }
    _startTracking();
  }

  final RiderRealtimeService _realtimeService;
  final RiderLocationService _locationService;
  final OsrmRouteService _routeService;
  final RiderLiveLocationRepository _liveLocationRepository;
  final RiderDeliveryRepository _deliveryRepository;
  StreamSubscription<RiderLocationReading>? _locationSubscription;
  LatLng? _lastLivePosition;
  var _refreshingRoute = false;

  DeliveryNavigationModel _model = const DeliveryNavigationModel();
  RiderNavigationSnapshot _navigationSnapshot = DemoMapPoints.snapshot;

  DeliveryNavigationModel get model => _model;
  RiderNavigationSnapshot get navigationSnapshot => _navigationSnapshot;

  bool get hasActiveOrder => model.orderId.isNotEmpty;
  bool get hasCustomerLocation => _navigationSnapshot.hasCustomerLocation;

  void callCustomer() {
    _realtimeService.customerCallRequested(
      _model.orderId,
      _model.customerPhone,
    );
  }

  void uploadDeliveryPhoto() {
    if (_model.hasDeliveryPhoto) return;

    _model = _model.copyWith(hasDeliveryPhoto: true);
    final order = RiderActiveDeliveryStore.instance.activeOrder;
    if (order != null) {
      unawaited(_deliveryRepository.uploadDeliveryProof(order));
    }
    _realtimeService.deliveryPhotoUploaded(_model.orderId);
    notifyListeners();
  }

  void markDelivered() {
    if (_model.isDelivered) return;

    _model = _model.copyWith(isDelivered: true, notificationSent: true);
    final order = RiderActiveDeliveryStore.instance.activeOrder;
    if (order != null) {
      unawaited(_deliveryRepository.markDelivered(order));
    }
    _realtimeService.orderDelivered(_model.orderId);
    _realtimeService.customerNotified(
      _model.orderId,
      'Your order has been delivered!',
    );
    RiderActiveDeliveryStore.instance.clear();
    notifyListeners();
  }

  void _startTracking() {
    _locationSubscription = _locationService.liveLocationStream().listen(
      (reading) => unawaited(_applyLocationReading(reading)),
      onError: (_) => _markLocationUnavailable(),
      onDone: _markLocationUnavailable,
    );
  }

  Future<void> _applyLocationReading(RiderLocationReading reading) async {
    if (_refreshingRoute) return;
    _refreshingRoute = true;
    try {
      final heading = _headingFor(reading, _lastLivePosition);
      _lastLivePosition = reading.position;
      final route = await _routeService.route([
        reading.position,
        _navigationSnapshot.customerPosition,
      ]);
      _navigationSnapshot = _navigationSnapshot.copyWith(
        riderPosition: reading.position,
        hasLiveLocation: true,
        locationStatus: 'Live GPS active',
        heading: heading,
        routePoints: route.points,
        distanceLabel: route.distanceLabel,
        etaLabel: route.etaLabel,
      );
      _model = _model.copyWith(
        eta: route.etaLabel,
        distance: route.distanceLabel,
      );
      await _liveLocationRepository.saveLocation(
        riderId: _riderId,
        orderId: _model.orderId,
        position: reading.position,
        heading: heading,
      );
      notifyListeners();
    } finally {
      _refreshingRoute = false;
    }
  }

  void _markLocationUnavailable() {
    _navigationSnapshot = _navigationSnapshot.copyWith(
      hasLiveLocation: false,
      locationStatus: 'Turn on location to start live tracking',
      routePoints: [_navigationSnapshot.customerPosition],
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}

String get _riderId {
  try {
    return FirebaseAuth.instance.currentUser?.uid ?? 'demo-rider';
  } catch (_) {
    return 'demo-rider';
  }
}

RiderNavigationSnapshot _snapshotForOrder(RiderOrderModel order) {
  final sellerLat = order.sellerLat;
  final sellerLng = order.sellerLng;
  final deliveryLat = order.deliveryLat;
  final deliveryLng = order.deliveryLng;
  final hasSeller = sellerLat != null && sellerLng != null;
  final hasCustomer = deliveryLat != null && deliveryLng != null;
  final seller = hasSeller ? LatLng(sellerLat, sellerLng) : DemoMapPoints.seller;
  final customer = hasCustomer
      ? LatLng(deliveryLat, deliveryLng)
      : DemoMapPoints.customer;
  return DemoMapPoints.snapshot.copyWith(
    sellerPosition: seller,
    customerPosition: customer,
    routePoints: hasSeller && hasCustomer ? [seller, customer] : [seller],
    hasSellerLocation: hasSeller,
    hasCustomerLocation: hasCustomer,
    sellerName: order.storeName,
    sellerAddress: order.sellerAddress ?? '',
    sellerPhone: order.sellerPhone ?? '',
    sellerImageUrl: order.shopImageUrl,
    sellerImageBase64: order.shopImageBase64,
    customerName: order.customerName ?? 'Customer',
    customerAddress: order.deliveryAddress ?? order.customerArea,
  );
}

double _headingFor(RiderLocationReading reading, LatLng? previousPosition) {
  if (reading.heading.isFinite && reading.heading >= 0) {
    return reading.heading % 360;
  }
  if (previousPosition == null) return 0;
  return _bearingBetween(previousPosition, reading.position);
}

double _bearingBetween(LatLng from, LatLng to) {
  final fromLat = _radians(from.latitude);
  final toLat = _radians(to.latitude);
  final deltaLng = _radians(to.longitude - from.longitude);
  final y = math.sin(deltaLng) * math.cos(toLat);
  final x =
      math.cos(fromLat) * math.sin(toLat) -
      math.sin(fromLat) * math.cos(toLat) * math.cos(deltaLng);
  return (_degrees(math.atan2(y, x)) + 360) % 360;
}

double _radians(double degrees) => degrees * math.pi / 180;

double _degrees(double radians) => radians * 180 / math.pi;