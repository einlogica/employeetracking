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
  runApp(CheckInPage());
}

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      foregroundServiceNotificationId: 888,
     
    ),
    iosConfiguration: IosConfiguration(), // iOS not supported well
  );

  await service.startService();
}

void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  final battery = Battery();

  Timer.periodic(const Duration(minutes: 15), (timer) async {
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
      final batteryLevel = await battery.batteryLevel;
      final now = DateTime.now();

      await DBHelper.insertCheckIn({
        'datetime': now.toIso8601String(),
        'battery': batteryLevel,
        'latitude': position.latitude,
        'longitude': position.longitude,
      });

      print("✅ Auto Check-In stored: $now");
    } catch (e) {
      print("❌ Background Check-In Error: $e");
    }
  });
}
