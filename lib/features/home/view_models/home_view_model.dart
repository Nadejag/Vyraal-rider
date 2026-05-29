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
import '../../../core/realtime/rider_email_notification_service.dart';
import '../../login/models/rider_user_model.dart';
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

    final firebaseUser = FirebaseAuth.instance.currentUser;
    RiderEmailNotificationService.instance.bindRider(
      firebaseUser?.uid,
      email: firebaseUser?.email,
      name: firebaseUser?.displayName,
    );
    _authService.getSavedUser().then((savedUser) {
      if (savedUser != null) {
        _sessionRiderId = savedUser.id;
        RiderEmailNotificationService.instance.updateRiderProfile(
          email: savedUser.email,
          name: savedUser.name,
        );
        _model = _model.copyWith(
          profile: _model.profile.copyWith(
            emailNotificationsEnabled: savedUser.emailNotificationsEnabled,
          ),
        );
        if (firebaseUser == null) _startRealtimeHistory();
        if (firebaseUser == null && _userProfileSubscription == null) {
          _userProfileSubscription = _authService.watchUser(savedUser.id).listen((user) {
            if (user != null) {
              _sessionRiderId = user.id;
              _model = _model.copyWith(
                profile: _model.profile.copyWith(
                  fullName: user.name,
                  phoneNumber: user.phone,
                  cnic: user.cnicNumber,
                  bikeRegistrationNumber: user.vehicleNumber,
                  vehicleName: user.vehicleType,
                  email: user.email ?? '',
                  isOnline: user.isOnline,
                  emailNotificationsEnabled: user.emailNotificationsEnabled,
                  profilePhotoUrl: user.profilePhotoUrl.isEmpty
                      ? null
                      : user.profilePhotoUrl,
                  verificationStatus: user.verificationStatus,
                ),
              );
              notifyListeners();
            }
          });
        }
        notifyListeners();
      }
    });

    final watchRiderId = firebaseUser?.uid ?? _sessionRiderId;
    if (watchRiderId != null && watchRiderId.isNotEmpty) {
      _userProfileSubscription = _authService.watchUser(watchRiderId).listen((user) {
        if (user != null) {
          _sessionRiderId = user.id;
          _model = _model.copyWith(
            profile: _model.profile.copyWith(
              fullName: user.name,
              phoneNumber: user.phone,
              cnic: user.cnicNumber,
              bikeRegistrationNumber: user.vehicleNumber,
              vehicleName: user.vehicleType,
              email: user.email ?? '',
              isOnline: user.isOnline,
              emailNotificationsEnabled: user.emailNotificationsEnabled,
              profilePhotoUrl:
                  user.profilePhotoUrl.isEmpty ? null : user.profilePhotoUrl,
              verificationStatus: user.verificationStatus,
            ),
          );
          notifyListeners();
        }
      });
    }

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
  StreamSubscription<RiderUserModel?>? _userProfileSubscription;

  LatLng? _riderPosition;
  String? _activePopupNotificationId;
  String? _sessionRiderId;
  bool _hasLoadedOrders = false;
  bool _isChangingWorkStatus = false;

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

  bool get isChangingStatus => _isChangingWorkStatus;
  bool get isLoading => !_hasLoadedOrders && _model.ordersError == null;
  bool get isOnline => _model.profile.isOnline;
  bool get isAcceptingOrder => false;

  Future<void> refresh() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      try {
        final snap = await vyraalDatabase.ref('users/riders/${firebaseUser.uid}').get().timeout(const Duration(seconds: 4));
        final value = snap.value;
        if (value is Map) {
          final user = RiderUserModel.fromJson(Map<String, dynamic>.from(value));
          await _authService.saveUser(user);
          _model = _model.copyWith(
            profile: _model.profile.copyWith(
              fullName: user.name,
              phoneNumber: user.phone,
              cnic: user.cnicNumber,
              bikeRegistrationNumber: user.vehicleNumber,
              vehicleName: user.vehicleType,
              email: user.email ?? '',
              isOnline: user.isOnline,
              emailNotificationsEnabled: user.emailNotificationsEnabled,
              profilePhotoUrl:
                  user.profilePhotoUrl.isEmpty ? null : user.profilePhotoUrl,
              verificationStatus: user.verificationStatus,
            ),
          );
        }
      } catch (_) {}
    }
    _rebuildHistory();
    notifyListeners();
  }

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

  Future<void> toggleOnlineStatus(bool isOnline) async {
    final previousProfile = _model.profile;
    _isChangingWorkStatus = true;
    _model = _model.copyWith(profile: _model.profile.copyWith(isOnline: isOnline));
    _realtimeService.riderStatusChanged(isOnline);
    notifyListeners();

    try {
      final riderId = _riderId;
      if (riderId.isNotEmpty && riderId != 'demo-rider') {
        await _authService.updateWorkStatus(
          riderId,
          isOnline ? 'online' : 'offline',
        );
      }
      _model = _model.copyWith(profile: _model.profile.copyWith(isOnline: isOnline));
    } catch (error) {
      _model = _model.copyWith(profile: previousProfile);
      setError('Could not update realtime work status. Please try again.');
    } finally {
      _isChangingWorkStatus = false;
    }
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

    final riderId = _riderId;
    if (riderId.isNotEmpty && riderId != 'demo-rider') {
      vyraalDatabase.ref('users/riders/$riderId/alertsEnabled').set(enabled);
      vyraalDatabase.ref('riders/$riderId/alertsEnabled').set(enabled);
    }

    notifyListeners();
  }

  void toggleEmailNotifications(bool enabled) {
    if (_model.profile.emailNotificationsEnabled == enabled) return;

    _model = _model.copyWith(
      profile: _model.profile.copyWith(emailNotificationsEnabled: enabled),
    );

    final riderId = _riderId;
    if (riderId.isNotEmpty && riderId != 'demo-rider') {
      vyraalDatabase.ref('users/riders/$riderId/emailNotificationsEnabled').set(enabled);
      vyraalDatabase.ref('riders/$riderId/emailNotificationsEnabled').set(enabled);
    }

    _authService.getSavedUser().then((savedUser) {
      if (savedUser != null) {
        final updatedUser = savedUser.copyWith(emailNotificationsEnabled: enabled);
        _authService.saveUser(updatedUser);
      }
    });

    notifyListeners();
  }

  Future<bool> updateEmail(String email) async {
    final normalizedEmail = email.trim();
    if (!_isValidEmail(normalizedEmail)) {
      setError('Enter a valid notification email address.');
      return false;
    }
    if (_model.profile.email == normalizedEmail) return true;

    _model = _model.copyWith(
      profile: _model.profile.copyWith(email: normalizedEmail),
    );
    RiderEmailNotificationService.instance.updateRiderProfile(
      email: normalizedEmail,
      name: _model.profile.fullName,
    );
    notifyListeners();

    try {
      final riderId = _riderId;
      if (riderId.isNotEmpty && riderId != 'demo-rider') {
        await _authService.updateNotificationEmail(
          riderId: riderId,
          email: normalizedEmail,
          emailNotificationsEnabled: _model.profile.emailNotificationsEnabled,
        );
      }
      return true;
    } catch (error) {
      setError('Could not save notification email. Please try again.');
      return false;
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
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
        final orderId = event.payload['orderId']?.toString() ?? '';
        final sellerName = event.payload['sellerName']?.toString() ?? 'Nearby shop';
        _addNotification(
          RiderNotificationModel(
            id: '${event.type}-$orderId-${DateTime.now().microsecondsSinceEpoch}',
            type: RiderNotificationType.orderRequest,
            title: 'New order request',
            message:
                '$sellerName is nearby. Accept within 60 seconds.',
            timeLabel: 'Now',
            isUrgent: true,
            showPopup: true,
          ),
        );
        unawaited(_sendNewOrderRequestEmail(orderId, sellerName));
        break;
      case 'order_accepted':
        final orderId = event.payload['orderId']?.toString() ?? '';
        _addNotification(
          RiderNotificationModel(
            id: '${event.type}-$orderId-${DateTime.now().microsecondsSinceEpoch}',
            type: RiderNotificationType.orderAccepted,
            title: 'Order accepted',
            message: 'Order locked to you. Head to the seller for pickup.',
            timeLabel: 'Now',
            showPopup: true,
          ),
        );
        unawaited(_sendOrderAcceptedEmail(orderId));
        break;
      case 'payout_approved':
        final amount = event.payload['amount']?.toString() ?? '0';
        _addNotification(
          RiderNotificationModel(
            id: '${event.type}-${DateTime.now().microsecondsSinceEpoch}',
            type: RiderNotificationType.payoutApproved,
            title: 'Payout approved',
            message:
                'Your payout of Rs. $amount is approved.',
            timeLabel: 'Now',
            showPopup: true,
          ),
        );
        unawaited(_sendPayoutApprovedEmail(amount));
        break;
      case 'admin_message_received':
        final message = event.payload['message']?.toString() ?? '';
        _addNotification(
          RiderNotificationModel(
            id: '${event.type}-${DateTime.now().microsecondsSinceEpoch}',
            type: RiderNotificationType.adminMessage,
            title: 'Admin message',
            message: message,
            timeLabel: 'Now',
            showPopup: true,
          ),
        );
        unawaited(_sendAdminMessageEmail(message));
        break;
      case 'admin_announcement_received':
        final title = event.payload['title']?.toString() ?? 'Announcement';
        final message = event.payload['message']?.toString() ?? '';
        _addNotification(
          RiderNotificationModel(
            id: '${event.type}-${DateTime.now().microsecondsSinceEpoch}',
            type: RiderNotificationType.announcement,
            title: title,
            message: message,
            timeLabel: 'Now',
            showPopup: true,
          ),
        );
        unawaited(_sendAnnouncementEmail(title, message));
        break;
      case 'withdrawal_requested':
        final amount = event.payload['amount']?.toString() ?? '0';
        final method = event.payload['method']?.toString() ?? 'JazzCash';
        unawaited(_sendWithdrawalRequestedEmail(amount, method));
        break;
    }
  }

  Future<void> _sendNewOrderRequestEmail(String orderId, String sellerName) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) return;

    final subject = 'Vyraal Rider: New Delivery Request - $orderId';
    final text = '''Hello Rider,

A new delivery request is available near you!
- Order ID: $orderId
- Seller: $sellerName

Open the Vyraal Rider app within 60 seconds to accept this order and earn delivery fees!''';

    final html = '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 8px; background-color: #ffffff;">
        <h2 style="color: #FF5A5F; margin-top: 0;">New Delivery Request Nearby!</h2>
        <p style="font-size: 16px; color: #333;">Hello Rider,</p>
        <p style="font-size: 15px; color: #555; line-height: 1.5;">
          A new delivery request is available near your current location. Act fast to accept it!
        </p>
        <div style="margin: 20px 0; padding: 15px; background-color: #f9f9f9; border-left: 4px solid #FF5A5F; border-radius: 4px;">
          <table style="width: 100%; border-collapse: collapse; font-size: 14px;">
            <tr>
              <td style="padding: 6px 0; color: #666; font-weight: bold;">Order ID:</td>
              <td style="padding: 6px 0; color: #333; font-weight: bold;">$orderId</td>
            </tr>
            <tr>
              <td style="padding: 6px 0; color: #666; font-weight: bold;">Pickup Shop:</td>
              <td style="padding: 6px 0; color: #333;">$sellerName</td>
            </tr>
          </table>
        </div>
        <p style="font-size: 14px; color: #666; margin-top: 25px;">
          Open the <strong>Vyraal Rider</strong> app now to accept the job before it gets assigned to another rider.
        </p>
      </div>
    ''';

    await RiderEmailNotificationService.instance.sendRiderEmail(
      eventType: 'rider_new_delivery_request',
      eventKey: '${orderId}_request',
      subject: subject,
      text: text,
      html: html,
      explicitTo: email,
      extra: {
        'orderId': orderId,
        'sellerName': sellerName,
      },
    );
  }

  Future<void> _sendOrderAcceptedEmail(String orderId) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) return;

    final subject = 'Vyraal Rider: Order Confirmed - $orderId';
    final text = '''Hello Rider,

