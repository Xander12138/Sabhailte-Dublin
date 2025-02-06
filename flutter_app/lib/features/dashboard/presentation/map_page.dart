import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<Marker> disasterMarkers = [];

  @override
  void initState() {
    super.initState();
    fetchDisasterData();
  }

  Future<void> fetchDisasterData() async {
    try {
      final response = await http.get(Uri.parse(' https://0c8f-134-226-213-134.ngrok-free.app/api/disasters'));

      if (response.statusCode == 200) {
        final List disasters = jsonDecode(response.body)['disasters'];
        final List<Marker> markers = [];

        for (var disaster in disasters) {
          final location = disaster['location'];
          final LatLng? coordinates = await getCoordinatesFromLocation(location);

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

        setState(() {
          disasterMarkers = markers;
        });
      } else {
        throw Exception('Failed to fetch disaster data');
      }
    } catch (e) {
      print('Error fetching disasters: $e');
    }
  }

  Future<LatLng?> getCoordinatesFromLocation(String location) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.opencagedata.com/geocode/v1/json?q=$location&key=4825cbf7470240f3b4ec32ecdcbebb4c'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Disaster Map'),
      ),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(53.349805, -6.26031), // Default to Dublin
          zoom: 12.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: disasterMarkers,
          ),
        ],
      ),
    );
  }
}
