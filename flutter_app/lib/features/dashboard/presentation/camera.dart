import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  List<CameraDescription>? cameras;
  CameraController? cameraController;
  bool isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        cameraController = CameraController(
          cameras![0], // Use the first available camera
          ResolutionPreset.high,
        );
        await cameraController?.initialize();
        setState(() {
          isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Error initializing camera: $e");
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isCameraInitialized
          ? Stack(
              children: [
                CameraPreview(cameraController!),
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: FloatingActionButton(
                    onPressed: () async {
                      if (cameraController!.value.isRecordingVideo) {
                        final file = await cameraController?.stopVideoRecording();
                        debugPrint("Video saved to: ${file?.path}");
                      } else {
                        await cameraController?.startVideoRecording();
                        debugPrint("Started recording...");
                      }
                      setState(() {});
                    },
                    child: Icon(
                      cameraController!.value.isRecordingVideo ? Icons.stop : Icons.videocam,
                    ),
                  ),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
