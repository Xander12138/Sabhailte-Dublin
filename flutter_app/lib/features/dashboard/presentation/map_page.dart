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

// Define the coordinate for the image marker (adjust as needed)
final LatLng imageMarkerLocation = LatLng(53.349805, -6.26031); // Example: Dublin center

// Create the marker with your image
final imageMarker = Marker(
  width: 80.0,
  height: 80.0,
  point: imageMarkerLocation,
  builder: (ctx) => Container(
    child: Image.asset(
      'assets/fire_accidents.png', // Ensure this asset is added in your pubspec.yaml
      fit: BoxFit.contain,
    ),
  ),
);

class _MapPageState extends State<MapPage> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  List<LatLng> routePoints = []; // 路线的坐标点
  List<LatLng> restrictAreaPoints = []; // 限制区域的坐标点
  bool _isLoading = false; // 加载状态

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
    setState(() {
      _isLoading = true; // 开始加载
    });

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
        final List<dynamic> coordinates = data['route_map']; // 确保字段名与返回的数据一致
        setState(() {
          routePoints = coordinates
              .map((coord) => LatLng(coord[0], coord[1])) // 转换为 LatLng 格式
              .toList();

          // 解析限制区域的坐标
          final List<dynamic> restrictAreas = data['restrict_areas'];
          restrictAreaPoints = restrictAreas
              .map((coord) => LatLng(coord[0], coord[1])) // 转换为 LatLng 格式
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
    } finally {
      setState(() {
        _isLoading = false; // 结束加载
      });
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

    final restrictPolygon = Polygon(
      points: restrictAreaPoints,
      color: Colors.red.withOpacity(0.3),
      borderStrokeWidth: 2.0,
      borderColor: Colors.red,
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
          if (_isLoading) // 显示加载指示器
            Center(child: CircularProgressIndicator()),
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
                if (restrictAreaPoints.isNotEmpty)
                  PolygonLayer(
                    polygons: [restrictPolygon],
                  ),
                  MarkerLayer(
                    markers: [imageMarker],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