You have successfully accepted the order $orderId.
Please head to the pickup shop to collect the products, and deliver them to the customer.

Safe travels!''';

    final html = '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 8px; background-color: #ffffff;">
        <h2 style="color: #2CA58D; margin-top: 0;">Order Assigned</h2>
        <p style="font-size: 16px; color: #333;">Hello Rider,</p>
        <p style="font-size: 15px; color: #555; line-height: 1.5;">
          You have successfully accepted order <strong>$orderId</strong>.
        </p>
        <div style="margin: 20px 0; padding: 15px; background-color: #f9f9f9; border-left: 4px solid #2CA58D; border-radius: 4px;">
          <p style="margin: 0; font-size: 14px; color: #333; line-height: 1.6;">
            <strong>Step 1:</strong> Navigate to the merchant's store location.<br>
            <strong>Step 2:</strong> Match the order items and pick up the package.<br>
            <strong>Step 3:</strong> Proceed directly to delivery location.<br>
          </p>
        </div>
        <p style="font-size: 14px; color: #666; margin-top: 25px;">
          Please ensure safe driving. Navigate using maps directly in the <strong>Vyraal Rider</strong> app.
        </p>
      </div>
    ''';

    await RiderEmailNotificationService.instance.sendRiderEmail(
      eventType: 'rider_order_accepted',
      eventKey: '${orderId}_accepted',
      subject: subject,
      text: text,
      html: html,
      explicitTo: email,
      extra: {
        'orderId': orderId,
      },
    );
  }

  Future<void> _sendPayoutApprovedEmail(String amount) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) return;

    final subject = 'Vyraal Rider: Payout Approved of Rs. $amount';
    final text = '''Hello Rider,

Great news! Your payout request of Rs. $amount has been approved by the admin.
The funds are on their way to your payment method.

Keep up the great work!''';

    final html = '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 8px; background-color: #ffffff;">
        <h2 style="color: #4A90E2; margin-top: 0;">Payout Approved!</h2>
        <p style="font-size: 16px; color: #333;">Hello Rider,</p>
        <p style="font-size: 15px; color: #555; line-height: 1.5;">
          Your payout request has been successfully reviewed and approved.
        </p>
        <div style="margin: 20px 0; padding: 15px; background-color: #f9f9f9; border-left: 4px solid #4A90E2; border-radius: 4px;">
          <table style="width: 100%; border-collapse: collapse; font-size: 14px;">
            <tr>
              <td style="padding: 6px 0; color: #666; font-weight: bold;">Status:</td>
              <td style="padding: 6px 0; color: #2CA58D; font-weight: bold;">Approved</td>
            </tr>
            <tr>
              <td style="padding: 6px 0; color: #666; font-weight: bold;">Approved Amount:</td>
              <td style="padding: 6px 0; color: #4A90E2; font-weight: bold; font-size: 16px;">Rs. $amount</td>
            </tr>
          </table>
        </div>
        <p style="font-size: 14px; color: #666; margin-top: 25px;">
          Payout updates can take some time to process via bank transfers/wallets. Thank you for your service with <strong>Vyraal</strong>!
        </p>
      </div>
    ''';

    await RiderEmailNotificationService.instance.sendRiderEmail(
      eventType: 'rider_payout_approved',
      eventKey: 'payout_${DateTime.now().millisecondsSinceEpoch}',
      subject: subject,
      text: text,
      html: html,
      explicitTo: email,
      extra: {
        'amount': amount,
      },
    );
  }

  Future<void> _sendAdminMessageEmail(String message) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) return;

    final subject = 'Vyraal Rider: Message from Support';
    final text = '''Hello Rider,

