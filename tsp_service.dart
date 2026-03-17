import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
class TspService {
  static const String tspUrl = "https://smeary-unmounting-kennedi.ngrok-free.dev/api";
  static Future<List<int>> getOptimalOrder({
    required LatLng origin,
    required List<LatLng> destinations,
    String profile = "driving", // ✅ profil envoyé au TSP → transmis à OSRM
  }) async {
    try {
      final List<Map<String, double>> points = [
        // Index 0 = livreur
        {"lat": origin.latitude, "lng": origin.longitude},
        // Index 1, 2, 3... = destinations
        for (final d in destinations)
          {"lat": d.latitude, "lng": d.longitude},
      ];

      final response = await http.post(
        Uri.parse(tspUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "points": points,
          "profile": profile, // ✅ même profil que OSRM Flutter
        }),
      ).timeout(const Duration(seconds: 60)); // plus long car OSRM côté Python

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> rawOrder = data["order"];
        final List<int> order = rawOrder
            .map((e) => e as int)
            .where((i) => i != 0)  // retire le dépôt
            .map((i) => i - 1)     // décale les indices
            .toList();
        return order;
      } else {
        throw Exception("TSP erreur: ${response.statusCode}");
      }
    } catch (e) {
      // Fallback : ordre original
      return List.generate(destinations.length, (i) => i);
    }
  }
}
