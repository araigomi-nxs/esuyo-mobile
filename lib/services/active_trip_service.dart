import 'package:flutter/foundation.dart';
import '../models/route_model.dart';

class ActiveTripData {
  final String from;
  final String to;
  final double distanceKm;
  final double fare;
  final String vehicleType;
  final int estimatedMinutes;
  final DateTime startedAt;
  final RouteModel? route;

  ActiveTripData({
    required this.from,
    required this.to,
    required this.distanceKm,
    required this.fare,
    required this.vehicleType,
    required this.estimatedMinutes,
    this.route,
  }) : startedAt = DateTime.now();

  int get _totalMinutes =>
      estimatedMinutes > 0 ? estimatedMinutes : (distanceKm * 4).round().clamp(1, 120);

  double get progress {
    final elapsed = DateTime.now().difference(startedAt).inSeconds;
    final total = _totalMinutes * 60;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  double get kmLeft => (distanceKm * (1 - progress)).clamp(0, distanceKm);

  int get minutesLeft {
    final elapsed = DateTime.now().difference(startedAt).inMinutes;
    return (_totalMinutes - elapsed).clamp(0, _totalMinutes);
  }
}

class ActiveTripService extends ChangeNotifier {
  static final ActiveTripService instance = ActiveTripService._();
  ActiveTripService._();

  ActiveTripData? _trip;
  ActiveTripData? get trip => _trip;
  bool get hasActiveTrip => _trip != null;

  void startTrip(ActiveTripData data) {
    _trip = data;
    notifyListeners();
  }

  void endTrip() {
    _trip = null;
    notifyListeners();
  }
}
