import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'camera.dart';
import 'map_page.dart';
import 'live_stream_page.dart';
import 'viewer_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:camera/camera.dart';

class GoLivePage extends StatefulWidget {
  @override
  _GoLivePageState createState() => _GoLivePageState();
}

class _GoLivePageState extends State<GoLivePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  bool _shareLocation = true;
  bool _isLoading = false;
  String _errorMessage = '';
  Position? _currentPosition;
  bool _locationPermissionChecked = false;
  CameraController? _cameraController;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      _cameraController = CameraController(
        cameras[0],
        ResolutionPreset.medium,
      );
      await _cameraController!.initialize();
      setState(() {});
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
    });

    var camera = await Permission.camera.status;
    if (camera.isDenied) {
      camera = await Permission.camera.request();
    }

    var microphone = await Permission.microphone.status;
    if (microphone.isDenied) {
      microphone = await Permission.microphone.request();
    }

    if (_shareLocation) {
      await _checkLocationPermission();
    }

    if (camera.isGranted) {
      await _initializeCamera();
    }

    setState(() {
      _isLoading = false;
      if (camera.isDenied || camera.isPermanentlyDenied) {
        _errorMessage = 'Camera permission is required to go live.';
      } else if (microphone.isDenied || microphone.isPermanentlyDenied) {
        _errorMessage = 'Microphone permission is required to go live.';
      }
    });
  }

  Future<void> _checkLocationPermission() async {
    if (_locationPermissionChecked) return;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _shareLocation = false;
        _errorMessage = 'Location services are disabled. Streaming without location.';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _shareLocation = false;
          _errorMessage = 'Location permission denied. Streaming without location.';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _shareLocation = false;
        _errorMessage = 'Location permission permanently denied. Streaming without location.';
      });
      return;
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      setState(() {
        _locationPermissionChecked = true;
      });
    } catch (e) {
      print("Error getting location: $e");
      setState(() {
        _shareLocation = false;
        _errorMessage = 'Error accessing location. Streaming without location.';
      });
    }
  }

  Future<void> _reportDisaster(BuildContext context) async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();
    final time = _timeController.text.trim();

    if (title.isEmpty || description.isEmpty || location.isEmpty || time.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all the fields')),
      );
      return;
    }

    try {
      final requestBody = {
        'title': title,
        'description': description,
        'location': location,
        'time': time,
      };

      final response = await http.post(
        Uri.parse('http://170.106.106.90:8001/news'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Disaster Reported Successfully!')),
        );
      } else {
        throw Exception('Failed to report disaster. Status code: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _startLiveStream() async {
    if (_titleController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a title for your stream.';
      });
      return;
    }

    // Recheck location if needed
    if (_shareLocation && !_locationPermissionChecked) {
      await _checkLocationPermission();
    }

    // Create stream metadata
    final streamMetadata = {
      'title': _titleController.text,
      'description': _descriptionController.text,
    };

    // Add location if available and sharing is enabled
    if (_shareLocation && _currentPosition != null) {
      streamMetadata['location'] = jsonEncode({
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
      });
    }

    // Navigate to live stream page with metadata
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveStreamPage(streamMetadata: streamMetadata),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Go Live'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 20),
                  
                  // Camera Preview
                  if (_cameraController != null && _cameraController!.value.isInitialized)
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CameraPreview(_cameraController!),
                      ),
                    ),
                  SizedBox(height: 20),

                  // Stream Title Input
                  TextField(
                    controller: _titleController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Stream Title',
                      labelStyle: TextStyle(color: Colors.grey),
                      hintText: 'Enter a title for your stream',
                      hintStyle: TextStyle(color: Colors.grey[700]),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.title, color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Stream Description Input
                  TextField(
                    controller: _descriptionController,
                    style: TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      labelStyle: TextStyle(color: Colors.grey),
                      hintText: 'Add details about your stream',
                      hintStyle: TextStyle(color: Colors.grey[700]),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: Icon(Icons.description, color: Colors.grey),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Share Location Switch
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.grey),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Share Your Location',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Let viewers see where you\'re streaming from',
                                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _shareLocation,
                          onChanged: (value) {
                            setState(() {
                              _shareLocation = value;
                              _errorMessage = '';
                              if (value) {
                                _checkLocationPermission();
                              }
                            });
                          },
                          activeColor: Colors.blue,
                        ),
                      ],
                    ),
                  ),

                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),

                  SizedBox(height: 32),

                  // Go Live Button
                  ElevatedButton(
                    onPressed: _startLiveStream,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'Go Live',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),

                  SizedBox(height: 24),

                  // See Live Button
                  ElevatedButton(
                    onPressed: () {
                      try {
                        print("Navigating to ViewerPage");
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ViewerPage()),
                        ).then((value) {
                          print("Returned from ViewerPage");
                        }).catchError((error) {
                          print("Navigation error: $error");
                        });
                      } catch (e) {
                        print("Exception while navigating: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'See Live',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _timeController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }
}
