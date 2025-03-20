import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:sabhailte_dubin/core/constant.dart';


class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  List<LatLng> routePoints = [];

  @override
  void initState() {
    super.initState();
  }

  Future<LatLng?> _getCoordinatesFromLocation(String location) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.opencagedata.com/geocode/v1/json?q=$location&key=952fab34fe944ac7a7155d132f948b2b'),
      );
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
        SnackBar(content: Text('Please enter both start and destination')),
      );
      return;
    }

    final startCoords = await _getCoordinatesFromLocation(startLoc);
    final destCoords = await _getCoordinatesFromLocation(destLoc);

    if (startCoords == null || destCoords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not geocode one or both locations')),
      );
      return;
    }

    await _fetchCustomRoute(startCoords, destCoords);
  }

  Future<void> _fetchCustomRoute(LatLng start, LatLng end) async {
  try {
    final startString = '${start.longitude},${start.latitude}';
    final endString = '${end.longitude},${end.latitude}';

    final url = '$BASE_URL/route_map?start=$startString&end=$endString';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // 确保 `route_map` 存在并解析
      if (data.containsKey('route_map')) {
        final route = data['route_map'] as List;
        List<LatLng> points = route.map((coord) {
          return LatLng(coord[0], coord[1]); // 注意顺序是 [lat, lng]
        }).toList();

        setState(() {
          routePoints = points;
        });
      } else {
        print('No route_map data found in response');
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
      appBar: AppBar(
        title: Text('Route Map'),
        backgroundColor: Colors.black,
      ),
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
            ],
          ),
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Route Map',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Positioned(
            top: 80,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.white70,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _startController,
                      decoration: InputDecoration(
                        labelText: 'Start Location',
                        labelStyle: TextStyle(color: Colors.black),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: Icon(Icons.my_location, color: Colors.black),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _destinationController,
                      decoration: InputDecoration(
                        labelText: 'Destination Location',
                        labelStyle: TextStyle(color: Colors.black),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        prefixIcon: Icon(Icons.flag, color: Colors.black),
                      ),
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _computeRoute,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Show Route',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