You received a message from Vyraal Admin:

"$message"

Please open the app to reply if needed.''';

    final html = '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 8px; background-color: #ffffff;">
        <h2 style="color: #6C757D; margin-top: 0;">Support Message Received</h2>
        <p style="font-size: 16px; color: #333;">Hello Rider,</p>
        <p style="font-size: 15px; color: #555; line-height: 1.5;">
          You have received a direct message from the Vyraal Support Admin:
        </p>
        <div style="margin: 20px 0; padding: 15px; background-color: #f8f9fa; border: 1px dashed #ced4da; border-radius: 4px; font-style: italic; color: #495057;">
          "$message"
        </div>
        <p style="font-size: 14px; color: #666; margin-top: 25px;">
          Please launch the <strong>Vyraal Rider</strong> app to chat with support.
        </p>
      </div>
    ''';

    await RiderEmailNotificationService.instance.sendRiderEmail(
      eventType: 'rider_admin_message',
      eventKey: 'admin_msg_${message.hashCode}',
      subject: subject,
      text: text,
      html: html,
      explicitTo: email,
      extra: {
        'message': message,
      },
    );
  }

  Future<void> _sendAnnouncementEmail(String title, String message) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) return;

    final subject = 'Vyraal Announcement: $title';
    final text = '''Hello Rider,

A new administrative announcement has been published:

$title
$message''';

    final html = '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 8px; background-color: #ffffff;">
        <h2 style="color: #F0AD4E; margin-top: 0;">New Announcement</h2>
        <p style="font-size: 16px; color: #333;">Hello Rider,</p>
        <p style="font-size: 15px; color: #555; line-height: 1.5; font-weight: bold;">
          $title
        </p>
        <div style="margin: 20px 0; padding: 15px; background-color: #fcf8e3; border-left: 4px solid #F0AD4E; border-radius: 4px; color: #8a6d3b; line-height: 1.6;">
          $message
        </div>
        <p style="font-size: 14px; color: #666; margin-top: 25px;">
          Stay safe out there! Thank you for partnering with <strong>Vyraal</strong>.
        </p>
      </div>
    ''';

    await RiderEmailNotificationService.instance.sendRiderEmail(
      eventType: 'rider_announcement',
      eventKey: 'announcement_${title.hashCode}_${message.hashCode}',
      subject: subject,
      text: text,
      html: html,
      explicitTo: email,
      extra: {
        'title': title,
        'message': message,
      },
    );
  }

  Future<void> _sendWithdrawalRequestedEmail(String amount, String method) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) return;

    final subject = 'Vyraal: Withdrawal Request Submitted of Rs. $amount';
    final text = '''Hello Rider,

