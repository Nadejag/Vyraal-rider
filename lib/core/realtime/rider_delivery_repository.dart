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
  final Map<String, Map<String, String?>> _sellerImageCache = {};

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
        .asyncMap((event) => _ordersFromSnapshot(event.snapshot));
  }

  Future<bool> acceptOrder(RiderOrderModel order) async {
    final database = _database ?? _maybeDatabase();
    if (database == null) return false;

    final key = order.orderKey ?? _firebaseKey(order.id);
    if (!await _currentRiderIsApproved()) {
      return false;
    }
    final riderId = _riderId;
    final riderProfile = await _currentRiderProfile();
    final riderName = _profileText(riderProfile, const [
      'name',
      'fullName',
    ], _riderName);
    final riderPhone = _profileText(riderProfile, const [
      'phone',
      'phoneNumber',
    ], _riderPhone);
    final riderPhoto = _profileText(riderProfile, const [
      'profilePhotoUrl',
      'profilePhotoBase64',
      'avatarUrl',
      'photoUrl',
    ], '');
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
        'assignedRiderPhotoUrl': riderPhoto,
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
      'orders/$key/assignedRiderPhotoUrl': riderPhoto,
      'orders/$key/timeline/riderAcceptedAt': ServerValue.timestamp,
      'orders/$key/updatedAt': ServerValue.timestamp,
      'activeDeliveries/$key/requestStatus': 'accepted',
      'activeDeliveries/$key/deliveryStage': 'riderAssigned',
      'activeDeliveries/$key/assignedRiderId': riderId,
      'activeDeliveries/$key/assignedRiderName': riderName,
      'activeDeliveries/$key/assignedRiderPhone': riderPhone,
      'activeDeliveries/$key/assignedRiderPhotoUrl': riderPhoto,
      'activeDeliveries/$key/updatedAt': ServerValue.timestamp,
      'orderTracking/$key/requestStatus': 'accepted',
      'orderTracking/$key/deliveryStage': 'riderAssigned',
      'orderTracking/$key/assignedRiderId': riderId,
      'orderTracking/$key/assignedRiderName': riderName,
      'orderTracking/$key/assignedRiderPhone': riderPhone,
      'orderTracking/$key/assignedRiderPhotoUrl': riderPhoto,
      'orderTracking/$key/updatedAt': ServerValue.timestamp,
      'deliveryTracking/$key/requestStatus': 'accepted',
      'deliveryTracking/$key/deliveryStage': 'riderAssigned',
      'deliveryTracking/$key/assignedRiderId': riderId,
      'deliveryTracking/$key/assignedRiderName': riderName,
      'deliveryTracking/$key/assignedRiderPhone': riderPhone,
      'deliveryTracking/$key/assignedRiderPhotoUrl': riderPhoto,
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
        'users/sellers/$sellerId/orders/$key/assignedRiderPhotoUrl': riderPhoto,
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
        'users/customers/$customerId/orders/$key/assignedRiderPhotoUrl':
            riderPhoto,
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

  Future<void> uploadDeliveryProof(
    RiderOrderModel order, {
    String? proofImageBase64,
    String? proofImageUrl,
  }) async {
    final database = _database ?? _maybeDatabase();
    if (database == null) return;
    final key = order.orderKey ?? _firebaseKey(order.id);
    final now = ServerValue.timestamp;
    final sellerId = order.sellerId;
    final customerId = order.customerId;
    final proof = proofImageBase64?.trim();
    final proofUrl = proofImageUrl?.trim();
    final updates = <String, Object?>{
      'deliveryRequests/$key/deliveryProofUploaded': true,
      'deliveryRequests/$key/deliveryProofUploadedAt': now,
      'deliveryRequests/$key/deliveryProofImageBase64': proof,
      'deliveryRequests/$key/deliveryProofImageUrl': proofUrl,
      'deliveryRequests/$key/updatedAt': now,
      'deliveryRequests/$key/timeline/deliveryProofUploadedAt': now,
      'orders/$key/deliveryProofUploaded': true,
      'orders/$key/deliveryProofUploadedAt': now,
      'orders/$key/deliveryProofImageBase64': proof,
      'orders/$key/deliveryProofImageUrl': proofUrl,
      'orders/$key/updatedAt': now,
      'orders/$key/timeline/deliveryProofUploadedAt': now,
      'orderTracking/$key/deliveryProofUploaded': true,
      'orderTracking/$key/deliveryProofUploadedAt': now,
      'orderTracking/$key/deliveryProofImageBase64': proof,
      'orderTracking/$key/deliveryProofImageUrl': proofUrl,
      'orderTracking/$key/updatedAt': now,
      'deliveryTracking/$key/deliveryProofUploaded': true,
      'deliveryTracking/$key/deliveryProofUploadedAt': now,
      'deliveryTracking/$key/deliveryProofImageBase64': proof,
      'deliveryTracking/$key/deliveryProofImageUrl': proofUrl,
      'deliveryTracking/$key/updatedAt': now,
    };
    if (sellerId != null && sellerId.isNotEmpty) {
      updates.addAll({
        'users/sellers/$sellerId/orders/$key/deliveryProofUploaded': true,
        'users/sellers/$sellerId/orders/$key/deliveryProofUploadedAt': now,
        'users/sellers/$sellerId/orders/$key/deliveryProofImageBase64': proof,
        'users/sellers/$sellerId/orders/$key/deliveryProofImageUrl': proofUrl,
        'users/sellers/$sellerId/orders/$key/updatedAt': now,
        'users/sellers/$sellerId/orders/$key/timeline/deliveryProofUploadedAt':
            now,
      });
    }
    if (customerId != null && customerId.isNotEmpty) {
      updates.addAll({
        'users/customers/$customerId/orders/$key/deliveryProofUploaded': true,
        'users/customers/$customerId/orders/$key/deliveryProofUploadedAt': now,
        'users/customers/$customerId/orders/$key/deliveryProofImageBase64':
            proof,
        'users/customers/$customerId/orders/$key/deliveryProofImageUrl':
            proofUrl,
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

  Future<List<RiderOrderModel>> _ordersFromSnapshot(
    DataSnapshot snapshot,
  ) async {
    final value = snapshot.value;
    if (value is! Map) return const [];
    final orders = <RiderOrderModel>[];
    for (final entry in value.entries) {
      final raw = entry.value;
      if (raw is! Map) continue;
      final data = Map<String, dynamic>.from(raw);
      var order = _orderFromJson(data, entry.key.toString());
      if (_hasDeclined(data)) continue;
      order = await _withStableSellerImage(order);
      orders.add(order);
    }
    orders.sort((a, b) => b.id.compareTo(a.id));
    if (orders.isNotEmpty) {
      orders[0] = orders[0].copyWith(isHighlighted: true);
    }
    return orders;
  }

  Future<RiderOrderModel> _withStableSellerImage(RiderOrderModel order) async {
    final sellerId = order.sellerId?.trim();
    final currentUrl = order.shopImageUrl?.trim();
    final currentBase64 = order.shopImageBase64?.trim();
    final hasImage =
        (currentUrl != null && currentUrl.isNotEmpty) ||
        (currentBase64 != null && currentBase64.isNotEmpty);

    if (sellerId != null && sellerId.isNotEmpty && hasImage) {
      _sellerImageCache[sellerId] = {
        'url': currentUrl,
        'base64': currentBase64,
      };
      return order;
    }

    if (sellerId == null || sellerId.isEmpty) return order;
    final cached = _sellerImageCache[sellerId];
    if (cached != null) {
      return order.copyWith(
        shopImageUrl: cached['url'],
        shopImageBase64: cached['base64'],
      );
    }

    final fetched = await _fetchSellerImage(sellerId);
    if (fetched == null) return order;
    _sellerImageCache[sellerId] = fetched;
    return order.copyWith(
      shopImageUrl: fetched['url'],
      shopImageBase64: fetched['base64'],
    );
  }

  Future<Map<String, String?>?> _fetchSellerImage(String sellerId) async {
    final database = _database ?? _maybeDatabase();
    if (database == null) return null;
    for (final path in [
      'publicSellers/$sellerId',
      'sellerShopLocations/$sellerId',
      'shopLocations/$sellerId',
      'users/sellers/$sellerId/storeProfile',
      'users/sellers/$sellerId',
    ]) {
      try {
        final snap = await database
            .ref(path)
            .get()
            .timeout(const Duration(milliseconds: 1200));
        final value = snap.value;
        if (value is! Map) continue;
        final data = Map<String, dynamic>.from(value);
        final url = _firstText(data, const [
          'shopImageUrl',
          'sellerImageUrl',
          'profileImageUrl',
          'imageUrl',
          'image',
          'shopImageBase64',
          'imageBase64',
        ]);
        final base64 = _firstText(data, const [
          'shopImageBase64',
          'imageBase64',
          'sellerImageBase64',
          'shopImageUrl',
          'image',
        ]);
        if ((url?.isNotEmpty ?? false) || (base64?.isNotEmpty ?? false)) {
          return {'url': url, 'base64': base64};
        }
      } catch (_) {}
    }
    return null;
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
      shopImageUrl: _firstText(json, const [
        'sellerImageUrl',
        'shopImageUrl',
        'profileImageUrl',
        'sellerPhotoUrl',
        'shopPhotoUrl',
        'imageUrl',
        'image',
        'shopImageBase64',
        'imageBase64',
        'sellerImageBase64',
      ]),
      shopImageBase64: _firstText(json, const [
        'shopImageBase64',
        'imageBase64',
        'sellerImageBase64',
        'shopImageUrl',
        'sellerImageUrl',
        'image',
      ]),
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
      final earningText = order.estimatedEarning.replaceAll(
        RegExp(r'[^0-9.]'),
        '',
      );
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
      final snap = await database
          .ref('users/riders/$_riderId')
          .get()
          .timeout(const Duration(seconds: 3));
      final value = snap.value;
      if (value is! Map) return false;
      final data = Map<String, dynamic>.from(value);
      return data['isVerified'] == true ||
          data['verificationStatus'] == 'approved';
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _currentRiderProfile() async {
    final database = _database ?? _maybeDatabase();
    if (database == null) return const {};
    try {
      final snap = await database
          .ref('users/riders/$_riderId')
          .get()
          .timeout(const Duration(seconds: 3));
      final value = snap.value;
      if (value is! Map) return const {};
      return Map<String, dynamic>.from(value);
    } catch (_) {
      return const {};
    }
  }

  String _profileText(
    Map<String, dynamic> profile,
    List<String> keys,
    String fallback,
  ) {
    for (final key in keys) {
      final text = profile[key]?.toString().trim() ?? '';
      if (text.isNotEmpty && text != 'null') return text;
    }
    return fallback;
  }

  String? _firstText(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final text = json[key]?.toString().trim() ?? '';
      if (text.isNotEmpty && text != 'null') return text;
    }
    return null;
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
