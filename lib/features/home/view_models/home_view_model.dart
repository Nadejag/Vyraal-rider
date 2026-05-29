import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/auth/rider_auth_service.dart';
import '../../../core/base/base_view_model.dart';
import '../../../core/firebase_database_refs.dart';
import '../../../core/maps/rider_location_service.dart';
import '../../../core/realtime/rider_active_delivery_store.dart';
import '../../../core/realtime/rider_delivery_repository.dart';
import '../../../core/realtime/rider_realtime_service.dart';
import '../models/home_model.dart';

class HomeViewModel extends BaseViewModel {
  HomeViewModel({
    RiderRealtimeService? realtimeService,
    RiderDeliveryRepository? deliveryRepository,
    RiderLocationService locationService = const RiderLocationService(),
    RiderAuthService? authService,
  }) : _realtimeService = realtimeService ?? RiderRealtimeService.instance,
       _deliveryRepository = deliveryRepository ?? RiderDeliveryRepository(),
       _locationService = locationService,
       _authService = authService ?? RiderAuthService() {
    _realtimeSubscription = _realtimeService.events.listen(
      _handleRealtimeEvent,
    );
    _startLocationTracking();

    if (_deliveryRepository.isFirebaseReady) {
      _model = _model.copyWith(orders: const []);
      _deliveryOrdersSubscription = _deliveryRepository
          .watchAvailableOrders()
          .listen(_replaceAvailableOrders, onError: _handleOrdersError);
      _startRealtimeHistory();
    } else {
      _startOrderDiscovery();
    }
  }

  void init() {}

  final RiderRealtimeService _realtimeService;
  final RiderDeliveryRepository _deliveryRepository;
  final RiderLocationService _locationService;
  final RiderAuthService _authService;

  final Map<String, Timer> _requestTimers = {};
  final Set<String> _seenRequestIds = {};
  final List<RiderNotificationModel> _notifications = [];

  final Map<String, Map<String, dynamic>> _completedOrdersByKey = {};
  final Map<String, Map<String, dynamic>> _globalHistoryOrdersByKey = {};
  final Map<String, Map<String, dynamic>> _riderEarningsByKey = {};
  final Map<String, Map<String, dynamic>> _userEarningsByKey = {};
  Map<String, dynamic> _riderStats = const {};

  late final StreamSubscription<RiderRealtimeEvent> _realtimeSubscription;
  StreamSubscription<List<RiderOrderModel>>? _deliveryOrdersSubscription;
  StreamSubscription<RiderLocationReading>? _locationSubscription;
  StreamSubscription<DatabaseEvent>? _completedOrdersSubscription;
  StreamSubscription<DatabaseEvent>? _globalHistoryOrdersSubscription;
  StreamSubscription<DatabaseEvent>? _riderEarningsSubscription;
  StreamSubscription<DatabaseEvent>? _userEarningsSubscription;
  StreamSubscription<DatabaseEvent>? _riderStatsSubscription;

  LatLng? _riderPosition;
  String? _activePopupNotificationId;
  bool _hasLoadedOrders = false;

  HomeModel _model = const HomeModel(
    todayTrips: 0,
    todayEarnings: 'Rs. 0',
    orders: [],
    weeklyTotal: 'Rs. 0',
    weeklyGrowth: '0%',
    weekRange: 'Live week',
    weeklyEarnings: [],
    tripHistory: [],
    payoutStatus: PayoutStatus.pending,
    totalTrips: 0,
    hoursOnline: 0,
    detailedTrips: [],
    profile: RiderProfileModel(
      fullName: 'Rider',
      phoneNumber: '',
      cnic: '',
      bikeRegistrationNumber: '',
      vehicleName: '',
      memberSince: '',
      cnicStatus: DocumentReviewStatus.pending,
      bikeDocsStatus: DocumentReviewStatus.pending,
    ),
  );

  HomeModel get model => _model;

  LatLng? get riderPosition => _riderPosition;

  List<RiderOrderModel> get availableOrders {
    final orders = _model.orders
        .map(_orderWithLiveDistance)
        .where((order) => order.distanceKm <= 3)
        .toList();
    orders.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return orders;
  }

