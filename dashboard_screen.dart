import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // On retire le Scaffold et l'AppBar pour l'intégrer dans le Drawer
    return Container(
      color: const Color(0xFFF5F6FA),
      child: Column(
        children: [
          // Header du Dashboard (Zone bleue)
          Container(
            padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
            color: Colors.blue,
            width: double.infinity,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.delivery_dining, size: 35, color: Colors.blue),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Bonjour, Hicham 👋",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      "Statut : En ligne",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  "Vos Statistiques",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                // Statistiques en colonne pour le menu
                _StatCard(title: "Livraisons", value: "8", icon: Icons.local_shipping),
                const SizedBox(height: 10),
                _StatCard(title: "Effectuées", value: "3", icon: Icons.check_circle),
                const SizedBox(height: 10),
                _StatCard(title: "Distance", value: "12 km", icon: Icons.map),

                const SizedBox(height: 30),

                const Text(
                  "Actions rapides",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),

                _ActionButton(
                  icon: Icons.list_alt,
                  text: "Voir les livraisons",
                  color: Colors.orange,
                  onTap: () {},
                ),
                _ActionButton(
                  icon: Icons.settings,
                  text: "Paramètres",
                  color: Colors.grey,
                  onTap: () {},
                ),

                const SizedBox(height: 20),
                // Bouton pour fermer le menu
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text("Fermer le menu", style: TextStyle(color: Colors.red)),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Les sous-widgets (StatCard et ActionButton) restent identiques mais adaptés ---

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _StatCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 15),
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.text, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 15),
              Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}