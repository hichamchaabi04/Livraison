import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/osrm_service.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

// ══════════════════════════════════════════
//  MODEL STOP — enrichi avec station_id, client, phone
// ══════════════════════════════════════════
class DeliveryStop {
  final int? stationId;       // ✅ ID en base
  final String address;
  final LatLng latLng;
  final String clientName;
  final String phone;
  List<LatLng> routePoints;
  bool delivered;
  String distanceText;
  String durationText;
  String arrivalTime;
  double durationMinutes;

  DeliveryStop({
    this.stationId,
    required this.address,
    required this.latLng,
    this.clientName = "",
    this.phone = "",
    this.routePoints = const [],
    this.delivered = false,
    this.distanceText = "",
    this.durationText = "",
    this.arrivalTime = "",
    this.durationMinutes = 0,
  });

  DeliveryStop copyWith({
    int? stationId,
    String? address,
    LatLng? latLng,
    String? clientName,
    String? phone,
    List<LatLng>? routePoints,
    bool? delivered,
    String? distanceText,
    String? durationText,
    String? arrivalTime,
    double? durationMinutes,
  }) {
    return DeliveryStop(
      stationId: stationId ?? this.stationId,
      address: address ?? this.address,
      latLng: latLng ?? this.latLng,
      clientName: clientName ?? this.clientName,
      phone: phone ?? this.phone,
      routePoints: routePoints ?? this.routePoints,
      delivered: delivered ?? this.delivered,
      distanceText: distanceText ?? this.distanceText,
      durationText: durationText ?? this.durationText,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  LatLng? currentPosition;
  String selectedProfile = "driving";
  String selectedTransport = "car";
  MapController mapController = MapController();
  TextEditingController destinationController = TextEditingController();

  List<DeliveryStop> stops = [];
  bool isLoading = false;
  bool _showStopsList = true;

  // ✅ Trip courant en base
  int? currentTripId;

  final List<Color> routeColors = [
    Colors.blue, Colors.green, Colors.orange,
    Colors.purple, Colors.red, Colors.teal, Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  // ══════════════════════════════════════════
  //  GÉOLOCALISATION
  // ══════════════════════════════════════════
  Future<void> _getLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      currentPosition = LatLng(position.latitude, position.longitude);
    });
  }

  Future<LatLng> getLatLngFromAddress(String address) async {
    List<Location> locations = await locationFromAddress(address);
    return LatLng(locations.first.latitude, locations.first.longitude);
  }

