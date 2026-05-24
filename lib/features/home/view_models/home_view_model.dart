import 'dart:async';

import '../../../core/base/base_view_model.dart';
import '../../../core/realtime/rider_realtime_service.dart';
import '../models/home_model.dart';

class HomeViewModel extends BaseViewModel {
  HomeViewModel({RiderRealtimeService? realtimeService})
    : _realtimeService = realtimeService ?? RiderRealtimeService.instance {
    _realtimeSubscription = _realtimeService.events.listen(
      _handleRealtimeEvent,
    );
    _startOrderDiscovery();
  }

  final RiderRealtimeService _realtimeService;
  final Map<String, Timer> _requestTimers = {};
  late final StreamSubscription<RiderRealtimeEvent> _realtimeSubscription;
  final List<RiderNotificationModel> _notifications = [
    const RiderNotificationModel(
      id: 'admin-welcome',
      type: RiderNotificationType.adminMessage,
      title: 'Admin message',
      message: 'Keep profile documents updated to avoid payout delays.',
      timeLabel: 'Today',
      isUnread: false,
    ),
    const RiderNotificationModel(
      id: 'weekly-announcement',
      type: RiderNotificationType.announcement,
      title: 'Weekend boost',
      message: 'High demand expected Saturday evening in Gulberg and DHA.',
      timeLabel: 'Today',
      isUnread: false,
    ),
  ];
  String? _activePopupNotificationId;

  HomeModel _model = const HomeModel(
    todayTrips: 12,
    todayEarnings: 'Rs. 1,450',
    orders: [
      RiderOrderModel(
        id: 'order-amanat-dairy',
        storeName: 'Amanat Dairy',
        distanceKm: 1.2,
        estimatedEarning: 'Rs. 80',
        items: 'Milk, Eggs',
        itemCount: 2,
        customerArea: 'DHA Phase 5',
        shopImageAsset: 'assets/images/shop1.png',
        isHighlighted: true,
      ),
      RiderOrderModel(
        id: 'order-green-grocers',
        storeName: 'Green Grocers',
        distanceKm: 0.8,
        estimatedEarning: 'Rs. 65',
        items: 'Apples, Bananas, Bread',
        itemCount: 3,
        customerArea: 'Model Town',
        shopImageAsset: 'assets/images/shop2.png',
      ),
    ],
    weeklyTotal: 'Rs. 8,200',
    weeklyGrowth: '+12%',
    weekRange: 'Oct 21 - Oct 27',
    weeklyEarnings: [
      WeeklyEarningModel(day: 'Mon', amount: 780),
      WeeklyEarningModel(day: 'Tue', amount: 940),
      WeeklyEarningModel(day: 'Wed', amount: 1120),
      WeeklyEarningModel(day: 'Thu', amount: 980),
      WeeklyEarningModel(day: 'Fri', amount: 1340),
      WeeklyEarningModel(day: 'Sat', amount: 1580, isToday: true),
      WeeklyEarningModel(day: 'Sun', amount: 1460),
    ],
    tripHistory: [
      TripHistoryModel(
        sellerName: 'Amanat Dairy',
        customerName: 'Zainab K.',
        location: 'DHA Phase 6, Block C',
        dateTime: 'Oct 27, 2:14 PM',
        amount: 'Rs. 450',
        paymentType: PaymentType.cash,
      ),
      TripHistoryModel(
        sellerName: 'Green Grocers',
        customerName: 'Ahmed R.',
        location: 'Gulberg III, Main Blvd',
        dateTime: 'Oct 27, 12:45 PM',
        amount: 'Rs. 320',
        paymentType: PaymentType.online,
      ),
      TripHistoryModel(
        sellerName: 'Royal Bakeries',
        customerName: 'Sara M.',
        location: 'Model Town, Block H',
        dateTime: 'Oct 26, 9:30 PM',
        amount: 'Rs. 580',
        paymentType: PaymentType.cash,
      ),
      TripHistoryModel(
        sellerName: 'Pizza Mania',
        customerName: 'Usman T.',
        location: 'Johar Town, Expo Road',
        dateTime: 'Oct 26, 6:15 PM',
        amount: 'Rs. 290',
        paymentType: PaymentType.online,
      ),
    ],
    payoutStatus: PayoutStatus.pending,
    totalTrips: 42,
    hoursOnline: 38.5,
    detailedTrips: [
      DetailedTripModel(
        dateTime: 'Oct 27, 2:14 PM',
        id: 'VR-99283',
        pickup: 'Royal Bakeries, Gulberg',
        dropOff: 'DHA Phase 5, Block L',
        amount: 'Rs. 85',
        paymentType: PaymentType.cash,
        status: TripStatus.completed,
      ),
      DetailedTripModel(
        dateTime: 'Oct 27, 1:05 PM',
        id: 'VR-99152',
        pickup: 'The Burger Joint, Johar Town',
        dropOff: 'Wapda Town, Phase 1',
        amount: 'Rs. 0',
        paymentType: PaymentType.online,
        status: TripStatus.canceled,
      ),
      DetailedTripModel(
        dateTime: 'Oct 26, 8:45 PM',
        id: 'VR-98544',
        pickup: 'Pizza Mania, Model Town',
        dropOff: 'Faisal Town, Block C',
        amount: 'Rs. 120',
        paymentType: PaymentType.cash,
        status: TripStatus.completed,
      ),
    ],
    profile: RiderProfileModel(
      fullName: 'Ahmed Ali',
      phoneNumber: '+92 300 1234567',
      cnic: '42201-XXXXXXX-X',
      bikeRegistrationNumber: 'KDL-8829',
      vehicleName: 'Honda CD 70 (2022)',
      memberSince: 'Oct 2023',
    ),
  );

