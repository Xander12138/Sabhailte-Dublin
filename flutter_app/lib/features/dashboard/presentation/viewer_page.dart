import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ViewerPage extends StatefulWidget {
  @override
  _ViewerPageState createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  late WebSocketChannel _channel;
  Uint8List? _currentFrame;

  @override
  void initState() {
    super.initState();
    _channel = WebSocketChannel.connect(Uri.parse('ws://0c8f-134-226-213-134.ngrok-free.app/ws/stream'));
    _channel.stream.listen((data) {
      print("Received frame");
      setState(() {
        _currentFrame = data;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Viewer'),
      ),
      body: Center(
        child: _currentFrame != null
            ? Image.memory(_currentFrame!) // Display the live frame
            : Text(
                'Waiting for live stream...',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }
}
