import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../utils/tts_helper.dart';
import '../utils/backend_api.dart';
import 'result_widget.dart';

class LiveCameraPage extends StatefulWidget {
  const LiveCameraPage({super.key});

  @override
  State<LiveCameraPage> createState() => _LiveCameraPageState();
}

class _LiveCameraPageState extends State<LiveCameraPage> {
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  bool isProcessing = false;

  // Results from backend
  List<String> objects = [];
  String caption = '';

  final TTSHelper ttsHelper = TTSHelper();
  final BackendAPI backend = BackendAPI();

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();

    if (cameras.isNotEmpty) {
      _controller = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller?.initialize();

      if (!mounted) return;

      setState(() {});

      // Start auto-capture loop
      autoCaptureLoop();
    }
  }

  Future<void> autoCaptureLoop() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 5));
      if (!isProcessing) {
        captureAndSendImage();
      }
    }
  }

  Future<void> captureAndSendImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      setState(() {
        isProcessing = true;
      });

      // Capture image
      final XFile file = await _controller!.takePicture();
      final String imagePath = file.path;

      // Send to backend
      final Map<String, dynamic> result = await backend.sendImage(imagePath);

      // Update UI
      setState(() {
        objects = List<String>.from(result['objects'] ?? []);
        caption = result['caption'] ?? '';
      });

      // Speak results
      if (caption.isNotEmpty) {
        await ttsHelper.speak(caption);
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_controller!),
          if (objects.isNotEmpty || caption.isNotEmpty)
            ResultWidget(objects: objects, caption: caption),
        ],
      ),
    );
  }
}
