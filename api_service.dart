import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      "https://smeary-unmounting-kennedi.ngrok-free.dev/api";

  static String _authToken = "";

  // ════════════════════════════════════════
  //  ✅ AJOUT — nom utilisateur en mémoire
  // ════════════════════════════════════════
  static String _userName = "Livreur";

  static void setToken(String token) {
    _authToken = token;
    debugPrint("✅ Token sauvegardé: $token");
  }

  static void setUserName(String name) {
    _userName = name;
    debugPrint("✅ UserName sauvegardé: $name");
  }

  static String get userName => _userName;

  static Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "ngrok-skip-browser-warning": "true",
    if (_authToken.isNotEmpty) "Authorization": "Bearer $_authToken",
  };

  // ══════════════════════════════════════════
  //  INSCRIPTION
  // ══════════════════════════════════════════
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/register");
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "password_confirmation": password,
        }),
      ).timeout(const Duration(seconds: 15));

      debugPrint("REGISTER STATUS: ${response.statusCode}");
      debugPrint("REGISTER BODY: ${response.body}");

      final data = _parseResponse(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data["token"] != null) {
          _authToken = data["token"];
        }
        // ✅ Sauvegarde nom à l'inscription aussi
        if (data["user"] != null && data["user"]["name"] != null) {
          _userName = data["user"]["name"];
        }
        return {
          "success": true,
          "message": data["message"] ?? "Inscription réussie",
          "token": data["token"],
          "user": data["user"],
        };
      } else {
        if (response.statusCode == 422) {
          final errors = data["errors"] as Map<String, dynamic>?;
          String errorMsg = "Erreur de validation";
          if (errors != null && errors.isNotEmpty) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              errorMsg = firstError.first.toString();
            }
          }
          return {"success": false, "message": errorMsg};
        }
        return {
          "success": false,
          "message": data["message"] ?? "Erreur serveur (${response.statusCode})",
        };
      }
    } on http.ClientException catch (e) {
      return {"success": false, "message": "Erreur réseau : ${e.message}"};
    } catch (e) {
      return {"success": false, "message": "Erreur connexion : $e"};
    }
  }

  // ══════════════════════════════════════════
  //  CONNEXION
  // ══════════════════════════════════════════
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/login");
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      ).timeout(const Duration(seconds: 15));

      debugPrint("LOGIN STATUS: ${response.statusCode}");
      debugPrint("LOGIN BODY: ${response.body}");

      final data = _parseResponse(response);

      if (response.statusCode == 200) {
        if (data["token"] != null) {
          _authToken = data["token"];
        }
        // ✅ AJOUT — sauvegarde du nom automatiquement dans login()
        if (data["user"] != null && data["user"]["name"] != null) {
          _userName = data["user"]["name"];
          debugPrint("✅ Nom sauvegardé: $_userName");
        }
        return {
          "success": true,
          "message": data["message"] ?? "Connexion réussie",
          "token": data["token"],
          "user": data["user"],
        };
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Email ou mot de passe incorrect",
        };
      }
    } on http.ClientException catch (e) {
      return {"success": false, "message": "Erreur réseau : ${e.message}"};
    } catch (e) {
      return {"success": false, "message": "Erreur connexion : $e"};
    }
  }

  // ══════════════════════════════════════════
  //  DÉCONNEXION
  // ══════════════════════════════════════════
  static void logout() {
    _authToken = "";
    _userName = "Livreur"; // ✅ reset aussi le nom
  }

  // ══════════════════════════════════════════
  //  CRÉER UN TRIP
  // ══════════════════════════════════════════
  static Future<Map<String, dynamic>> createTrip({
    required String vehicleType,
    required double startLat,
    required double startLng,
  }) async {
    final url = Uri.parse("$baseUrl/trips");

    final Map<String, String> vehicleMap = {
      "car":   "driving",
      "motor": "cycling",
      "foot":  "walking",
    };
    final String mappedVehicle = vehicleMap[vehicleType] ?? "driving";

    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "vehicle_type": mappedVehicle,
          "start_lat": startLat,
          "start_lng": startLng,
          "status": "pending",
        }),
      ).timeout(const Duration(seconds: 15));

      debugPrint("CREATE TRIP STATUS: ${response.statusCode}");
      debugPrint("CREATE TRIP BODY: ${response.body}");

      final data = _parseResponse(response);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": true,
          "trip_id": data["trip"]?["id"] ?? data["id"],
          "message": data["message"] ?? "Trip créé",
        };
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Erreur création trip",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Erreur: $e"};
    }
  }

  // ══════════════════════════════════════════
  //  AJOUTER UNE STATION
  // ══════════════════════════════════════════
  static Future<Map<String, dynamic>> addStation({
    required int tripId,
    required String clientName,
    required String phone,
    required String address,
    required double lat,
    required double lng,
    int? visitOrder,
  }) async {
    final url = Uri.parse("$baseUrl/trips/$tripId/stations");
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "client_name": clientName,
          "phone": phone.isNotEmpty ? phone : null,
          "address": address,
          "lat": lat,
          "lng": lng,
          "status": "pending",
          if (visitOrder != null) "visit_order": visitOrder,
        }),
      ).timeout(const Duration(seconds: 15));

      debugPrint("ADD STATION STATUS: ${response.statusCode}");
      debugPrint("ADD STATION BODY: ${response.body}");

      final data = _parseResponse(response);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": true,
          "station_id": data["station"]?["id"] ?? data["id"],
          "message": data["message"] ?? "Station ajoutée",
        };
      } else {
        // ✅ Message clair si téléphone dupliqué
        final message = data["message"] ?? "";
        if (message.contains("Duplicate entry") &&
            message.contains("phone")) {
          return {
            "success": false,
            "message": "Ce numéro de téléphone est déjà utilisé",
          };
        }
        return {
          "success": false,
          "message": data["message"] ?? "Erreur ajout station",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Erreur: $e"};
    }
  }

  // ══════════════════════════════════════════
  //  OPTIMISER LE TRIP (TSP)
  // ══════════════════════════════════════════
  static Future<Map<String, dynamic>> optimizeTrip({
    required int tripId,
    required String profile,
  }) async {
    final url = Uri.parse("$baseUrl/trips/$tripId/optimize");
    try {
      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({"profile": profile}),
      ).timeout(const Duration(seconds: 60));

      debugPrint("OPTIMIZE STATUS: ${response.statusCode}");
      debugPrint("OPTIMIZE BODY: ${response.body}");

      final data = _parseResponse(response);
      if (response.statusCode == 200) {
        return {
          "success": true,
          "stations": data["stations"] ?? [],
          "order": data["order"] ?? [],
          "message": data["message"] ?? "Optimisé",
        };
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Erreur optimisation TSP",
        };
      }
    } catch (e) {
      return {"success": false, "message": "Erreur TSP: $e"};
    }
  }

  // ══════════════════════════════════════════
  //  METTRE À JOUR STATUT STATION
  // ══════════════════════════════════════════
  static Future<Map<String, dynamic>> updateStationStatus({
    required int stationId,
    required String status,
  }) async {
    final url = Uri.parse("$baseUrl/stations/$stationId/status");
    try {
      final response = await http.patch(
        url,
        headers: _headers,
        body: jsonEncode({"status": status}),
      ).timeout(const Duration(seconds: 15));

      final data = _parseResponse(response);
      return {
        "success": response.statusCode == 200,
        "message": data["message"] ?? "Statut mis à jour",
      };
    } catch (e) {
      return {"success": false, "message": "Erreur: $e"};
    }
  }

  // ══════════════════════════════════════════
  //  HELPER
  // ══════════════════════════════════════════
  static Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      final contentType = response.headers["content-type"] ?? "";
      if (!contentType.contains("application/json")) {
        debugPrint("⚠️ Réponse non-JSON: $contentType");
        debugPrint(
            "BODY: ${response.body.substring(0, response.body.length.clamp(0, 300))}");
        return {
          "message": "Serveur ngrok non joignable ou retourne du HTML."
        };
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {"message": "Réponse serveur invalide"};
    }
  }
  // ══════════════════════════════════════════
//  RÉCUPÉRER HISTORIQUE TRIPS + STATIONS
//  GET /api/trips/history  ✅ endpoint correct
// ══════════════════════════════════════════
  static Future<Map<String, dynamic>> getTrips() async {
    final url = Uri.parse("$baseUrl/trips/history"); // ✅ /history au lieu de /trips
    try {
      final response = await http.get(
        url,
        headers: _headers,
      ).timeout(const Duration(seconds: 15));

      debugPrint("GET HISTORY STATUS: ${response.statusCode}");
      debugPrint("GET HISTORY BODY: ${response.body}");

      final data = _parseResponse(response);
      if (response.statusCode == 200) {
// ✅ Laravel paginate retourne { data: [...], total, ... }
        return {
          "success": true,
          "trips": data["data"] ?? [],
        };
      }
      return {"success": false, "message": data["message"] ?? "Erreur"};
    } catch (e) {
      return {"success": false, "message": "Erreur: $e"};
    }
  }
}

