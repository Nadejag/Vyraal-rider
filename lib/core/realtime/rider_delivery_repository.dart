import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../features/home/models/home_model.dart';
import '../firebase_database_refs.dart';
import 'rider_active_delivery_store.dart';

class RiderDeliveryRepository {
  RiderDeliveryRepository({FirebaseDatabase? database}) : _database = database;

  final FirebaseDatabase? _database;

  bool get isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Stream<List<RiderOrderModel>> watchAvailableOrders() {
    final database = _database ?? _maybeDatabase();
    if (database == null) return const Stream.empty();

    return database
        .ref('deliveryRequests')
        .orderByChild('requestStatus')
        .equalTo('available')
        .onValue
        .map((event) => _ordersFromSnapshot(event.snapshot));
  }

  Future<bool> acceptOrder(RiderOrderModel order) async {
    final database = _database ?? _maybeDatabase();
    if (database == null) return false;

    final key = order.orderKey ?? _firebaseKey(order.id);
    if (!await _currentRiderIsApproved()) {
      return false;
    }
    final riderId = _riderId;
    final riderName = _riderName;
    final riderPhone = _riderPhone;
    final acceptedAt = ServerValue.timestamp;
    final requestRef = database.ref('deliveryRequests/$key');
    final result = await requestRef.runTransaction((currentValue) {
      if (currentValue is! Map) return Transaction.abort();
      final current = Map<String, dynamic>.from(currentValue);
      if (current['requestStatus'] != 'available') {
        return Transaction.abort();
      }
      return Transaction.success({
        ...current,
        'requestStatus': 'accepted',
        'deliveryStage': 'riderAssigned',
        'assignedRiderId': riderId,
        'assignedRiderName': riderName,
        'assignedRiderPhone': riderPhone,
        'acceptedAt': acceptedAt,
        'updatedAt': acceptedAt,
        'timeline': {
          ...Map<String, Object?>.from(current['timeline'] as Map? ?? {}),
          'riderAcceptedAt': acceptedAt,
        },
      });
    });

    if (!result.committed) return false;

    final sellerId = order.sellerId;
    final customerId = order.customerId;
    final updates = <String, Object?>{
      'orders/$key/requestStatus': 'accepted',
      'orders/$key/deliveryStage': 'riderAssigned',
      'orders/$key/assignedRiderId': riderId,
      'orders/$key/assignedRiderName': riderName,
      'orders/$key/assignedRiderPhone': riderPhone,
      'orders/$key/timeline/riderAcceptedAt': ServerValue.timestamp,
      'orders/$key/updatedAt': ServerValue.timestamp,
      'activeDeliveries/$key/requestStatus': 'accepted',
      'activeDeliveries/$key/deliveryStage': 'riderAssigned',
      'activeDeliveries/$key/assignedRiderId': riderId,
      'activeDeliveries/$key/assignedRiderName': riderName,
      'activeDeliveries/$key/assignedRiderPhone': riderPhone,
      'activeDeliveries/$key/updatedAt': ServerValue.timestamp,
      'orderTracking/$key/requestStatus': 'accepted',
      'orderTracking/$key/deliveryStage': 'riderAssigned',
      'orderTracking/$key/assignedRiderId': riderId,
      'orderTracking/$key/updatedAt': ServerValue.timestamp,
      'deliveryTracking/$key/requestStatus': 'accepted',
      'deliveryTracking/$key/deliveryStage': 'riderAssigned',
      'deliveryTracking/$key/assignedRiderId': riderId,
      'deliveryTracking/$key/updatedAt': ServerValue.timestamp,
      'users/riders/$riderId/activeOrders/$key': {
        'orderId': key,
        'requestStatus': 'accepted',
        'deliveryStage': 'riderAssigned',
        'sellerId': sellerId,
        'customerId': customerId,
        'acceptedAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      },
      'riders/$riderId/activeOrders/$key': {
        'orderId': key,
        'requestStatus': 'accepted',
        'deliveryStage': 'riderAssigned',
        'sellerId': sellerId,
        'customerId': customerId,
        'acceptedAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      },
      'admin/activeDeliveries/$key/requestStatus': 'accepted',
      'admin/activeDeliveries/$key/deliveryStage': 'riderAssigned',
      'admin/activeDeliveries/$key/assignedRiderId': riderId,
      'admin/activeDeliveries/$key/updatedAt': ServerValue.timestamp,
    };
    if (sellerId != null && sellerId.isNotEmpty) {
      updates.addAll({
        'users/sellers/$sellerId/orders/$key/riderStatus': 'accepted',
        'users/sellers/$sellerId/orders/$key/deliveryStage': 'riderAssigned',
        'users/sellers/$sellerId/orders/$key/assignedRiderId': riderId,
        'users/sellers/$sellerId/orders/$key/assignedRiderName': riderName,
        'users/sellers/$sellerId/orders/$key/assignedRiderPhone': riderPhone,
        'users/sellers/$sellerId/orders/$key/timeline/riderAcceptedAt':
            ServerValue.timestamp,
        'users/sellers/$sellerId/orders/$key/updatedAt': ServerValue.timestamp,
      });
    }
    if (customerId != null && customerId.isNotEmpty) {
      updates.addAll({
        'users/customers/$customerId/orders/$key/riderStatus': 'accepted',
        'users/customers/$customerId/orders/$key/deliveryStage':
            'riderAssigned',
        'users/customers/$customerId/orders/$key/assignedRiderId': riderId,
        'users/customers/$customerId/orders/$key/assignedRiderName': riderName,
        'users/customers/$customerId/orders/$key/assignedRiderPhone':
            riderPhone,
        'users/customers/$customerId/orders/$key/timeline/riderAcceptedAt':
            ServerValue.timestamp,
        'users/customers/$customerId/orders/$key/updatedAt':
            ServerValue.timestamp,
      });
    }

    await database.ref().update(updates);
    RiderActiveDeliveryStore.instance.setActiveOrder(order);
    return true;
  }

  Future<void> markHeadingToSeller(RiderOrderModel order) {
    return _updateDeliveryStage(
      order,
      deliveryStage: 'riderHeadingToSeller',
      riderStatus: 'headingToSeller',
      orderStatus: 'preparing',
      timelineKey: 'riderHeadingToSellerAt',
    );
  }

  Future<void> markPickedUp(RiderOrderModel order) {
    return _updateDeliveryStage(
      order,
      deliveryStage: 'pickedUp',
      riderStatus: 'pickedUp',
      orderStatus: 'dispatched',
      customerStatus: 'onTheWay',
      timelineKey: 'pickedUpAt',
    );
  }

  Future<void> markHeadingToCustomer(RiderOrderModel order) {
    return _updateDeliveryStage(
      order,
      deliveryStage: 'riderHeadingToCustomer',
      riderStatus: 'headingToCustomer',
      orderStatus: 'dispatched',
      customerStatus: 'onTheWay',
      timelineKey: 'riderHeadingToCustomerAt',
    );
  }

  Future<void> uploadDeliveryProof(RiderOrderModel order) async {
    final database = _database ?? _maybeDatabase();
    if (database == null) return;
    final key = order.orderKey ?? _firebaseKey(order.id);
    final now = ServerValue.timestamp;
    final sellerId = order.sellerId;
    final customerId = order.customerId;
    final updates = <String, Object?>{
      'deliveryRequests/$key/deliveryProofUploaded': true,
      'deliveryRequests/$key/deliveryProofUploadedAt': now,
      'deliveryRequests/$key/updatedAt': now,
      'deliveryRequests/$key/timeline/deliveryProofUploadedAt': now,
      'orders/$key/deliveryProofUploaded': true,
      'orders/$key/deliveryProofUploadedAt': now,
      'orders/$key/updatedAt': now,
      'orders/$key/timeline/deliveryProofUploadedAt': now,
    };
    if (sellerId != null && sellerId.isNotEmpty) {
      updates.addAll({
        'users/sellers/$sellerId/orders/$key/deliveryProofUploaded': true,
        'users/sellers/$sellerId/orders/$key/deliveryProofUploadedAt': now,
        'users/sellers/$sellerId/orders/$key/updatedAt': now,
        'users/sellers/$sellerId/orders/$key/timeline/deliveryProofUploadedAt':
            now,
      });
    }
    if (customerId != null && customerId.isNotEmpty) {
      updates.addAll({
        'users/customers/$customerId/orders/$key/deliveryProofUploaded': true,
        'users/customers/$customerId/orders/$key/deliveryProofUploadedAt': now,
        'users/customers/$customerId/orders/$key/updatedAt': now,
        'users/customers/$customerId/orders/$key/timeline/deliveryProofUploadedAt':
            now,
      });
    }
    await database.ref().update(updates);
  }

  Future<void> markDelivered(RiderOrderModel order) {
    return _updateDeliveryStage(
      order,
      deliveryStage: 'delivered',
      riderStatus: 'delivered',
      orderStatus: 'completed',
      customerStatus: 'delivered',
      requestStatus: 'delivered',
      timelineKey: 'deliveredAt',
    );
  }

  Future<void> declineOrder(RiderOrderModel order) async {
    final database = _database ?? _maybeDatabase();
    if (database == null) return;
    final key = order.orderKey ?? _firebaseKey(order.id);
    await database.ref('deliveryRequests/$key/declinedRiders/$_riderId').set({
      'declinedAt': ServerValue.timestamp,
    });
  }

  Future<void> timeoutOrder(RiderOrderModel order) async {
    final database = _database ?? _maybeDatabase();
    if (database == null) return;
    final key = order.orderKey ?? _firebaseKey(order.id);
    await database.ref('deliveryRequests/$key/timeouts/$_riderId').set({
      'timedOutAt': ServerValue.timestamp,
    });
  }

  FirebaseDatabase? _maybeDatabase() {
    try {
      if (Firebase.apps.isEmpty) return null;
      return vyraalDatabase;
    } catch (_) {
      return null;
    }
  }

  List<RiderOrderModel> _ordersFromSnapshot(DataSnapshot snapshot) {
    final value = snapshot.value;
    if (value is! Map) return const [];
    final orders = <RiderOrderModel>[];
    for (final entry in value.entries) {
      final raw = entry.value;
      if (raw is! Map) continue;
      final data = Map<String, dynamic>.from(raw);
      final order = _orderFromJson(data, entry.key.toString());
      if (_hasDeclined(data)) continue;
      orders.add(order);
    }
    orders.sort((a, b) => b.id.compareTo(a.id));
    if (orders.isNotEmpty) {
      orders[0] = orders[0].copyWith(isHighlighted: true);
    }
    return orders;
  }

  RiderOrderModel _orderFromJson(Map<String, dynamic> json, String key) {
    final amount =
        ((json['riderEarning'] as num?)?.toDouble() ??
                (json['deliveryFee'] as num?)?.toDouble() ??
                ((json['amount'] as num? ?? 0).toDouble() * 0.08).clamp(
                  60,
                  180,
                ))
            .toDouble();
    final itemSummary = (json['itemSummary'] as String?)?.trim();
    final itemCount = (json['itemCount'] as num?)?.toInt() ?? 1;
    return RiderOrderModel(
      id: json['id'] as String? ?? key,
      orderKey: json['orderKey'] as String? ?? key,
      sellerId: json['sellerId'] as String?,
      customerId: json['customerId'] as String?,
      customerName: json['customerName'] as String?,
      customerPhone: json['customerPhone'] as String?,
      sellerPhone: json['sellerPhone'] as String?,
      sellerAddress: json['sellerAddress'] as String?,
      deliveryAddress: json['deliveryAddress'] as String?,
      paymentAmount: 'Rs. ${(json['amount'] as num? ?? 0).toStringAsFixed(0)}',
      storeName:
          json['sellerName'] as String? ??
          json['shopName'] as String? ??
          'Seller',
      distanceKm: ((json['distanceKm'] as num?)?.toDouble() ?? 1.0)
          .clamp(0.1, 99)
          .toDouble(),
      estimatedEarning: 'Rs. ${amount.toStringAsFixed(0)}',
      items: itemSummary == null || itemSummary.isEmpty
          ? '$itemCount item${itemCount == 1 ? '' : 's'}'
          : itemSummary,
      itemCount: itemCount,
      customerArea: _shortArea(json['deliveryAddress'] as String?),
      shopImageAsset: 'assets/images/shop1.png',
      shopImageUrl:
          json['sellerImageUrl'] as String? ??
          json['shopImageUrl'] as String? ??
          json['profileImageUrl'] as String?,
      shopImageBase64: json['shopImageBase64'] as String?,
      sellerLat: (json['sellerLat'] as num?)?.toDouble(),
      sellerLng: (json['sellerLng'] as num?)?.toDouble(),
      deliveryLat: (json['deliveryLat'] as num?)?.toDouble(),
      deliveryLng: (json['deliveryLng'] as num?)?.toDouble(),
    );
  }

  Future<void> _updateDeliveryStage(
    RiderOrderModel order, {
    required String deliveryStage,
    required String riderStatus,
    required String orderStatus,
    String? customerStatus,
    String? requestStatus,
    required String timelineKey,
  }) async {
    final database = _database ?? _maybeDatabase();
    if (database == null) return;
    final key = order.orderKey ?? _firebaseKey(order.id);
    final now = ServerValue.timestamp;
    final sellerId = order.sellerId;
    final customerId = order.customerId;
    final updates = <String, Object?>{
      'deliveryRequests/$key/deliveryStage': deliveryStage,
      'deliveryRequests/$key/riderStatus': riderStatus,
      'deliveryRequests/$key/status': orderStatus,
      'deliveryRequests/$key/updatedAt': now,
      'deliveryRequests/$key/timeline/$timelineKey': now,
      'orders/$key/deliveryStage': deliveryStage,
      'orders/$key/riderStatus': riderStatus,
      'orders/$key/status': orderStatus,
      'orders/$key/updatedAt': now,
      'orders/$key/timeline/$timelineKey': now,
      'activeDeliveries/$key/deliveryStage': deliveryStage,
      'activeDeliveries/$key/riderStatus': riderStatus,
      'activeDeliveries/$key/status': orderStatus,
      'activeDeliveries/$key/updatedAt': now,
      'orderTracking/$key/deliveryStage': deliveryStage,
      'orderTracking/$key/riderStatus': riderStatus,
      'orderTracking/$key/status': orderStatus,
      'orderTracking/$key/updatedAt': now,
      'deliveryTracking/$key/deliveryStage': deliveryStage,
      'deliveryTracking/$key/riderStatus': riderStatus,
      'deliveryTracking/$key/status': orderStatus,
      'deliveryTracking/$key/updatedAt': now,
      'admin/activeDeliveries/$key/deliveryStage': deliveryStage,
      'admin/activeDeliveries/$key/riderStatus': riderStatus,
      'admin/activeDeliveries/$key/status': orderStatus,
      'admin/activeDeliveries/$key/updatedAt': now,
    };
    if (requestStatus != null) {
      updates['deliveryRequests/$key/requestStatus'] = requestStatus;
      updates['orders/$key/requestStatus'] = requestStatus;
    }
    if (sellerId != null && sellerId.isNotEmpty) {
      updates.addAll({
        'users/sellers/$sellerId/orders/$key/deliveryStage': deliveryStage,
        'users/sellers/$sellerId/orders/$key/riderStatus': riderStatus,
        'users/sellers/$sellerId/orders/$key/status': orderStatus,
        'users/sellers/$sellerId/orders/$key/updatedAt': now,
        'users/sellers/$sellerId/orders/$key/timeline/$timelineKey': now,
      });
    }
    if (customerId != null && customerId.isNotEmpty) {
      updates.addAll({
        'users/customers/$customerId/orders/$key/deliveryStage': deliveryStage,
        'users/customers/$customerId/orders/$key/riderStatus': riderStatus,
        'users/customers/$customerId/orders/$key/status':
            customerStatus ?? orderStatus,
        'users/customers/$customerId/orders/$key/updatedAt': now,
        'users/customers/$customerId/orders/$key/timeline/$timelineKey': now,
      });
    }
    if (deliveryStage == 'delivered') {
      final riderId = _riderId;
      final earningText = order.estimatedEarning.replaceAll(RegExp(r'[^0-9.]'), '');
      final earning = double.tryParse(earningText) ?? 0;
      updates.addAll({
        'users/riders/$riderId/activeOrders/$key': null,
        'riders/$riderId/activeOrders/$key': null,
        'users/riders/$riderId/completedOrders/$key': {
          'orderId': key,
          'status': 'delivered',
          'deliveryStage': 'delivered',
          'amount': earning,
          'deliveryFee': earning,
          'completedAt': now,
          'updatedAt': now,
        },
        'riders/$riderId/completedOrders/$key': {
          'orderId': key,
          'status': 'delivered',
          'deliveryStage': 'delivered',
          'amount': earning,
          'deliveryFee': earning,
          'completedAt': now,
          'updatedAt': now,
        },
        'riderEarnings/$riderId/$key': {
          'orderId': key,
          'status': 'earned',
          'amount': earning,
          'deliveryFee': earning,
          'createdAt': now,
          'updatedAt': now,
        },
        'riderHistory/$riderId/$key': {
          'orderId': key,
          'type': 'delivered',
          'status': 'delivered',
          'amount': earning,
          'deliveryFee': earning,
          'completedAt': now,
          'updatedAt': now,
        },
      });
    }
    await database.ref().update(updates);
  }

  Future<bool> _currentRiderIsApproved() async {
    final database = _database ?? _maybeDatabase();
    if (database == null) return false;
    try {
      final snap = await database.ref('users/riders/$_riderId').get().timeout(const Duration(seconds: 3));
      final value = snap.value;
      if (value is! Map) return false;
      final data = Map<String, dynamic>.from(value);
      return data['isVerified'] == true || data['verificationStatus'] == 'approved';
    } catch (_) {
      return false;
    }
  }

  bool _hasDeclined(Map<String, dynamic> json) {
    final declined = json['declinedRiders'];
    if (declined is! Map) return false;
    return declined.containsKey(_riderId);
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

  String get _riderId {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? 'demo-rider';
    } catch (_) {
      return 'demo-rider';
    }
  }

  String get _riderName {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final name = user?.displayName?.trim();
      if (name != null && name.isNotEmpty) return name;
    } catch (_) {}
    return 'Vyraal rider';
  }

  String get _riderPhone {
    try {
      final phone = FirebaseAuth.instance.currentUser?.phoneNumber?.trim();
      if (phone != null && phone.isNotEmpty) return phone;
    } catch (_) {}
    return '';
  }

  String _firebaseKey(String value) {
    return value.replaceAll(RegExp(r'[.#$\[\]/]'), '_');
  }
}