import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:sabhailte_dubin/core/constant.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  List<LatLng> routePoints = [];
  List<LatLng> restrictedAreaPoints = [];

  @override
  void initState() {
    super.initState();
  }

  Future<LatLng?> _getCoordinatesFromLocation(String location) async {
    try {
      final response = await http.get(Uri.parse('$BASE_URL/route-map'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'].isNotEmpty) {
          final lat = data['results'][0]['geometry']['lat'];
          final lng = data['results'][0]['geometry']['lng'];
          return LatLng(lat, lng);
        } else {
          throw Exception('No results found for location: $location');
        }
      } else {
        throw Exception('Failed to fetch coordinates for location: $location');
      }
    } catch (e) {
      print('Error geocoding location: $e');
      return null;
    }
  }

  Future<void> _computeRoute() async {
    final startLoc = _startController.text.trim();
    final destLoc = _destinationController.text.trim();

    if (startLoc.isEmpty || destLoc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both start and destination')),
      );
      return;
    }

    final startCoords = await _getCoordinatesFromLocation(startLoc);
    final destCoords = await _getCoordinatesFromLocation(destLoc);

    if (startCoords == null || destCoords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not geocode one or both locations')),
      );
      return;
    }

    await _fetchCustomRoute(startCoords, destCoords);
  }

  Future<void> _fetchCustomRoute(LatLng start, LatLng end) async {
    try {
      final startString = '${start.latitude},${start.longitude}';
      final endString = '${end.latitude},${end.longitude}';

      final url = '$BASE_URL/route_map?start=$startString&end=$endString';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Ensure `route_map` exists and parse it
        if (data.containsKey('route_map')) {
          final route = data['route_map'] as List;
          List<LatLng> points = route.map((coord) {
            return LatLng(coord[0], coord[1]); // Note order is [lat, lng]
          }).toList();

          setState(() {
            routePoints = points;
          });
        } else {
          print('No route_map data found in response');
        }

        // Parse `restrict_areas`
        if (data.containsKey('restrict_areas')) {
          final restrictAreas = data['restrict_areas'] as List;
          List<LatLng> areaPoints = restrictAreas.map((coord) {
            return LatLng(coord[0], coord[1]); // Note order is [lat, lng]
          }).toList();
          print('Found restrict_areas data in response');

          setState(() {
            restrictedAreaPoints = areaPoints;
          });
        } else {
          print('No restrict_areas data found in response');
        }
      } else {
        print('Failed to fetch route. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
  }

  Future<void> _fetchOSRMRoute(LatLng start, LatLng end) async {
    try {
      final startString = '${start.longitude},${start.latitude}';
      final endString = '${end.longitude},${end.latitude}';
      final url =
          'http://router.project-osrm.org/route/v1/driving/$startString;$endString?overview=full&geometries=geojson';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final route = data['routes'][0]['geometry']['coordinates'] as List;
        List<LatLng> points = route.map((coord) {
          return LatLng(coord[1], coord[0]);
        }).toList();
        setState(() {
          routePoints = points;
        });
      } else {
        print('Failed to fetch route. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching route: $e');
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
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              center: LatLng(53.349805, -6.26031), // Default to Dublin
              zoom: 12.0,
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
              if (restrictedAreaPoints.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: restrictedAreaPoints,
                      color: Colors.red.withOpacity(0.8), // Fills the area with semi-transparent red
                      borderColor: Colors.red, // Sets the border to red
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
