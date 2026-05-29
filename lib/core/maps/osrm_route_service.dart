import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsrmRouteResult {
  const OsrmRouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  String get distanceLabel {
    if (distanceMeters <= 0) return '--';
    if (distanceMeters < 1000) return '${distanceMeters.round()} m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get etaLabel {
    if (durationSeconds <= 0) return '--';
    final minutes = (durationSeconds / 60).ceil().clamp(1, 999);
    return '$minutes mins';
  }
}

class OsrmRouteService {
  const OsrmRouteService({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<OsrmRouteResult> route(List<LatLng> stops) async {
    final cleanStops = stops.where(_isValidPoint).toList(growable: false);
    if (cleanStops.length < 2) return _fallback(cleanStops);

    final client = _client ?? http.Client();
    final coordinates = cleanStops
        .map((point) => '${point.longitude},${point.latitude}')
        .join(';');
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$coordinates'
      '?overview=full&geometries=geojson&alternatives=false&steps=false',
    );

    try {
      final response = await client.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return _fallback(cleanStops);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = body['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return _fallback(cleanStops);

      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>?;
      final rawCoordinates = geometry?['coordinates'] as List<dynamic>?;
      if (rawCoordinates == null || rawCoordinates.length < 2) {
        return _fallback(cleanStops);
      }

      final points = rawCoordinates.map((rawPoint) {
        final point = rawPoint as List<dynamic>;
        return LatLng(
          (point[1] as num).toDouble(),
          (point[0] as num).toDouble(),
        );
      }).where(_isValidPoint).toList(growable: false);

      if (points.length < 2) return _fallback(cleanStops);

      return OsrmRouteResult(
        points: points,
        distanceMeters: (route['distance'] as num?)?.toDouble() ?? 0,
        durationSeconds: (route['duration'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {
      return _fallback(cleanStops);
    } finally {
      if (_client == null) client.close();
    }
  }

  OsrmRouteResult _fallback(List<LatLng> stops) {
    if (stops.length < 2) {
      return OsrmRouteResult(
        points: stops,
        distanceMeters: 0,
        durationSeconds: 0,
      );
    }

    final distance = const Distance();
    var meters = 0.0;
    for (var i = 0; i < stops.length - 1; i++) {
      meters += distance.as(LengthUnit.Meter, stops[i], stops[i + 1]);
    }

    return OsrmRouteResult(
      points: stops,
      distanceMeters: meters,
      durationSeconds: (meters / 1000) * 240,
    );
  }

  bool _isValidPoint(LatLng point) {
    return point.latitude.isFinite &&
        point.longitude.isFinite &&
        point.latitude >= -90 &&
        point.latitude <= 90 &&
        point.longitude >= -180 &&
        point.longitude <= 180;
  }
}