  String? get ordersError => _model.ordersError;

  List<RiderNotificationModel> get notifications =>
      List.unmodifiable(_notifications);

  int get unreadNotificationsCount =>
      _notifications.where((notification) => notification.isUnread).length;

  RiderNotificationModel? get activePopupNotification {
    final id = _activePopupNotificationId;
    if (id == null) return null;

    for (final notification in _notifications) {
      if (notification.id == id && notification.showPopup) {
        return notification;
      }
    }

    return null;
  }

  bool get isChangingStatus => _model.profile.isBusy;
  bool get isLoading => !_hasLoadedOrders && _model.ordersError == null;
  bool get isOnline => _model.profile.isOnline;
  bool get isAcceptingOrder => false;

  Future<void> refresh() async {}

  void toggleWorkStatus(bool isOnline) => toggleOnlineStatus(isOnline);

  void selectTab(int index) {
    if (_model.selectedTabIndex == index) return;
    _model = _model.copyWith(selectedTabIndex: index);
    notifyListeners();
  }

  void _handleOrdersError(Object error) {
    _hasLoadedOrders = true;
    _model = _model.copyWith(
      orders: const [],
      ordersError:
          'Realtime orders are blocked by Firebase Database rules. Deploy database.rules.json, then restart the Rider app.',
    );
    notifyListeners();
  }

  void _startLocationTracking() {
    _locationSubscription = _locationService.liveLocationStream().listen((
      reading,
    ) {
      _riderPosition = reading.position;
      notifyListeners();
    }, onError: (_) {});
  }

  void _startRealtimeHistory() {
    final database = _maybeDatabase();
    final riderId = _riderId;
    if (database == null || riderId.isEmpty || riderId == 'demo-rider') {
      return;
    }

    _completedOrdersSubscription = database
        .ref('users/riders/$riderId/completedOrders')
        .onValue
        .listen((event) {
          _completedOrdersByKey
            ..clear()
            ..addAll(_mapOfMaps(event.snapshot));
          _rebuildHistory();
        }, onError: (_) {});

    _globalHistoryOrdersSubscription = database
        .ref('orders')
        .orderByChild('assignedRiderId')
        .equalTo(riderId)
        .onValue
        .listen((event) {
          _globalHistoryOrdersByKey
            ..clear()
            ..addAll(_mapOfMaps(event.snapshot));
          _rebuildHistory();
        }, onError: (_) {});

    _riderEarningsSubscription = database
        .ref('riderEarnings/$riderId')
        .onValue
        .listen((event) {
          _riderEarningsByKey
            ..clear()
            ..addAll(_mapOfMaps(event.snapshot));
          _rebuildHistory();
        }, onError: (_) {});

    _userEarningsSubscription = database
        .ref('users/riders/$riderId/earnings')
        .onValue
        .listen((event) {
          _userEarningsByKey
            ..clear()
            ..addAll(_mapOfMaps(event.snapshot));
          _rebuildHistory();
        }, onError: (_) {});

    _riderStatsSubscription = database
        .ref('riderStats/$riderId')
        .onValue
        .listen((event) {
          final value = event.snapshot.value;
          _riderStats = value is Map
              ? Map<String, dynamic>.from(value)
              : const {};
          _rebuildHistory();
        }, onError: (_) {});
  }