  String _computeArrivalTime(double cumulativeMinutes) {
    final now = DateTime.now();
    final arrival = now.add(Duration(seconds: (cumulativeMinutes * 60).round()));
    final h = arrival.hour.toString().padLeft(2, '0');
    final m = arrival.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  // ══════════════════════════════════════════
  //  CRÉER OU RÉCUPÉRER LE TRIP EN BASE
  // ══════════════════════════════════════════
  Future<int?> _ensureTrip() async {
    if (currentTripId != null) return currentTripId;
    if (currentPosition == null) return null;

    final result = await ApiService.createTrip(
      vehicleType: selectedTransport,
      startLat: currentPosition!.latitude,
      startLng: currentPosition!.longitude,
    );

    if (result["success"] == true) {
      currentTripId = result["trip_id"] as int?;
      debugPrint("✅ Trip créé: $currentTripId");
      return currentTripId;
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur création trip: ${result['message']}"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  // ══════════════════════════════════════════
  //  FORMULAIRE AJOUT STATION
  //  Affiche bottomSheet avec champs client
  // ══════════════════════════════════════════
  void _showAddStationForm() {
    final formKey = GlobalKey<FormState>();
    final clientCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController(
        text: destinationController.text);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Titre ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_location_alt,
                          color: Colors.blue, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "Nouvelle station de livraison",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── Nom client ──
                TextFormField(
                  controller: clientCtrl,
                  decoration: InputDecoration(
                    labelText: "Nom du client *",
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? "Champ obligatoire" : null,
                ),
                const SizedBox(height: 12),

                // ── Téléphone ──
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Téléphone",
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Adresse ──
                TextFormField(
                  controller: addressCtrl,
                  decoration: InputDecoration(
                    labelText: "Adresse *",
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? "Champ obligatoire" : null,
                ),
                const SizedBox(height: 20),

                // ── Bouton Ajouter ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      "Ajouter la station",
                      style: TextStyle(fontSize: 15, color: Colors.white),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.pop(ctx); // ferme le bottom sheet
                      await _addDestination(
                        address: addressCtrl.text.trim(),
                        clientName: clientCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  //  AJOUTER UNE DESTINATION + STATION EN BASE
  // ══════════════════════════════════════════
  Future<void> _addDestination({
    required String address,
    required String clientName,
    String phone = "",
  }) async {
    if (address.trim().isEmpty) return;
    setState(() => isLoading = true);

    try {
      // 1. Géocoder l'adresse
      LatLng latLng = await getLatLngFromAddress(address);

      // 2. Créer le trip si pas encore fait
      final tripId = await _ensureTrip();
      if (tripId == null) {
        setState(() => isLoading = false);
        return;
      }

      // 3. Sauvegarder la station en base
      final stationResult = await ApiService.addStation(
        tripId: tripId,
        clientName: clientName,
        phone: phone,
        address: address,
        lat: latLng.latitude,
        lng: latLng.longitude,
        visitOrder: stops.length + 1,
      );

      int? stationId;
      if (stationResult["success"] == true) {
        stationId = stationResult["station_id"] as int?;
        debugPrint("✅ Station ajoutée ID: $stationId");
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("⚠️ Station non sauvegardée: ${stationResult['message']}"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }

      // 4. Ajouter localement et calculer routes
      stops.add(DeliveryStop(
        stationId: stationId,
        address: address,
        latLng: latLng,
        clientName: clientName,
        phone: phone,
      ));

      destinationController.clear();
      _showStopsList = true;

      // 5. Optimiser via TSP backend si trip existe
      if (tripId != null && stops.length >= 2) {
        await _optimizeWithTsp(tripId);
      } else {
        await _calculateAllRoutes();
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Adresse introuvable: $address")),
        );
      }
    }
  }



  // ══════════════════════════════════════════
  //  OPTIMISATION TSP VIA BACKEND
  //  Appelle /api/trips/{id}/optimize
  //  Réorganise stops selon l'ordre retourné
  // ══════════════════════════════════════════



  Future<void> _optimizeWithTsp(int tripId) async {
    setState(() => isLoading = true);

    final result = await ApiService.optimizeTrip(
      tripId: tripId,
      profile: selectedProfile,
    );

    if (result["success"] == true) {
      final List<dynamic> orderedStations = result["stations"] ?? [];

      if (orderedStations.isNotEmpty) {
        // Réorganise les stops selon l'ordre TSP
        List<DeliveryStop> reordered = [];
        for (final s in orderedStations) {
          final id = s["id"];
          final found = stops.firstWhere(
                (stop) => stop.stationId == id,
            orElse: () => stops.firstWhere(
                  (stop) =>
              (stop.latLng.latitude - (s["lat"] as num).toDouble()).abs() < 0.0001,
              orElse: () => stops.first,
            ),
          );
          reordered.add(found);
        }

        // Ajoute les stops sans station_id à la fin
        for (final stop in stops) {
          if (!reordered.any((r) => r.stationId == stop.stationId &&
              stop.stationId != null)) {
            if (!reordered.contains(stop)) reordered.add(stop);
          }
        }

        stops = reordered;
        debugPrint("✅ Stops réorganisés par TSP: ${stops.map((s) => s.address)}");
      }
    } else {
      debugPrint("⚠️ TSP échoué: ${result['message']} — ordre original conservé");
    }

    // Calcule les routes dans le nouvel ordre
    await _calculateAllRoutes();
  }

  // ══════════════════════════════════════════
  //  CALCUL ROUTES OSRM (chaîne)
  // ══════════════════════════════════════════
  Future<void> _calculateAllRoutes() async {
    if (stops.isEmpty || currentPosition == null) {
      setState(() => isLoading = false);
      return;
    }
    setState(() => isLoading = true);

    LatLng fromPoint = currentPosition!;
    double cumulativeMinutes = 0;

    for (int i = 0; i < stops.length; i++) {
      if (stops[i].delivered) continue;
      try {
        final result = await OsrmService.getRoute(
            fromPoint, stops[i].latLng, selectedProfile);

        double dur = result["duration"];
        cumulativeMinutes += dur;

        stops[i] = stops[i].copyWith(
          routePoints: result["points"],
          distanceText: "${result["distance"].toStringAsFixed(2)} km",
          durationText: "${dur.toStringAsFixed(0)} min",
          arrivalTime: _computeArrivalTime(cumulativeMinutes),
          durationMinutes: dur,
        );

        fromPoint = stops[i].latLng;
      } catch (e) {
        debugPrint("Erreur OSRM: $e");
      }
    }

    setState(() => isLoading = false);
    _fitAllRoutes();
  }

  void _fitAllRoutes() {
    List<LatLng> allPoints = [if (currentPosition != null) currentPosition!];
    for (var stop in stops) {
      allPoints.addAll(stop.routePoints);
    }
    if (allPoints.length > 1) {
      mapController.fitCamera(CameraFit.coordinates(
          coordinates: allPoints, padding: const EdgeInsets.all(50)));
    }
  }

  // ══════════════════════════════════════════
  //  MARQUER LIVRÉ — met à jour en base aussi
  // ══════════════════════════════════════════
  void _markDelivered(int index) async {
    // Mise à jour locale
    setState(() {
      stops[index] = stops[index].copyWith(
        routePoints: [],
        delivered: true,
        arrivalTime: "",
        durationMinutes: 0,
      );
    });

    // Mise à jour en base si station_id disponible
    final stationId = stops[index].stationId;
    if (stationId != null) {
      final result = await ApiService.updateStationStatus(
        stationId: stationId,
        status: "delivered",
      );
      if (result["success"] == true) {
        debugPrint("✅ Station $stationId marquée livrée");
      } else {
        debugPrint("⚠️ Erreur update statut: ${result['message']}");
      }
    }

    await _calculateAllRoutes();
  }

  void _removeStop(int index) async {
    setState(() => stops.removeAt(index));
    await _calculateAllRoutes();
  }

  // ══════════════════════════════════════════
  //  BOUTON TRANSPORT
  // ══════════════════════════════════════════
  Widget _transportButton(String transport, IconData icon, String label) {
    final bool selected = selectedTransport == transport;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTransport = transport;
          switch (transport) {
            case "car":
              selectedProfile = "driving";
              break;
            case "motor":
              selectedProfile = "cycling";
              break;
            case "foot":
              selectedProfile = "foot";
              break;
          }
          // ✅ Réinitialise le trip si transport change
          currentTripId = null;
        });
        _calculateAllRoutes();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? Colors.blue : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? Colors.blue : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected ? Colors.white : Colors.grey, size: 18),
            const SizedBox(width: 3),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<int> activeIndexes = [];
    for (int i = 0; i < stops.length; i++) {
      if (!stops[i].delivered) activeIndexes.add(i);
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        width: 300,
        child: DashboardScreen(
          totalStops: stops.length,
          deliveredStops: stops.where((s) => s.delivered).length,
          totalDistance: stops.fold(0.0, (sum, s) {
            if (s.distanceText.isEmpty) return sum;
            return sum + (double.tryParse(
                s.distanceText.replaceAll(' km', '')) ?? 0);
          }),
          totalDuration: stops.fold(0.0, (sum, s) => sum + s.durationMinutes),
          currentTripId: currentTripId,
          userName: ApiService.userName,  // ✅ vrai nom
        ),
      ),
      body: currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [

          // ════════════════════════
          //  🗺️ CARTE
          // ════════════════════════
          FlutterMap(
            mapController: mapController,
            options: MapOptions(center: currentPosition!, zoom: 15),
            children: [
              TileLayer(
                urlTemplate:
                "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: 'com.example.gestion_livraison',
              ),
              PolylineLayer(
                polylines: [
                  for (int i = 0; i < activeIndexes.length; i++)
                    if (stops[activeIndexes[i]].routePoints.isNotEmpty)
                      Polyline(
                        points: stops[activeIndexes[i]].routePoints,
                        strokeWidth: 4,
                        color: routeColors[i % routeColors.length],
                      ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentPosition!,
                    width: 50,
                    height: 50,
                    child: const Icon(Icons.location_pin,
                        color: Colors.red, size: 50),
                  ),
                  for (int i = 0; i < activeIndexes.length; i++)
                    Marker(
                      point: stops[activeIndexes[i]].latLng,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: routeColors[i % routeColors.length],
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            "${i + 1}",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ════════════════════════
          //  🍔 BOUTON MENU
          // ════════════════════════
          Positioned(
            top: 50,
            left: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              child: const Icon(Icons.menu, color: Colors.black),
            ),
          ),

          // ════════════════════════════════════════
          //  🔍 BARRE RECHERCHE + LISTE STOPS
          // ════════════════════════════════════════
          Positioned(
            top: 110,
            left: 15,
            right: 15,
            child: Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: destinationController,
                            decoration: const InputDecoration(
                              hintText: "Entrer une adresse...",
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _showAddStationForm(),
                          ),
                        ),
                        // ── Toggle liste ──
                        if (activeIndexes.isNotEmpty)
                          GestureDetector(
                            onTap: () => setState(
                                    () => _showStopsList = !_showStopsList),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: _showStopsList
                                    ? Colors.blue.shade50
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _showStopsList
                                      ? Colors.blue
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _showStopsList
                                        ? Icons.visibility_off
                                        : Icons.list_alt,
                                    color: _showStopsList
                                        ? Colors.blue
                                        : Colors.grey,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${activeIndexes.length}",
                                    style: TextStyle(
                                      color: _showStopsList
                                          ? Colors.blue
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // ── Bouton + ouvre le formulaire ──
                        isLoading
                            ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2))
                            : IconButton(
                          icon: const Icon(Icons.add,
                              color: Colors.blue),
                          onPressed: _showAddStationForm,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── LISTE DES STOPS ──
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) =>
                      SizeTransition(
                          sizeFactor: animation, child: child),
                  child: _showStopsList && activeIndexes.isNotEmpty
                      ? Card(
                    key: const ValueKey("stopsList"),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics:
                      const NeverScrollableScrollPhysics(),
                      itemCount: activeIndexes.length,
                      separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final stop = stops[activeIndexes[i]];
                        final color =
                        routeColors[i % routeColors.length];
                        return ListTile(
                          dense: true,
                          leading: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle),
                            child: Center(
                              child: Text("${i + 1}",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                          ),
                          title: Text(
                            stop.clientName.isNotEmpty
                                ? stop.clientName
                                : stop.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              // ✅ Adresse
                              Text(
                                stop.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600]),
                              ),
                              // ✅ Téléphone si présent
                              if (stop.phone.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.phone,
                                        size: 11,
                                        color: Colors.grey),
                                    const SizedBox(width: 3),
                                    Text(
                                      stop.phone,
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              // ✅ Distance + durée
                              if (stop.distanceText.isNotEmpty)
                                Text(
                                  "${stop.distanceText} · ${stop.durationText}",
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500]),
                                ),
                              // ✅ Heure d'arrivée
                              if (stop.arrivalTime.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.access_time,
                                        size: 12,
                                        color: Colors.blueAccent),
                                    const SizedBox(width: 3),
                                    Text(
                                      "Arrivée : ${stop.arrivalTime}",
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.blueAccent,
                                          fontWeight:
                                          FontWeight.w600),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton.icon(
                                onPressed: () => _markDelivered(
                                    activeIndexes[i]),
                                icon: const Icon(Icons.check_circle,
                                    color: Colors.green, size: 18),
                                label: const Text("Livré",
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 12)),
                                style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize:
                                    const Size(60, 30)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.red, size: 18),
                                onPressed: () =>
                                    _removeStop(activeIndexes[i]),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                      : const SizedBox.shrink(
                      key: ValueKey("hidden")),
                ),
              ],
            ),
          ),

          // ════════════════════════════════════════
          //  🚗 TRANSPORT + RÉSUMÉ
          // ════════════════════════════════════════
          Positioned(
            bottom: 20,
            left: 15,
            right: 15,
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _transportButton(
                              "car", Icons.directions_car, "Voiture"),
                          const SizedBox(width: 4),
                          _transportButton(
                              "motor", Icons.motorcycle, "Moto"),
                          const SizedBox(width: 4),
                          _transportButton(
                              "foot", Icons.directions_walk, "Pied"),
                        ],
                      ),
                    ),
                    if (stops.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${stops.where((s) => s.delivered).length}/${stops.length} livrés",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                          Text(
                            "${activeIndexes.length} restant(s)",
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 11),
                          ),
                          // ✅ Indicateur trip sauvegardé
                          if (currentTripId != null)
                            Row(
                              children: [
                                const Icon(Icons.cloud_done,
                                    size: 11, color: Colors.green),
                                const SizedBox(width: 3),
                                Text(
                                  "Trip #$currentTripId",
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.green),
                                ),
                              ],
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}