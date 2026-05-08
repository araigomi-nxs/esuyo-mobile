class FareRates {
  final double base;
  final double baseKm;
  final double perKm;

  const FareRates({
    required this.base,
    required this.baseKm,
    required this.perKm,
  });
}

/// LTFRB fare matrix (March 2026 rates), mirrored from esuyo-web/app.js
class FareMatrix {
  static const Map<String, FareRates> _rates = {
    'puj':         FareRates(base: 14.00, baseKm: 4, perKm: 2.00),
    'mpuj':        FareRates(base: 17.00, baseKm: 4, perKm: 2.30),
    'pub-city':    FareRates(base: 15.00, baseKm: 5, perKm: 2.49),
    'pub-city-ac': FareRates(base: 18.00, baseKm: 5, perKm: 2.98),
    'uv-express':  FareRates(base: 25.00, baseKm: 5, perKm: 2.50),
  };

  static FareRates getRates(String? vehicleType) =>
      _rates[vehicleType] ?? _rates['puj']!;

  /// Matches web app calcFare(km, vehicleType):
  ///   km ≤ baseKm → base fare
  ///   km >  baseKm → base + (km − baseKm) × perKm
  static double calculate(double km, String? vehicleType) {
    final r = getRates(vehicleType);
    if (km <= r.baseKm) return r.base;
    return double.parse(
      (r.base + (km - r.baseKm) * r.perKm).toStringAsFixed(2),
    );
  }
}
