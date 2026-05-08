class RouteStop {
  final String name;
  final double lat;
  final double lng;
  final String address;
  final double roadDistFromPrev;
  final List<List<double>> roadPathFromPrev; // [[lng, lat], ...]

  RouteStop({
    required this.name,
    required this.lat,
    required this.lng,
    this.address = '',
    this.roadDistFromPrev = 0,
    this.roadPathFromPrev = const [],
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    List<List<double>> path = [];
    final raw = json['roadPathFromPrev'];
    if (raw is List) {
      path = raw.map((p) {
        final coords = p as List;
        return coords.map((v) => (v as num).toDouble()).toList();
      }).toList();
    }
    return RouteStop(
      name: json['name']?.toString() ?? '',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      address: json['address']?.toString() ?? '',
      roadDistFromPrev: (json['roadDistFromPrev'] as num?)?.toDouble() ?? 0,
      roadPathFromPrev: path,
    );
  }
}

class RouteModel {
  final String id;
  final String name;
  final String color;
  final String? vehicleType;
  final String? description;
  final String? hours;
  final String? frequency;
  final List<RouteStop> stops;

  RouteModel({
    required this.id,
    required this.name,
    required this.color,
    this.vehicleType,
    this.description,
    this.hours,
    this.frequency,
    required this.stops,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    final stopsRaw = json['stops'] as List? ?? [];
    return RouteModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      color: json['color']?.toString() ?? '#0046C7',
      vehicleType: json['vehicle_type']?.toString(),
      description: json['description']?.toString(),
      hours: json['hours']?.toString(),
      frequency: json['frequency']?.toString(),
      stops: stopsRaw
          .map((s) => RouteStop.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  double get totalDistKm =>
      stops.fold(0.0, (sum, s) => sum + s.roadDistFromPrev);

  bool get hasHours => hours != null && hours!.isNotEmpty;

  bool get isActive {
    final h = hours;
    if (h == null || h.isEmpty) return true;
    final parts = h.split(RegExp(r'\s*[-–]\s*'));
    if (parts.length < 2) return true;
    final start = _parseMinutes(parts[0].trim());
    final end = _parseMinutes(parts[1].trim());
    if (start == null || end == null) return true;
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    return start <= end
        ? nowMin >= start && nowMin <= end
        : nowMin >= start || nowMin <= end;
  }

  static int? _parseMinutes(String s) {
    final upper = s.toUpperCase();
    final isPm = upper.contains('PM');
    final isAm = upper.contains('AM');
    final clean = s.replaceAll(RegExp(r'[APMapm\s]'), '');
    int hour, minute = 0;
    if (clean.contains(':')) {
      final p = clean.split(':');
      hour = int.tryParse(p[0]) ?? -1;
      minute = int.tryParse(p[1]) ?? 0;
    } else {
      hour = int.tryParse(clean) ?? -1;
    }
    if (hour < 0) return null;
    if (isPm && hour != 12) hour += 12;
    if (isAm && hour == 12) hour = 0;
    if (hour > 23 || minute > 59) return null;
    return hour * 60 + minute;
  }

  String get vehicleLabel {
    switch (vehicleType) {
      case 'puj': return 'PUJ (Traditional Jeepney)';
      case 'mpuj': return 'MPUJ (Modern Jeepney)';
      case 'pub-city': return 'PUB City';
      case 'pub-city-ac': return 'PUB w/AC';
      case 'uv-express': return 'UV Express';
      default: return 'Jeepney';
    }
  }
}
