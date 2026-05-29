import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';

import '../firebase_database_refs.dart';
import '../realtime/rider_realtime_service.dart';

class RiderLiveLocationRepository {
  RiderLiveLocationRepository({
    RiderRealtimeService? realtimeService,
    FirebaseDatabase? database,
  }) : _realtimeService = realtimeService ?? RiderRealtimeService.instance,
       _database = database;

  final RiderRealtimeService _realtimeService;
  final FirebaseDatabase? _database;

  Future<void> saveLocation({
    required String riderId,
    required String orderId,
    required LatLng position,
    required double heading,
    double speed = 0,
    double accuracy = 0,
  }) async {
    if (riderId.trim().isEmpty) return;

    final now = ServerValue.timestamp;
    final cleanOrderId = orderId.trim();
    final key = cleanOrderId.isEmpty ? '' : _firebaseKey(cleanOrderId);
    final payload = <String, Object>{
      'riderId': riderId,
      'orderId': cleanOrderId,
      'currentOrderId': cleanOrderId,
      'lat': position.latitude,
      'lng': position.longitude,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'heading': heading,
      'speed': speed,
      'accuracy': accuracy,
      'isOnline': true,
      'updatedAt': now,
    };

    _realtimeService.riderLocationUpdated(payload);

    final database = _database ?? _maybeDatabase();
    if (database == null) return;

    final updates = <String, Object>{
      'riderLiveLocations/$riderId': payload,
      'liveRiderLocations/$riderId': payload,
      'riderLocations/$riderId': payload,
      'riders/$riderId/liveLocation': payload,
      'riders/$riderId/isOnline': true,
      'riders/$riderId/locationUpdatedAt': now,
      'users/riders/$riderId/liveLocation': payload,
      'users/riders/$riderId/isOnline': true,
      'users/riders/$riderId/locationUpdatedAt': now,
    };

    if (key.isNotEmpty) {
      updates.addAll({
        'riders/$riderId/currentOrderId': key,
        'users/riders/$riderId/currentOrderId': key,
        'users/riders/$riderId/activeOrders/$key/riderLocation': payload,
        'riders/$riderId/activeOrders/$key/riderLocation': payload,
        'orders/$key/riderLocation': payload,
        'deliveryRequests/$key/riderLocation': payload,
      });

      try {
        final snapshot = await database.ref('orders/$key').get();
        final value = snapshot.value;
        if (value is Map) {
          final data = Map<String, dynamic>.from(value);
          final sellerId = (data['sellerId'] as String?)?.trim();
          final customerId = (data['customerId'] as String?)?.trim();
          if (sellerId != null && sellerId.isNotEmpty) {
            updates['users/sellers/$sellerId/orders/$key/riderLocation'] =
                payload;
          }
          if (customerId != null && customerId.isNotEmpty) {
            updates['users/customers/$customerId/orders/$key/riderLocation'] =
                payload;
          }
        }
      } catch (_) {}
    }

    await database.ref().update(updates);
  }

  Future<void> markOffline({required String riderId}) async {
    if (riderId.trim().isEmpty) return;
    final database = _database ?? _maybeDatabase();
    if (database == null) return;
    final now = ServerValue.timestamp;
    await database.ref().update({
      'riderLiveLocations/$riderId/isOnline': false,
      'riderLiveLocations/$riderId/updatedAt': now,
      'liveRiderLocations/$riderId/isOnline': false,
      'liveRiderLocations/$riderId/updatedAt': now,
      'riderLocations/$riderId/isOnline': false,
      'riderLocations/$riderId/updatedAt': now,
      'riders/$riderId/isOnline': false,
      'riders/$riderId/locationUpdatedAt': now,
      'users/riders/$riderId/isOnline': false,
      'users/riders/$riderId/locationUpdatedAt': now,
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

  String _firebaseKey(String value) =>
      value.replaceAll(RegExp(r'[.#$\[\]/]'), '_');
}