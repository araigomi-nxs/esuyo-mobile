import 'dart:async';
import 'dart:math' show sin, cos, atan2, sqrt, pi;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/map_style_service.dart';
import '../../services/active_trip_service.dart';
import '../../models/route_model.dart';
import '../../widgets/map_compass.dart';

class TripProgressScreen extends StatefulWidget {
  const TripProgressScreen({super.key});

  @override
  State<TripProgressScreen> createState() => _TripProgressScreenState();
}

class _TripProgressScreenState extends State<TripProgressScreen> {
  ml.MapLibreMapController? _mapController;
  bool _styleLoaded = false;
  bool _dataDrawn = false;
  bool _locationLayerAdded = false;
  String? _mapStyle;
  double _bearing = 0.0;

  ml.LatLng? _startLocation;
  ml.LatLng? _currentLocation;
  bool _isLocating = false;
  DateTime? _lastUpdated;
  Timer? _locationTimer;
  List<ml.LatLng> _flatCoords = [];

  @override
  void initState() {
    super.initState();
    _loadStyle();
    _initLocationTracking();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStyle() async {
    final style = await MapStyleService.terrainStyle();
    if (!mounted) return;
    setState(() => _mapStyle = style);
  }

  void _onMapCreated(ml.MapLibreMapController controller) {
    _mapController = controller;
  }

  Future<void> _onStyleLoaded() async {
    _styleLoaded = true;
    if (_styleLoaded && !_dataDrawn) await _drawRoute();
  }

  void _onCameraIdle() {
    final bearing = _mapController?.cameraPosition?.bearing ?? 0.0;
    if ((bearing - _bearing).abs() > 0.1) setState(() => _bearing = bearing);
  }

  // ── Location ──────────────────────────────────────────────────────────────

  Future<void> _initLocationTracking() async {
    await _updateLocation(isFirst: true);
    _locationTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _updateLocation();
    });
  }

  Future<void> _updateLocation({bool isFirst = false}) async {
    if (_isLocating) return;
    if (mounted) setState(() => _isLocating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _isLocating = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      final raw = ml.LatLng(pos.latitude, pos.longitude);
      final snapped = _flatCoords.isNotEmpty ? _snapToRoute(raw) : raw;
      setState(() {
        _currentLocation = snapped;
        if (isFirst || _startLocation == null) _startLocation = snapped;
        _lastUpdated = DateTime.now();
        _isLocating = false;
      });
      await _updateLocationLayer(snapped);
      if (isFirst) {
        await _mapController?.animateCamera(
          ml.CameraUpdate.newLatLngZoom(snapped, 15.5),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  // ── Snap to route ─────────────────────────────────────────────────────────

  List<ml.LatLng> _buildFlatCoords(RouteModel route) {
    final coords = <ml.LatLng>[];
    for (final stop in route.stops) {
      for (final c in stop.roadPathFromPrev) {
        coords.add(
            ml.LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()));
      }
    }
    if (coords.isEmpty) {
      for (final stop in route.stops) {
        coords.add(ml.LatLng(stop.lat, stop.lng));
      }
    }
    return coords;
  }

  ml.LatLng _snapToRoute(ml.LatLng user) {
    if (_flatCoords.isEmpty) return user;
    double bestDistSq = double.infinity;
    ml.LatLng best = _flatCoords.first;
    for (int i = 0; i < _flatCoords.length - 1; i++) {
      final ax = _flatCoords[i].longitude, ay = _flatCoords[i].latitude;
      final bx = _flatCoords[i + 1].longitude,
          by = _flatCoords[i + 1].latitude;
      final px = user.longitude, py = user.latitude;
      final dx = bx - ax, dy = by - ay;
      final lenSq = dx * dx + dy * dy;
      final tc =
          lenSq > 0 ? ((px - ax) * dx + (py - ay) * dy) / lenSq : 0.0;
      final t = tc.clamp(0.0, 1.0);
      final nx = ax + t * dx, ny = ay + t * dy;
      final dsq = (px - nx) * (px - nx) + (py - ny) * (py - ny);
      if (dsq < bestDistSq) {
        bestDistSq = dsq;
        best = ml.LatLng(ny, nx);
      }
    }
    return best;
  }

  double _haversine(ml.LatLng a, ml.LatLng b) {
    const R = 6371000.0;
    final lat1 = a.latitude * pi / 180;
    final lat2 = b.latitude * pi / 180;
    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLng = (b.longitude - a.longitude) * pi / 180;
    final hav = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    return R * 2 * atan2(sqrt(hav), sqrt(1 - hav));
  }

  // ── Map drawing ───────────────────────────────────────────────────────────

  Future<void> _drawRoute() async {
    final ctrl = _mapController;
    if (ctrl == null) return;
    final trip = ActiveTripService.instance.trip;
    if (trip == null) return;
    final route = trip.route;
    _dataDrawn = true;

    if (route != null) {
      _flatCoords = _buildFlatCoords(route);
      final stops = route.stops;
      final routeColor = route.color;

      final lineFeatures = <Map<String, dynamic>>[];
      for (final stop in stops) {
        if (stop.roadPathFromPrev.isEmpty) continue;
        lineFeatures.add({
          'type': 'Feature',
          'geometry': {
            'type': 'LineString',
            'coordinates': stop.roadPathFromPrev,
          },
          'properties': {'routeColor': routeColor},
        });
      }
      await ctrl.addGeoJsonSource('route-data', {
        'type': 'FeatureCollection',
        'features': lineFeatures,
      });
      await ctrl.addLineLayer(
        'route-data',
        'route-line',
        ml.LineLayerProperties(
          lineColor: ['get', 'routeColor'],
          lineWidth: 4.0,
          lineOpacity: 0.9,
        ),
        enableInteraction: false,
      );
      await ctrl.addSymbolLayer(
        'route-data',
        'route-arrows',
        ml.SymbolLayerProperties(
          textField: '>>',
          textSize: 12,
          textColor: ['get', 'routeColor'],
          textOpacity: 0.9,
          textHaloColor: '#ffffff',
          textHaloWidth: 1.5,
          symbolPlacement: 'line',
          symbolSpacing: 60,
          textAllowOverlap: true,
          textIgnorePlacement: true,
          textKeepUpright: false,
        ),
        enableInteraction: false,
      );

      // A / B markers
      final fromStop = stops.firstWhere(
        (s) => s.name == trip.from,
        orElse: () => stops.first,
      );
      final toStop = stops.firstWhere(
        (s) => s.name == trip.to,
        orElse: () => stops.last,
      );
      await ctrl.addGeoJsonSource('ab-markers', {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [fromStop.lng, fromStop.lat],
            },
            'properties': {'label': 'A', 'color': '#16A34A'},
          },
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [toStop.lng, toStop.lat],
            },
            'properties': {'label': 'B', 'color': '#DC2626'},
          },
        ],
      });
      await ctrl.addCircleLayer(
        'ab-markers',
        'ab-circle',
        ml.CircleLayerProperties(
          circleRadius: 13.0,
          circleColor: ['get', 'color'],
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 2.5,
        ),
        enableInteraction: false,
      );
      await ctrl.addSymbolLayer(
        'ab-markers',
        'ab-label',
        ml.SymbolLayerProperties(
          textField: ['get', 'label'],
          textSize: 11,
          textColor: '#FFFFFF',
          textAllowOverlap: true,
          textIgnorePlacement: true,
        ),
        enableInteraction: false,
      );

      // Fit camera to route
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
            bottom: 200,
          ),
        );
      }
    }

    // Load jeepney icon and register with map
    final assetData = await rootBundle.load('assets/jeep.png');
    final codec = await ui.instantiateImageCodec(
      assetData.buffer.asUint8List(),
      targetWidth: 52,
      targetHeight: 52,
    );
    final frame = await codec.getNextFrame();
    final pngBytes =
        await frame.image.toByteData(format: ui.ImageByteFormat.png);
    await ctrl.addImage('jeep-icon', pngBytes!.buffer.asUint8List());

    // User location layer (empty at first, updated by GPS)
    await ctrl.addGeoJsonSource('user-loc', {
      'type': 'FeatureCollection',
      'features': [],
    });
    await ctrl.addSymbolLayer(
      'user-loc',
      'user-jeep-icon',
      ml.SymbolLayerProperties(
        iconImage: 'jeep-icon',
        iconSize: 1.0,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
      ),
      enableInteraction: false,
    );
    _locationLayerAdded = true;
  }

  Future<void> _updateLocationLayer(ml.LatLng pos) async {
    if (!_locationLayerAdded) return;
    await _mapController?.setGeoJsonSource('user-loc', {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [pos.longitude, pos.latitude],
          },
          'properties': {},
        },
      ],
    });
  }

  // ── Progress calculations ─────────────────────────────────────────────────

  double get _totalKm => ActiveTripService.instance.trip?.distanceKm ?? 0;

  double get _kmCovered {
    final trip = ActiveTripService.instance.trip;
    if (trip == null) return 0;
    if (_startLocation != null && _currentLocation != null) {
      return (_haversine(_startLocation!, _currentLocation!) / 1000)
          .clamp(0, _totalKm);
    }
    return _totalKm * trip.progress;
  }

  double get _kmLeft => (_totalKm - _kmCovered).clamp(0, _totalKm);
  double get _progress =>
      _totalKm > 0 ? (_kmCovered / _totalKm).clamp(0.0, 1.0) : 0;

  String get _lastUpdatedLabel {
    if (_lastUpdated == null) return 'Locating…';
    final diff = DateTime.now().difference(_lastUpdated!).inMinutes;
    if (diff < 1) return 'Updated just now';
    return 'Updated $diff min ago';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final trip = ActiveTripService.instance.trip;
    if (trip == null) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.go('/passenger'));
      return const SizedBox.shrink();
    }

    final mapHeight = MediaQuery.of(context).size.height * 0.58;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/passenger'),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          'Trip Progress',
          style: GoogleFonts.lexend(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ActiveTripService.instance.endTrip();
              context.go('/passenger');
            },
            child: Text(
              'End Trip',
              style: GoogleFonts.lexend(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Map ────────────────────────────────────────────────────────────
          SizedBox(
            height: mapHeight,
            child: _mapStyle == null
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : Stack(
                    children: [
                      ml.MapLibreMap(
                        styleString: _mapStyle!,
                        onMapCreated: _onMapCreated,
                        onStyleLoadedCallback: _onStyleLoaded,
                        onCameraIdle: _onCameraIdle,
                        compassEnabled: false,
                        initialCameraPosition: ml.CameraPosition(
                          target: _currentLocation ??
                              (trip.route?.stops.isNotEmpty == true
                                  ? ml.LatLng(trip.route!.stops.first.lat,
                                      trip.route!.stops.first.lng)
                                  : const ml.LatLng(13.1391, 123.7438)),
                          zoom: 13.0,
                          tilt: 45,
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
                      // Compass + locate button
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Column(
                          children: [
                            MapCompass(bearing: _bearing),
                            const SizedBox(height: 8),
                            _isLocating
                                ? Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          blurRadius: 4,
                                          color: Colors.black
                                              .withValues(alpha: 0.2),
                                        )
                                      ],
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(10),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  )
                                : Material(
                                    color: Colors.white,
                                    shape: const CircleBorder(),
                                    elevation: 3,
                                    child: InkWell(
                                      onTap: _updateLocation,
                                      customBorder: const CircleBorder(),
                                      child: const SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: Icon(
                                          Icons.my_location_rounded,
                                          size: 20,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                      // Last-updated chip
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              _lastUpdatedLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // ── Info panel ────────────────────────────────────────────────────
          Expanded(
            child: Container(
              color: const Color(0xFF0F172A),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Circular progress ring
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: CircularProgressIndicator(
                            value: _progress,
                            strokeWidth: 7,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.1),
                            valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF60A5FA)),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _kmLeft.toStringAsFixed(1),
                              style: GoogleFonts.lexend(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'km left',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white54,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Trip details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF60A5FA)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ON A TRIP',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF60A5FA),
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _RouteRow(
                            label: 'A', color: const Color(0xFF16A34A),
                            text: trip.from),
                        const SizedBox(height: 2),
                        _RouteRow(
                            label: 'B', color: const Color(0xFFDC2626),
                            text: trip.to),
                        const SizedBox(height: 8),
                        Text(
                          '${_kmCovered.toStringAsFixed(1)} / ${_totalKm.toStringAsFixed(1)} km  ·  ₱${trip.fare.toStringAsFixed(2)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                        Text(
                          trip.minutesLeft > 0
                              ? '~${trip.minutesLeft} min remaining'
                              : 'Arriving soon',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final String label;
  final Color color;
  final String text;

  const _RouteRow(
      {required this.label, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.lexend(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.lexend(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
