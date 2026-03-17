import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  List<dynamic> trips = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  // ══════════════════════════════════════════
  //  CHARGER LES TRIPS DEPUIS L'API
  // ══════════════════════════════════════════
  Future<void> _loadTrips() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await ApiService.getTrips();

    setState(() {
      isLoading = false;
      if (result["success"] == true) {
        trips = result["trips"] ?? [];
        // ✅ Trier par date décroissante (plus récent en premier)
        trips.sort((a, b) {
          final dateA = DateTime.tryParse(a["created_at"] ?? "") ?? DateTime(0);
          final dateB = DateTime.tryParse(b["created_at"] ?? "") ?? DateTime(0);
          return dateB.compareTo(dateA);
        });
      } else {
        errorMessage = result["message"];
      }
    });
  }

  // ══════════════════════════════════════════
  //  FORMATER LA DATE
  // ══════════════════════════════════════════
  String _formatDate(String? dateStr) {
    if (dateStr == null) return "—";
    final date = DateTime.tryParse(dateStr);
    if (date == null) return "—";
    final local = date.toLocal();
    return "${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}  ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}";
  }

  // ══════════════════════════════════════════
  //  COULEUR ET LABEL DU STATUT
  // ══════════════════════════════════════════
  Color _statusColor(String? status) {
    switch (status) {
      case "completed": return Colors.green;
      case "optimized": return Colors.blue;
      case "pending":   return Colors.orange;
      default:          return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case "completed": return "Terminé";
      case "optimized": return "Optimisé";
      case "pending":   return "En attente";
      default:          return status ?? "—";
    }
  }

  IconData _vehicleIcon(String? type) {
    switch (type) {
      case "driving": return Icons.directions_car;
      case "cycling": return Icons.motorcycle;
      case "walking": return Icons.directions_walk;
      default:        return Icons.local_shipping;
    }
  }

  String _vehicleLabel(String? type) {
    switch (type) {
      case "driving": return "Voiture";
      case "cycling": return "Moto";
      case "walking": return "Pied";
      default:        return type ?? "—";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        title: const Text(
          "Historique des trips",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrips,
            tooltip: "Actualiser",
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _buildError()
          : trips.isEmpty
          ? _buildEmpty()
          : _buildTripList(),
    );
  }

  // ══════════════════════════════════════════
  //  ÉTAT ERREUR
  // ══════════════════════════════════════════
  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? "Erreur inconnue",
            style: const TextStyle(color: Colors.red, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadTrips,
            icon: const Icon(Icons.refresh),
            label: const Text("Réessayer"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  //  ÉTAT VIDE
  // ══════════════════════════════════════════
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Aucun trip trouvé",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Vos trips apparaîtront ici",
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  //  LISTE DES TRIPS
  // ══════════════════════════════════════════
  Widget _buildTripList() {
    return RefreshIndicator(
      onRefresh: _loadTrips,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return _buildTripCard(trip, index);
        },
      ),
    );
  }

  // ══════════════════════════════════════════
  //  CARTE D'UN TRIP
  // ══════════════════════════════════════════
  Widget _buildTripCard(Map<String, dynamic> trip, int index) {
    final status = trip["status"] as String?;
    final statusColor = _statusColor(status);
    final vehicleType = trip["vehicle_type"] as String?;
    final stations = trip["stations"] as List? ?? [];

    // ✅ Calcul stats
    final int totalStations = stations.length;
    final int deliveredStations = stations
        .where((s) => s["status"] == "delivered")
        .length;

    // ✅ Distance et durée depuis le backend
    final double? totalDistance = double.tryParse(
        trip["total_distance"]?.toString() ?? "");
    final double? totalTime = double.tryParse(
        trip["total_time"]?.toString() ?? "");

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // ── Header carte ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
              border: Border(
                left: BorderSide(color: statusColor, width: 4),
              ),
            ),
            child: Row(
              children: [
                // Numéro trip
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      "#${trip["id"]}",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Trip du ${_formatDate(trip["created_at"])}",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(_vehicleIcon(vehicleType),
                              size: 13, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            _vehicleLabel(vehicleType),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Badge statut
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Stats du trip ──
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _TripStat(
                  icon: Icons.place,
                  label: "Stations",
                  value: "$totalStations",
                  color: Colors.blue,
                ),
                _divider(),
                _TripStat(
                  icon: Icons.check_circle,
                  label: "Livrées",
                  value: "$deliveredStations",
                  color: Colors.green,
                ),
                _divider(),
                _TripStat(
                  icon: Icons.route,
                  label: "Distance",
                  value: totalDistance != null
                      ? "${(totalDistance / 1000).toStringAsFixed(1)} km"
                      : "—",
                  color: Colors.orange,
                ),
                _divider(),
                _TripStat(
                  icon: Icons.access_time,
                  label: "Durée",
                  value: totalTime != null
                      ? "${(totalTime / 60).toStringAsFixed(0)} min"
                      : "—",
                  color: Colors.purple,
                ),
              ],
            ),
          ),

          // ── Liste des stations ──
          if (stations.isNotEmpty) ...[
            const Divider(height: 1),
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 0),
              title: Text(
                "Voir les stations ($totalStations)",
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
              children: [
                ...stations.map((station) =>
                    _buildStationTile(station)).toList(),
                const SizedBox(height: 8),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider() => Container(
    width: 1,
    height: 30,
    color: Colors.grey[200],
    margin: const EdgeInsets.symmetric(horizontal: 8),
  );

  // ══════════════════════════════════════════
  //  TUILE D'UNE STATION
  // ══════════════════════════════════════════
  Widget _buildStationTile(Map<String, dynamic> station) {
    final status = station["status"] as String?;
    final isDelivered = status == "delivered";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Numéro ordre
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: isDelivered
                  ? Colors.green.withOpacity(0.15)
                  : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "${station["visit_order"] ?? "?"}",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDelivered ? Colors.green : Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station["client_name"] ?? "—",
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (station["address"] != null)
                  Text(
                    station["address"],
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (station["phone"] != null)
                  Row(
                    children: [
                      const Icon(Icons.phone,
                          size: 10, color: Colors.grey),
                      const SizedBox(width: 3),
                      Text(
                        station["phone"],
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Badge statut station
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDelivered
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isDelivered ? "Livré" : "En attente",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDelivered ? Colors.green : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
//  WIDGET STAT D'UN TRIP
// ══════════════════════════════════════════
class _TripStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TripStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}