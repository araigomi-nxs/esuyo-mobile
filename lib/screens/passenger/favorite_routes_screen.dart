import 'dart:async';
import 'dart:math' show Point;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_colors.dart';
import '../../models/route_model.dart';
import '../../models/landmark_model.dart';
import '../../services/supabase_service.dart';
import '../../services/map_style_service.dart';
import '../../widgets/map_compass.dart';

class FavoriteRoutesScreen extends StatefulWidget {
  const FavoriteRoutesScreen({super.key});

  @override
  State<FavoriteRoutesScreen> createState() => _FavoriteRoutesScreenState();
}

class _FavoriteRoutesScreenState extends State<FavoriteRoutesScreen> {
  List<RouteModel> _routes = [];
  List<LandmarkModel> _landmarks = [];
  bool _loading = true;
  bool _hasError = false;
  String _search = '';
  String? _mapStyle;

  ml.MapLibreMapController? _mapController;
  VoidCallback? _cameraListener;
  bool _styleLoaded = false;
  bool _dataDrawn = false;
  double _bearing = 0.0;
  Map<String, dynamic>? _selectedFeature;
  Offset? _cardOffset;
  ml.LatLng? _selectedCoords;
  int _cardProjectionTicket = 0;
  bool _isProjectingCard = false;
  bool _pendingCardProjection = false;
  Map<String, dynamic>? _legazpiBarangays;
  Future<void>? _barangaysLoadFuture;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final FocusNode _searchFocus = FocusNode();
  double _sheetSize = 0.45;
  String _filterTown = '';
  String _filterBarangay = '';
  String _filterVehicle = '';
  Map<String, List<String>> _areaIndex = {};
  Timer? _statusRefreshTimer;

  static const Map<String, String> _vehicleFilterLabels = {
    '': 'All',
    'puj': 'PUJ',
    'mpuj': 'MPUJ',
    'pub-city': 'PUB City',
    'pub-city-ac': 'PUB w/AC',
    'uv-express': 'UV',
  };

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

