// ignore_for_file: library_private_types_in_public_api, unused_field, unused_element

import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:employer/database_helper.dart';
import 'package:employer/routemap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';

class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key});

  @override
  _CheckInPageState createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  final Battery _battery = Battery();

  String _locationText = "Location: Not available";
  String _batteryText = "Battery: Unknown";
  String _dateText = "Not yet checked in";
  String _timeText = "Not yet checked in";

  List<Map<String, dynamic>> _checkIns = [];
  List<Map<String, dynamic>> routes = [];

  Timer? _uiRefreshTimer;
  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    final data = await DBHelper.getAllRoutes();
    setState(() {
      routes = data;
    });
  }

  void _checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }
  }

  @override
  void dispose() {
    _uiRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCheckIns() async {
    final data = await DBHelper.getAllRoutes(limit: 10);

    if (data.isNotEmpty) {
      final latest = data.first;
      final dt = DateTime.parse(latest['datetime']);

      setState(() {
        _checkIns = data.reversed.toList();
        _dateText = "Date: ${dt.day}/${dt.month}/${dt.year}";
        _timeText = "Time: ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
        _batteryText = "Battery: ${latest['battery']}%";
        _locationText =
            "Location:\nLat: ${latest['latitude'].toStringAsFixed(5)}\nLng: ${latest['longitude'].toStringAsFixed(5)}";
      });
    } else {
      setState(() {
        _checkIns = [];
        _dateText = "Not yet checked in";
        _timeText = "Not yet checked in";
        _batteryText = "Battery: Unknown";
        _locationText = "Location: Not available";
      });
    }

    print("✅ Refreshed UI with latest data");
  }

  void _startService() async {
    final service = FlutterBackgroundService();
    service.startService();
  }

  Future<void> _stopAutoCheckIn() async {
    final service = FlutterBackgroundService();

    service.invoke("stopService");
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Auto Check-In stopped")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Check-In')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      _startService();
                      _loadRoutes();
                    },

                    child: Text('Check In', style: TextStyle(fontSize: 20)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await _stopAutoCheckIn();
                    },
                    child: Text("Check-Out", style: TextStyle(fontSize: 20)),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await DBHelper.deleteCheckIn();
                      setState(() {});
                    },
                    child: Icon(Icons.clear),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            // Text(_dateText, style: TextStyle(fontSize: 16)),
            // SizedBox(height: 10),
            // Text(_timeText, style: TextStyle(fontSize: 16)),
            // SizedBox(height: 10),
            // Text(_batteryText, style: TextStyle(fontSize: 16)),
            // SizedBox(height: 10),
            // Text(
            //   _locationText,
            //   style: TextStyle(fontSize: 16),
            //   textAlign: TextAlign.center,
            // ),
            Divider(),
          Expanded(
  child: routes.isEmpty
      ? const Center(child: Text("No 15-minute summary data yet."))
      : ListView.builder(
          itemCount: routes.length,
          itemBuilder: (context, index) {
            final r = routes[index];
         return Card(
  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
  child: ListTile(
    leading: const Icon(Icons.route),
    title: Text(
      "Start: ${r['start_time']}\nEnd: ${r['end_time']}",
      style: const TextStyle(fontSize: 14),
    ),
    subtitle: Text(
      "Battery: ${r['battery']}%  |  "
      "Dist: ${((r['distance'] ?? 0.0) as num).toStringAsFixed(1)} m  |  "
      "Speed: ${((r['speed'] ?? 0.0) as num).toStringAsFixed(1)} km/h  |  "
      "Status: ${r['status'] == 1 ? "Moving" : "Static"}",
    ),
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RouteMapPage(routeRow: r),
        ),
      );
    },
  ),
);

          },
        ),
),

          ],
        ),
      ),
    );
  }
}