  void _rebuildHistory() {
    final orderMaps = <String, Map<String, dynamic>>{};
    orderMaps.addAll(_globalHistoryOrdersByKey);
    orderMaps.addAll(_completedOrdersByKey);

    final earnings = <String, Map<String, dynamic>>{};
    earnings.addAll(_userEarningsByKey);
    earnings.addAll(_riderEarningsByKey);

    final detailedTrips = <DetailedTripModel>[];
    final compactTrips = <TripHistoryModel>[];
    final tripDates = <String, int>{};
    final tripAmounts = <String, double>{};

    for (final entry in orderMaps.entries) {
      final key = entry.key;
      final json = Map<String, dynamic>.from(entry.value);
      final status = _tripStatus(json);
      if (status == null) continue;

      final earningJson = _findEarningForOrder(key, json, earnings);
      final amount = _earningAmount(json, earningJson);
      final completedAt = _completedTimestamp(json, earningJson);
      final dateTimeLabel = _dateLabel(completedAt);
      final paymentType = _paymentType(json, earningJson);
      final pickup = _text(json, const [
        'sellerAddress',
        'pickupAddress',
        'shopAddress',
        'storeName',
        'sellerName',
        'shopName',
      ], fallback: 'Seller pickup');
      final dropOff = _text(json, const [
        'deliveryAddress',
        'customerAddress',
        'dropOffAddress',
        'customerArea',
      ], fallback: 'Customer location');
      final id = _text(json, const ['id', 'orderId'], fallback: key);
      final sellerName = _text(json, const [
        'storeName',
        'sellerName',
        'shopName',
      ], fallback: 'Seller');
      final customerName = _text(json, const [
        'customerName',
        'buyerName',
        'userName',
      ], fallback: 'Customer');

      detailedTrips.add(
        DetailedTripModel(
          dateTime: dateTimeLabel,
          id: id,
          pickup: pickup,
          dropOff: dropOff,
          amount: _moneyLabel(amount),
          paymentType: paymentType,
          status: status,
        ),
      );

      compactTrips.add(
        TripHistoryModel(
          sellerName: sellerName,
          customerName: customerName,
          location: _shortArea(dropOff),
          dateTime: dateTimeLabel,
          amount: _moneyLabel(amount),
          paymentType: paymentType,
        ),
      );

      if (status == TripStatus.completed) {
        final keyDate = _dateKey(completedAt);
        tripDates[keyDate] = (tripDates[keyDate] ?? 0) + 1;
        tripAmounts[keyDate] = (tripAmounts[keyDate] ?? 0) + amount;
      }
    }

    detailedTrips.sort(
      (a, b) => _sortLabel(b.dateTime).compareTo(_sortLabel(a.dateTime)),
    );
    compactTrips.sort(
      (a, b) => _sortLabel(b.dateTime).compareTo(_sortLabel(a.dateTime)),
    );

    final completedTrips = detailedTrips
        .where((trip) => trip.status == TripStatus.completed)
        .length;
    final now = DateTime.now();
    final todayKey = _dateKey(now.millisecondsSinceEpoch);
    final todayTrips = tripDates[todayKey] ?? 0;
    final todayEarning = tripAmounts[todayKey] ?? 0;
    final weekly = _weeklyEarnings(tripAmounts);
    final weeklyTotal = weekly.fold<int>(0, (sum, item) => sum + item.amount);
    final previousWeekTotal = _previousWeekTotal(tripAmounts);

    _model = _model.copyWith(
      todayTrips: todayTrips,
      todayEarnings: _moneyLabel(todayEarning),
      weeklyTotal: _moneyLabel(weeklyTotal),
      weeklyGrowth: _growthLabel(weeklyTotal, previousWeekTotal),
      weekRange: _weekRangeLabel(),
      weeklyEarnings: weekly,
      tripHistory: compactTrips.take(8).toList(),
      totalTrips: completedTrips,
      hoursOnline: _hoursOnline(),
      detailedTrips: detailedTrips,
    );
    notifyListeners();
  }

  RiderOrderModel _orderWithLiveDistance(RiderOrderModel order) {
    final riderPosition = _riderPosition;
    final sellerLat = order.sellerLat;
    final sellerLng = order.sellerLng;
    if (riderPosition == null || sellerLat == null || sellerLng == null) {
      return order;
    }

    final meters = const Distance().as(
      LengthUnit.Meter,
      riderPosition,
      LatLng(sellerLat, sellerLng),
    );
    return order.copyWith(distanceKm: meters / 1000);
  }

  Future<void> declineOrder(RiderOrderModel order) async {
    _cancelRequestTimer(order.id);
    _model = _model.copyWith(
      orders: _model.orders.where((item) => item.id != order.id).toList(),
    );
    unawaited(_deliveryRepository.declineOrder(order));
    _realtimeService.orderDeclined(order.id);
    notifyListeners();
  }

