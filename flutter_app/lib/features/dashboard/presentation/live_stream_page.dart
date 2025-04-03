import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sabhailte_dubin/core/constant.dart';
import 'package:image/image.dart' as img;

class LiveStreamPage extends StatefulWidget {
  final dynamic streamMetadata;

  const LiveStreamPage({
    super.key,
    required this.streamMetadata,
  });

  @override
  State<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  WebSocketChannel? _channel;
  String? _streamId;

  bool _isConnecting = false;
  bool _isStreaming = false;
  String _statusMessage = 'Ready to stream';
  int _viewerCount = 0;

  // Streaming quality settings
  final ResolutionPreset _resolutionPreset = ResolutionPreset.high;
  final double _compressionQuality = 0.85;
  final int _targetFps = 24;

  // Streaming health metrics
  int _sentFrames = 0;
  int _droppedFrames = 0;
  double _averageFps = 0;
  List<DateTime> _lastFrameTimes = [];
  Timer? _metricsTimer;

  // Location tracking
  Position? _currentPosition;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _startLocationTracking();

    // Start timer to update metrics
    _metricsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateStreamMetrics();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app going to background
    if (state == AppLifecycleState.paused) {
      _stopStreaming('App went to background');
    }
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are disabled
      setState(() {
        _statusMessage = 'Location services are disabled';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _statusMessage = 'Location permission denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _statusMessage = 'Location permissions permanently denied';
      });
      return;
    }

    // Start location updates
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          _currentPosition = position;
        });

        // Send location update if streaming
        if (_isStreaming && _channel != null) {
          _channel!.sink.add(jsonEncode({
            'type': 'metadata',
            'location': {
              'latitude': position.latitude,
              'longitude': position.longitude,
            }
          }));
        }
      } catch (e) {
        print('Error getting location: $e');
      }
    });
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() {
        _statusMessage = 'No cameras found';
      });
      return;
    }

    // Use the first back camera
    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    // Initialize camera with specified resolution
    _cameraController = CameraController(
      backCamera,
      _resolutionPreset,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error initializing camera: $e';
      });
    }
  }

  Future<void> _startStreaming() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      setState(() {
        _statusMessage = 'Camera not initialized';
      });
      return;
    }

    if (_isStreaming) {
      setState(() {
        _statusMessage = 'Already streaming';
      });
      return;
    }

    setState(() {
      _isConnecting = true;
      _statusMessage = 'Connecting to server...';
    });

    try {
      // Connect to WebSocket server
      final wsUrl = 'ws://${BASE_URL.replaceAll('http://', '')}/ws/stream';
      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        pingInterval: const Duration(seconds: 5),
      );

      // Listen for server messages
      _channel!.stream.listen(
        (message) {
          if (message is String) {
            final data = jsonDecode(message);

            if (data.containsKey('status') && data['status'] == 'connected') {
              setState(() {
                _streamId = data['stream_id'];
                _isStreaming = true;
                _isConnecting = false;
                _statusMessage = 'Streaming live';
                _sentFrames = 0;
                _droppedFrames = 0;
                _lastFrameTimes = [];
              });

              // Send initial metadata
              _channel!.sink.add(jsonEncode({
                'type': 'metadata',
                'title': widget.streamMetadata['title'] ?? 'Live Stream',
                'description': widget.streamMetadata['description'] ?? 'Emergency Broadcast',
                'device_info': Platform.isAndroid ? 'Android' : Platform.isIOS ? 'iOS' : 'Unknown',
                'location': _currentPosition != null
                  ? {
                      'latitude': _currentPosition!.latitude,
                      'longitude': _currentPosition!.longitude,
                    }
                  : null,
              }));

              // Start streaming frames
              _startCapturingFrames();
            } else if (data.containsKey('viewers')) {
              setState(() {
                _viewerCount = data['viewers'];
              });
            } else if (data.containsKey('error')) {
              setState(() {
                _statusMessage = 'Error: ${data['error']}';
                _isStreaming = false;
                _isConnecting = false;
              });
            }
          }
        },
        onError: (error) {
          setState(() {
            _statusMessage = 'Connection error: $error';
            _isStreaming = false;
            _isConnecting = false;
          });
        },
        onDone: () {
          setState(() {
            _statusMessage = 'Connection closed';
            _isStreaming = false;
            _isConnecting = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error connecting: $e';
        _isStreaming = false;
        _isConnecting = false;
      });
    }
  }

  Future<void> _startCapturingFrames() async {
    final frameInterval = Duration(milliseconds: (1000 / _targetFps).round());
    DateTime lastFrameTime = DateTime.now();

    await _cameraController!.startImageStream((CameraImage image) async {
      // Control frame rate
      final now = DateTime.now();
      if (now.difference(lastFrameTime) < frameInterval) {
        _droppedFrames++;
        return;
      }

      if (!_isStreaming || _channel == null) return;

      // Track frame timing for FPS calculation
      _lastFrameTimes.add(now);
      if (_lastFrameTimes.length > 30) {
        _lastFrameTimes.removeAt(0);
      }

      lastFrameTime = now;

      try {
        // Convert camera image to JPEG bytes
        final bytes = await _processImageForStreaming(image);
        if (bytes != null) {
          // Send frame to server
          _channel!.sink.add(bytes);
          _sentFrames++;
        }
      } catch (e) {
        print('Error processing frame: $e');
      }
    });
  }

  Future<Uint8List?> _processImageForStreaming(CameraImage image) async {
    // Convert to JPEG and compress
    try {
      // For YUV420 format which is most common
      if (image.format.group == ImageFormatGroup.yuv420) {
        // Convert YUV to RGB
        final img.Image? convertedImage = _convertYUV420ToImage(image);
        if (convertedImage == null) return null;

        var processedImage = convertedImage;
        if (image.width > 720) {
          processedImage = img.copyResize(
            convertedImage,
            width: 720,
            height: (720 * image.height / image.width).round(),
            interpolation: img.Interpolation.linear,
          );
        }

        // Encode to JPEG with quality setting
        return Uint8List.fromList(
          img.encodeJpg(processedImage, quality: (_compressionQuality * 100).round())
        );
      }
      // For JPEG format which is already compressed
      else if (image.format.group == ImageFormatGroup.jpeg) {
        // Directly use the JPEG data
        return Uint8List.fromList(image.planes[0].bytes);
      }
    } catch (e) {
      print('Error processing image: $e');
    }
    return null;
  }

  img.Image? _convertYUV420ToImage(CameraImage image) {
    // This is a simplified conversion. For a more accurate conversion,
    // you may need a more sophisticated algorithm or a plugin.
    try {
      final width = image.width;
      final height = image.height;

      // Create Image from YUV420
      final rgbImage = img.Image(width: width, height: height);

      // YUV to RGB conversion
      final yPlane = image.planes[0].bytes;
      final uPlane = image.planes[1].bytes;
      final vPlane = image.planes[2].bytes;

      final yRowStride = image.planes[0].bytesPerRow;
      final uvRowStride = image.planes[1].bytesPerRow;
      final uvPixelStride = image.planes[1].bytesPerPixel!;

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int yIndex = y * yRowStride + x;
          final int uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

          int Y = yPlane[yIndex];
          int U = uPlane[uvIndex];
          int V = vPlane[uvIndex];

          // Convert YUV to RGB
          Y = Y & 0xff;
          U = U & 0xff;
          V = V & 0xff;

          // Using BT.601 conversion formulas
          int r = (1.164 * (Y - 16) + 1.596 * (V - 128)).round();
          int g = (1.164 * (Y - 16) - 0.813 * (V - 128) - 0.391 * (U - 128)).round();
          int b = (1.164 * (Y - 16) + 2.018 * (U - 128)).round();

          // Clamp RGB values
          r = r.clamp(0, 255);
          g = g.clamp(0, 255);
          b = b.clamp(0, 255);

          // Set pixel color
          rgbImage.setPixelRgb(x, y, r, g, b);
        }
      }

      return rgbImage;
    } catch (e) {
      print('Error converting YUV to RGB: $e');
      return null;
    }
  }

  void _updateStreamMetrics() {
    if (!_isStreaming) return;

    // Calculate FPS from the last frame times
    if (_lastFrameTimes.length > 1) {
      final first = _lastFrameTimes.first;
      final last = _lastFrameTimes.last;
      final duration = last.difference(first).inMilliseconds;
      if (duration > 0) {
        final fps = (_lastFrameTimes.length - 1) * 1000 / duration;
        setState(() {
          _averageFps = fps;
        });
      }
    }
  }

  void _stopStreaming([String reason = 'Stream ended']) {
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
    }

    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }

    setState(() {
      _statusMessage = reason;
      _isStreaming = false;
      _isConnecting = false;
      _viewerCount = 0;
    });
  }

  @override
  void dispose() {
    _stopStreaming('Page closed');
    _metricsTimer?.cancel();
    _locationTimer?.cancel();
    _cameraController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Stream'),
        backgroundColor: Colors.black,
        actions: [
          if (_isStreaming)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              child: Row(
                children: [
                  Icon(Icons.remove_red_eye, color: Colors.red, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '$_viewerCount',
                    style: const TextStyle(
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
      body: Column(
        children: [
          // Camera preview
          Expanded(
            child: Stack(
              children: [
                // Camera preview
                if (_cameraController != null &&
                    _cameraController!.value.isInitialized)
                  Center(
                    child: AspectRatio(
                      aspectRatio: _cameraController!.value.aspectRatio,
                      child: CameraPreview(_cameraController!),
                    ),
                  )
                else
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),

                // Live indicator
                if (_isStreaming)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
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

                // Stream metrics
                if (_isStreaming)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'FPS: ${_averageFps.toStringAsFixed(1)}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            'Sent: $_sentFrames',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            'Dropped: $_droppedFrames',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Status and controls
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status message
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Stream button
                ElevatedButton(
                  onPressed: _isConnecting
                    ? null
                    : _isStreaming
                      ? () => _stopStreaming('Stream ended by user')
                      : _startStreaming,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isStreaming ? Colors.red : Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    _isConnecting
                      ? 'Connecting...'
                      : _isStreaming
                        ? 'Stop Streaming'
                        : 'Start Streaming',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
