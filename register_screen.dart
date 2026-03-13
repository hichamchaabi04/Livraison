import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  // relation entre la coque et logique de I
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ce que ça correct
  final _formKey = GlobalKey<FormState>();
  // récupère ce que je taper
  final nomCtrl = TextEditingController();
  final prenomCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  // pour button
  bool loading = false;
// Fonction appelée quand on clique sur Créer le compte
  void register() async {
    // les roles des infos
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
// envoie les donnée vers laravel (backend)
    final result = await ApiService.register(
      nom: nomCtrl.text,
      prenom: prenomCtrl.text,
      email: emailCtrl.text,
      password: passwordCtrl.text,
    );
    // fin de chargement
    setState(() => loading = false);
// Compte créé ou Erreur
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(result['message'] ?? 'Erreur')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15)],
            ),
            // Lie tous les champs à la validation
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Icône de livreur
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.orange[100],
                    child: Icon(
                      Icons.delivery_dining,
                      size: 50,
                      color: Colors.orange[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Créer un compte livreur",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Récupère le texte et Empêche champ vide


                  // Nom
                  TextFormField(
                    controller: nomCtrl,
                    decoration: InputDecoration(
                      labelText: "Nom",
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? "Champ requis" : null,
                  ),
                  const SizedBox(height: 12),

                  // Prénom
                  TextFormField(
                    controller: prenomCtrl,
                    decoration: InputDecoration(
                      labelText: "Prénom",
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? "Champ requis" : null,
                  ),
                  const SizedBox(height: 12),

                  // Email
                  TextFormField(
                    controller: emailCtrl,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => v!.contains("@") ? null : "Email invalide",
                  ),
                  const SizedBox(height: 12),

                  // Mot de passe
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Mot de passe",
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) => v!.length < 6 ? "Min 6 caractères" : null,
                  ),
                  const SizedBox(height: 24),

                  // Bouton créer compte
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.orange[800],
                        shadowColor: Colors.orange[200],
                        elevation: 5,
                      ),
                      onPressed: loading ? null : register,
                      child: loading
                          ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                          : const Text(
                        "Créer le compte",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