  Future<bool> acceptOrder(RiderOrderModel order) async {
    if (order.isLocked) return false;

    final isRealtime = _deliveryRepository.isFirebaseReady;
    if (isRealtime) {
      final accepted = await _deliveryRepository.acceptOrder(order);
      if (!accepted) return false;
      await _deliveryRepository.markHeadingToSeller(order);
    } else {
      RiderActiveDeliveryStore.instance.setActiveOrder(order);
    }
    _cancelRequestTimer(order.id);
    _model = _model.copyWith(
      orders: _model.orders
          .where((item) => item.id != order.id)
          .map((item) => item.copyWith(isHighlighted: false))
          .toList(),
    );
    _realtimeService.orderAccepted(order.id);
    _realtimeService.orderLocked(order.id);
    notifyListeners();
    return true;
  }

  void dismissNotificationPopup() {
    final id = _activePopupNotificationId;
    if (id == null) return;

    _activePopupNotificationId = null;
    _replaceNotification(
      id,
      (notification) => notification.copyWith(showPopup: false),
    );
    notifyListeners();
  }

  void markNotificationsRead() {
    for (var index = 0; index < _notifications.length; index++) {
      _notifications[index] = _notifications[index].copyWith(isUnread: false);
    }
    notifyListeners();
  }

  void updateProfile({
    String? fullName,
    String? cnic,
    String? bikeRegistrationNumber,
    String? vehicleName,
  }) {
    _model = _model.copyWith(
      profile: _model.profile.copyWith(
        fullName: fullName,
        cnic: cnic,
        bikeRegistrationNumber: bikeRegistrationNumber,
        vehicleName: vehicleName,
      ),
    );
    _realtimeService.riderProfileUpdated();
    notifyListeners();
  }

  void toggleOnlineStatus(bool isOnline) {
    _model = _model.copyWith(
      profile: _model.profile.copyWith(isOnline: isOnline),
    );
    _realtimeService.riderStatusChanged(isOnline);
    notifyListeners();
  }

  void uploadProfilePhoto() {
    _model = _model.copyWith(
      profile: _model.profile.copyWith(hasProfilePhoto: true),
    );
    _realtimeService.riderProfilePhotoUploaded();
    notifyListeners();
  }

  void uploadCnicDocument() {
    _model = _model.copyWith(
      profile: _model.profile.copyWith(
        cnicStatus: DocumentReviewStatus.pending,
      ),
    );
    _realtimeService.riderDocumentUploaded('cnic');
    notifyListeners();
  }

  void uploadBikeDocument() {
    _model = _model.copyWith(
      profile: _model.profile.copyWith(
        bikeDocsStatus: DocumentReviewStatus.pending,
      ),
    );
    _realtimeService.riderDocumentUploaded('bike_docs');
    notifyListeners();
  }

  void changeLanguage(String language) {
    if (_model.profile.language == language) return;

    _model = _model.copyWith(
      profile: _model.profile.copyWith(language: language),
    );
    _realtimeService.riderLanguageChanged(language);
    notifyListeners();
  }

  void toggleAlerts(bool enabled) {
    if (_model.profile.alertsEnabled == enabled) return;

    _model = _model.copyWith(
      profile: _model.profile.copyWith(alertsEnabled: enabled),
    );
    _realtimeService.riderAlertsChanged(enabled);
    notifyListeners();
  }

  void openHelpCenter() {
    _realtimeService.riderSupportRequested('help_center');
  }

  void contactSupport() {
    _realtimeService.riderSupportRequested('contact_support');
  }

