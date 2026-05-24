import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'rider_map_models.dart';

class RiderLocationReading {
  const RiderLocationReading({required this.position, required this.heading});

  final LatLng position;
  final double heading;
}

class RiderLocationService {
  const RiderLocationService();

  Future<RiderLocationReading> currentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      final allowed =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!allowed || !serviceEnabled) return _fallback;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 4),
        ),
      );

      return RiderLocationReading(
        position: LatLng(position.latitude, position.longitude),
        heading: position.heading.isFinite ? position.heading : 0,
      );
    } catch (_) {
      return _fallback;
    }
  }

  RiderLocationReading get _fallback {
    return const RiderLocationReading(
      position: DemoMapPoints.rider,
      heading: 42,
    );
  }
}
