// TODO Implement this library.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsrmService {
  // You can change baseUrl to your own OSRM instance if needed.
  static const String baseUrl = 'https://router.project-osrm.org';

  /// Returns a polyline (list of LatLng) from OSRM between start and end.
  static Future<List<LatLng>> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    // OSRM expects lon,lat order in the path!
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
    // coords are [lon, lat]; convert to LatLng(lat, lon)
    return coords.map<LatLng>((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();
  }
}
