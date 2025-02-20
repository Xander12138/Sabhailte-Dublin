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
  // 路线数据
  final List<LatLng> routeCoordinates = [
    LatLng(53.344075, -6.257303),
    LatLng(53.3460, -6.2700),
    LatLng(53.3420, -6.2500),
    LatLng(53.3420, -6.2700),
    // 可根据需求添加更多点
  ];

  // 禁止进入区域（bbox）
  final List<LatLng> restrictedArea = [
    LatLng(53.3460, -6.2700), // 左上角
    LatLng(53.3460, -6.2500), // 右上角
    LatLng(53.3420, -6.2500), // 右下角
    LatLng(53.3420, -6.2700), // 左下角
    LatLng(53.3460, -6.2700), // 回到起点
  ];

  // Controllers for user input
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  // Holds the markers for news locations
  List<Marker> newsMarkers = [];

  // Holds the points of the computed route
  List<LatLng> routePoints = [];

  @override
  void initState() {
    super.initState();
    _fetchNewsData();
  }

  /// 1. Fetch news data and create markers for each item.
  Future<void> _fetchNewsData() async {
    try {
      final response = await http.get(Uri.parse('http://170.106.106.90:8001/news'));
      if (response.statusCode == 200) {
        final List newsItems = jsonDecode(response.body) as List;
        final List<Marker> markers = [];

        for (var news in newsItems) {
          final String location = news['location'] ?? '';
          if (location.isNotEmpty) {
            final LatLng? coordinates = await _getCoordinatesFromLocation(location);
            if (coordinates != null) {
              markers.add(
                Marker(
                  width: 80.0,
                  height: 80.0,
                  point: coordinates,
                  builder: (ctx) => Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40.0,
                  ),
                ),
              );
            }
          }
        }

        setState(() {
          newsMarkers = markers;
        });
      } else {
        throw Exception('Failed to fetch news data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching news: $e');
    }
  }

  /// 2. Convert a location string into coordinates using OpenCage.
  Future<LatLng?> _getCoordinatesFromLocation(String location) async {
    try {
      final enhancedLocation = '$location, Ireland';
      final query = Uri.encodeComponent(enhancedLocation);
      final url =
          'https://api.opencagedata.com/geocode/v1/json?q=$query&key=4825cbf7470240f3b4ec32ecdcbebb4c';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final lat = data['results'][0]['geometry']['lat'];
          final lng = data['results'][0]['geometry']['lng'];
          return LatLng(lat, lng);
        } else {
          print('No results found for location: $location');
          return null;
        }
      } else {
        print('Failed to fetch coordinates for location: $location. Status code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error geocoding location: $e');
      return null;
    }
  }

  /// 3. Compute the route when the user presses the button
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

    await _fetchOSRMRoute(startCoords, destCoords);
  }

  /// 4. Fetch the road route from OSRM and update [routePoints].
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

        // Convert each [lng, lat] pair into a LatLng
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
                        prefixIcon: Icon(Icons.my_location),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _destinationController,
                      decoration: InputDecoration(
                        labelText: 'Destination Location',
                        prefixIcon: Icon(Icons.flag),
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _computeRoute,
                      child: Text('Show Route'),
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

