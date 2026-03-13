import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/osrm_service.dart';
import 'dashboard_screen.dart';

class DeliveryStop {
  final String address;
  final LatLng latLng;
  List<LatLng> routePoints;
  bool delivered;
  String distanceText;
  String durationText;
  String arrivalTime;
  double durationMinutes;

  DeliveryStop({
    required this.address,
    required this.latLng,
    this.routePoints = const [],
    this.delivered = false,
    this.distanceText = "",
    this.durationText = "",
    this.arrivalTime = "",
    this.durationMinutes = 0,
  });
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
  bool _showStopsList = true; // ✅ Toggle liste

  final List<Color> routeColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

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

  double _haversineDistance(LatLng a, LatLng b) {
    const Distance distance = Distance();
    return distance(a, b);
  }

  List<DeliveryStop> _sortByProximity(List<DeliveryStop> unsorted) {
    if (unsorted.isEmpty) return [];
    List<DeliveryStop> remaining = List.from(unsorted);
    List<DeliveryStop> sorted = [];
    LatLng current = currentPosition!;

    while (remaining.isNotEmpty) {
      remaining.sort((a, b) => _haversineDistance(current, a.latLng)
          .compareTo(_haversineDistance(current, b.latLng)));
      sorted.add(remaining.first);
      current = remaining.first.latLng;
      remaining.removeAt(0);
    }
    return sorted;
  }

  String _computeArrivalTime(double cumulativeMinutes) {
    final now = DateTime.now();
    final arrival =
    now.add(Duration(seconds: (cumulativeMinutes * 60).round()));
    final h = arrival.hour.toString().padLeft(2, '0');
    final m = arrival.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  Future<void> _calculateAllRoutes() async {
    if (stops.isEmpty || currentPosition == null) return;
    setState(() => isLoading = true);

    List<DeliveryStop> sorted =
    _sortByProximity(stops.where((s) => !s.delivered).toList());
    List<DeliveryStop> delivered =
    stops.where((s) => s.delivered).toList();
    stops = [...delivered, ...sorted];

    LatLng fromPoint = currentPosition!;
    double cumulativeMinutes = 0;

    for (int i = 0; i < stops.length; i++) {
      if (stops[i].delivered) continue;
      try {
        final result = await OsrmService.getRoute(
            fromPoint, stops[i].latLng, selectedProfile);

        double dur = result["duration"];
        cumulativeMinutes += dur;
        String arrival = _computeArrivalTime(cumulativeMinutes);

        stops[i] = DeliveryStop(
          address: stops[i].address,
          latLng: stops[i].latLng,
          routePoints: result["points"],
          delivered: false,
          distanceText: "${result["distance"].toStringAsFixed(2)} km",
          durationText: "${dur.toStringAsFixed(0)} min",
          arrivalTime: arrival,
          durationMinutes: dur,
        );
        fromPoint = stops[i].latLng;
      } catch (e) {
        debugPrint("Erreur calcul route: $e");
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

  Future<void> _addDestination(String address) async {
    if (address.trim().isEmpty) return;
    setState(() => isLoading = true);
    try {
      LatLng latLng = await getLatLngFromAddress(address);
      stops.add(DeliveryStop(address: address, latLng: latLng));
      destinationController.clear();
      _showStopsList = true; // ✅ Auto-affiche la liste à l'ajout
      await _calculateAllRoutes();
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Adresse introuvable: $address")),
        );
      }
    }
  }

  void _markDelivered(int index) async {
    setState(() {
      stops[index] = DeliveryStop(
        address: stops[index].address,
        latLng: stops[index].latLng,
        routePoints: [],
        delivered: true,
        distanceText: stops[index].distanceText,
        durationText: stops[index].durationText,
        arrivalTime: "",
        durationMinutes: 0,
      );
    });
    await _calculateAllRoutes();
  }

  void _removeStop(int index) async {
    setState(() => stops.removeAt(index));
    await _calculateAllRoutes();
  }

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
        });
        _calculateAllRoutes();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                color: selected ? Colors.white : Colors.grey, size: 20),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.grey,
                    fontSize: 12,
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
      drawer: const Drawer(
        width: 300,
        child: DashboardScreen(),
      ),
      body: currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          /// 🗺️ CARTE
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

          /// 🍔 BOUTON MENU
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

          /// 🔍 BARRE DE RECHERCHE + LISTE
          Positioned(
            top: 110,
            left: 15,
            right: 15,
            child: Column(
              children: [
                // Barre de recherche
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
                              hintText: "Ajouter une destination...",
                              border: InputBorder.none,
                            ),
                            onSubmitted: (val) => _addDestination(val),
                          ),
                        ),

                        // ✅ BOUTON TOGGLE LISTE
                        if (activeIndexes.isNotEmpty)
                          GestureDetector(
                            onTap: () => setState(
                                    () => _showStopsList = !_showStopsList),
                            child: AnimatedContainer(
                              duration:
                              const Duration(milliseconds: 200),
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

                        // Bouton Ajouter
                        isLoading
                            ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2))
                            : IconButton(
                          icon: const Icon(Icons.add,
                              color: Colors.blue),
                          onPressed: () => _addDestination(
                              destinationController.text),
                        ),
                      ],
                    ),
                  ),
                ),

                // ✅ LISTE ANIMÉE (visible / cachée)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) => SizeTransition(
                    sizeFactor: animation,
                    child: child,
                  ),
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
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text("${i + 1}",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                          ),
                          title: Text(stop.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13)),
                          subtitle: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              if (stop.distanceText.isNotEmpty)
                                Text(
                                  "${stop.distanceText} · ${stop.durationText}",
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600]),
                                ),
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
                                          color:
                                          Colors.blueAccent,
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
                                icon: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 18),
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
                                constraints:
                                const BoxConstraints(),
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

          /// 🚗 TRANSPORT + RÉSUMÉ
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
                    horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _transportButton(
                            "car", Icons.directions_car, "Voiture"),
                        const SizedBox(width: 6),
                        _transportButton(
                            "motor", Icons.motorcycle, "Moto"),
                        const SizedBox(width: 6),
                        _transportButton(
                            "foot", Icons.directions_walk, "Pied"),
                      ],
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
                                fontSize: 14),
                          ),
                          Text(
                            "${activeIndexes.length} restant(s)",
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
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