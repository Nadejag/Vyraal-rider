import 'dart:async';

import '../../../core/base/base_view_model.dart';
import '../../../core/maps/osrm_route_service.dart';
import '../../../core/maps/rider_live_location_repository.dart';
import '../../../core/maps/rider_location_service.dart';
import '../../../core/maps/rider_map_models.dart';
import '../../../core/realtime/rider_realtime_service.dart';
import '../models/navigation_model.dart';

class PickupNavigationViewModel extends BaseViewModel {
  PickupNavigationViewModel({
    RiderRealtimeService? realtimeService,
    RiderLocationService locationService = const RiderLocationService(),
    OsrmRouteService routeService = const OsrmRouteService(),
    RiderLiveLocationRepository? liveLocationRepository,
  }) : _realtimeService = realtimeService ?? RiderRealtimeService.instance,
       _locationService = locationService,
       _routeService = routeService,
       _liveLocationRepository =
           liveLocationRepository ?? RiderLiveLocationRepository() {
    _startTracking();
  }

  final RiderRealtimeService _realtimeService;
  final RiderLocationService _locationService;
  final OsrmRouteService _routeService;
  final RiderLiveLocationRepository _liveLocationRepository;
  Timer? _trackingTimer;

  final PickupNavigationModel model = const PickupNavigationModel();
  RiderNavigationSnapshot _navigationSnapshot = DemoMapPoints.snapshot;

  RiderNavigationSnapshot get navigationSnapshot => _navigationSnapshot;

  void markPickedUp() {
    _realtimeService.orderPickedUp('order-amanat-dairy');
  }

  void _startTracking() {
    _refreshLocationAndRoute();
    _trackingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshLocationAndRoute(),
    );
  }

  Future<void> _refreshLocationAndRoute() async {
    final reading = await _locationService.currentLocation();
    final route = await _routeService.route([
      reading.position,
      _navigationSnapshot.sellerPosition,
    ]);
    _navigationSnapshot = _navigationSnapshot.copyWith(
      riderPosition: reading.position,
      heading: reading.heading,
      routePoints: route.points,
      distanceLabel: route.distanceLabel,
      etaLabel: route.etaLabel,
    );
    await _liveLocationRepository.saveLocation(
      riderId: 'demo-rider',
      orderId: 'order-amanat-dairy',
      position: reading.position,
      heading: reading.heading,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }
}

class DeliveryNavigationViewModel extends BaseViewModel {
  DeliveryNavigationViewModel({
    RiderRealtimeService? realtimeService,
    RiderLocationService locationService = const RiderLocationService(),
    OsrmRouteService routeService = const OsrmRouteService(),
    RiderLiveLocationRepository? liveLocationRepository,
  }) : _realtimeService = realtimeService ?? RiderRealtimeService.instance,
       _locationService = locationService,
       _routeService = routeService,
       _liveLocationRepository =
           liveLocationRepository ?? RiderLiveLocationRepository() {
    _startTracking();
  }

  final RiderRealtimeService _realtimeService;
  final RiderLocationService _locationService;
  final OsrmRouteService _routeService;
  final RiderLiveLocationRepository _liveLocationRepository;
  Timer? _trackingTimer;

  DeliveryNavigationModel _model = const DeliveryNavigationModel();
  RiderNavigationSnapshot _navigationSnapshot = DemoMapPoints.snapshot;

  DeliveryNavigationModel get model => _model;
  RiderNavigationSnapshot get navigationSnapshot => _navigationSnapshot;

  void callCustomer() {
    _realtimeService.customerCallRequested(
      _model.orderId,
      _model.customerPhone,
    );
  }

  void uploadDeliveryPhoto() {
    if (_model.hasDeliveryPhoto) return;

    _model = _model.copyWith(hasDeliveryPhoto: true);
    _realtimeService.deliveryPhotoUploaded(_model.orderId);
    notifyListeners();
  }

  void markDelivered() {
    if (_model.isDelivered) return;

    _model = _model.copyWith(isDelivered: true, notificationSent: true);
    _realtimeService.orderDelivered(_model.orderId);
    _realtimeService.customerNotified(
      _model.orderId,
      'Your order has been delivered!',
    );
    notifyListeners();
  }

  void _startTracking() {
    _refreshLocationAndRoute();
    _trackingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshLocationAndRoute(),
    );
  }

  Future<void> _refreshLocationAndRoute() async {
    final reading = await _locationService.currentLocation();
    final route = await _routeService.route([
      reading.position,
      _navigationSnapshot.customerPosition,
    ]);
    _navigationSnapshot = _navigationSnapshot.copyWith(
      riderPosition: reading.position,
      heading: reading.heading,
      routePoints: route.points,
      distanceLabel: route.distanceLabel,
      etaLabel: route.etaLabel,
    );
    _model = _model.copyWith(
      eta: route.etaLabel,
      distance: route.distanceLabel,
    );
    await _liveLocationRepository.saveLocation(
      riderId: 'demo-rider',
      orderId: _model.orderId,
      position: reading.position,
      heading: reading.heading,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }
}