  HomeModel get model => _model;

  List<RiderOrderModel> get availableOrders =>
      _model.orders.where((order) => order.distanceKm <= 3).toList();

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

  void selectTab(int index) {
    if (_model.selectedTabIndex == index) return;

    _model = _model.copyWith(selectedTabIndex: index);
    notifyListeners();
  }

  void declineOrder(String orderId) {
    _cancelRequestTimer(orderId);
    _model = _model.copyWith(
      orders: _model.orders.where((order) => order.id != orderId).toList(),
    );
    _realtimeService.orderDeclined(orderId);
    notifyListeners();
  }

  void acceptOrder(String orderId) {
    final orderIndex = _model.orders.indexWhere((order) => order.id == orderId);
    if (orderIndex == -1) return;

    final order = _model.orders[orderIndex];
    if (order.isLocked) return;

    _cancelRequestTimer(orderId);
    _model = _model.copyWith(
      orders: _model.orders
          .where((order) => order.id != orderId)
          .map((order) => order.copyWith(isHighlighted: false))
          .toList(),
    );
    _realtimeService.orderAccepted(orderId);
    _realtimeService.orderLocked(orderId);
    notifyListeners();
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

  void logout() {
    if (_model.profile.isOnline) {
      _model = _model.copyWith(
        profile: _model.profile.copyWith(isOnline: false),
        selectedTabIndex: 0,
      );
      _realtimeService.riderStatusChanged(false);
    }

    _realtimeService.riderLoggedOut();
    notifyListeners();
  }

  void _startOrderDiscovery() {
    for (final order in availableOrders) {
      _startRequestTimer(order.id);
      Future<void>.microtask(
        () => _realtimeService.orderRequestAlert(order.id, order.storeName),
      );
    }
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
    _cancelRequestTimer(orderId);
    _model = _model.copyWith(
      orders: _model.orders.where((order) => order.id != orderId).toList(),
    );
    _realtimeService.orderTimedOut(orderId);
    notifyListeners();
  }

  void _cancelRequestTimer(String orderId) {
    _requestTimers.remove(orderId)?.cancel();
  }

  @override
  void dispose() {
    _realtimeSubscription.cancel();
    for (final timer in _requestTimers.values) {
      timer.cancel();
    }
    _requestTimers.clear();
    super.dispose();
  }
}
