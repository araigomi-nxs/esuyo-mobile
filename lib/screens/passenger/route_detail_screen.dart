import 'dart:async';
import 'dart:math' show Point;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../models/route_model.dart';
import '../../models/landmark_model.dart';
import '../../services/map_style_service.dart';
import '../../services/supabase_service.dart';
import '../../services/location_service.dart';
import '../../services/favorites_service.dart';
import '../../widgets/map_compass.dart';

class RouteDetailScreen extends StatefulWidget {
  final RouteModel route;

  const RouteDetailScreen({super.key, required this.route});

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  ml.MapLibreMapController? _mapController;
  bool _dataDrawn = false;
  bool _styleLoaded = false;
  bool _landmarksLoaded = false;
  String? _mapStyle;
  List<LandmarkModel> _landmarks = [];
  Timer? _statusRefreshTimer;
  double _bearing = 0.0;

  @override
  void initState() {
    super.initState();
    _loadStyle();
    _loadLandmarks();
    _statusRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadStyle() async {
    final style = await MapStyleService.terrainStyle();
    if (!mounted) return;
    setState(() => _mapStyle = style);
  }

  Future<void> _loadLandmarks() async {
    try {
      final landmarks = await SupabaseService.fetchLandmarks();
      if (!mounted) return;
      setState(() => _landmarks = landmarks);
    } catch (e) {
      debugPrint('Error loading landmarks: $e');
    }
    if (!mounted) return;
    _landmarksLoaded = true;
    if (_styleLoaded && !_dataDrawn) await _drawRoute();
  }

  @override
  void dispose() {
    _statusRefreshTimer?.cancel();
    super.dispose();
  }

  Color get _color {
    try {
      final h = widget.route.color.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return AppColors.primaryContainer;
    }
  }

  ml.LatLng get _center => widget.route.stops.isNotEmpty
      ? ml.LatLng(widget.route.stops.first.lat, widget.route.stops.first.lng)
      : const ml.LatLng(13.1391, 123.7438);

  void _onMapCreated(ml.MapLibreMapController controller) {
    _mapController = controller;
  }

  Future<void> _onStyleLoaded() async {
    _styleLoaded = true;
    if (_landmarksLoaded && !_dataDrawn) await _drawRoute();
  }

  Future<void> _drawRoute() async {
    final ctrl = _mapController;
    if (ctrl == null) return;
    _dataDrawn = true;

    final stops = widget.route.stops;
    final routeColor = widget.route.color;

    // ── Route GeoJSON ──────────────────────────────────────────────────────
    final routeFeatures = <Map<String, dynamic>>[];

    for (final stop in stops) {
      if (stop.roadPathFromPrev.isEmpty) continue;
      routeFeatures.add({
        'type': 'Feature',
        'geometry': {
          'type': 'LineString',
          'coordinates': stop.roadPathFromPrev,
        },
        'properties': {'featureType': 'route-line', 'routeColor': routeColor},
      });
    }

    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      routeFeatures.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [stop.lng, stop.lat],
        },
        'properties': {
          'featureType': 'route-stop',
          'routeColor': routeColor,
          'isTerminal': i == 0 || i == stops.length - 1,
        },
      });
    }

    await ctrl.addGeoJsonSource('route-data', {
      'type': 'FeatureCollection',
      'features': routeFeatures,
    });

    await ctrl.addLineLayer(
      'route-data',
      'route-line',
      ml.LineLayerProperties(
        lineColor: ['get', 'routeColor'],
        lineWidth: 4.0,
        lineOpacity: 0.9,
      ),
      filter: [
        '==',
        ['get', 'featureType'],
        'route-line',
      ],
      enableInteraction: false,
    );

    await ctrl.addSymbolLayer(
      'route-data',
      'route-arrows',
      ml.SymbolLayerProperties(
        textField: '>>',
        textSize: [
          'interpolate',
          ['linear'],
          ['zoom'],
          10,
          10,
          12,
          12,
          14,
          14,
          16,
          16,
        ],
        textColor: ['get', 'routeColor'],
        textOpacity: 0.95,
        textHaloColor: '#ffffff',
        textHaloWidth: 1.5,
        symbolPlacement: 'line',
        symbolSpacing: 55,
        textAllowOverlap: true,
        textIgnorePlacement: true,
        textKeepUpright: false,
      ),
      filter: [
        '==',
        ['get', 'featureType'],
        'route-line',
      ],
      minzoom: 10,
      enableInteraction: false,
    );

    await ctrl.addCircleLayer(
      'route-data',
      'route-stops',
      ml.CircleLayerProperties(
        circleRadius: [
          'case',
          ['get', 'isTerminal'],
          8.0,
          5.0,
        ],
        circleColor: ['get', 'routeColor'],
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 2.0,
      ),
      filter: [
        '==',
        ['get', 'featureType'],
        'route-stop',
      ],
      enableInteraction: false,
    );

    // ── Landmarks ──────────────────────────────────────────────────────────
    if (_landmarks.isNotEmpty) {
      final lmFeatures = _landmarks
          .map(
            (lm) => {
              'type': 'Feature',
              'geometry': {
                'type': 'Point',
                'coordinates': [lm.lng, lm.lat],
              },
              'properties': {'name': lm.name, 'category': lm.category},
            },
          )
          .toList();

      await ctrl.addGeoJsonSource('landmarks', {
        'type': 'FeatureCollection',
        'features': lmFeatures,
      });

      await ctrl.addCircleLayer(
        'landmarks',
        'landmarks-circle',
        ml.CircleLayerProperties(
          circleRadius: [
            'interpolate',
            ['linear'],
            ['zoom'],
            10,
            1.5,
            13,
            3,
            16,
            5,
          ],
          circleColor: [
            'match',
            ['get', 'category'],
            'mall',
            '#E91E63',
            'hospital',
            '#F44336',
            'school',
            '#42A5F5',
            'church',
            '#BA68C8',
            'gov',
            '#90A4AE',
            'terminal',
            '#FF9800',
            'airport',
            '#00BCD4',
            'port',
            '#A1887F',
            'park',
            '#8BC34A',
            'bank',
            '#66BB6A',
            'market',
            '#FF7043',
            '7eleven',
            '#00703c',
            '711',
            '#00703c',
            'factory',
            '#78909C',
            'gasstation',
            '#FFC107',
            'fastfood',
            '#FF7043',
            'restaurant',
            '#FF9800',
            'cafe',
            '#FF8F00',
            'accommodation',
            '#0288D1',
            'viewpoint',
            '#F06292',
            '#9575CD',
          ],
          circleStrokeWidth: 2,
          circleStrokeColor: '#ffffff',
          circleOpacity: 0.9,
        ),
        enableInteraction: false,
      );

      await ctrl.addSymbolLayer(
        'landmarks',
        'landmarks-label',
        ml.SymbolLayerProperties(
          textField: ['get', 'name'],
          textSize: 10,
          textOffset: [0, 1.2],
          textAnchor: 'top',
          textAllowOverlap: false,
          textIgnorePlacement: false,
          textColor: '#444444',
          textHaloColor: '#ffffff',
          textHaloWidth: 2,
        ),
        minzoom: 14,
        enableInteraction: false,
      );
    }

    // ── Fit camera to route bounds ─────────────────────────────────────────
    if (stops.length >= 2) {
      double minLat = stops.first.lat, maxLat = stops.first.lat;
      double minLng = stops.first.lng, maxLng = stops.first.lng;
      for (final s in stops) {
        if (s.lat < minLat) minLat = s.lat;
        if (s.lat > maxLat) maxLat = s.lat;
        if (s.lng < minLng) minLng = s.lng;
        if (s.lng > maxLng) maxLng = s.lng;
      }
      await ctrl.animateCamera(
        ml.CameraUpdate.newLatLngBounds(
          ml.LatLngBounds(
            southwest: ml.LatLng(minLat, minLng),
            northeast: ml.LatLng(maxLat, maxLng),
          ),
          left: 60,
          top: 60,
          right: 60,
          bottom: 60,
        ),
      );
    }
  }

  Future<void> _onMapClick(Point<double> point, ml.LatLng coords) async {
    final ctrl = _mapController;
    if (ctrl == null) return;
    const r = 28.0;
    final rect = Rect.fromLTRB(
      point.x - r,
      point.y - r,
      point.x + r,
      point.y + r,
    );
    final hits = await ctrl.queryRenderedFeaturesInRect(rect, [
      'route-stops',
    ], null);
    if (hits.isEmpty) return;
    final geometry = (hits[0] as Map)['geometry'] as Map?;
    final coordsList = geometry?['coordinates'] as List?;
    if (coordsList == null || coordsList.length < 2) return;
    final lat = (coordsList[1] as num).toDouble();
    final lng = (coordsList[0] as num).toDouble();
    await ctrl.animateCamera(
      ml.CameraUpdate.newLatLngZoom(ml.LatLng(lat, lng), 16.5),
    );
  }

  Future<void> _focusStop(RouteStop stop) async {
    final ctrl = _mapController;
    if (ctrl == null) return;
    await ctrl.animateCamera(
      ml.CameraUpdate.newLatLngZoom(ml.LatLng(stop.lat, stop.lng), 16.5),
    );
  }

  void _onCameraIdle() {
    final bearing = _mapController?.cameraPosition?.bearing ?? 0.0;
    if ((bearing - _bearing).abs() > 0.1) {
      setState(() => _bearing = bearing);
    }
  }


  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final color = _color;
    final mapHeight = MediaQuery.of(context).size.height * 0.40;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.95),
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryContainer),
        ),
        title: Text(
          route.name,
          style: GoogleFonts.lexend(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          ListenableBuilder(
            listenable: FavoritesService.instance,
            builder: (context, _) {
              final isFav = FavoritesService.instance.isFavorite(route.id);
              return IconButton(
                icon: Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFav
                      ? const Color(0xFFE91E63)
                      : AppColors.primaryContainer,
                ),
                onPressed: () => FavoritesService.instance.toggle(route.id),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Fixed map ───────────────────────────────────────────────────────
          SizedBox(
            height: mapHeight,
            child: _mapStyle == null
                ? const Center(child: CircularProgressIndicator())
                : route.stops.isEmpty
                ? Container(
                    color: AppColors.surfaceContainerLowest,
                    child: const Center(
                      child: Icon(
                        Icons.map_outlined,
                        size: 48,
                        color: AppColors.outline,
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      ml.MapLibreMap(
                        styleString: _mapStyle!,
                        onMapCreated: _onMapCreated,
                        onStyleLoadedCallback: _onStyleLoaded,
                        onMapClick: _onMapClick,
                        onCameraIdle: _onCameraIdle,
                        compassEnabled: false,
                        initialCameraPosition: ml.CameraPosition(
                          target: _center,
                          zoom: 13.0,
                          tilt: 55,
                          bearing: -15,
                        ),
                        trackCameraPosition: true,
                        tiltGesturesEnabled: false,
                        zoomGesturesEnabled: true,
                        scrollGesturesEnabled: true,
                        rotateGesturesEnabled: true,
                        gestureRecognizers: {
                          Factory<OneSequenceGestureRecognizer>(
                            () => EagerGestureRecognizer(),
                          ),
                        },
                      ),
                      Positioned(
                        top: 16,
                        right: 16,
                        child: MapCompass(bearing: _bearing),
                      ),
                    ],
                  ),
          ),
          // ── Scrollable bottom panel ──────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatChip(
                      icon: Icons.place_rounded,
                      label: '${route.stops.length} stops',
                      color: color,
                    ),
                    if (route.totalDistKm > 0)
                      _StatChip(
                        icon: Icons.straighten_rounded,
                        label: '${route.totalDistKm.toStringAsFixed(1)} km',
                        color: color,
                      ),
                    _StatChip(
                      icon: Icons.directions_bus_rounded,
                      label: route.vehicleLabel.split(' ').first,
                      color: color,
                    ),
                    _StatChip(
                      icon: route.isActive
                          ? Icons.verified_rounded
                          : Icons.error_outline_rounded,
                      label: route.isActive ? 'ACTIVE' : 'INACTIVE',
                      color: route.isActive
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                  ],
                ),
                if (route.description != null &&
                    route.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    route.description!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.outline,
                    ),
                  ),
                ],
                if (route.hours != null || route.frequency != null) ...[
                  const SizedBox(height: 24),
                  _ScheduleCard(route: route),
                ],
                const SizedBox(height: 24),
                Text(
                  'Stops (${route.stops.length})',
                  style: GoogleFonts.lexend(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _StopsTimeline(
                  route: route,
                  color: color,
                  landmarks: _landmarks,
                  onStopTapped: _focusStop,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final RouteModel route;

  const _ScheduleCard({required this.route});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          if (route.hours != null)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SERVICE HOURS',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    route.hours!,
                    style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          if (route.hours != null && route.frequency != null)
            Container(
              width: 1,
              height: 36,
              color: Colors.white10,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
          if (route.frequency != null)
            Expanded(
              child: Column(
                crossAxisAlignment: route.hours != null
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FREQUENCY',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    route.frequency!,
                    style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StopsTimeline extends StatelessWidget {
  final RouteModel route;
  final Color color;
  final List<LandmarkModel> landmarks;
  final void Function(RouteStop)? onStopTapped;

  const _StopsTimeline({
    required this.route,
    required this.color,
    required this.landmarks,
    this.onStopTapped,
  });

  @override
  Widget build(BuildContext context) {
    final stops = route.stops;
    if (stops.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Center(
          child: Text(
            'No stop data',
            style: GoogleFonts.plusJakartaSans(color: AppColors.outline),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (int i = 0; i < stops.length; i++)
            _StopRow(
              stop: stops[i],
              isFirst: i == 0,
              isLast: i == stops.length - 1,
              color: color,
              landmarks: landmarks,
              onTap: onStopTapped != null
                  ? () => onStopTapped!(stops[i])
                  : null,
            ),
        ],
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  final RouteStop stop;
  final bool isFirst;
  final bool isLast;
  final Color color;
  final List<LandmarkModel> landmarks;
  final VoidCallback? onTap;

  const _StopRow({
    required this.stop,
    required this.isFirst,
    required this.isLast,
    required this.color,
    required this.landmarks,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTerminal = isFirst || isLast;
    final nearbyLandmarks = LocationService.getNearbyLandmarks(
      stop.lat,
      stop.lng,
      landmarks,
      radiusKm: 0.2,
      maxResults: 3,
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: isTerminal ? 14 : 10,
                  height: isTerminal ? 14 : 10,
                  decoration: BoxDecoration(
                    color: isTerminal ? color : color.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 44,
                    color: color.withValues(alpha: 0.2),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isTerminal)
                      Text(
                        isFirst ? 'TERMINAL' : 'END',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: color,
                          letterSpacing: 1.2,
                        ),
                      ),
                    Text(
                      stop.name,
                      style: GoogleFonts.lexend(
                        fontSize: isTerminal ? 15 : 14,
                        fontWeight: isTerminal
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (stop.address.isNotEmpty)
                      Text(
                        stop.address,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.outline,
                        ),
                      ),
                    if (stop.roadDistFromPrev > 0 && !isFirst)
                      Text(
                        '+${stop.roadDistFromPrev.toStringAsFixed(2)} km',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppColors.outline,
                        ),
                      ),
                    if (nearbyLandmarks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...nearbyLandmarks.map((landmark) {
                        final distKm = LocationService.calculateDistance(
                          stop.lat,
                          stop.lng,
                          landmark.lat,
                          landmark.lng,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Text(
                                _getLandmarkEmoji(landmark.category),
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  landmark.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    color: AppColors.outline,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${(distKm * 1000).toStringAsFixed(0)}m',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  color: AppColors.outline,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLandmarkEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'hospital':
        return '🏥';
      case 'school':
        return '🏫';
      case 'church':
        return '⛪';
      case 'gov':
        return '🏛️';
      case 'terminal':
        return '🚌';
      case 'airport':
        return '✈️';
      case 'mall':
        return '🛍️';
      case 'bank':
        return '🏦';
      case 'market':
        return '🛒';
      case 'park':
        return '🌳';
      case 'factory':
        return '🏭';
      case 'gasstation':
        return '⛽';
      case 'fastfood':
        return '🍔';
      case 'restaurant':
        return '🍽️';
      case 'cafe':
        return '☕';
      case 'accommodation':
        return '🛏️';
      case 'viewpoint':
        return '📸';
      case '7eleven':
      case '711':
        return '7️⃣';
      case 'port':
        return '⚓';
      default:
        return '📍';
    }
  }
}