We have received your withdrawal request of Rs. $amount via $method.
Our team is reviewing the transaction details and will process it shortly.

Thank you for your patience!''';

    final html = '''
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 8px; background-color: #ffffff;">
        <h2 style="color: #17A2B8; margin-top: 0;">Withdrawal Request Submitted</h2>
        <p style="font-size: 16px; color: #333;">Hello Rider,</p>
        <p style="font-size: 15px; color: #555; line-height: 1.5;">
          We have received your withdrawal request. It is currently under review.
        </p>
        <div style="margin: 20px 0; padding: 15px; background-color: #f9f9f9; border-left: 4px solid #17A2B8; border-radius: 4px;">
          <table style="width: 100%; border-collapse: collapse; font-size: 14px;">
            <tr>
              <td style="padding: 6px 0; color: #666; font-weight: bold;">Method:</td>
              <td style="padding: 6px 0; color: #333;">$method</td>
            </tr>
            <tr>
              <td style="padding: 6px 0; color: #666; font-weight: bold;">Amount:</td>
              <td style="padding: 6px 0; color: #17A2B8; font-weight: bold; font-size: 16px;">Rs. $amount</td>
            </tr>
            <tr>
              <td style="padding: 6px 0; color: #666; font-weight: bold;">Status:</td>
              <td style="padding: 6px 0; color: #F0AD4E; font-weight: bold;">Under Review</td>
            </tr>
          </table>
        </div>
        <p style="font-size: 14px; color: #666; margin-top: 25px;">
          Withdrawal processing usually takes up to 24 hours. You can review request updates in the Rider app wallet page.
        </p>
      </div>
    ''';

    await RiderEmailNotificationService.instance.sendRiderEmail(
      eventType: 'rider_withdrawal_requested',
      eventKey: 'withdrawal_${DateTime.now().millisecondsSinceEpoch}',
      subject: subject,
      text: text,
      html: html,
      explicitTo: email,
      extra: {
        'amount': amount,
        'method': method,
      },
    );
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
      return FirebaseAuth.instance.currentUser?.uid ??
          _sessionRiderId ??
          'demo-rider';
    } catch (_) {
      return _sessionRiderId ?? 'demo-rider';
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
    unawaited(_userProfileSubscription?.cancel());
    for (final timer in _requestTimers.values) {
      timer.cancel();
    }
    _requestTimers.clear();
    super.dispose();
  }
}
