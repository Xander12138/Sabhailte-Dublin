import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class LiveStreamPage extends StatefulWidget {
  @override
  _LiveStreamPageState createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  CameraController? _cameraController;
  WebSocketChannel? _channel;
  bool isStreaming = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
      );
      await _cameraController!.initialize();
      setState(() {});
    }
  }

  void _startStreaming() {
    if (_cameraController != null && !_cameraController!.value.isStreamingImages) {
      _channel = WebSocketChannel.connect(Uri.parse('ws://0c8f-134-226-213-134.ngrok-free.app/ws/stream'));
      _cameraController?.startImageStream((image) {
        if (isStreaming) {
          print("Sending frame...");
          _channel?.sink.add(image.planes[0].bytes);
        }
      });
      setState(() {
        isStreaming = true;
      });
    }
  }

  void _stopStreaming() {
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      _cameraController?.stopImageStream();
      _channel?.sink.close(status.goingAway);
      print("Stopped streaming");
      setState(() {
        isStreaming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Live Stream'),
      ),
      body: _cameraController?.value.isInitialized ?? false
          ? Stack(
              children: [
                CameraPreview(_cameraController!),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: isStreaming ? _stopStreaming : _startStreaming,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isStreaming ? Colors.red : Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      isStreaming ? 'Stop Streaming' : 'Start Streaming',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            )
          : Center(child: CircularProgressIndicator()),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _channel?.sink.close();
    super.dispose();
  }
}
