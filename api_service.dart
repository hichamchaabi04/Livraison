import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      "https://smeary-unmounting-kennedi.ngrok-free.dev/api"; // ✅ .dev corrigé

  static Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "ngrok-skip-browser-warning": "true",
  };

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

      // ✅ Log pour déboguer
      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      final data = _parseResponse(response);

      if (response.statusCode == 200) {
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

      print("STATUS: ${response.statusCode}");
      print("BODY: ${response.body}");

      final data = _parseResponse(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
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
  //  HELPER : parse JSON proprement
  // ══════════════════════════════════════════
  static Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      // ✅ Vérifie que la réponse contient bien du JSON (pas une page HTML ngrok)
      final contentType = response.headers["content-type"] ?? "";
      if (!contentType.contains("application/json")) {
        print("⚠️ Réponse non-JSON reçue : $contentType");
        print("BODY brut : ${response.body.substring(0, response.body.length.clamp(0, 300))}");
        return {"message": "Le serveur ngrok n'est pas joignable ou retourne du HTML. Vérifiez que le tunnel est actif."};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {"message": "Réponse serveur invalide"};
    }
  }
}