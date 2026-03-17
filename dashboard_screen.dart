import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'trip_history_screen.dart';
class DashboardScreen extends StatefulWidget {
  // ✅ Reçoit les stats du MapScreen en temps réel
  final int totalStops;
  final int deliveredStops;
  final double totalDistance;   // en km
  final double totalDuration;   // en minutes
  final int? currentTripId;
  final String userName;

  const DashboardScreen({
    super.key,
    this.totalStops = 0,
    this.deliveredStops = 0,
    this.totalDistance = 0,
    this.totalDuration = 0,
    this.currentTripId,
    this.userName = "Livreur",
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  // ══════════════════════════════════════════
  //  DÉCONNEXION
  // ══════════════════════════════════════════
  void _logout() {
    ApiService.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Calcul progression
    final int remaining = widget.totalStops - widget.deliveredStops;
    final double progress = widget.totalStops > 0
        ? widget.deliveredStops / widget.totalStops
        : 0.0;

    // ✅ Formatage distance
    final String distanceText = widget.totalDistance > 0
        ? "${widget.totalDistance.toStringAsFixed(1)} km"
        : "—";

    // ✅ Formatage durée
    final String durationText = widget.totalDuration > 0
        ? "${widget.totalDuration.toStringAsFixed(0)} min"
        : "—";

    return Container(
      color: const Color(0xFFF5F6FA),
      child: Column(
        children: [

          // ══════════════════════════════════════════
          //  HEADER — nom + statut + trip actif
          // ══════════════════════════════════════════
          Container(
            padding: const EdgeInsets.only(
                top: 55, left: 20, right: 20, bottom: 20),
            color: Colors.blue[700],
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dans le header du dashboard — remplacez le Row du nom :
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delivery_dining,
                          size: 30, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Flexible(                              // ✅ AJOUT — évite overflow du nom
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Bonjour, ${widget.userName} 👋",
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,  // ✅ coupe si trop long
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.greenAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                "En ligne · Livreur",
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ✅ Trip actif badge
                if (widget.currentTripId != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_done,
                            size: 14, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(
                          "Trip #${widget.currentTripId} · En cours",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ══════════════════════════════════════════
          //  CONTENU SCROLLABLE
          // ══════════════════════════════════════════
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [

                // ── Titre section ──
                const Text(
                  "Statistiques du trip actuel",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 10),

                // ══════════════════════════════════════════
                //  GRILLE 4 CARDS
                // ══════════════════════════════════════════
                // ══════════════════════════════════════════
//  REMPLACEZ GridView.count par ceci
// ══════════════════════════════════════════
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: "Stations",
                        value: "${widget.totalStops}",
                        icon: Icons.place,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        title: "Livrées",
                        value: "${widget.deliveredStops}",
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: "Distance",
                        value: distanceText,
                        icon: Icons.route,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatCard(
                        title: "Durée est.",
                        value: durationText,
                        icon: Icons.access_time,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ══════════════════════════════════════════
                //  BARRE DE PROGRESSION
                // ══════════════════════════════════════════
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Progression",
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                          Text(
                            "${(progress * 100).toStringAsFixed(0)}%",
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue[700]!),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${widget.deliveredStops} livrées",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.green),
                          ),
                          Text(
                            "$remaining restantes",
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Titre section actions ──
                const Text(
                  "Actions",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 10),

                // ══════════════════════════════════════════
                //  BOUTON HISTORIQUE
                // ══════════════════════════════════════════
                _ActionButton(
                  icon: Icons.history,
                  text: "Historique des trips",
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context); // ferme le drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TripHistoryScreen(),
                      ),
                    );
                  },
                ),

                // ══════════════════════════════════════════
                //  BOUTON DÉCONNEXION
                // ══════════════════════════════════════════
                _ActionButton(
                  icon: Icons.logout,
                  text: "Déconnexion",
                  color: Colors.red,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Déconnexion"),
                        content: const Text(
                            "Voulez-vous vraiment vous déconnecter ?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("Annuler"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _logout();
                            },
                            child: const Text("Oui",
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                // ── Fermer le menu ──
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                  label: const Text("Fermer le menu",
                      style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
//  WIDGET STAT CARD
// ══════════════════════════════════════════
// ══════════════════════════════════════════
//  WIDGET STAT CARD — corrigé overflow
// ══════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // ✅ height fixe — jamais de overflow
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4)
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// ══════════════════════════════════════════
//  WIDGET ACTION BUTTON
// ══════════════════════════════════════════
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.text,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(text,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: color)),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }
}