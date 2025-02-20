import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert'; // For JSON decoding
import 'package:http/http.dart' as http; // For HTTP requests

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Holds the markers for news locations
  List<Marker> newsMarkers = [];

  // Holds the points of the computed route
  List<LatLng> routePoints = [];

  // Holds the restricted area (polygon)
  List<LatLng> restrictedArea = [];

  @override
  void initState() {
    super.initState();
    _fetchRouteAndRestrictedArea();
  }

  /// 1. Fetch route and restricted area data from the API
  Future<void> _fetchRouteAndRestrictedArea() async {
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:8001/route_map'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Parse `route_map` into a list of LatLng
        final List<dynamic> routeMap = data['route_map'];
        final List<LatLng> routeCoordinates = routeMap.map((coord) {
          return LatLng(coord[0], coord[1]);
        }).toList();

        // Parse `restrict_areas` into a list of LatLng
        final List<dynamic> restrictAreas = data['restrict_areas'];
        final List<LatLng> restrictedCoordinates = restrictAreas.map((coord) {
          return LatLng(coord[0], coord[1]);
        }).toList();

        setState(() {
          routePoints = routeCoordinates;
          restrictedArea = restrictedCoordinates;
        });
      } else {
        throw Exception('Failed to fetch route and restricted area data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching route and restricted area: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final routePolyline = Polyline(
      points: routePoints,
      strokeWidth: 4.0,
      color: Colors.blue,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Route and Restricted Area'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              center: LatLng(53.344075, -6.257303),
              zoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
              ),
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [routePolyline],
                ),
              MarkerLayer(
                markers: newsMarkers,
              ),
              if (restrictedArea.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: restrictedArea,
                      color: Colors.red.withOpacity(0.5),
                      borderColor: Colors.red,
                      borderStrokeWidth: 2.0,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
