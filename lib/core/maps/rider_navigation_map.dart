import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'rider_map_models.dart';

class RiderNavigationMap extends StatefulWidget {
  const RiderNavigationMap({
    required this.snapshot,
    required this.stage,
    this.compact = false,
    super.key,
  });

  final RiderNavigationSnapshot snapshot;
  final RiderRouteStage stage;
  final bool compact;

  @override
  State<RiderNavigationMap> createState() => _RiderNavigationMapState();
}

class _RiderNavigationMapState extends State<RiderNavigationMap>
    with TickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _routeRevealController;
  late final AnimationController _cameraController;
  Animation<LatLng>? _cameraCenterAnimation;
  Animation<double>? _cameraZoomAnimation;
  var _mapReady = false;
  var _lastCenter = DemoMapPoints.rider;
  var _lastZoom = 14.5;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _routeRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..forward();
    _cameraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )..addListener(_tickCamera);
  }

  @override
  void didUpdateWidget(covariant RiderNavigationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot.routePoints != widget.snapshot.routePoints ||
        oldWidget.stage != widget.stage) {
      _routeRevealController.forward(from: 0);
    }
    if (widget.snapshot.hasLiveLocation &&
        oldWidget.snapshot.riderPosition != widget.snapshot.riderPosition) {
      _animateTo(widget.snapshot.riderPosition, _lastZoom);
    }
  }

  @override
  void dispose() {
    _routeRevealController.dispose();
    _cameraController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;
    final initialFit = CameraFit.coordinates(
      coordinates: _fitCoordinates,
      padding: EdgeInsets.fromLTRB(
        widget.compact ? 44 : 54,
        widget.compact ? 48 : 88,
        widget.compact ? 44 : 54,
        widget.compact ? 44 : 170,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.compact ? 16 : 0),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCameraFit: initialFit,
              minZoom: 11,
              maxZoom: 18,
              backgroundColor: const Color(0xFFE8EEF2),
              onMapReady: () {
                _mapReady = true;
                _lastCenter = widget.snapshot.hasLiveLocation
                    ? widget.snapshot.riderPosition
                    : _destination;
                _lastZoom = _mapController.camera.zoom;
              },
              onPositionChanged: (camera, hasGesture) {
                if (!hasGesture) return;
                _lastCenter = camera.center;
                _lastZoom = camera.zoom;
              },
              interactionOptions: const InteractionOptions(
                flags:
                    InteractiveFlag.drag |
                    InteractiveFlag.pinchZoom |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.flingAnimation,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.koadly.vyraal.rider',
                retinaMode: RetinaMode.isHighDensity(context),
                tileBuilder: (context, tileWidget, tile) {
                  return DecoratedBox(
                    decoration: const BoxDecoration(color: Color(0xFFE8EEF2)),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        1.03,
                        0,
                        0,
                        0,
                        4,
                        0,
                        1.03,
                        0,
                        0,
                        4,
                        0,
                        0,
                        0.98,
                        0,
                        2,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ]),
                      child: tileWidget,
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _routeRevealController,
                builder: (context, _) {
                  final visibleRoute = _visibleRoute(route);
                  if (visibleRoute.length < 2) {
                    return const SizedBox.shrink();
                  }
                  return PolylineLayer(
                    polylines: [
                      Polyline(
                        points: visibleRoute,
                        color: const Color(0xFF111827).withValues(alpha: 0.18),
                        strokeWidth: widget.compact ? 13 : 18,
                        borderColor: Colors.white.withValues(alpha: 0.7),
                        borderStrokeWidth: 2,
                      ),
                      Polyline(
                        points: visibleRoute,
                        color: const Color(0xFFFFC914),
                        strokeWidth: widget.compact ? 5 : 7,
                        borderColor: const Color(0xFF6E5200),
                        borderStrokeWidth: widget.compact ? 0.6 : 0.8,
                      ),
                    ],
                  );
                },
              ),
              MarkerLayer(markers: _markers),
              RichAttributionWidget(
                showFlutterMapAttribution: false,
                alignment: AttributionAlignment.bottomRight,
                attributions: const [
                  TextSourceAttribution('OpenStreetMap contributors'),
                  TextSourceAttribution('OSRM route', prependCopyright: false),
                ],
              ),
            ],
          ),
          Positioned(
            left: 12,
            top: 12,
            child: widget.snapshot.hasLiveLocation
                ? _MapLegend(
                    stage: widget.stage,
                    eta: widget.snapshot.etaLabel,
                    distance: widget.snapshot.distanceLabel,
                    compact: widget.compact,
                  )
                : _LiveGpsBanner(
                    message: widget.snapshot.locationStatus,
                    compact: widget.compact,
                  ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: _MapControls(
              compact: widget.compact,
              onFitRoute: _fitRoute,
              onRider: widget.snapshot.hasLiveLocation
                  ? () => _animateTo(widget.snapshot.riderPosition, 16)
                  : () => _animateTo(_destination, 16),
              onDestination: () => _animateTo(_destination, 16),
              onZoomIn: () => _animateTo(_lastCenter, (_lastZoom + 0.7)),
              onZoomOut: () => _animateTo(_lastCenter, (_lastZoom - 0.7)),
            ),
          ),
          if (!widget.compact)
            Positioned(
              left: 16,
              right: 16,
              bottom: 18,
              child: widget.snapshot.hasLiveLocation
                  ? _RouteSummaryCard(
                      stage: widget.stage,
                      eta: widget.snapshot.etaLabel,
                      distance: widget.snapshot.distanceLabel,
                    )
                  : _RouteSummaryCard(
                      stage: widget.stage,
                      eta: 'Waiting for GPS',
                      distance: 'Live tracking off',
                    ),
            ),
        ],
      ),
    );
  }

  List<Marker> get _markers {
    final destinationMarker = widget.stage == RiderRouteStage.pickup
        ? Marker(
            point: widget.snapshot.sellerPosition,
            width: widget.compact ? 68 : 82,
            height: widget.compact ? 68 : 82,
            child: _SellerMarker(
              name: widget.snapshot.sellerName,
              imageUrl: widget.snapshot.sellerImageUrl,
              imageBase64: widget.snapshot.sellerImageBase64,
              compact: widget.compact,
            ),
          )
        : Marker(
            point: widget.snapshot.customerPosition,
            width: widget.compact ? 52 : 62,
            height: widget.compact ? 52 : 62,
            child: _PinMarker(
              color: const Color(0xFFE11D48),
              icon: Icons.home_outlined,
              label: widget.snapshot.customerName,
            ),
          );

    return [
      if (widget.snapshot.hasLiveLocation)
        Marker(
          point: widget.snapshot.riderPosition,
          width: widget.compact ? 64 : 76,
          height: widget.compact ? 64 : 76,
          child: _RiderMarker(heading: widget.snapshot.heading),
        ),
      destinationMarker,
    ];
  }

  List<LatLng> get _route {
    if (!widget.snapshot.hasLiveLocation) return [_destination];
    return widget.snapshot.routePoints.isEmpty
        ? [widget.snapshot.riderPosition, _destination]
        : widget.snapshot.routePoints;
  }

  List<LatLng> get _fitCoordinates {
    if (widget.snapshot.hasLiveLocation) return _route;
    return [
      widget.snapshot.sellerPosition,
      widget.snapshot.customerPosition,
      _destination,
    ];
  }

  LatLng get _destination {
    return widget.stage == RiderRouteStage.pickup
        ? widget.snapshot.sellerPosition
        : widget.snapshot.customerPosition;
  }

  List<LatLng> _visibleRoute(List<LatLng> route) {
    if (route.length <= 2) return route;
    final visibleCount = (route.length * _routeRevealController.value)
        .ceil()
        .clamp(2, route.length);
    return route.take(visibleCount).toList();
  }

  void _fitRoute() {
    if (!_mapReady) return;
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: _fitCoordinates,
        padding: const EdgeInsets.fromLTRB(54, 82, 54, 170),
      ),
    );
    _lastCenter = _mapController.camera.center;
    _lastZoom = _mapController.camera.zoom;
  }

  void _animateTo(LatLng center, double zoom) {
    if (!_mapReady) return;
    final safeZoom = zoom.clamp(11.0, 18.0);
    _cameraCenterAnimation = LatLngTween(begin: _lastCenter, end: center)
        .animate(
          CurvedAnimation(
            parent: _cameraController,
            curve: Curves.easeOutCubic,
          ),
        );
    _cameraZoomAnimation = Tween<double>(begin: _lastZoom, end: safeZoom)
        .animate(
          CurvedAnimation(
            parent: _cameraController,
            curve: Curves.easeOutCubic,
          ),
        );
    _cameraController.forward(from: 0);
    _lastCenter = center;
    _lastZoom = safeZoom;
  }

  void _tickCamera() {
    final center = _cameraCenterAnimation?.value;
    final zoom = _cameraZoomAnimation?.value;
    if (!_mapReady || center == null || zoom == null) return;
    _mapController.move(center, zoom, id: 'vyraal-map-animation');
  }
}

