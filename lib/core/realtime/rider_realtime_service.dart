import 'dart:async';

class RiderRealtimeService {
  RiderRealtimeService._();

  static final RiderRealtimeService instance = RiderRealtimeService._();

  final _events = StreamController<RiderRealtimeEvent>.broadcast();

  Stream<RiderRealtimeEvent> get events => _events.stream;

  void riderStatusChanged(bool isOnline) {
    _emit(RiderRealtimeEvent('rider_status_changed', {'isOnline': isOnline}));
  }

  void riderProfileUpdated() {
    _emit(const RiderRealtimeEvent('rider_profile_updated', {}));
  }

  void riderDocumentUploaded(String documentType) {
    _emit(
      RiderRealtimeEvent('rider_document_uploaded', {'type': documentType}),
    );
  }

  void riderProfilePhotoUploaded() {
    _emit(const RiderRealtimeEvent('rider_profile_photo_uploaded', {}));
  }

  void riderLanguageChanged(String language) {
    _emit(RiderRealtimeEvent('rider_language_changed', {'language': language}));
  }

  void riderAlertsChanged(bool enabled) {
    _emit(RiderRealtimeEvent('rider_alerts_changed', {'enabled': enabled}));
  }

  void riderSupportRequested(String supportType) {
    _emit(RiderRealtimeEvent('rider_support_requested', {'type': supportType}));
  }

  void riderLoggedOut() {
    _emit(const RiderRealtimeEvent('rider_logged_out', {}));
  }

  void orderAccepted(String orderId) {
    _emit(RiderRealtimeEvent('order_accepted', {'orderId': orderId}));
  }

  void orderRequestAlert(String orderId, String sellerName) {
    _emit(
      RiderRealtimeEvent('new_order_request_alert', {
        'orderId': orderId,
        'sellerName': sellerName,
      }),
    );
  }

  void orderLocked(String orderId) {
    _emit(RiderRealtimeEvent('order_locked_to_rider', {'orderId': orderId}));
  }

  void orderDeclined(String orderId) {
    _emit(RiderRealtimeEvent('order_declined', {'orderId': orderId}));
  }

  void orderTimedOut(String orderId) {
    _emit(RiderRealtimeEvent('order_sent_to_next_rider', {'orderId': orderId}));
  }

  void orderPickedUp(String orderId) {
    _emit(RiderRealtimeEvent('order_picked_up', {'orderId': orderId}));
  }

  void orderDelivered(String orderId) {
    _emit(RiderRealtimeEvent('order_delivered', {'orderId': orderId}));
  }

  void customerCallRequested(String orderId, String phoneNumber) {
    _emit(
      RiderRealtimeEvent('customer_call_requested', {
        'orderId': orderId,
        'phoneNumber': phoneNumber,
      }),
    );
  }

  void deliveryPhotoUploaded(String orderId) {
    _emit(RiderRealtimeEvent('delivery_photo_uploaded', {'orderId': orderId}));
  }

  void customerNotified(String orderId, String message) {
    _emit(
      RiderRealtimeEvent('customer_notification_sent', {
        'orderId': orderId,
        'message': message,
      }),
    );
  }

  void riderLocationUpdated(Map<String, Object> payload) {
    _emit(RiderRealtimeEvent('rider_location_updated', payload));
  }

  void withdrawalRequested(int amount, {String? method, String? status}) {
    final payload = <String, Object>{'amount': amount};
    if (method != null) payload['method'] = method;
    if (status != null) payload['status'] = status;

    _emit(RiderRealtimeEvent('withdrawal_requested', payload));
  }

  void payoutApproved(int amount) {
    _emit(RiderRealtimeEvent('payout_approved', {'amount': amount}));
  }

  void adminMessage(String message) {
    _emit(RiderRealtimeEvent('admin_message_received', {'message': message}));
  }

  void announcement(String title, String message) {
    _emit(
      RiderRealtimeEvent('admin_announcement_received', {
        'title': title,
        'message': message,
      }),
    );
  }

  void _emit(RiderRealtimeEvent event) {
    if (!_events.isClosed) _events.add(event);
  }
}

class RiderRealtimeEvent {
  const RiderRealtimeEvent(this.type, this.payload);

  final String type;
  final Map<String, Object> payload;
}
