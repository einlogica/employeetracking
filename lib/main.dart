import 'dart:async';
import 'dart:ui';
import 'package:employer/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:employer/database_helper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  runApp(MaterialApp(home: CheckInPage(),));
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
  DartPluginRegistrant.ensureInitialized();
  final battery = Battery();
  Position? _lastPosition;
  bool start =true;
  DateTime _lastDateTime = DateTime.now();

  service.on('stopService').listen((event) {
    service.stopSelf();
  });




  Timer.periodic(const Duration(seconds: 10), (timer) async {
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
        double distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );

        if (distance > 30 || start || now.difference(_lastDateTime)>Duration(minutes: 15)) {
          final batteryLevel = await battery.batteryLevel;
          _lastPosition = position;
          _lastDateTime = now;
          await DBHelper.insertCheckIn({
            'datetime': now.toIso8601String(),
            'battery': batteryLevel,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'distance': distance,
            'speed': position.speed*3.6,
            'status':0
          });


          print("✅ Auto Check-In stored: $now");
          start=false;
        }
        else{
          print("🛑 Skipped: moved only ${distance.toStringAsFixed(1)} meters");
          return; // don't save
        }
      }




    } catch (e) {
      print("❌ Background Check-In Error: $e");
    }
  });
}
