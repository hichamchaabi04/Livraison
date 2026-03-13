import '../models/delivery_point.dart';
import 'dart:math';

class TspService {
  static double distance(
      double lat1, double lon1, double lat2, double lon2) {
    const r = 6371; // rayon terre (km)
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _deg2rad(double deg) => deg * pi / 180;

  /// 🔥 Nearest Neighbor
  static List<DeliveryPoint> optimize(
      DeliveryPoint start, List<DeliveryPoint> points) {
    final remaining = List<DeliveryPoint>.from(points);
    final result = <DeliveryPoint>[start];

    var current = start;

    while (remaining.isNotEmpty) {
      remaining.sort((a, b) =>
          distance(current.lat, current.lng, a.lat, a.lng)
              .compareTo(
              distance(current.lat, current.lng, b.lat, b.lng)));

      current = remaining.removeAt(0);
      result.add(current);
    }

    return result;
  }
}
