import 'dart:math';
import '../models/landmark_model.dart';

class LocationService {
  // Calculate distance between two coordinates using Haversine formula
  static double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371; // km
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  // Get nearby landmarks for a given location
  static List<LandmarkModel> getNearbyLandmarks(
    double lat,
    double lng,
    List<LandmarkModel> allLandmarks, {
    double radiusKm = 0.2, // 200 meters
    int maxResults = 2,
  }) {
    if (allLandmarks.isEmpty) return [];

    final nearby =
        allLandmarks
            .map((landmark) {
              final distKm = calculateDistance(
                lat,
                lng,
                landmark.lat,
                landmark.lng,
              );
              return MapEntry(landmark, distKm);
            })
            .where((entry) => entry.value <= radiusKm)
            .toList()
          ..sort((a, b) => a.value.compareTo(b.value));

    return nearby.take(maxResults).map((e) => e.key).toList();
  }

  // Convert distance in km to meters for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 0.001) return '0m';
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)}m';
    }
    return '${distanceKm.toStringAsFixed(2)}km';
  }
}
