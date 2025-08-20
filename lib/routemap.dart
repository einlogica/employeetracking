import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'osrm_service.dart';

class RouteMapPage extends StatefulWidget {
  final Map<String, dynamic> routeRow; // a single row from your "route(s)" table

  const RouteMapPage({super.key, required this.routeRow});

  @override
  State<RouteMapPage> createState() => _RouteMapPageState();
}

class _RouteMapPageState extends State<RouteMapPage> {
  List<LatLng> _routePoints = [];
  bool _loading = true;
  String? _error;

  late final LatLng _start;
  late final LatLng _end;

  @override
  void initState() {
    super.initState();
    _start = LatLng(
      (widget.routeRow['start_latitude'] ?? 0.0).toDouble(),
      (widget.routeRow['start_longitude'] ?? 0.0).toDouble(),
    );
    _end = LatLng(
      (widget.routeRow['end_latitude'] ?? 0.0).toDouble(),
      (widget.routeRow['end_longitude'] ?? 0.0).toDouble(),
    );
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    try {
      final pts = await OsrmService.getRoute(
        startLat: _start.latitude,
        startLng: _start.longitude,
        endLat: _end.latitude,
        endLng: _end.longitude,
      );
      setState(() {
        _routePoints = pts;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _routePoints.isNotEmpty
        ? _routePoints[_routePoints.length ~/ 2]
        : _start;

    return Scaffold(
      appBar: AppBar(title: const Text('Route (OSRM)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.employer',
                    ),
                   
                    if (_routePoints.isNotEmpty)
                      PolylineLayer(polylines: [
                        Polyline(points: _routePoints, strokeWidth: 4),
                      ]),
                    // Start & End markers
                    MarkerLayer(markers: [
                      Marker(
                        point: _start,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.location_pin, size: 36),
                      ),
                      Marker(
                        point: _end,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.flag, size: 32),
                      ),
                    ]),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadRoute,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