class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end})
    : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    return LatLng(
      begin!.latitude + (end!.latitude - begin!.latitude) * t,
      begin!.longitude + (end!.longitude - begin!.longitude) * t,
    );
  }
}

class _RiderMarker extends StatelessWidget {
  const _RiderMarker({required this.heading});

  final double heading;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.86, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.7, end: 1),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, value, _) {
              return Container(
                width: 58 * value,
                height: 58 * value,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFFFC914,
                  ).withValues(alpha: 0.22 * (1 - value + 0.3)),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFFC914),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: AnimatedRotation(
              turns: heading / 360,
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOut,
              child: const Icon(
                Icons.navigation_rounded,
                color: Color(0xFF6E5200),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SellerMarker extends StatelessWidget {
  const _SellerMarker({
    required this.name,
    required this.compact,
    this.imageUrl,
    this.imageBase64,
  });

  final String name;
  final bool compact;
  final String? imageUrl;
  final String? imageBase64;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 46.0 : 54.0;
    return Tooltip(
      message: name,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.82, end: 1),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: size,
              height: size,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFC914), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.20),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: ClipOval(child: _sellerImage()),
            ),
          ),
          if (!compact)
            Container(
              constraints: const BoxConstraints(maxWidth: 78),
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFC914)),
              ),
              child: Text(
                name.isEmpty ? 'Shop' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sellerImage() {
    final base64 = imageBase64?.trim();
    if (base64 != null && base64.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(base64),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(),
        );
      } catch (_) {
        return _fallback();
      }
    }

    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty && url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFF10B981),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
    );
  }
}

