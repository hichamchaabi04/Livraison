import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final nomCompletCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool loading = false;
  bool _obscurePassword = true;

  void register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);

    final result = await ApiService.register(
      name: nomCompletCtrl.text,
      email: emailCtrl.text,
      password: passwordCtrl.text,
    );

    setState(() => loading = false);

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
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Icône livreur
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
                  const SizedBox(height: 8),
                  Text(
                    "Remplissez les informations ci-dessous",
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 28),

                  // Nom complet
                  TextFormField(
                    controller: nomCompletCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: "Nom complet",
                      hintText: "Ex: Ahmed Benali",
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.orange.shade800, width: 2),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Champ requis";
                      }
                      if (v.trim().split(' ').length < 2) {
                        return "Entrez votre nom et prénom";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      hintText: "exemple@email.com",
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.orange.shade800, width: 2),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Champ requis";
                      if (!v.contains("@") || !v.contains(".")) {
                        return "Email invalide";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Mot de passe
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Mot de passe",
                      hintText: "Min. 6 caractères",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.orange.shade800, width: 2),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return "Champ requis";
                      if (v.length < 6) return "Minimum 6 caractères";
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

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
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        "Créer le compte",
                        style: TextStyle(
                            fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lien vers login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Déjà un compte ?",
                          style: TextStyle(color: Colors.grey[600])),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Se connecter",
                          style: TextStyle(
                              color: Colors.orange[800],
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
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


