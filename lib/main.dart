import 'dart:async';
import 'dart:ui';
import 'package:employer/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:employer/database_helper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  runApp(MaterialApp(home: CheckInPage()));
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(), // iOS not supported well
  );

  // await service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  print("Executing Background Service");
  // DartPluginRegistrant.ensureInitialized();
  final battery = Battery();
  int minuteCounter = 0;
  Position? _lastPosition;
  bool start = true;
  DateTime _lastDateTime = DateTime.now();


  int distanceGap = 0;
  Duration timeGap = Duration(seconds: 10);


  service.on('stopService').listen((event) {
    service.stopSelf();
  });


  _lastPosition = await Geolocator.getCurrentPosition();
  final batteryLevel = await battery.batteryLevel;
  final now = DateTime.now();

  await DBHelper.insertCheckIn({
    'datetime': now.toIso8601String(),
    'battery': batteryLevel,
    'latitude': _lastPosition.latitude,
    'longitude': _lastPosition.longitude,
  });

  print("✅ Auto Check-In stored: $now");

  Timer.periodic(timeGap, (timer) async {
    print("..");
    if (service is AndroidServiceInstance) {
      if (!(await service.isForegroundService())) {
        return;
      }
    }

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition();
      final now = DateTime.now();

      if (_lastPosition != null) {
        print("==========");
        double distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        if (distance >= distanceGap ||
            start ||
            now.difference(_lastDateTime) > Duration(minutes: 15)) {
          final batteryLevel = await battery.batteryLevel;
          _lastPosition = position;
          _lastDateTime = now;
          await DBHelper.insertCheckIn({
            'datetime': now.toIso8601String(),
            'battery': batteryLevel,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'distance': distance,
            'speed': position.speed * 3.6,
            'status': 0,
          });
          minuteCounter++;
          if (minuteCounter >= 15) {
            final latestCheckins = await DBHelper.getAllCheckIns();
            if (latestCheckins.isNotEmpty) {
              final last15 = latestCheckins.take(15).toList();
              final first = last15.last; // oldest in 15min
              final last = last15.first; // latest

              // Calculate total distance across 15min
              double totalDist = 0.0;
              for (int i = 0; i < last15.length - 1; i++) {
                totalDist += Geolocator.distanceBetween(
                  last15[i]['latitude'],
                  last15[i]['longitude'],
                  last15[i + 1]['latitude'],
                  last15[i + 1]['longitude'],
                );
              }

              final status = totalDist >= 30 ? 1 : 0;

              // Insert into route table
              await DBHelper.insertRoute({
                "start_time": first['datetime'],
                "end_time": last['datetime'],
                "battery": last['battery'],
                "start_latitude": first['latitude'],
                "start_longitude": first['longitude'],
                "end_latitude": last['latitude'],
                "end_longitude": last['longitude'],
                "distance": totalDist,
                "speed": last['speed'], // could avg instead
                "status": status,
              });

              // Print last 10 routes
              final routes = await DBHelper.getAllRoutes();
              final last10 = routes.take(10).toList();
              print("📌 Last 10 routes:");
              for (var r in last10) {
                print(
                  "Route ${r['id']} | Status: ${r['status']} | "
                  "Start: ${r['start_time']} | End: ${r['end_time']} | "
                  "Battery: ${r['battery']} | Dist: ${r['distance']} | Speed: ${r['speed']}",
                );
              }
            }

            // Reset counter
            minuteCounter = 0;
          
        
        print("✅ Auto Check-In stored: $now");
        start = false;
      } else {
        print("🛑 Skipped: moved only ${distance.toStringAsFixed(1)} meters");
        return; // don't save
      }
   
  }
}
}  catch (e) {
      print("❌ Background Check-In Error: $e");
    }});
}
