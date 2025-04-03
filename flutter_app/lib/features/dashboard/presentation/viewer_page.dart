import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:sabhailte_dubin/core/constant.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class ViewerPage extends StatefulWidget {
  final String? streamId;

  const ViewerPage({Key? key, this.streamId}) : super(key: key);

  @override
  _ViewerPageState createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  WebSocketChannel? _channel;
  Uint8List? _currentFrame;
  Map<String, dynamic>? _streamMetadata;
  List<Map<String, dynamic>> _activeStreams = [];
  bool _isLoading = true;
  bool _isConnected = false;
  String _statusMessage = 'Loading...';
  int _viewerCount = 0;
  bool _showMap = false;
  LatLng? _streamLocation;

  @override
  void initState() {
    super.initState();
    if (widget.streamId != null) {
      _connectToStream(widget.streamId!);
    } else {
      _fetchAvailableStreams();
    }
  }

  Future<void> _fetchAvailableStreams() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Fetching available streams...';
    });

    try {
      print("Attempting to fetch streams from: $BASE_URL/streams");
      final response = await httpGet('$BASE_URL/streams');
      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _activeStreams = List<Map<String, dynamic>>.from(data['streams']);
          _isLoading = false;
          _statusMessage = _activeStreams.isEmpty
            ? 'No active streams available'
            : 'Select a stream to watch';
        });
      } else {
        setState(() {
          _isLoading = false;
          _statusMessage = 'Error fetching streams: ${response.statusCode}';
        });
      }
    } catch (e) {
      print("Exception during fetch: $e");
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error connecting to server: $e';
      });
    }
  }

  Future<void> _connectToStream(String streamId) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Connecting to stream...';
    });

    try {
      // Connect to stream WebSocket
      final wsUrl = 'ws://${BASE_URL.replaceAll('http://', '')}/ws/view/$streamId';
      print("Connecting to WebSocket: $wsUrl");

      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        pingInterval: Duration(seconds: 5),
      );

      // Listen for stream data
      _channel!.stream.listen(
        (dynamic message) {
          if (message is String) {
            try {
              print("Received string message: ${message.substring(0, message.length > 100 ? 100 : message.length)}...");
              final data = jsonDecode(message);

              if (data.containsKey('status')) {
                if (data['status'] == 'connected') {
                  setState(() {
                    _isConnected = true;
                    _isLoading = false;
                    _statusMessage = 'Connected to stream';
                    _streamMetadata = data['metadata'];
                    _viewerCount = data['viewers'] ?? 0;

                    // Check for location data
                    if (_streamMetadata != null &&
                        _streamMetadata!.containsKey('location') &&
                        _streamMetadata!['location'] != null) {
                      final location = _streamMetadata!['location'];
                      _streamLocation = LatLng(
                        double.parse(location['latitude'].toString()),
                        double.parse(location['longitude'].toString()),
                      );
                    }
                  });
                } else if (data['status'] == 'stream_ended') {
                  setState(() {
                    _isConnected = false;
                    _statusMessage = 'Stream has ended';
                  });
                }
              }

              if (data.containsKey('viewers')) {
                setState(() {
                  _viewerCount = data['viewers'];
                });
              }

              if (data.containsKey('error')) {
                setState(() {
                  _isLoading = false;
                  _isConnected = false;
                  _statusMessage = 'Error: ${data['error']}';
                });
              }
            } catch (e) {
              print('Error parsing message: $e');
            }
          } else if (message is List<int>) {
            // Handle binary frame data
            print("Received binary data of size: ${message.length}");
            setState(() {
              _currentFrame = Uint8List.fromList(message);
            });
          }
        },
        onError: (error) {
          print("WebSocket error: $error");
          setState(() {
            _isLoading = false;
            _isConnected = false;
            _statusMessage = 'Connection error: $error';
          });
        },
        onDone: () {
          print("WebSocket connection closed");
          setState(() {
            _isConnected = false;
            _statusMessage = 'Stream ended';
          });
        },
      );
    } catch (e) {
      print("Exception during stream connection: $e");
      setState(() {
        _isLoading = false;
        _isConnected = false;
        _statusMessage = 'Error connecting: $e';
      });
    }
  }

  void _disconnectFromStream() {
    print("Disconnecting from stream");
    _channel?.sink.close();
    setState(() {
      _isConnected = false;
      _currentFrame = null;
      _streamMetadata = null;
      _fetchAvailableStreams();
    });
  }

  @override
  void dispose() {
    print("Disposing ViewerPage, closing channel");
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(_streamMetadata != null && _streamMetadata!.containsKey('title')
          ? _streamMetadata!['title']
          : 'Live Viewer'),
        actions: [
          if (_streamLocation != null)
            IconButton(
              icon: Icon(_showMap ? Icons.videocam : Icons.map),
              onPressed: () {
                setState(() {
                  _showMap = !_showMap;
                });
              },
            ),
          if (_isConnected)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              child: Row(
                children: [
                  Icon(Icons.remove_red_eye, color: Colors.red, size: 16),
                  SizedBox(width: 4),
                  Text(
                    '$_viewerCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      backgroundColor: Colors.black,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          : _isConnected
              ? _showMap && _streamLocation != null
                  ? _buildMapView()
                  : _buildStreamView()
              : _buildStreamListView(),
    );
  }

  Widget _buildStreamView() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video frame
              if (_currentFrame != null)
                Image.memory(
                  _currentFrame!,
                  fit: BoxFit.contain,
                  gaplessPlayback: true, // Prevents flickering
                )
              else
                Center(
                  child: Text(
                    'Waiting for video...',
                    style: TextStyle(color: Colors.white),
                  ),
                ),

              // Live indicator
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Stream info and controls
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.grey[900],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_streamMetadata != null && _streamMetadata!.containsKey('description'))
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    _streamMetadata!['description'] ?? '',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Live viewers: $_viewerCount',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.exit_to_app, color: Colors.white),
                    label: Text(
                      'Exit Stream',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: _disconnectFromStream,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapView() {
    return Column(
      children: [
        // Map view
        Expanded(
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _streamLocation!,
              zoom: 15,
            ),
            markers: {
              Marker(
                markerId: MarkerId('stream_location'),
                position: _streamLocation!,
                infoWindow: InfoWindow(
                  title: _streamMetadata != null && _streamMetadata!.containsKey('title')
                      ? _streamMetadata!['title']
                      : 'Live Stream',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStreamListView() {
    if (_activeStreams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              'No active streams available',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _fetchAvailableStreams,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchAvailableStreams();
      },
      child: ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: _activeStreams.length,
        itemBuilder: (context, index) {
          final stream = _activeStreams[index];
          final streamId = stream['stream_id'];
          final title = stream['title'] ?? 'Stream $streamId';
          final viewers = stream['viewers'] ?? 0;
          final duration = stream['duration'] ?? 0;

          return Card(
            color: Colors.grey[850],
            margin: EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                _connectToStream(streamId);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(duration),
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        Row(
                          children: [
                            Icon(Icons.remove_red_eye, color: Colors.grey[400], size: 16),
                            SizedBox(width: 4),
                            Text(
                              '$viewers',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return 'Started $seconds seconds ago';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return 'Started $minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      final hours = seconds ~/ 3600;
      return 'Started $hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }
  }
}

Future<http.Response> httpGet(String url) async {
  try {
    print("HTTP GET request to: $url");
    final response = await http.get(Uri.parse(url));
    print("Response received: ${response.statusCode}");
    return response;
  } catch (e) {
    print("HTTP GET error: $e");
    rethrow;
  }
}
