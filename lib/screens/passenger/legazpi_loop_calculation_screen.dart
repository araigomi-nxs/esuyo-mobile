import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart' show rootBundle, HapticFeedback;
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import '../../theme/app_colors.dart';
import '../../models/route_model.dart';
import '../../models/landmark_model.dart';
import '../../services/supabase_service.dart';
import '../../services/location_service.dart';
import '../../services/map_style_service.dart';
import '../../utils/fare_matrix.dart';
import '../../widgets/map_compass.dart';
import 'package:geolocator/geolocator.dart';

class LegazpiLoopCalculationScreen extends StatefulWidget {
  final RouteModel? initialRoute;
  const LegazpiLoopCalculationScreen({super.key, this.initialRoute});

  @override
  State<LegazpiLoopCalculationScreen> createState() =>
      _LegazpiLoopCalculationScreenState();
}

class _LegazpiLoopCalculationScreenState
    extends State<LegazpiLoopCalculationScreen> {
  bool hasDiscount = false;
  int currentTip = 5;
  String selectedDropOff = 'Ayala Mall';
  String? _pressedStop;

  ml.MapLibreMapController? _mapController;
  final List<ml.Circle> _stopCircles = [];
  String? _mapStyle;
  bool _styleLoaded = false;
  double _bearing = 0.0;

  // Marker drag state
  final GlobalKey _mapKey = GlobalKey();
  List<List<double>> _flatRouteCoords = [];
  ml.LatLng? _markerALatLng;
  ml.LatLng? _markerBLatLng;
  double _sliderDistanceKm = 0.0; // distance along route for B marker
  String _startingPointName = 'Locating...';
  bool _isLocating = false;
  bool _pointerDown = false;
  String? _activeDragMarker;
  bool _dragProcessing = false;

  // Drop-off locations
  final Map<String, Map<String, double>> dropOffLocations = {
    'Tagas': {'lat': 13.1305, 'lng': 123.7235},
    'Bogtong': {'lat': 13.1350, 'lng': 123.7260},
    'Bonot': {'lat': 13.1395, 'lng': 123.7290},
    'Oro-Site': {'lat': 13.1415, 'lng': 123.7310},
    'Ayala Mall': {'lat': 13.1460, 'lng': 123.7380},
    'Cabangan': {'lat': 13.1480, 'lng': 123.7350},
    'Albay/Capitol': {'lat': 13.1470, 'lng': 123.7300},
    'Bicol University': {'lat': 13.1430, 'lng': 123.7240},
    'Sagpon': {'lat': 13.1380, 'lng': 123.7200},
    'Daraga Centro': {'lat': 13.1280, 'lng': 123.7250},
    'San Roque': {'lat': 13.1255, 'lng': 123.7290},
    'Banag': {'lat': 13.1335, 'lng': 123.7345},
    'Binitayan': {'lat': 13.1375, 'lng': 123.7380},
  };

  final List<String> dropOffPoints = [
    'Tagas',
    'Bogtong',
    'Bonot',
    'Oro-Site',
    'Ayala Mall',
    'Cabangan',
    'Albay/Capitol',
    'Bicol University',
    'Sagpon',
    'Daraga Centro',
    'San Roque',
    'Banag',
    'Binitayan',
  ];

  List<LandmarkModel> _landmarks = [];

  // Custom drop-off mode state
  bool _isCustomDropOffMode = false;


  // Barangay geocoding
  Map<String, dynamic>? _legazpiBarangays;
  Future<void>? _barangaysLoadFuture;

  Future<void> _ensureBarangaysLoaded() {
    if (_legazpiBarangays != null) return Future.value();
    if (_barangaysLoadFuture != null) return _barangaysLoadFuture!;
    _barangaysLoadFuture = () async {
      try {
        final raw = await rootBundle.loadString(
          'assets/legazpi-barangays.json',
        );
        _legazpiBarangays = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        _legazpiBarangays = null;
      }
    }();
    return _barangaysLoadFuture!;
  }

  bool _pointInRing(double lng, double lat, List<dynamic> ring) {
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final pi = ring[i] as List<dynamic>;
      final pj = ring[j] as List<dynamic>;
      final xi = (pi[0] as num).toDouble();
      final yi = (pi[1] as num).toDouble();
      final xj = (pj[0] as num).toDouble();
      final yj = (pj[1] as num).toDouble();
      final intersects =
          ((yi > lat) != (yj > lat)) &&
          (lng < (xj - xi) * (lat - yi) / ((yj - yi) + 1e-12) + xi);
      if (intersects) inside = !inside;
    }
    return inside;
  }

  Map<String, dynamic>? _getBrgyFeatureFromCoords(double lng, double lat) {
    final geo = _legazpiBarangays;
    if (geo == null) return null;

    final features = geo['features'];
    if (features is! List<dynamic>) return null;

    for (final feat in features) {
      if (feat is! Map<String, dynamic>) continue;
      final geometry = feat['geometry'];
      if (geometry is! Map<String, dynamic>) continue;

      final type = geometry['type']?.toString();
      final coordinates = geometry['coordinates'];
      if (coordinates is! List<dynamic>) continue;

      final polygons = type == 'MultiPolygon' ? coordinates : [coordinates];
      for (final polygon in polygons) {
        if (polygon is! List<dynamic> || polygon.isEmpty) continue;
        final outer = polygon.first;
        if (outer is! List<dynamic>) continue;
        if (_pointInRing(lng, lat, outer)) {
          return feat as Map<String, dynamic>;
        }
      }
    }

    return null;
  }

  String? _getBrgyFromCoords(double lng, double lat) {
    final feature = _getBrgyFeatureFromCoords(lng, lat);
    if (feature == null) return null;
    final props = feature['properties'];
    if (props is! Map<String, dynamic>) return null;
    final name = props['name']?.toString();
    return (name != null && name.isNotEmpty) ? name : null;
  }

  LandmarkModel? _nearestLandmark(double lat, double lng) {
    if (_landmarks.isEmpty) return null;
    double best = double.infinity;
    LandmarkModel? found;
    for (final lm in _landmarks) {
      final dx = lm.lat - lat;
      final dy = lm.lng - lng;
      final dist = dx * dx + dy * dy;
      if (dist < best) {
        best = dist;
        found = lm;
      }
    }
    return found;
  }

  Future<String> _getAddressFromCoords(double lat, double lng) async {
    try {
      await _ensureBarangaysLoaded();
      final results = await Future.wait([
        http
            .get(
              Uri.parse(
                'https://photon.komoot.io/reverse?lon=$lng&lat=$lat&limit=1',
              ),
            )
            .then((res) {
              if (res.statusCode != 200) return null;
              return jsonDecode(res.body) as Map<String, dynamic>;
            })
            .catchError((_) => null),
        Future.value(_getBrgyFromCoords(lng, lat)),
      ]);
      final photon = results[0] as Map<String, dynamic>?;
      final localBrgy = results[1] as String?;
      Map<String, dynamic>? props;
      final features = photon?['features'];
      if (features is List &&
          features.isNotEmpty &&
          features.first is Map<String, dynamic>) {
        final p = (features.first as Map<String, dynamic>)['properties'];
        if (p is Map<String, dynamic>) props = p;
      }
      final parts = <String>[];
      final street = props?['street']?.toString();
      final houseNumber = props?['housenumber']?.toString();
      if (street != null &&
          street.isNotEmpty &&
          !street.toLowerCase().contains('unnamed')) {
        parts.add(
          houseNumber != null && houseNumber.isNotEmpty
              ? '$houseNumber $street'
              : street,
        );
      }
      if (localBrgy != null && localBrgy.isNotEmpty) {
        parts.add('Brgy. $localBrgy');
      }
      return parts.join(', ');
    } catch (_) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    final route = widget.initialRoute;
    if (route != null && route.stops.isNotEmpty) {
      _applyRouteModel(route);
    }
    _loadMapStyle();
    _loadLandmarks();
    _locateAndSnapToRoute();
  }

  Future<void> _loadMapStyle() async {
    final style = await MapStyleService.terrainStyle();
    if (!mounted) return;
    setState(() => _mapStyle = style);
  }

  Future<void> _loadLandmarks() async {
    try {
      final landmarks = await SupabaseService.fetchLandmarks();
      if (!mounted) return;
      setState(() => _landmarks = landmarks);
    } catch (_) {}
    if (!mounted) return;
    if (_styleLoaded) await _drawLandmarks();
  }

  Future<void> _locateAndSnapToRoute() async {
    if (!mounted) return;
    setState(() => _isLocating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() { _startingPointName = 'Permission denied'; _isLocating = false; });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      // Wait until route coords are built (may not be ready yet)
      if (_flatRouteCoords.isEmpty) _flatRouteCoords = _buildFlatRouteCoords();
      if (_flatRouteCoords.isEmpty) {
        setState(() { _startingPointName = 'Route unavailable'; _isLocating = false; });
        return;
      }
      final snapped = _coordAtDistance(_projectToRoute(ml.LatLng(pos.latitude, pos.longitude)));
      final address = await _getAddressFromCoords(snapped.latitude, snapped.longitude);
      if (!mounted) return;
      setState(() {
        _markerALatLng = snapped;
        _startingPointName = address.isNotEmpty ? address : 'Near route';
        _isLocating = false;
      });
      _updateMapMarkers();
    } catch (_) {
      if (mounted) setState(() { _startingPointName = 'Location unavailable'; _isLocating = false; });
    }
  }

  // Apply a RouteModel into state. Safe to call before map is ready.
  void _applyRouteModel(RouteModel route) {
    dropOffLocations.clear();
    dropOffPoints.clear();
    for (final stop in route.stops) {
      dropOffLocations[stop.name] = {'lat': stop.lat, 'lng': stop.lng};
      dropOffPoints.add(stop.name);
    }
    if (dropOffPoints.isNotEmpty) selectedDropOff = dropOffPoints.first;
  }

  // Single source of truth for drawing the current route on the map.
  Future<void> _drawRouteOnMap() async {
    final c = _mapController;
    if (c == null) return;

    for (final sc in _stopCircles) {
      try {
        await c.removeCircle(sc);
      } catch (_) {}
    }
    _stopCircles.clear();

    if (dropOffLocations.isEmpty) return;

    final route = widget.initialRoute;
    final routeHex = route?.color ?? '#0046C7';

    // Build flat coord list for snap-to-route and yellow path
    _flatRouteCoords = _buildFlatRouteCoords();

    // Initialise A marker at first stop
    if (route != null && route.stops.isNotEmpty) {
      _markerALatLng = ml.LatLng(route.stops.first.lat, route.stops.first.lng);
    }
    // Initialise B marker at selected drop-off
    final selCoord = dropOffLocations[selectedDropOff];
    if (selCoord != null) {
      _markerBLatLng = ml.LatLng(selCoord['lat']!, selCoord['lng']!);
      _sliderDistanceKm = _projectToRoute(_markerBLatLng!);
    }

    // Build road-following GeoJSON from roadPathFromPrev when available
    final routeFeatures = <Map<String, dynamic>>[];
    if (route != null && route.stops.isNotEmpty) {
      for (final stop in route.stops) {
        if (stop.roadPathFromPrev.isEmpty) continue;
        routeFeatures.add({
          'type': 'Feature',
          'geometry': {
            'type': 'LineString',
            'coordinates': stop.roadPathFromPrev,
          },
          'properties': {'featureType': 'route-line', 'routeColor': routeHex},
        });
      }
    }
    // Fallback: straight line between stops
    if (routeFeatures.isEmpty) {
      routeFeatures.add({
        'type': 'Feature',
        'geometry': {
          'type': 'LineString',
          'coordinates': dropOffLocations.entries
              .map((e) => [e.value['lng']!, e.value['lat']!])
              .toList(),
        },
        'properties': {'featureType': 'route-line', 'routeColor': routeHex},
      });
    }

    try {
      await c.addGeoJsonSource('route-data', {
        'type': 'FeatureCollection',
        'features': routeFeatures,
      });

      await c.addLineLayer(
        'route-data',
        'route-line',
        ml.LineLayerProperties(
          lineColor: ['get', 'routeColor'],
          lineWidth: 5.0,
          lineOpacity: 1.0,
          lineCap: 'round',
          lineJoin: 'round',
        ),
        filter: [
          '==',
          ['get', 'featureType'],
          'route-line',
        ],
        enableInteraction: false,
      );

      await c.addSymbolLayer(
        'route-data',
        'route-arrows',
        ml.SymbolLayerProperties(
          textField: '>>',
          textSize: [
            'interpolate',
            ['linear'],
            ['zoom'],
            10,
            11,
            12,
            13,
            14,
            15,
            16,
            17,
          ],
          textColor: ['get', 'routeColor'],
          textOpacity: 1.0,
          textHaloColor: '#ffffff',
          textHaloWidth: 2.0,
          symbolPlacement: 'line',
          symbolSpacing: 50,
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
    } catch (_) {}

    // Yellow A→B highlight path — always create source+layer so setGeoJsonSource works on updates
    try {
      try {
        await c.removeLayer('ab-path-line');
      } catch (_) {}
      try {
        await c.removeSource('ab-path-data');
      } catch (_) {}
      final seg = _yellowSegmentCoords();
      await c.addGeoJsonSource('ab-path-data', {
        'type': 'FeatureCollection',
        'features': seg.length >= 2
            ? [
                {
                  'type': 'Feature',
                  'geometry': {'type': 'LineString', 'coordinates': seg},
                  'properties': {},
                },
              ]
            : [],
      });
      await c.addLineLayer(
        'ab-path-data',
        'ab-path-line',
        ml.LineLayerProperties(
          lineColor: '#FBBF24',
          lineWidth: 7.0,
          lineOpacity: 0.9,
          lineCap: 'round',
          lineJoin: 'round',
        ),
        enableInteraction: false,
      );
    } catch (_) {}

    // Fit camera to route bounds
    final lats = dropOffLocations.values.map((e) => e['lat']!).toList();
    final lngs = dropOffLocations.values.map((e) => e['lng']!).toList();

    // Draw A/B pin labels: A = starting point, B = selected drop-off
    try {
      try {
        await c.removeLayer('route-pins-layer');
      } catch (_) {}
      try {
        await c.removeSource('route-pins');
      } catch (_) {}

      final pinFeatures = <Map<String, dynamic>>[];
      // Starting point (A) — first stop if available
      if (widget.initialRoute != null &&
          widget.initialRoute!.stops.isNotEmpty) {
        final s = widget.initialRoute!.stops.first;
        pinFeatures.add({
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [s.lng, s.lat],
          },
          'properties': {'label': 'A', 'color': '#22c55e'},
        });
      }
      // Selected drop-off (B)
      final sel = dropOffLocations[selectedDropOff];
      if (sel != null) {
        pinFeatures.add({
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [sel['lng']!, sel['lat']!],
          },
          'properties': {'label': 'B', 'color': '#ef4444'},
        });
      }

      await c.addGeoJsonSource('route-pins', {
        'type': 'FeatureCollection',
        'features': pinFeatures,
      });

      // Add pin images to style
      await _addPinImageToStyle(c, 'pin-a', '#22c55e', 'A');
      await _addPinImageToStyle(c, 'pin-b', '#ef4444', 'B');

      await c.addSymbolLayer(
        'route-pins',
        'route-pins-layer',
        ml.SymbolLayerProperties(
          iconImage: [
            'case',
            [
              '==',
              ['get', 'label'],
              'A',
            ],
            'pin-a',
            'pin-b',
          ],
          iconSize: 1.25,
          iconAnchor: 'bottom',
          iconAllowOverlap: true,
        ),
      );
    } catch (_) {}
    if (lats.length >= 2) {
      final minLat = lats.reduce((a, b) => a < b ? a : b);
      final maxLat = lats.reduce((a, b) => a > b ? a : b);
      final minLng = lngs.reduce((a, b) => a < b ? a : b);
      final maxLng = lngs.reduce((a, b) => a > b ? a : b);
      try {
        await c.animateCamera(
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
      } catch (_) {}
    }
  }

  Future<void> _handleMapTap(Point<double> point, ml.LatLng coords) async {
    if (!_isCustomDropOffMode) return;

    final snapped = _coordAtDistance(_projectToRoute(coords));

    // Show a temporary placeholder name while resolving address
    const placeholder = 'Custom Point';
    setState(() {
      selectedDropOff = placeholder;
      if (!dropOffLocations.containsKey(placeholder)) {
        dropOffLocations[placeholder] = {
          'lat': snapped.latitude,
          'lng': snapped.longitude,
        };
        dropOffPoints.add(placeholder);
      }
    });

    // Resolve address and nearest landmark in background
    final address = await _getAddressFromCoords(
      snapped.latitude,
      snapped.longitude,
    );
    final nearbyLm = _nearestLandmark(snapped.latitude, snapped.longitude);

    final parts = <String>[];
    if (address.isNotEmpty) parts.add(address);
    if (nearbyLm != null) parts.add('near ${nearbyLm.name}');

    final customName = parts.isNotEmpty
        ? parts.join(', ')
        : 'Custom Point (${snapped.latitude.toStringAsFixed(4)}, ${snapped.longitude.toStringAsFixed(4)})';

    if (!mounted) return;
    setState(() {
      // Replace placeholder entry with resolved name
      dropOffLocations.remove(placeholder);
      dropOffPoints.remove(placeholder);
      selectedDropOff = customName;
      if (!dropOffLocations.containsKey(customName)) {
        dropOffLocations[customName] = {
          'lat': snapped.latitude,
          'lng': snapped.longitude,
        };
        dropOffPoints.add(customName);
      }
    });

    // Update map markers to show B pin for custom drop-off
    _updateMapMarkers();

    // Exit custom mode after selection
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _isCustomDropOffMode = false);
        _restoreMapTilt();
      }
    });
  }

  Future<void> _toggleCustomDropOffMode() async {
    final entering = !_isCustomDropOffMode;
    setState(() => _isCustomDropOffMode = entering);
    final c = _mapController;
    if (c == null) return;
    final pos = c.cameraPosition;
    if (pos == null) return;
    await c.animateCamera(
      ml.CameraUpdate.newCameraPosition(
        ml.CameraPosition(
          target: pos.target,
          zoom: pos.zoom,
          tilt: entering ? 0.0 : 55.0,
          bearing: pos.bearing,
        ),
      ),
    );
  }

  Future<void> _restoreMapTilt() async {
    final c = _mapController;
    if (c == null) return;
    final pos = c.cameraPosition;
    if (pos == null) return;
    await c.animateCamera(
      ml.CameraUpdate.newCameraPosition(
        ml.CameraPosition(
          target: pos.target,
          zoom: pos.zoom,
          tilt: 55.0,
          bearing: pos.bearing,
        ),
      ),
    );
  }

  final List<int> tips = [0, 5, 10, 20];

  String get _vehicleType => widget.initialRoute?.vehicleType ?? 'puj';

  // Haversine distance between two coordinates (km)
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371;
    final dLat = (lat2 - lat1) * 3.14159 / 180;
    final dLng = (lng2 - lng1) * 3.14159 / 180;
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(lat1 * 3.14159 / 180) *
            cos(lat2 * 3.14159 / 180) *
            sin(dLng / 2) *
            sin(dLng / 2));
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  // Cumulative road distance along route path from first stop to selected drop-off.
  double get _selectedDropOffDistance {
    final route = widget.initialRoute;
    if (route == null || route.stops.isEmpty) return 0;

    // Named stop: sum roadDistFromPrev up to matching stop
    final total = route.stops.fold(0.0, (sum, s) => sum + s.roadDistFromPrev);
    if (total > 0) {
      double cum = 0;
      for (final stop in route.stops) {
        cum += stop.roadDistFromPrev;
        if (stop.name == selectedDropOff) return cum;
      }
    }

    // Slider / custom drop-off: _sliderDistanceKm is the cumulative route km
    if (_sliderDistanceKm > 0) return _sliderDistanceKm;

    return 0;
  }

  // Total route length in km.
  double _totalRouteDistanceKm() {
    if (_flatRouteCoords.length < 2) return 0;
    double cum = 0;
    for (int i = 1; i < _flatRouteCoords.length; i++) {
      final a = _flatRouteCoords[i - 1];
      final b = _flatRouteCoords[i];
      cum += _calculateDistance(a[1], a[0], b[1], b[0]);
    }
    return cum;
  }

  // Returns the exact LatLng at the given km distance along the route,
  // interpolating between vertices for sub-segment precision.
  ml.LatLng _coordAtDistance(double km) {
    if (_flatRouteCoords.isEmpty) {
      return _markerALatLng ?? const ml.LatLng(13.1391, 123.7438);
    }
    if (km <= 0) {
      return ml.LatLng(_flatRouteCoords.first[1], _flatRouteCoords.first[0]);
    }
    double cum = 0;
    for (int i = 1; i < _flatRouteCoords.length; i++) {
      final a = _flatRouteCoords[i - 1];
      final b = _flatRouteCoords[i];
      final segLen = _calculateDistance(a[1], a[0], b[1], b[0]);
      if (cum + segLen >= km) {
        final t = segLen > 0 ? (km - cum) / segLen : 0.0;
        return ml.LatLng(a[1] + (b[1] - a[1]) * t, a[0] + (b[0] - a[0]) * t);
      }
      cum += segLen;
    }
    final last = _flatRouteCoords.last;
    return ml.LatLng(last[1], last[0]);
  }

  // Projects a LatLng onto the nearest segment of the route and returns
  // the cumulative km distance from the route start to that projected point.
  double _projectToRoute(ml.LatLng tapped) {
    if (_flatRouteCoords.isEmpty) return 0;
    double bestDist = double.infinity;
    double bestRouteKm = 0;
    double cumKm = 0;
    for (int i = 1; i < _flatRouteCoords.length; i++) {
      final a = _flatRouteCoords[i - 1];
      final b = _flatRouteCoords[i];
      final segLen = _calculateDistance(a[1], a[0], b[1], b[0]);
      final t = _projectOntoSegment(
        tapped.latitude, tapped.longitude,
        a[1], a[0], b[1], b[0],
      );
      final pLat = a[1] + (b[1] - a[1]) * t;
      final pLng = a[0] + (b[0] - a[0]) * t;
      final d = _calculateDistance(tapped.latitude, tapped.longitude, pLat, pLng);
      if (d < bestDist) {
        bestDist = d;
        bestRouteKm = cumKm + t * segLen;
      }
      cumKm += segLen;
    }
    return bestRouteKm;
  }

  // Returns t ∈ [0,1] for the closest point on segment A→B to point P.
  double _projectOntoSegment(
    double pLat, double pLng,
    double aLat, double aLng,
    double bLat, double bLng,
  ) {
    final abLat = bLat - aLat;
    final abLng = bLng - aLng;
    final lenSq = abLat * abLat + abLng * abLng;
    if (lenSq < 1e-18) return 0.0;
    final t = ((pLat - aLat) * abLat + (pLng - aLng) * abLng) / lenSq;
    return t.clamp(0.0, 1.0);
  }

  // LTFRB fare: base fare if ≤ baseKm, else base + (km − baseKm) × perKm
  double get _selectedDropOffFare =>
      FareMatrix.calculate(_selectedDropOffDistance, _vehicleType);

  // Estimated travel time at 20 km/h city average + 5 min buffer
  int get _estimatedMinutes =>
      ((_selectedDropOffDistance / 20) * 60).toInt() + 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: AppColors.surface.withValues(alpha: 0.8),
            elevation: 0,
            centerTitle: false,
            title: Text(
              'Select Drop Off Point',
              style: GoogleFonts.lexend(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Map Section — MapLibre GL with pitch:55 bearing:-15 matching esuyo-web
                SizedBox(
                  height: 320,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      _mapStyle == null
                          ? const Center(child: CircularProgressIndicator())
                          : ml.MapLibreMap(
                              key: _mapKey,
                              initialCameraPosition: const ml.CameraPosition(
                                target: ml.LatLng(13.1391, 123.7438),
                                zoom: 13.2,
                                tilt: 55,
                                bearing: -15,
                              ),
                              styleString: _mapStyle!,
                              onMapCreated: (controller) =>
                                  _mapController = controller,
                              onStyleLoadedCallback: _onStyleLoaded,
                              onMapClick: _handleMapTap,
                              onMapLongClick: _onMapLongClick,
                              onCameraIdle: _onCameraIdle,
                              compassEnabled: false,
                              featureTapsTriggersMapClick: true,
                              trackCameraPosition: true,
                              rotateGesturesEnabled: _activeDragMarker == null,
                              zoomGesturesEnabled: true,
                              scrollGesturesEnabled: _activeDragMarker == null,
                              tiltGesturesEnabled: false,
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
                      if (_isCustomDropOffMode)
                        Positioned(
                          bottom: 52,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.80),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Tap to set drop-off',
                                      style: GoogleFonts.lexend(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Listener: tracks pointer state and drives drag movement.
                      // Long-press activation is handled by onMapLongClick (native).
                      Positioned.fill(
                        child: Listener(
                          behavior: HitTestBehavior.translucent,
                          onPointerDown: (_) => _pointerDown = true,
                          onPointerMove: _handlePointerMove,
                          onPointerUp: (_) => _handlePointerUpCancel(),
                          onPointerCancel: (_) => _handlePointerUpCancel(),
                        ),
                      ),
                    ],
                  ),
                ),
                // Details Sheet
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(40),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 48,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'LOOP 1 OVERVIEW',
                                style: GoogleFonts.lexend(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.0,
                                  color: AppColors.outline,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.tertiaryContainer.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(width: 8),
                                  Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.tertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Daraga-Legazpi Circuit',
                          style: GoogleFonts.lexend(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Single route slider: B is draggable; A is visual and fixed at route start
                        if (_flatRouteCoords.isNotEmpty) ...[
                          Text(
                            'Route Position',
                            style: GoogleFonts.lexend(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.outline,
                            ),
                          ),
                          const SizedBox(height: 8),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final totalDist = _totalRouteDistanceKm();
                              final safeTotal = totalDist > 0 ? totalDist : 1.0;
                              const aFrac = 0.0;
                              final bFrac = (_sliderDistanceKm / safeTotal)
                                  .clamp(0.0, 1.0);

                              final tickFractions = <double>[];
                              for (final stop
                                  in widget.initialRoute?.stops ??
                                      <RouteStop>[]) {
                                final d = _projectToRoute(
                                  ml.LatLng(stop.lat, stop.lng),
                                );
                                tickFractions.add(
                                  (d / safeTotal).clamp(0.0, 1.0),
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Drag B to any point on the route',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppColors.outline,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    height: 52,
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        // Live price bubble floating above B marker
                                        Positioned(
                                          left: ((constraints.maxWidth - 16) *
                                                      bFrac -
                                                  28)
                                              .clamp(
                                            0.0,
                                            constraints.maxWidth - 72.0,
                                          ),
                                          top: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              '₱${FareMatrix.calculate(_sliderDistanceKm, _vehicleType).toStringAsFixed(2)}',
                                              style: GoogleFonts.lexend(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        for (final t in tickFractions)
                                          Positioned(
                                            left:
                                                (constraints.maxWidth - 8) * t,
                                            top: 42,
                                            child: Container(
                                              width: 2,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: AppColors.outline
                                                    .withValues(alpha: 0.45),
                                                borderRadius:
                                                    BorderRadius.circular(1),
                                              ),
                                            ),
                                          ),
                                        Positioned(
                                          left:
                                              (constraints.maxWidth - 16) *
                                              aFrac,
                                          top: 32,
                                          child: _sliderMarker(
                                            'A',
                                            const Color(0xFF22C55E),
                                          ),
                                        ),
                                        Positioned(
                                          left:
                                              (constraints.maxWidth - 16) *
                                              bFrac,
                                          top: 32,
                                          child: _sliderMarker(
                                            'B',
                                            const Color(0xFFEF4444),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 5,
                                      activeTrackColor: AppColors.primary,
                                      inactiveTrackColor: AppColors.outline
                                          .withValues(alpha: 0.22),
                                      thumbColor: AppColors.primary,
                                      overlayColor: AppColors.primary
                                          .withValues(alpha: 0.12),
                                    ),
                                    child: Slider.adaptive(
                                      value: _sliderDistanceKm.clamp(
                                        0.0,
                                        safeTotal,
                                      ),
                                      min: 0,
                                      max: safeTotal,
                                      onChanged: (v) {
                                        final snapped = _coordAtDistance(v);
                                        setState(() {
                                          _sliderDistanceKm = v;
                                          _markerBLatLng = snapped;
                                          selectedDropOff = 'Custom Point';
                                          dropOffLocations['Custom Point'] = {
                                            'lat': snapped.latitude,
                                            'lng': snapped.longitude,
                                          };
                                          if (!dropOffPoints.contains(
                                            'Custom Point',
                                          )) {
                                            dropOffPoints.add('Custom Point');
                                          }
                                        });
                                        _refreshPinsAndPath();
                                      },
                                      onChangeEnd: (v) async {
                                        final snapped = _coordAtDistance(v);
                                        await _setDropOffFromLatLng(snapped);
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 16),
                        _buildInputPod(
                          icon: Icons.location_on,
                          iconColor: Colors.green,
                          label: 'STARTING POINT',
                          value: _startingPointName,
                          letter: 'A',
                          isLoading: _isLocating,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isCustomDropOffMode
                                  ? AppColors.primary
                                  : AppColors.primary.withValues(alpha: 0.3),
                              width: _isCustomDropOffMode ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Left: preloaded drop-off selector
                              Expanded(
                                child: GestureDetector(
                                  onTap: _showDropOffModal,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 14,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: Text(
                                              'B',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'DROP OFF',
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AppColors.outline,
                                                      letterSpacing: 1.0,
                                                    ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                selectedDropOff,
                                                style: GoogleFonts.lexend(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.tertiary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.keyboard_arrow_down,
                                          color: AppColors.tertiary,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Divider
                              Container(
                                width: 1,
                                height: 48,
                                color: AppColors.outline.withValues(alpha: 0.15),
                              ),
                              // Right: custom drop toggle
                              GestureDetector(
                                onTap: _toggleCustomDropOffMode,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isCustomDropOffMode
                                        ? AppColors.primary.withValues(
                                            alpha: 0.12,
                                          )
                                        : Colors.transparent,
                                    borderRadius: const BorderRadius.horizontal(
                                      right: Radius.circular(14),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: _isCustomDropOffMode
                                              ? AppColors.primary
                                              : AppColors.tertiaryContainer,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _isCustomDropOffMode
                                              ? Icons.check
                                              : Icons.map,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'CUSTOM',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.outline,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      Text(
                                        _isCustomDropOffMode ? 'On' : 'Off',
                                        style: GoogleFonts.lexend(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _isCustomDropOffMode
                                              ? AppColors.primary
                                              : AppColors.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Drop-off Summary Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      selectedDropOff,
                                      style: GoogleFonts.lexend(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          size: 14,
                                          color: Colors.white70,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$_estimatedMinutes min',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          Icons.straighten,
                                          size: 14,
                                          color: Colors.white70,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_selectedDropOffDistance.toStringAsFixed(1)} km',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Fare with indicators
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (hasDiscount)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade400,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            '-20%',
                                            style: GoogleFonts.lexend(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      if (currentTip > 0)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade400,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            '+₱$currentTip tip',
                                            style: GoogleFonts.lexend(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        '₱${((hasDiscount ? _selectedDropOffFare * 0.8 : _selectedDropOffFare) + currentTip).toStringAsFixed(2)}',
                                        style: GoogleFonts.lexend(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (hasDiscount || currentTip > 0) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '₱${_selectedDropOffFare.toStringAsFixed(2)} base',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: Colors.white60,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () =>
                              setState(() => hasDiscount = !hasDiscount),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: hasDiscount
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: hasDiscount
                                          ? AppColors.primary
                                          : AppColors.outline,
                                      width: 2,
                                    ),
                                  ),
                                  child: hasDiscount
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Apply 20% Discount',
                                        style: GoogleFonts.lexend(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'Student / Senior / PWD',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          color: AppColors.outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'TIP YOUR DRIVER',
                          style: GoogleFonts.lexend(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                            color: AppColors.outline,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: tips.map((tip) {
                            final isSelected = currentTip == tip;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => currentTip = tip),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected
                                        ? null
                                        : Border.all(
                                            color: AppColors.outline.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (tip == 5) ...[
                                          Icon(
                                            Icons.star,
                                            size: 12,
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.primary,
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          tip == 0 ? 'None' : '₱$tip',
                                          style: GoogleFonts.lexend(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? Colors.white
                                                : AppColors.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              context.pushNamed(
                                'confirm_payment',
                                extra: {
                                  'startingPoint': 'Legazpi City Hall',
                                  'dropOffPoint': selectedDropOff,
                                  'distance': _selectedDropOffDistance,
                                  'vehicleType': _vehicleType,
                                  'fare': hasDiscount
                                      ? _selectedDropOffFare * 0.8
                                      : _selectedDropOffFare,
                                  'baseFare': _selectedDropOffFare,
                                  'tip': currentTip,
                                  'totalFare':
                                      (hasDiscount
                                          ? _selectedDropOffFare * 0.8
                                          : _selectedDropOffFare) +
                                      currentTip,
                                  'estimatedMinutes': _estimatedMinutes,
                                  'hasDiscount': hasDiscount,
                                  'paymentMethod': 'E-Suyo Wallet',
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Confirm & Pay',
                                  style: GoogleFonts.lexend(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.arrow_forward),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPod({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    String? letter,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: isLoading
                ? Padding(
                    padding: const EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: iconColor,
                    ),
                  )
                : letter != null
                    ? Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            color: iconColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.outline,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderMarker(String label, Color color) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.lexend(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }



  void _showDropOffModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SELECT DROP-OFF',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  itemCount: dropOffPoints.length,
                  itemBuilder: (context, index) {
                    final point = dropOffPoints[index];
                    final isSelected = selectedDropOff == point;
                    final isPressed = _pressedStop == point;
                    return GestureDetector(
                      onTapDown: (_) => setState(() => _pressedStop = point),
                      onTapUp: (_) => _selectStop(point),
                      onTapCancel: () => setState(() => _pressedStop = null),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isPressed
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : (isSelected
                                    ? AppColors.primary.withValues(alpha: 0.08)
                                    : Colors.transparent),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.location_on_rounded,
                              color: isPressed
                                  ? AppColors.primary
                                  : (isSelected
                                        ? AppColors.primary
                                        : AppColors.outline),
                              size: 20,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final loc = dropOffLocations[point];
                                  final nearby = loc != null
                                      ? LocationService.getNearbyLandmarks(
                                          loc['lat']!,
                                          loc['lng']!,
                                          _landmarks,
                                          radiusKm: 0.3,
                                          maxResults: 2,
                                        )
                                      : <LandmarkModel>[];
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        point,
                                        style: GoogleFonts.lexend(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.onSurface,
                                        ),
                                      ),
                                      if (nearby.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        ...nearby.map((lm) {
                                          final distKm =
                                              LocationService.calculateDistance(
                                                loc!['lat']!,
                                                loc['lng']!,
                                                lm.lat,
                                                lm.lng,
                                              );
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            child: Row(
                                              children: [
                                                Text(
                                                  _landmarkEmoji(lm.category),
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    lm.name,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style:
                                                        GoogleFonts.plusJakartaSans(
                                                          fontSize: 10,
                                                          color:
                                                              AppColors.outline,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${(distKm * 1000).toStringAsFixed(0)}m',
                                                  style:
                                                      GoogleFonts.plusJakartaSans(
                                                        fontSize: 9,
                                                        color:
                                                            AppColors.outline,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectStop(String point) {
    setState(() {
      _pressedStop = point;
      selectedDropOff = point;
    });
    _updateMapMarkers();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _pressedStop = null);
    });
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  Future<void> _onStyleLoaded() async {
    _styleLoaded = true;
    await _drawRouteOnMap();
    await _drawLandmarks();
  }

  void _onCameraIdle() {
    final bearing = _mapController?.cameraPosition?.bearing ?? 0.0;
    if ((bearing - _bearing).abs() > 0.1) {
      setState(() => _bearing = bearing);
    }
  }

  Future<void> _drawLandmarks() async {
    final c = _mapController;
    if (c == null || _landmarks.isEmpty) return;

    final features = _landmarks
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

    try {
      await c.addGeoJsonSource('landmarks', {
        'type': 'FeatureCollection',
        'features': features,
      });

      await c.addCircleLayer(
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

      await c.addSymbolLayer(
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
    } catch (_) {}
  }

  String _landmarkEmoji(String category) {
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

  // Generate a teardrop pin image matching the web's CSS design
  Future<void> _addPinImageToStyle(
    ml.MapLibreMapController controller,
    String imageName,
    String colorHex,
    String label,
  ) async {
    // Matches the web CSS exactly:
    //   width/height: 52px (scaled from 32px)
    //   border-radius: 50% 50% 50% 0   (sharp bottom-left = pin tip)
    //   transform: rotate(-45deg), transform-origin: bottom left
    //
    // After rotation the bounding box is S*sqrt(2) × S*sqrt(2).
    // Pin tip lands at bottom-center → correct for iconAnchor:'bottom'.
    const double S = 52.0; // CSS element side length
    const double r = S / 2; // corner radius (50%)
    // Canvas: add 4px padding on each side for border + shadow
    const int canvasW = 82;
    const int canvasH = 82;
    const double pinX = canvasW / 2.0; // pin tip is at horizontal center
    const double pinY = canvasH - 4.0; // pin tip near canvas bottom

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..isAntiAlias = true;
    final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

    // Translate to pin tip, rotate -45° — replicates CSS transform
    canvas.save();
    canvas.translate(pinX, pinY);
    canvas.rotate(-pi / 4);

    // In this local (rotated) space the CSS element occupies (0, -S) → (S, 0).
    // (0, 0) is the sharp bottom-left corner = pin tip.
    final rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, -S, S, S),
      topLeft: const Radius.circular(r),
      topRight: const Radius.circular(r),
      bottomRight: const Radius.circular(r),
      bottomLeft: Radius.zero,
    );

    // Shadow (shift in local space)
    paint
      ..style = PaintingStyle.fill
      ..color = Colors.black.withValues(alpha: 0.35);
    canvas.drawRRect(rrect.shift(const Offset(1.5, 1.5)), paint);

    // Fill
    paint.color = color;
    canvas.drawRRect(rrect, paint);

    // White border — 2.5px matches web
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.white;
    canvas.drawRRect(rrect, paint);

    canvas.restore();

    // Visual center of marker head in canvas space.
    // CSS element center is at local (S/2, -S/2); after rotate(-45°) + translate
    // it lands exactly at canvas (pinX, pinY - S*sqrt(2)/2).
    const double labelY = pinY - S * sqrt2 / 2;

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(pinX - textPainter.width / 2, labelY - textPainter.height / 2),
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(canvasW, canvasH);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    try {
      await controller.addImage(imageName, pngBytes);
    } catch (_) {}
  }

  // ── Route-coord helpers ─────────────────────────────────────────────────────

  List<List<double>> _buildFlatRouteCoords() {
    final route = widget.initialRoute;
    if (route == null) return [];
    final coords = <List<double>>[];
    for (final stop in route.stops) {
      if (stop.roadPathFromPrev.isNotEmpty) {
        for (final c in stop.roadPathFromPrev) {
          coords.add([c[0].toDouble(), c[1].toDouble()]);
        }
      } else {
        coords.add([stop.lng, stop.lat]);
      }
    }
    return coords;
  }

  List<List<double>> _yellowSegmentCoords() {
    if (_flatRouteCoords.isEmpty || _sliderDistanceKm <= 0) return [];
    final result = <List<double>>[];
    double cum = 0;
    for (int i = 0; i < _flatRouteCoords.length; i++) {
      result.add(_flatRouteCoords[i]);
      if (i + 1 >= _flatRouteCoords.length) break;
      final next = _flatRouteCoords[i + 1];
      final segLen = _calculateDistance(
        _flatRouteCoords[i][1], _flatRouteCoords[i][0], next[1], next[0]);
      if (cum + segLen >= _sliderDistanceKm) {
        if (segLen > 0) {
          final t = (_sliderDistanceKm - cum) / segLen;
          result.add([
            _flatRouteCoords[i][0] + (next[0] - _flatRouteCoords[i][0]) * t,
            _flatRouteCoords[i][1] + (next[1] - _flatRouteCoords[i][1]) * t,
          ]);
        }
        break;
      }
      cum += segLen;
    }
    return result;
  }

  // ── Live source refresh (no layer recreation) ────────────────────────────────

  Future<void> _refreshPinsAndPath() async {
    final c = _mapController;
    if (c == null) return;

    final pinFeatures = <Map<String, dynamic>>[];
    if (_markerALatLng != null) {
      pinFeatures.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [_markerALatLng!.longitude, _markerALatLng!.latitude],
        },
        'properties': {'label': 'A', 'color': '#22c55e'},
      });
    }
    if (_markerBLatLng != null) {
      pinFeatures.add({
        'type': 'Feature',
        'geometry': {
          'type': 'Point',
          'coordinates': [_markerBLatLng!.longitude, _markerBLatLng!.latitude],
        },
        'properties': {'label': 'B', 'color': '#ef4444'},
      });
    }
    try {
      await c.setGeoJsonSource('route-pins', {
        'type': 'FeatureCollection',
        'features': pinFeatures,
      });
    } catch (_) {}

    await _refreshYellowPath(c);
  }

  Future<void> _refreshYellowPath(ml.MapLibreMapController c) async {
    final seg = _yellowSegmentCoords();
    try {
      await c.setGeoJsonSource('ab-path-data', {
        'type': 'FeatureCollection',
        'features': seg.length >= 2
            ? [
                {
                  'type': 'Feature',
                  'geometry': {'type': 'LineString', 'coordinates': seg},
                  'properties': {},
                },
              ]
            : [],
      });
    } catch (_) {}
  }

  // ── Drag gesture handlers ────────────────────────────────────────────────────
  // Long-press activation comes from MapLibre's native onMapLongClick (bypasses
  // Flutter gesture arena entirely).  The Listener only handles move/up to drive
  // the drag once _activeDragMarker is set.

  // Called by MapLibreMap.onMapLongClick — point is in logical px, same space as
  // toScreenLocation.  Icons are screen-aligned billboards, so screen-space distance
  // is correct even with tilt=55 (LatLng distance is perspective-distorted).
  Future<void> _onMapLongClick(Point<double> point, ml.LatLng coords) async {
    if (!mounted || !_pointerDown) return;
    final c = _mapController;
    if (c == null) return;

    final touchPos = Offset(point.x, point.y);
    String? which;
    double closestDist = 90.0; // px threshold

    // Screen-space check: pin tip is at toScreenLocation result;
    // head centre is ~51px above → check midpoint 25px above tip.
    if (_markerBLatLng != null) {
      try {
        final pt = await c.toScreenLocation(_markerBLatLng!);
        if (!mounted || !_pointerDown) return;
        final d =
            (Offset(pt.x.toDouble(), pt.y.toDouble() - 25) - touchPos).distance;
        if (d < closestDist) {
          closestDist = d;
          which = 'B';
        }
      } catch (_) {}
    }

    // Geographic fallback if toScreenLocation unavailable — pick closest within 3 km.
    if (which == null) {
      double closestKm = 3.0;
      if (_markerBLatLng != null) {
        final d = _calculateDistance(
          coords.latitude,
          coords.longitude,
          _markerBLatLng!.latitude,
          _markerBLatLng!.longitude,
        );
        if (d < closestKm) {
          closestKm = d;
          which = 'B';
        }
      }
    }

    if (which != null && mounted && _pointerDown) {
      HapticFeedback.mediumImpact();
      setState(() => _activeDragMarker = which);
    }
  }

  void _handlePointerMove(PointerMoveEvent e) {
    if (_activeDragMarker == null) return;
    _processDragMoveGlobal(e.position);
  }

  void _handlePointerUpCancel() {
    _pointerDown = false;
    if (_activeDragMarker != null) {
      setState(() => _activeDragMarker = null);
    }
  }

  Future<void> _processDragMoveGlobal(Offset globalPos) async {
    if (_activeDragMarker == null || _dragProcessing) return;
    _dragProcessing = true;
    try {
      final box = _mapKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;
      final localPos = box.globalToLocal(globalPos);
      final c = _mapController;
      if (c == null) return;
      final latLng = await c.toLatLng(Point<double>(localPos.dx, localPos.dy));
      if (_flatRouteCoords.isEmpty) return;
      final dist = _projectToRoute(latLng);
      final snapped = _coordAtDistance(dist);
      _sliderDistanceKm = dist;
      _markerBLatLng = snapped;
      await _refreshPinsAndPath();
      await _setDropOffFromLatLng(snapped);
    } finally {
      _dragProcessing = false;
    }
  }

  Future<void> _updateMapMarkers() async {
    final c = _mapController;
    if (c == null) return;

    // Update B marker to newly selected drop-off
    final sel = dropOffLocations[selectedDropOff];
    if (sel != null) {
      _markerBLatLng = ml.LatLng(sel['lat']!, sel['lng']!);
      _sliderDistanceKm = _projectToRoute(_markerBLatLng!);
    }

    // Live-update pin source (layers already exist from _drawRouteOnMap)
    await _refreshPinsAndPath();
  }

  // Create or update a custom drop-off entry from a LatLng position (used by B slider/drag)
  Future<void> _setDropOffFromLatLng(ml.LatLng snapped) async {
    const placeholder = 'Custom Point';
    // Use the given snapped coordinate directly — it's already projected to route
    final finalLatLng = snapped;

    setState(() {
      _markerBLatLng = finalLatLng;
      _sliderDistanceKm = _projectToRoute(finalLatLng);
      selectedDropOff = placeholder;
      // Upsert placeholder location
      dropOffLocations[placeholder] = {
        'lat': finalLatLng.latitude,
        'lng': finalLatLng.longitude,
      };
      if (!dropOffPoints.contains(placeholder)) dropOffPoints.add(placeholder);
    });

    // Resolve a nicer name/address in background
    final address = await _getAddressFromCoords(
      finalLatLng.latitude,
      finalLatLng.longitude,
    );
    final nearbyLm = _nearestLandmark(
      finalLatLng.latitude,
      finalLatLng.longitude,
    );
    final parts = <String>[];
    if (address.isNotEmpty) parts.add(address);
    if (nearbyLm != null) parts.add('near ${nearbyLm.name}');
    final customName = parts.isNotEmpty
        ? parts.join(', ')
        : 'Custom Point (${finalLatLng.latitude.toStringAsFixed(4)}, ${finalLatLng.longitude.toStringAsFixed(4)})';

    if (!mounted) return;
    setState(() {
      // remove old placeholder
      if (dropOffPoints.contains(placeholder)) {
        dropOffPoints.remove(placeholder);
        dropOffLocations.remove(placeholder);
      }
      selectedDropOff = customName;
      if (!dropOffLocations.containsKey(customName)) {
        dropOffLocations[customName] = {
          'lat': finalLatLng.latitude,
          'lng': finalLatLng.longitude,
        };
        dropOffPoints.add(customName);
      } else {
        dropOffLocations[customName] = {
          'lat': finalLatLng.latitude,
          'lng': finalLatLng.longitude,
        };
      }
    });

    await _updateMapMarkers();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
