import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class RiderLocationReading {
  const RiderLocationReading({
    required this.position,
    required this.heading,
    required this.speed,
    required this.accuracy,
    required this.recordedAt,
  });

  final LatLng position;
  final double heading;
  final double speed;
  final double accuracy;
  final DateTime recordedAt;
}

class RiderLocationService {
  const RiderLocationService();

  Future<RiderLocationReading?> currentLocation() async {
    try {
      final ready = await ensureReady();
      if (!ready) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return _readingFromPosition(position);
    } catch (_) {
      return null;
    }
  }

  Stream<RiderLocationReading> liveLocationStream() async* {
    final ready = await ensureReady();
    if (!ready) return;

    final first = await currentLocation();
    if (first != null) yield first;

    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      ),
    ).transform(
      StreamTransformer<Position, RiderLocationReading>.fromHandlers(
        handleData: (position, sink) => sink.add(_readingFromPosition(position)),
      ),
    );
  }

  Future<bool> ensureReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();

  Future<void> openAppSettings() => Geolocator.openAppSettings();

  RiderLocationReading _readingFromPosition(Position position) {
    final heading = position.heading.isFinite ? position.heading : 0.0;
    final speed = position.speed.isFinite ? position.speed : 0.0;
    final accuracy = position.accuracy.isFinite ? position.accuracy : 0.0;
    return RiderLocationReading(
      position: LatLng(position.latitude, position.longitude),
      heading: heading,
      speed: speed,
      accuracy: accuracy,
      recordedAt: position.timestamp,
    );
  }
}