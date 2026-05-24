import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';

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
  }) async {
    final payload = <String, Object>{
      'riderId': riderId,
      'orderId': orderId,
      'lat': position.latitude,
      'lng': position.longitude,
      'heading': heading,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    _realtimeService.riderLocationUpdated(payload);

    final database = _database ?? _maybeDatabase();
    if (database == null) return;

    await database.ref('riders/$riderId/liveLocation').set(payload);
    await database.ref('orders/$orderId/riderLocation').set(payload);
  }

  FirebaseDatabase? _maybeDatabase() {
    try {
      if (Firebase.apps.isEmpty) return null;
      return FirebaseDatabase.instance;
    } catch (_) {
      return null;
    }
  }
}
