import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://smeary-unmounting-kennedi.ngrok-free.dev/api";

  static Future<Map<String, dynamic>> register({
    required String nom,
    required String prenom,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/register");
    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: jsonEncode({
          "nom": nom,
          "prenom": prenom,
          "email": email,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": true,
          "message": data["message"] ?? "Inscription réussie"
        };
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Erreur serveur"
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Erreur connexion serveur"
      };
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/login");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          "success": true,
          "message": data["message"],
          "user": data["user"],
          "token": data["token"]
        };
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Email ou mot de passe incorrect"
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "Impossible de se connecter au serveur"
      };
    }
  }
}