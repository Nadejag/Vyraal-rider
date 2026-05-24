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
    if (distanceMeters < 1000) return '${distanceMeters.round()} m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get etaLabel {
    final minutes = (durationSeconds / 60).ceil().clamp(1, 999);
    return '$minutes mins';
  }
}

class OsrmRouteService {
  const OsrmRouteService({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<OsrmRouteResult> route(List<LatLng> stops) async {
    if (stops.length < 2) return _fallback(stops);

    final client = _client ?? http.Client();
    final coordinates = stops
        .map((point) => '${point.longitude},${point.latitude}')
        .join(';');
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$coordinates'
      '?overview=full&geometries=geojson&steps=true',
    );

    try {
      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return _fallback(stops);

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = body['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return _fallback(stops);

      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final rawCoordinates = geometry['coordinates'] as List<dynamic>;
      final points = rawCoordinates.map((rawPoint) {
        final point = rawPoint as List<dynamic>;
        return LatLng(
          (point[1] as num).toDouble(),
          (point[0] as num).toDouble(),
        );
      }).toList();

      return OsrmRouteResult(
        points: points,
        distanceMeters: (route['distance'] as num?)?.toDouble() ?? 0,
        durationSeconds: (route['duration'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {
      return _fallback(stops);
    } finally {
      if (_client == null) client.close();
    }
  }

  OsrmRouteResult _fallback(List<LatLng> stops) {
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
}