class _PinMarker extends StatelessWidget {
  const _PinMarker({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.82, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Tooltip(
        message: label,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
        ),
      ),
    );
  }
}

class _MapControls extends StatelessWidget {
  const _MapControls({
    required this.compact,
    required this.onFitRoute,
    required this.onRider,
    required this.onDestination,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final bool compact;
  final VoidCallback onFitRoute;
  final VoidCallback onRider;
  final VoidCallback onDestination;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 34.0 : 40.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MapControlButton(
            tooltip: 'Focus active route',
            icon: Icons.navigation_rounded,
            size: size,
            onTap: onFitRoute,
          ),
          _MapDivider(compact: compact),
          _MapControlButton(
            tooltip: 'Focus rider',
            icon: Icons.my_location_rounded,
            size: size,
            onTap: onRider,
          ),
          _MapDivider(compact: compact),
          _MapControlButton(
            tooltip: 'Focus destination',
            icon: Icons.flag_rounded,
            size: size,
            onTap: onDestination,
          ),
          if (!compact) ...[
            _MapDivider(compact: compact),
            _MapControlButton(
              tooltip: 'Zoom in',
              icon: Icons.add_rounded,
              size: size,
              onTap: onZoomIn,
            ),
            _MapDivider(compact: compact),
            _MapControlButton(
              tooltip: 'Zoom out',
              icon: Icons.remove_rounded,
              size: size,
              onTap: onZoomOut,
            ),
          ],
        ],
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.tooltip,
    required this.icon,
    required this.size,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: const Color(0xFF6E5200), size: size * 0.55),
        ),
      ),
    );
  }
}

class _MapDivider extends StatelessWidget {
  const _MapDivider({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 22 : 28,
      height: 1,
      color: const Color(0xFFD3C7AC),
    );
  }
}

class _LiveGpsBanner extends StatelessWidget {
  const _LiveGpsBanner({required this.message, required this.compact});

  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFC914)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 8 : 10,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.gps_not_fixed_rounded,
              color: Color(0xFFFFC914),
              size: 17,
            ),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: compact ? 170 : 230),
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 11 : 12,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({
    required this.stage,
    required this.eta,
    required this.distance,
    required this.compact,
  });

  final RiderRouteStage stage;
  final String eta;
  final String distance;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = stage == RiderRouteStage.pickup
        ? 'Rider to seller'
        : 'Rider to customer';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF111827).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 8 : 10,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.route_rounded, color: Color(0xFFFFC914), size: 17),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 11 : 12,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$eta • $distance',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: compact ? 10 : 11,
                    height: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({
    required this.stage,
    required this.eta,
    required this.distance,
  });

  final RiderRouteStage stage;
  final String eta;
  final String distance;

  @override
  Widget build(BuildContext context) {
    final destination = stage == RiderRouteStage.pickup ? 'Seller' : 'Customer';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD3C7AC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF4C2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.turn_right_rounded,
                color: Color(0xFF6E5200),
                size: 22,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Fastest route to $destination',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 13,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Updated with OSRM road routing',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF5F5F63),
                      fontSize: 11,
                      height: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$eta\n$distance',
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFF6E5200),
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
