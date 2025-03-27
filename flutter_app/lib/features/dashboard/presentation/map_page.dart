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
  final TextEditingController _endController = TextEditingController();
  List<LatLng> routePoints = []; // 路线的坐标点

  // 获取地点的经纬度
  Future<LatLng?> _getCoordinatesFromLocation(String location) async {
    try {
      final response = await http.get(Uri.parse(
          'https://nominatim.openstreetmap.org/search?q=$location&format=json&accept-language=en'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lng = double.parse(data[0]['lon']);
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

  // 调用自定义后台接口获取路线
  Future<void> _fetchRouteFromBackend(String startLat, String startLng, String endLat, String endLng) async {
    try {
      final url = Uri.parse('$BASE_URL/route_map'); // 替换为你的后台接口地址
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'start_lat': startLat,
          'start_lng': startLng,
          'end_lat': endLat,
          'end_lng': endLng,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> coordinates = data['route']; // 假设后台返回的路线点在 `route` 字段中
        setState(() {
          routePoints = coordinates
              .map((coord) => LatLng(coord[1], coord[0])) // 转换为 LatLng 格式
              .toList();
        });
      } else {
        throw Exception('Failed to fetch route from backend');
      }
    } catch (e) {
      print('Error fetching route from backend: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch route from backend')),
      );
    }
  }

  // 搜索路线
  Future<void> _searchRoute() async {
    final startLocation = _startController.text;
    final endLocation = _endController.text;

    if (startLocation.isEmpty || endLocation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both start and end locations')),
      );
      return;
    }

    final startCoords = await _getCoordinatesFromLocation(startLocation);
    final endCoords = await _getCoordinatesFromLocation(endLocation);

    if (startCoords != null && endCoords != null) {
      final startLat = startCoords.latitude.toString();
      final startLng = startCoords.longitude.toString();
      final endLat = endCoords.latitude.toString();
      final endLng = endCoords.longitude.toString();

      // 调用后台接口获取路线
      await _fetchRouteFromBackend(startLat, startLng, endLat, endLng);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not find one or both locations')),
      );
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
        title: const Text('Route Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _startController,
                  decoration: const InputDecoration(
                    hintText: 'Enter start location',
                    labelText: 'Start Location',
                  ),
                ),
                const SizedBox(height: 8.0),
                TextField(
                  controller: _endController,
                  decoration: const InputDecoration(
                    hintText: 'Enter end location',
                    labelText: 'End Location',
                  ),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _searchRoute,
                  child: const Text('Search Route'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: LatLng(53.349805, -6.26031), // 默认设置为都柏林
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
          ),
        ],
      ),
    );
  }
}
