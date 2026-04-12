import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsrmService {
  static Future<Map<String, dynamic>> getRoute(
      LatLng start,
      LatLng end,
      String profile,
      ) async {
    // OSRM ne supporte pas "foot" → on utilise "walking" via un autre endpoint
    // Pour la marche, on utilise le profil "foot" de l'instance publique OSRM
    String osrmProfile = profile;
    if (profile == "foot") osrmProfile = "foot";

    final url =
        "https://router.project-osrm.org/route/v1/$osrmProfile/"
        "${start.longitude},${start.latitude};"
        "${end.longitude},${end.latitude}"
        "?overview=full&geometries=geojson";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final route = data['routes'][0];

      double distance = route['distance'] / 1000;
      double duration = route['duration'] / 60;

      List coords = route['geometry']['coordinates'];
      List<LatLng> points = coords.map((c) => LatLng(c[1], c[0])).toList();

      return {
        "distance": distance,
        "duration": duration, // en minutes
        "points": points,
      };
    } else {
      throw Exception("Erreur OSRM: ${response.statusCode}");
    }
  }
}