  Future<void> logout() async {
    try {
      if (_model.profile.isOnline) {
        _model = _model.copyWith(
          profile: _model.profile.copyWith(isOnline: false),
          selectedTabIndex: 0,
        );
        _realtimeService.riderStatusChanged(false);
      }

      _realtimeService.riderLoggedOut();
      await FirebaseAuth.instance.signOut();
      await _authService.logout();
      notifyListeners();
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  void _startOrderDiscovery() {
    _hasLoadedOrders = true;
    for (final order in availableOrders) {
      _startRequestTimer(order.id);
      Future<void>.microtask(
        () => _realtimeService.orderRequestAlert(order.id, order.storeName),
      );
    }
  }

  void _replaceAvailableOrders(List<RiderOrderModel> orders) {
    _hasLoadedOrders = true;
    final previousIds = _model.orders.map((order) => order.id).toSet();
    for (final order in orders) {
      if (_seenRequestIds.add(order.id) && !previousIds.contains(order.id)) {
        _realtimeService.orderRequestAlert(order.id, order.storeName);
      }
      _startRequestTimer(order.id);
    }
    for (final oldOrder in _model.orders) {
      if (orders.every((order) => order.id != oldOrder.id)) {
        _cancelRequestTimer(oldOrder.id);
      }
    }
    _model = _model.copyWith(orders: orders, clearOrdersError: true);
    notifyListeners();
  }

  RiderOrderModel? _findOrder(String orderId) {
    for (final order in _model.orders) {
      if (order.id == orderId) return order;
    }
    return null;
  }

  void _handleRealtimeEvent(RiderRealtimeEvent event) {
    switch (event.type) {
      case 'new_order_request_alert':
        _addNotification(
          RiderNotificationModel(
            id: '${event.type}-${event.payload['orderId']}-${DateTime.now().microsecondsSinceEpoch}',
            type: RiderNotificationType.orderRequest,
            title: 'New order request',
            message:
                '${event.payload['sellerName']} is nearby. Accept within 60 seconds.',
            timeLabel: 'Now',
            isUrgent: true,
            showPopup: true,
          ),
        );
        break;
      case 'order_accepted':
        _addNotification(
          RiderNotificationModel(
            id: '${event.type}-${event.payload['orderId']}-${DateTime.now().microsecondsSinceEpoch}',
            type: RiderNotificationType.orderAccepted,
            title: 'Order accepted',
            message: 'Order locked to you. Head to the seller for pickup.',
            timeLabel: 'Now',
            showPopup: true,
          ),
        );
        break;
      case 'payout_approved':
        _addNotification(
          RiderNotificationModel(
            id: '${event.type}-${DateTime.now().microsecondsSinceEpoch}',
            type: RiderNotificationType.payoutApproved,
            title: 'Payout approved',
            message:
                'Your payout of Rs. ${event.payload['amount']} is approved.',
            timeLabel: 'Now',
            showPopup: true,
          ),
        );
        break;
      case 'admin_message_received':
        _addNotification(
          RiderNotificationModel(
            id: '${event.type}-${DateTime.now().microsecondsSinceEpoch}',
            type: RiderNotificationType.adminMessage,
            title: 'Admin message',
            message: event.payload['message'].toString(),
            timeLabel: 'Now',
            showPopup: true,
          ),
        );
        break;
      case 'admin_announcement_received':
        _addNotification(
          RiderNotificationModel(
            id: '${event.type}-${DateTime.now().microsecondsSinceEpoch}',
            type: RiderNotificationType.announcement,
            title: event.payload['title'].toString(),
            message: event.payload['message'].toString(),
            timeLabel: 'Now',
            showPopup: true,
          ),
        );
        break;
    }
  }

  void _addNotification(RiderNotificationModel notification) {
    _notifications.insert(0, notification);
    if (notification.showPopup) {
      _activePopupNotificationId = notification.id;
    }
    notifyListeners();
  }

  void _replaceNotification(
    String id,
    RiderNotificationModel Function(RiderNotificationModel notification) update,
  ) {
    final index = _notifications.indexWhere(
      (notification) => notification.id == id,
    );
    if (index == -1) return;

    _notifications[index] = update(_notifications[index]);
  }

  void _startRequestTimer(String orderId) {
    _requestTimers[orderId]?.cancel();
    _requestTimers[orderId] = Timer.periodic(const Duration(seconds: 1), (_) {
      final orderIndex = _model.orders.indexWhere(
        (order) => order.id == orderId,
      );
      if (orderIndex == -1) {
        _cancelRequestTimer(orderId);
        return;
      }

      final order = _model.orders[orderIndex];
      if (order.isLocked) {
        _cancelRequestTimer(orderId);
        return;
      }

      if (order.remainingSeconds <= 1) {
        _expireOrder(orderId);
        return;
      }

      final updatedOrders = [..._model.orders];
      updatedOrders[orderIndex] = order.copyWith(
        remainingSeconds: order.remainingSeconds - 1,
      );
      _model = _model.copyWith(orders: updatedOrders);
      notifyListeners();
    });
  }

  void _expireOrder(String orderId) {
    final order = _findOrder(orderId);
    _cancelRequestTimer(orderId);
    _model = _model.copyWith(
      orders: _model.orders.where((order) => order.id != orderId).toList(),
    );
    if (order != null) {
      unawaited(_deliveryRepository.timeoutOrder(order));
    }
    _realtimeService.orderTimedOut(orderId);
    notifyListeners();
  }

  void _cancelRequestTimer(String orderId) {
    _requestTimers.remove(orderId)?.cancel();
  }

  FirebaseDatabase? _maybeDatabase() {
    try {
      if (Firebase.apps.isEmpty) return null;
      return vyraalDatabase;
    } catch (_) {
      return null;
    }
  }

  Map<String, Map<String, dynamic>> _mapOfMaps(DataSnapshot snapshot) {
    final value = snapshot.value;
    if (value is! Map) return const {};
    final result = <String, Map<String, dynamic>>{};
    for (final entry in value.entries) {
      final raw = entry.value;
      if (raw is Map) {
        result[entry.key.toString()] = Map<String, dynamic>.from(raw);
      }
    }
    return result;
  }

  TripStatus? _tripStatus(Map<String, dynamic> json) {
    final status = _text(json, const [
      'status',
      'requestStatus',
      'riderStatus',
    ]);
    final stage = _text(json, const ['deliveryStage']);
    final combined = '$status $stage'.toLowerCase();
    if (combined.contains('deliver') ||
        combined.contains('complete') ||
        json['completedAt'] != null ||
        json['deliveredAt'] != null) {
      return TripStatus.completed;
    }
    if (combined.contains('cancel') ||
        combined.contains('reject') ||
        combined.contains('failed')) {
      return TripStatus.canceled;
    }
    return null;
  }

  Map<String, dynamic>? _findEarningForOrder(
    String key,
    Map<String, dynamic> order,
    Map<String, Map<String, dynamic>> earnings,
  ) {
    if (earnings.containsKey(key)) return earnings[key];
    final orderId = _text(order, const ['orderId', 'id', 'orderKey']);
    for (final entry in earnings.entries) {
      final value = entry.value;
      final earningOrderId = _text(value, const ['orderId', 'id', 'orderKey']);
      if (entry.key == orderId ||
          earningOrderId == orderId ||
          earningOrderId == key) {
        return value;
      }
    }
    return null;
  }

  double _earningAmount(
    Map<String, dynamic> order,
    Map<String, dynamic>? earning,
  ) {
    return _num(earning?['amount']) ??
        _num(earning?['deliveryFee']) ??
        _num(order['earning']) ??
        _num(order['riderEarning']) ??
        _num(order['deliveryFee']) ??
        _money(order['estimatedEarning']?.toString() ?? '') ??
        0;
  }

  int _completedTimestamp(
    Map<String, dynamic> order,
    Map<String, dynamic>? earning,
  ) {
    final timeline = order['timeline'];
    Object? deliveredAt;
    if (timeline is Map) {
      deliveredAt = timeline['deliveredAt'] ?? timeline['completedAt'];
    }
    return _timestamp(
          order['completedAt'] ??
              order['deliveredAt'] ??
              deliveredAt ??
              earning?['createdAt'] ??
              order['updatedAt'] ??
              order['createdAt'],
        ) ??
        DateTime.now().millisecondsSinceEpoch;
  }

  PaymentType _paymentType(
    Map<String, dynamic> order,
    Map<String, dynamic>? earning,
  ) {
    final method = _text(order, const [
      'paymentType',
      'paymentMethod',
      'method',
    ], fallback: earning?['method']?.toString() ?? '').toLowerCase();
    if (method.contains('online') ||
        method.contains('wallet') ||
        method.contains('jazz') ||
        method.contains('easy') ||
        method.contains('card')) {
      return PaymentType.online;
    }
    return PaymentType.cash;
  }

  List<WeeklyEarningModel> _weeklyEarnings(Map<String, double> amountsByDate) {
    final now = DateTime.now();
    final result = <WeeklyEarningModel>[];
    for (var index = 6; index >= 0; index--) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: index));
      final key = _dateKey(day.millisecondsSinceEpoch);
      result.add(
        WeeklyEarningModel(
          day: _weekdayShort(day.weekday),
          amount: (amountsByDate[key] ?? 0).round(),
          isToday: index == 0,
        ),
      );
    }
    return result;
  }

  int _previousWeekTotal(Map<String, double> amountsByDate) {
    final now = DateTime.now();
    var total = 0.0;
    for (var index = 13; index >= 7; index--) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: index));
      total += amountsByDate[_dateKey(day.millisecondsSinceEpoch)] ?? 0;
    }
    return total.round();
  }

  double _hoursOnline() {
    return _num(_riderStats['hoursOnline']) ??
        _num(_riderStats['totalHoursOnline']) ??
        ((_num(_riderStats['onlineSeconds']) ??
                _num(_riderStats['totalOnlineSeconds']) ??
                _num(
                  (_riderStats['today'] is Map
                      ? (_riderStats['today'] as Map)['onlineSeconds']
                      : null),
                ) ??
                0) /
            3600);
  }

  String _text(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return fallback;
  }

  double? _num(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', ''));
    return null;
  }

  double? _money(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned);
  }

  int? _timestamp(Object? value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final numeric = int.tryParse(value);
      if (numeric != null) return numeric;
      return DateTime.tryParse(value)?.millisecondsSinceEpoch;
    }
    return null;
  }

  String _moneyLabel(num value) => 'Rs. ${value.round()}';

  String _dateKey(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _dateLabel(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} • $hour:$minute $amPm';
  }

  int _sortLabel(String label) {
    final parts = label.split(' • ');
    if (parts.isEmpty) return 0;
    final dateParts = parts.first.split('/');
    if (dateParts.length != 3) return 0;
    final day = int.tryParse(dateParts[0]) ?? 1;
    final month = int.tryParse(dateParts[1]) ?? 1;
    final year = int.tryParse(dateParts[2]) ?? 1970;
    return DateTime(year, month, day).millisecondsSinceEpoch;
  }

  String _shortArea(String? address) {
    final parts = (address ?? '')
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'Customer location';
    if (parts.length == 1) return parts.first;
    return '${parts.first}, ${parts[1]}';
  }

  String _weekdayShort(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[(weekday - 1).clamp(0, 6)];
  }

  String _weekRangeLabel() {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    return '${start.day}/${start.month} - ${now.day}/${now.month}';
  }

  String _growthLabel(int current, int previous) {
    if (previous <= 0) return current > 0 ? '+100%' : '0%';
    final growth = ((current - previous) / previous) * 100;
    final prefix = growth >= 0 ? '+' : '';
    return '$prefix${growth.toStringAsFixed(0)}%';
  }

  String get _riderId {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? 'demo-rider';
    } catch (_) {
      return 'demo-rider';
    }
  }

  @override
  void dispose() {
    _realtimeSubscription.cancel();
    unawaited(_deliveryOrdersSubscription?.cancel());
    unawaited(_locationSubscription?.cancel());
    unawaited(_completedOrdersSubscription?.cancel());
    unawaited(_globalHistoryOrdersSubscription?.cancel());
    unawaited(_riderEarningsSubscription?.cancel());
    unawaited(_userEarningsSubscription?.cancel());
    unawaited(_riderStatsSubscription?.cancel());
    for (final timer in _requestTimers.values) {
      timer.cancel();
    }
    _requestTimers.clear();
    super.dispose();
  }
}
