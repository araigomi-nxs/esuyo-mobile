import 'dart:convert';
import 'package:http/http.dart' as http;

class MapStyleService {
  static const _cartoUrl =
      'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json';

  // Cached so it only fetches once per session
  static String? _cachedStyle;

  /// Returns a CartoDB Positron style JSON string with terrain (AWS Terrarium
  /// DEM, exaggeration 0.65) and hillshade baked in — matching the web app.
  static Future<String> terrainStyle() async {
    if (_cachedStyle != null) return _cachedStyle!;

    final response = await http.get(Uri.parse(_cartoUrl));
    final style = json.decode(response.body) as Map<String, dynamic>;

    // Inject terrain DEM source (two copies — one for terrain, one for hillshade)
    final sources = style['sources'] as Map<String, dynamic>;
    final demSpec = {
      'type': 'raster-dem',
      'tiles': [
        'https://s3.amazonaws.com/elevation-tiles-prod/terrarium/{z}/{x}/{y}.png'
      ],
      'encoding': 'terrarium',
      'tileSize': 256,
      'maxzoom': 14,
      'attribution': 'Terrain: Mapzen/AWS',
    };
    sources['terrain-dem'] = demSpec;
    sources['terrain-dem-hs'] = demSpec;

    // Set terrain exaggeration at root level (MapLibre style spec)
    style['terrain'] = {
      'source': 'terrain-dem',
      'exaggeration': 0.65,
    };

    // Insert hillshade layer before the first symbol layer
    final layers = style['layers'] as List<dynamic>;
    final firstSymbolIdx =
        layers.indexWhere((l) => (l as Map)['type'] == 'symbol');
    final hillshadeLayer = {
      'id': 'terrain-hillshade',
      'type': 'hillshade',
      'source': 'terrain-dem-hs',
      'paint': {
        'hillshade-exaggeration': 0.3,
        'hillshade-shadow-color': '#8a9bb0',
        'hillshade-highlight-color': '#ffffff',
        'hillshade-accent-color': '#b0bec5',
        'hillshade-illumination-direction': 315,
        'hillshade-illumination-anchor': 'map',
      },
    };
    if (firstSymbolIdx >= 0) {
      layers.insert(firstSymbolIdx, hillshadeLayer);
    } else {
      layers.add(hillshadeLayer);
    }

    _cachedStyle = json.encode(style);
    return _cachedStyle!;
  }
}
