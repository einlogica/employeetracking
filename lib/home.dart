// ignore_for_file: library_private_types_in_public_api, unused_field

import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:employer/database_helper.dart';
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

  Timer? _uiRefreshTimer;
  @override
  void initState() {
    super.initState();
    // _startService();
    // _loadCheckIns();
    _checkPermissions();
    //
    _uiRefreshTimer = Timer.periodic(Duration(minutes: 1), (_) {
      _loadCheckIns();
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
    final data = await DBHelper.getAllCheckIns();

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
              child:
                  _checkIns.isEmpty
                      ? Center(child: Text("No check-in data yet."))
                      : ListView.builder(
                        itemCount: _checkIns.length,
                        itemBuilder: (context, index) {
                          final item = _checkIns[index];
                          return ListTile(
                            leading: Icon(Icons.location_on),
                            title: Text(
                              "Lat: ${item['latitude']}, Lng: ${item['longitude']}",
                            ),
                            subtitle: Text(
                              "Time: ${item['datetime']}\nBattery: ${item['battery']}%\nSpeed: ${item['speed']}",
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