  String? _getBrgyFromCoords(double lng, double lat) {
    final feature = _getBrgyFeatureFromCoords(lng, lat);
    if (feature == null) return null;
    final props = feature['properties'];
    if (props is! Map<String, dynamic>) return null;
    final name = props['name']?.toString();
    return (name != null && name.isNotEmpty) ? name : null;
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
          return feat;
        }
      }
    }

    return null;
  }

  void _buildAreaIndex() {
    final geo = _legazpiBarangays;
    if (geo == null) {
      _areaIndex = {};
      return;
    }
    final features = geo['features'];
    if (features is! List<dynamic>) {
      _areaIndex = {};
      return;
    }

    final next = <String, List<String>>{};
    for (final feat in features) {
      if (feat is! Map<String, dynamic>) continue;
      final props = feat['properties'];
      if (props is! Map<String, dynamic>) continue;
      final city = props['city']?.toString();
      final name = props['name']?.toString();
      if (city == null || city.isEmpty || name == null || name.isEmpty) {
        continue;
      }
      next.putIfAbsent(city, () => []).add(name);
    }

    for (final values in next.values) {
      values.sort();
    }
    _areaIndex = next;
  }

  bool _routeMatchesArea(RouteModel route) {
    if (_filterTown.isEmpty && _filterBarangay.isEmpty) return true;

    return route.stops.any((stop) {
      final feat = _getBrgyFeatureFromCoords(stop.lng, stop.lat);
      if (feat == null) return false;
      final props = feat['properties'];
      if (props is! Map<String, dynamic>) return false;

      if (_filterBarangay.isNotEmpty) {
        return props['name']?.toString() == _filterBarangay;
      }
      return props['city']?.toString() == _filterTown;
    });
  }

  List<RouteModel> get _visibleRoutes {
    final query = _search.trim().toLowerCase();
    return _routes.where((route) {
      final searchMatch =
          query.isEmpty ||
          route.name.toLowerCase().contains(query) ||
          route.stops.any((s) => s.name.toLowerCase().contains(query));
      final areaMatch = _routeMatchesArea(route);
      final vehicleMatch =
          _filterVehicle.isEmpty ||
          ((route.vehicleType ?? 'puj') == _filterVehicle);
      return searchMatch && areaMatch && vehicleMatch;
    }).toList();
  }

  Future<void> _removeMapDataLayers(ml.MapLibreMapController ctrl) async {
    const layers = [
      'routes-flow-arrows',
      'routes-stop',
      'routes-line',
      'landmarks-label',
      'landmarks-circle',
    ];
    for (final layer in layers) {
      try {
        await ctrl.removeLayer(layer);
      } catch (_) {}
    }

    const sources = ['routes', 'landmarks'];
    for (final source in sources) {
      try {
        await ctrl.removeSource(source);
      } catch (_) {}
    }
  }

  Future<void> _applyFiltersToMap() async {
    final ctrl = _mapController;
    if (ctrl == null || !_styleLoaded) return;

    await _removeMapDataLayers(ctrl);
    if (!mounted) return;

    _dataDrawn = false;
    await _drawData();

    if (!mounted || _selectedFeature == null) return;
    final type = _selectedFeature!['type']?.toString();
    if (type == 'route') {
      final route = _selectedFeature!['route'] as RouteModel?;
      final stillVisible =
          route != null && _visibleRoutes.any((r) => r.id == route.id);
      if (!stillVisible) {
        setState(() {
          _selectedFeature = null;
          _cardOffset = null;
          _selectedCoords = null;
        });
      }
    }
    if (type == 'route-multi') {
      final routes = (_selectedFeature!['routes'] as List?)
          ?.whereType<RouteModel>()
          .where((r) => _visibleRoutes.any((v) => v.id == r.id))
          .toList();
      if (routes == null || routes.isEmpty) {
        setState(() {
          _selectedFeature = null;
          _cardOffset = null;
          _selectedCoords = null;
        });
      } else {
        setState(() {
          _selectedFeature = {..._selectedFeature!, 'routes': routes};
        });
      }
    }
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
        final first = features.first as Map<String, dynamic>;
        final p = first['properties'];
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
    _sheetController.addListener(_onSheetChanged);
    _searchFocus.addListener(_onSearchFocusChanged);
    _loadAll();
    _statusRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _onSearchFocusChanged() {
    if (!mounted || !_sheetController.isAttached) return;
    if (_searchFocus.hasFocus) {
      _sheetController.animateTo(
        1.0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else if (_sheetController.size > 0.45) {
      _sheetController.animateTo(
        0.45,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onSheetChanged() {
    if (!_sheetController.isAttached || !mounted) return;
    final next = _sheetController.size;
    if ((next - _sheetSize).abs() < 0.005) return;
    setState(() {
      _sheetSize = next;
    });
  }

  Future<void> _loadAll() async {
    try {
      final results = await Future.wait([
        SupabaseService.fetchRoutes(),
        SupabaseService.fetchLandmarks(),
        MapStyleService.terrainStyle(),
        _ensureBarangaysLoaded(),
      ]);
      if (!mounted) return;
      setState(() {
        _routes = results[0] as List<RouteModel>;
        _landmarks = results[1] as List<LandmarkModel>;
        _mapStyle = results[2] as String;
        _buildAreaIndex();
        _loading = false;
      });
      if (_styleLoaded && !_dataDrawn) _drawData();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _hasError = true;
      });
    }
  }

  void _onMapCreated(ml.MapLibreMapController controller) {
    if (_mapController != null && _cameraListener != null) {
      _mapController!.removeListener(_cameraListener!);
    }
    _mapController = controller;
    _cameraListener = _updateCardOffset;
    controller.addListener(_cameraListener!);
  }

  Future<void> _updateCardOffset() async {
    if (_isProjectingCard) {
      _pendingCardProjection = true;
      return;
    }

    _isProjectingCard = true;
    while (mounted) {
      _pendingCardProjection = false;
      final ctrl = _mapController;
      final coords = _selectedCoords;
      if (ctrl == null || coords == null) break;

      final ticket = ++_cardProjectionTicket;
      try {
        final screenPos = await ctrl.toScreenLocation(coords);
        if (!mounted || ticket != _cardProjectionTicket) continue;

        final next = Offset(screenPos.x.toDouble(), screenPos.y.toDouble());
        if (_cardOffset == null ||
            (next - _cardOffset!).distanceSquared > 0.5) {
          setState(() {
            _cardOffset = next;
          });
        }
      } catch (_) {
        // Ignore transient map/controller errors while the camera is moving.
      }

      if (!_pendingCardProjection) break;
    }

    _isProjectingCard = false;
  }

  @override
  void dispose() {
    _searchFocus
      ..removeListener(_onSearchFocusChanged)
      ..dispose();
    _statusRefreshTimer?.cancel();
    if (_mapController != null && _cameraListener != null) {
      _mapController!.removeListener(_cameraListener!);
    }
    _sheetController
      ..removeListener(_onSheetChanged)
      ..dispose();
    super.dispose();
  }

  void _setFilters(VoidCallback updater) {
    setState(updater);
    _applyFiltersToMap();
  }

  Future<void> _onStyleLoaded() async {
    _styleLoaded = true;
    if (_routes.isNotEmpty && !_dataDrawn) await _drawData();
  }

  void _onCameraIdle() {
    final bearing = _mapController?.cameraPosition?.bearing ?? 0.0;
    if ((bearing - _bearing).abs() > 0.1) {
      setState(() => _bearing = bearing);
    }
  }


  Future<void> _onMapClick(Point<double> point, ml.LatLng coords) async {
    final ctrl = _mapController;
    if (ctrl == null) return;

    const r = 22.0;
    final rect = Rect.fromLTRB(
      point.x - r,
      point.y - r,
      point.x + r,
      point.y + r,
    );

    // Landmarks first (rendered on top)
    final lmHits = await ctrl.queryRenderedFeaturesInRect(rect, [
      'landmarks-circle',
    ], null);
    if (lmHits.isNotEmpty) {
      final hit = lmHits[0] as Map;
      final props = hit['properties'] as Map;
      final geometry = hit['geometry'] as Map?;
      final featureCoords =
          (geometry?['coordinates'] as List?)
                  ?.map((value) => (value as num).toDouble())
                  .toList() !=
              null
          ? ml.LatLng(
              ((geometry?['coordinates'] as List)[1] as num).toDouble(),
              ((geometry?['coordinates'] as List)[0] as num).toDouble(),
            )
          : coords;
      final screenPos = await ctrl.toScreenLocation(featureCoords);
      if (!mounted) return;
      setState(() {
        _cardOffset = Offset(screenPos.x.toDouble(), screenPos.y.toDouble());
        _selectedCoords = featureCoords;
        _selectedFeature = {
          'type': 'landmark',
          'name': props['name']?.toString() ?? '',
          'category': props['category']?.toString() ?? '',
          'lat': featureCoords.latitude,
          'lng': featureCoords.longitude,
        };
      });
      return;
    }

    // Route stops
    final stopHits = await ctrl.queryRenderedFeaturesInRect(rect, [
      'routes-stop',
    ], null);
    if (stopHits.isNotEmpty) {
      final hit = stopHits[0] as Map;
      final props = hit['properties'] as Map;
      final geometry = hit['geometry'] as Map?;
      final featureCoords =
          (geometry?['coordinates'] as List?)
                  ?.map((value) => (value as num).toDouble())
                  .toList() !=
              null
          ? ml.LatLng(
              ((geometry?['coordinates'] as List)[1] as num).toDouble(),
              ((geometry?['coordinates'] as List)[0] as num).toDouble(),
            )
          : coords;
      final routeId = props['routeId']?.toString() ?? '';
      final visibleRoutes = _visibleRoutes;
      if (visibleRoutes.isEmpty) return;
      final route = visibleRoutes.firstWhere(
        (r) => r.id == routeId,
        orElse: () => visibleRoutes.first,
      );
      final screenPos = await ctrl.toScreenLocation(featureCoords);
      if (!mounted) return;
      setState(() {
        _cardOffset = Offset(screenPos.x.toDouble(), screenPos.y.toDouble());
        _selectedCoords = featureCoords;
        _selectedFeature = {
          'type': 'route',
          'route': route,
          'stopName': props['stopName']?.toString() ?? '',
        };
      });
      return;
    }

    // Route lines
    final lineHits = await ctrl.queryRenderedFeaturesInRect(rect, [
      'routes-line',
    ], null);
    if (lineHits.isNotEmpty) {
      final screenPos = await ctrl.toScreenLocation(coords);
      final routeIds = lineHits
          .map((hit) => ((hit as Map)['properties'] as Map)['routeId'])
          .whereType<String>()
          .toSet();

      final visibleRouteIds = _visibleRoutes.map((r) => r.id).toSet();
      final tappedRoutes = _routes
          .where((route) => routeIds.contains(route.id))
          .where((route) => visibleRouteIds.contains(route.id))
          .toList();

      if (tappedRoutes.isEmpty) {
        if (_selectedFeature != null) {
          setState(() {
            _selectedFeature = null;
            _cardOffset = null;
            _selectedCoords = null;
          });
        }
        return;
      }

      final tapLat = coords.latitude;
      final tapLng = coords.longitude;
      final lineSelectionToken = ++_cardProjectionTicket;

      if (!mounted) return;
      setState(() {
        _cardOffset = Offset(screenPos.x.toDouble(), screenPos.y.toDouble());
        _selectedCoords = coords;
        if (tappedRoutes.length > 1) {
          _selectedFeature = {
            'type': 'route-multi',
            'routes': tappedRoutes,
            'address': 'Locating…',
          };
        } else {
          final route = tappedRoutes.first;
          _selectedFeature = {
            'type': 'route',
            'route': route,
            'stopName': '',
            'address': 'Locating…',
          };
        }
      });

      final address = await _getAddressFromCoords(tapLat, tapLng);
      if (!mounted || lineSelectionToken != _cardProjectionTicket) return;
      setState(() {
        if (_selectedFeature == null) return;
        final currentType = _selectedFeature!['type']?.toString();
        if (currentType == 'route' || currentType == 'route-multi') {
          _selectedFeature = {
            ..._selectedFeature!,
            'address': address.isNotEmpty ? address : 'No address found',
            'lat': tapLat,
            'lng': tapLng,
          };
        }
      });
      return;
    }

    // Tapped empty space — dismiss
    if (_selectedFeature != null) {
      setState(() {
        _selectedFeature = null;
        _cardOffset = null;
        _selectedCoords = null;
        _cardProjectionTicket++;
      });
    }
  }

  Future<void> _drawData() async {
    final ctrl = _mapController;
    if (ctrl == null) return;
    _dataDrawn = true;
    final visibleRoutes = _visibleRoutes;

    // Routes as GeoJSON so queryRenderedFeatures works on tap
    final routeFeatures = <Map<String, dynamic>>[];
    for (final route in visibleRoutes) {
      for (final stop in route.stops) {
        if (stop.roadPathFromPrev.isEmpty) continue;
        routeFeatures.add({
          'type': 'Feature',
          'geometry': {
            'type': 'LineString',
            'coordinates': stop.roadPathFromPrev,
          },
          'properties': {
            'featureType': 'route-line',
            'routeId': route.id,
            'routeName': route.name,
            'routeColor': route.color,
            'vehicleLabel': route.vehicleLabel,
            'stopsCount': route.stops.length,
            'totalDistKm': route.totalDistKm,
            'description': route.description ?? '',
          },
        });
      }
      for (int i = 0; i < route.stops.length; i++) {
        final stop = route.stops[i];
        routeFeatures.add({
          'type': 'Feature',
          'geometry': {
            'type': 'Point',
            'coordinates': [stop.lng, stop.lat],
          },
          'properties': {
            'featureType': 'route-stop',
            'routeId': route.id,
            'routeName': route.name,
            'routeColor': route.color,
            'vehicleLabel': route.vehicleLabel,
            'stopsCount': route.stops.length,
            'totalDistKm': route.totalDistKm,
            'description': route.description ?? '',
            'stopName': stop.name,
            'isTerminal': i == 0 || i == route.stops.length - 1,
          },
        });
      }
    }

    await ctrl.addGeoJsonSource('routes', {
      'type': 'FeatureCollection',
      'features': routeFeatures,
    });

    await ctrl.addLineLayer(
      'routes',
      'routes-line',
      ml.LineLayerProperties(
        lineColor: ['get', 'routeColor'],
        lineWidth: 3.5,
        lineOpacity: 0.85,
      ),
      filter: [
        '==',
        ['get', 'featureType'],
        'route-line',
      ],
      enableInteraction: false,
    );

    await ctrl.addSymbolLayer(
      'routes',
      'routes-flow-arrows',
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
      'routes',
      'routes-stop',
      ml.CircleLayerProperties(
        circleRadius: [
          'case',
          ['get', 'isTerminal'],
          6.0,
          4.0,
        ],
        circleColor: ['get', 'routeColor'],
        circleStrokeColor: '#FFFFFF',
        circleStrokeWidth: 1.5,
      ),
      filter: [
        '==',
        ['get', 'featureType'],
        'route-stop',
      ],
      enableInteraction: false,
    );

    if (_landmarks.isNotEmpty) {
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

      await ctrl.addGeoJsonSource('landmarks', {
        'type': 'FeatureCollection',
        'features': features,
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
          textSize: 12,
          textOffset: [0, 1.5],
          textAnchor: 'top',
          textAllowOverlap: false,
          textIgnorePlacement: false,
          textColor: '#222222',
          textHaloColor: '#ffffff',
          textHaloWidth: 3,
        ),
        minzoom: 13,
        enableInteraction: false,
      );
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _hasError = false;
      _dataDrawn = false;
    });
    _loadAll();
  }

  Widget _buildAnchoredCard(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    final dpr = mq.devicePixelRatio;
    const cardWidth = 180.0;
    const cardEstimatedHeight = 84.0;
    const overlap = 10.0;
    final maxTop = size.height * 0.58 - cardEstimatedHeight;

    // Convert physical pixels to logical pixels
    final pinX = _cardOffset!.dx / dpr;
    final pinY = _cardOffset!.dy / dpr;

    final withinVisibleMap =
        pinX >= 8.0 &&
        pinX <= size.width - 8.0 &&
        pinY >= mq.padding.top + cardEstimatedHeight - overlap &&
        pinY <= size.height * 0.58;

    if (!withinVisibleMap) {
      return const SizedBox.shrink();
    }

    // Position card centered above the pin
    final left = (pinX - cardWidth / 2).clamp(
      8.0,
      size.width - cardWidth - 8.0,
    );

    // Position above the pin with overlap
    final top = (pinY - cardEstimatedHeight + overlap).clamp(
      mq.padding.top + 6.0,
      maxTop,
    );

    return Positioned(
      left: left,
      top: top,
      width: cardWidth,
      child: _MapInfoCard(
        feature: _selectedFeature!,
        onDismiss: () => setState(() {
          _selectedFeature = null;
          _cardOffset = null;
          _selectedCoords = null;
        }),
        onViewRoute: (route) =>
            context.push('/passenger/route_detail', extra: route),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCollapsed = _sheetSize <= 0.13;
    final visibleRoutes = _visibleRoutes;
    final panelTitle = isCollapsed
        ? '${visibleRoutes.length} route${visibleRoutes.length == 1 ? '' : 's'}'
        : 'All Routes';
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // Full-screen map
          Positioned.fill(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: _mapStyle != null
                  ? ml.MapLibreMap(
                      styleString: _mapStyle!,
                      onMapCreated: _onMapCreated,
                      onStyleLoadedCallback: _onStyleLoaded,
                      onMapClick: _onMapClick,
                      onCameraIdle: _onCameraIdle,
                      compassEnabled: false,
                      trackCameraPosition: true,
                      featureTapsTriggersMapClick: true,
                      initialCameraPosition: const ml.CameraPosition(
                        target: ml.LatLng(13.1391, 123.7438),
                        zoom: 13.2,
                        tilt: 55,
                        bearing: -15,
                      ),
                      tiltGesturesEnabled: false,
                    )
                  : ColoredBox(
                      color: AppColors.background,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
            ),
          ),

          // Compass — top right, same level as back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: MapCompass(bearing: _bearing),
          ),

          // Floating back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                elevation: 2,
                shadowColor: Colors.black26,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: AppColors.primaryContainer,
                  ),
                  onPressed: () => context.go('/passenger'),
                ),
              ),
            ),
          ),

          // Info card anchored above the tapped pin — rendered before sheet so it appears on top
          if (_selectedFeature != null && _cardOffset != null)
            _buildAnchoredCard(context),

          // Sliding panel
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.45,
            minChildSize: 0.12,
            maxChildSize: 1.0,
            snap: true,
            snapSizes: const [0.12, 0.45, 1.0],
            builder: (context, scrollController) {
              return Container(
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final panelCollapsed = constraints.maxHeight < 180;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag handle — full-width touch target
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onVerticalDragUpdate: (details) {
                            if (!_sheetController.isAttached) return;
                            final screenHeight = MediaQuery.of(
                              context,
                            ).size.height;
                            final delta = -details.primaryDelta! / screenHeight;
                            final next = (_sheetController.size + delta).clamp(
                              0.12,
                              1.0,
                            );
                            _sheetController.jumpTo(next);
                          },
                          onVerticalDragEnd: (details) {
                            if (!_sheetController.isAttached) return;
                            final velocity = details.primaryVelocity ?? 0;
                            final current = _sheetController.size;
                            double target;
                            if (velocity < -600) {
                              target = current > 0.45 ? 1.0 : 0.45;
                            } else if (velocity > 600) {
                              target = current < 0.45
                                  ? 0.12
                                  : (current < 0.75 ? 0.45 : 0.45);
                            } else {
                              if (current < 0.28) {
                                target = 0.12;
                              } else if (current < 0.72) {
                                target = 0.45;
                              } else {
                                target = 1.0;
                              }
                            }
                            _sheetController.animateTo(
                              target,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                            );
                          },
                          child: SizedBox(
                            width: double.infinity,
                            height: 36,
                            child: Center(
                              child: Container(
                                width: 44,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppColors.outline.withValues(
                                    alpha: 0.4,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Title
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Text(
                            panelTitle,
                            style: GoogleFonts.lexend(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        if (!panelCollapsed) ...[
                          // Search
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: TextField(
                              focusNode: _searchFocus,
                              onChanged: (v) => _setFilters(() => _search = v),
                              decoration: InputDecoration(
                                hintText: 'Search routes...',
                                hintStyle: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: AppColors.outline,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: AppColors.outline,
                                  size: 20,
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceContainerLowest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          _buildFilterControls(),
                        ],
                        Expanded(
                          child: panelCollapsed
                              ? SingleChildScrollView(
                                  controller: scrollController,
                                )
                              : Padding(
                                  padding: EdgeInsets.only(
                                    bottom: keyboardHeight,
                                  ),
                                  child: _buildList(scrollController),
                                ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildList(ScrollController scrollController) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 40,
              color: AppColors.outline,
            ),
            const SizedBox(height: 10),
            Text(
              'Could not load routes',
              style: GoogleFonts.lexend(color: AppColors.outline),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _retry, child: const Text('Retry')),
          ],
        ),
      );
    }
    final routes = _visibleRoutes;
    if (routes.isEmpty) {
      return Center(
        child: Text(
          'No routes found',
          style: GoogleFonts.plusJakartaSans(color: AppColors.outline),
        ),
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      itemCount: routes.length,
      itemBuilder: (context, i) => _RouteCard(
        route: routes[i],
        onTap: () => context.push('/passenger/route_detail', extra: routes[i]),
      ),
    );
  }

  Widget _buildFilterControls() {
    final towns = _areaIndex.keys.toList()..sort();
    final barangays = _filterTown.isEmpty
        ? const <String>[]
        : (_areaIndex[_filterTown] ?? const <String>[]);
    final hasFilter =
        _search.trim().isNotEmpty ||
        _filterTown.isNotEmpty ||
        _filterBarangay.isNotEmpty ||
        _filterVehicle.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _filterDropdown(
                  label: 'Town',
                  value: _filterTown,
                  items: towns,
                  onChanged: (v) => _setFilters(() {
                    _filterTown = v ?? '';
                    _filterBarangay = '';
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _filterDropdown(
                  label: 'Barangay',
                  value: _filterBarangay,
                  items: barangays,
                  enabled: _filterTown.isNotEmpty,
                  onChanged: (v) =>
                      _setFilters(() => _filterBarangay = v ?? ''),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _vehicleFilterLabels.entries.map((entry) {
                final selected = _filterVehicle == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      entry.value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: selected
                            ? AppColors.surface
                            : AppColors.primaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    selected: selected,
                    onSelected: (_) =>
                        _setFilters(() => _filterVehicle = entry.key),
                    selectedColor: AppColors.primaryContainer,
                    backgroundColor: AppColors.surfaceContainerLowest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: BorderSide(
                        color: selected
                            ? AppColors.primaryContainer
                            : AppColors.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                );
              }).toList(),
            ),
          ),
          if (hasFilter)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _setFilters(() {
                  _search = '';
                  _filterTown = '';
                  _filterBarangay = '';
                  _filterVehicle = '';
                }),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                child: Text(
                  'Clear filters',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryContainer,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value.isEmpty ? null : value,
          isExpanded: true,
          hint: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.outline,
            ),
          ),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
          isDense: true,
          iconSize: 18,
          dropdownColor: AppColors.surface,
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final RouteModel route;
  final VoidCallback onTap;

  const _RouteCard({required this.route, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(route.color);
    final totalKm = route.totalDistKm;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.directions_bus_rounded, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          route.name,
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          route.vehicleLabel.split(' ').first,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _RouteStatusTag(route: route),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (route.description != null &&
                      route.description!.isNotEmpty)
                    Text(
                      route.description!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_rounded,
                        size: 11,
                        color: AppColors.outline,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${route.stops.length} stops',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          color: AppColors.outline,
                        ),
                      ),
                      if (totalKm > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.straighten_rounded,
                          size: 11,
                          color: AppColors.outline,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${totalKm.toStringAsFixed(1)} km',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: AppColors.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.outline),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return AppColors.primaryContainer;
    }
  }
}

// ── Map info card ─────────────────────────────────────────────────────────────

class _MapInfoCard extends StatelessWidget {
  final Map<String, dynamic> feature;
  final VoidCallback onDismiss;
  final void Function(RouteModel) onViewRoute;

  const _MapInfoCard({
    required this.feature,
    required this.onDismiss,
    required this.onViewRoute,
  });

  static String _emoji(String category) {
    const map = {
      'hospital': '🏥',
      'school': '🏫',
      'church': '⛪',
      'gov': '🏛️',
      'terminal': '🚌',
      'airport': '✈️',
      'mall': '🛍️',
      'bank': '🏦',
      'market': '🛒',
      'park': '🌳',
      'factory': '🏭',
      'gasstation': '⛽',
      'fastfood': '🍔',
      'restaurant': '🍽️',
      'cafe': '☕',
      'accommodation': '🛏️',
      'viewpoint': '📸',
      '7eleven': '7️⃣',
      '711': '7️⃣',
      'port': '⚓',
    };
    return map[category] ?? '📍';
  }

  static Color _hexColor(String hex) {
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) {
      return AppColors.primaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = feature['type'] as String;
    // Stack allows us to render a small pointer triangle below the card
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Material(
          elevation: 6,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(10),
          color: AppColors.surface.withValues(alpha: 0.96),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: type == 'landmark'
                ? _buildLandmark()
                : type == 'route-multi'
                ? _buildMultiRoute(context)
                : _buildRoute(context),
          ),
        ),
        // small downward pointer to visually attach card to marker
        Positioned(
          bottom: -6,
          child: SizedBox(
            width: 18,
            height: 12,
            child: CustomPaint(
              painter: _TrianglePainter(color: AppColors.surface),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandmark() {
    final name = feature['name'] as String;
    final category = feature['category'] as String;
    final lat = (feature['lat'] as double).toStringAsFixed(4);
    final lng = (feature['lng'] as double).toStringAsFixed(4);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(_emoji(category), style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$category · $lat, $lng',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  color: AppColors.outline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onDismiss,
          child: const Icon(Icons.close, size: 16, color: AppColors.outline),
        ),
      ],
    );
  }

  Widget _buildRoute(BuildContext context) {
    final route = feature['route'] as RouteModel;
    final stopName = feature['stopName'] as String;
    final address = feature['address']?.toString();
    final color = _hexColor(route.color);
    final km = route.totalDistKm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                stopName.isNotEmpty ? '$stopName · ${route.name}' : route.name,
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(
                Icons.close,
                size: 16,
                color: AppColors.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${route.vehicleLabel.split(' ').first} · ${route.stops.length} stops'
          '${km > 0 ? ' · ${km.toStringAsFixed(1)} km' : ''}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            color: AppColors.outline,
          ),
        ),
        if (address != null && address.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            address,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: AppColors.outline,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => onViewRoute(route),
          child: Text(
            'View details →',
            style: GoogleFonts.lexend(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiRoute(BuildContext context) {
    final routes = (feature['routes'] as List).cast<RouteModel>();
    final visibleRoutes = routes.take(4).toList();
    final address = feature['address']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${routes.length} overlapping routes',
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(
                Icons.close,
                size: 16,
                color: AppColors.outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (address != null && address.isNotEmpty) ...[
          Text(
            address,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: AppColors.outline,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
        ],
        ...visibleRoutes.map((route) {
          final color = _hexColor(route.color);
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: GestureDetector(
              onTap: () => onViewRoute(route),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      route.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 14, color: color),
                ],
              ),
            ),
          );
        }),
        if (routes.length > visibleRoutes.length)
          Text(
            '+${routes.length - visibleRoutes.length} more',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: AppColors.outline,
            ),
          ),
      ],
    );
  }
}

class _RouteStatusTag extends StatelessWidget {
  final RouteModel route;

  const _RouteStatusTag({required this.route});

  @override
  Widget build(BuildContext context) {
    final active = route.isActive;
    final color = active ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final label = active ? 'ACTIVE' : 'INACTIVE';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
