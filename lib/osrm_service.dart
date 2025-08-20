// TODO Implement this library.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsrmService {
  
  static const String baseUrl = 'https://router.project-osrm.org';

  static Future<List<LatLng>> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    
    final path =
        '$baseUrl/route/v1/driving/$startLng,$startLat;$endLng,$endLat'
        '?overview=full&geometries=geojson&alternatives=false&steps=false';

    final res = await http.get(Uri.parse(path));
    if (res.statusCode != 200) {
      throw Exception('OSRM request failed: ${res.statusCode}');
    }

    final json = jsonDecode(res.body);
    if (json['routes'] == null || (json['routes'] as List).isEmpty) {
      throw Exception('No route found.');
    }

    final List coords = json['routes'][0]['geometry']['coordinates'];
   
    return coords.map<LatLng>((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
  }
}
