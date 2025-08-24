import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;

class RouteMapPage extends StatefulWidget {
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;

  final Map<String, dynamic> routeRow; // a single row from your "routes" table

  const RouteMapPage({
    super.key,
    required this.routeRow,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
  });

  @override
  State<RouteMapPage> createState() => _RouteMapPageState();
}

class _RouteMapPageState extends State<RouteMapPage> {
  List<LatLng> _routePoints = [];
  bool isLoading = true;

  late final LatLng _start;
  late final LatLng _end;

  @override
  void initState() {
    super.initState();
    _start = LatLng(
      (widget.routeRow['start_latitude'] ?? widget.startLat).toDouble(),
      (widget.routeRow['start_longitude'] ?? widget.startLng).toDouble(),
    );
    _end = LatLng(
      (widget.routeRow['end_latitude'] ?? widget.endLat).toDouble(),
      (widget.routeRow['end_longitude'] ?? widget.endLng).toDouble(),
    );

    fetchRoute(); // 🚀 Fetch route immediately
  }

  Future<void> fetchRoute() async {
    final url =
        "https://osmr-backend.calmflower-b8f267bc.centralindia.azurecontainerapps.io/route/v1/driving/"
        "${_start.longitude},${_start.latitude};${_end.longitude},${_end.latitude}"
        "?steps=true&geometries=polyline";

    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        final geometry = data['routes'][0]['geometry'];
        final polyline = PolylinePoints.decodePolyline(geometry);

        setState(() {
          _routePoints =
              polyline.map((p) => LatLng(p.latitude, p.longitude)).toList();
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load route");
      }
    } catch (e) {
      debugPrint("Error fetching route: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Route")),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                options: MapOptions(initialCenter: _start, initialZoom: 14),
                children: [
                  // Background map
                  TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: 'com.example.employer',
                  ),
                  // Route polyline
                  if (_routePoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 6.0,
                          color: Colors.blueAccent,
                        ),
                      ],
                    ),

                  // Start + End markers
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _start,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.green,
                          size: 40,
                        ),
                      ),
                      Marker(
                        point: _end,
                        width: 40,
                        height: 40,
                        child: const Icon(
                           Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchRoute,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
