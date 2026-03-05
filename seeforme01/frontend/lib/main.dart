// lib/main.dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';

// Global camera list
late List<CameraDescription> cameras;

// 🔗 Backend IP and Port (phone & PC must be on same WiFi)
const String backendLANIP = "192.168.1.34"; // <-- set to your PC LAN IP
const int backendPort = 5000;

String getBackendUrl() {
  return "http://$backendLANIP:$backendPort/predict";
}

Future<void> requestAppPermissions() async {
  await [
    Permission.camera,
    Permission.microphone,
    Permission.storage,
  ].request();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await requestAppPermissions();
  cameras = await availableCameras();
  runApp(const SeeForMeApp());
}

class SeeForMeApp extends StatelessWidget {
  const SeeForMeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SeeForMe',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
      ),
      home: LiveCameraPage(cameras: cameras),
    );
  }
}

class LiveCameraPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const LiveCameraPage({super.key, required this.cameras});
  @override
  State<LiveCameraPage> createState() => _LiveCameraPageState();
}

class _LiveCameraPageState extends State<LiveCameraPage> {
  CameraController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final rearCamera = widget.cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      _controller = CameraController(rearCamera, ResolutionPreset.medium);
      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _isInitialized = true);

      // Auto capture after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) capturePhoto();
      });
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  Future<void> capturePhoto() async {
    if (!(_controller?.value.isInitialized ?? false)) return;
    try {
      final image = await _controller!.takePicture();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultPage(imagePath: image.path),
        ),
      );
    } catch (e) {
      debugPrint("Capture error: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || !(_controller?.value.isInitialized ?? false)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Live Camera")),
      body: CameraPreview(_controller!),
    );
  }
}

class ResultPage extends StatefulWidget {
  final String imagePath;
  const ResultPage({super.key, required this.imagePath});
  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  String resultText = "படம் பகுப்பாய்வு செய்யப்படுகிறது...";
  bool isLoading = true;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _sendImageToBackend(File(widget.imagePath));
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("ta-IN");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.speak(text);
  }

  Future<void> _sendImageToBackend(File imageFile) async {
    final uri = Uri.parse(getBackendUrl());
    final request = http.MultipartRequest("POST", uri);
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        filename: path.basename(imageFile.path),
      ),
    );

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);

        // data['objects'] is expected to be List<String>
        String objectsStr = "";
        if (data['objects'] is List) {
          objectsStr = (data['objects'] as List).join(", ");
        } else {
          objectsStr = data['objects'].toString();
        }

        setState(() {
          resultText = "🔍 கண்டறியப்பட்ட பொருட்கள்: $objectsStr\n📝 விளக்கம்: ${data['caption']}";
          isLoading = false;
        });

        await _speak("கண்டறியப்பட்ட பொருட்கள்: $objectsStr. விளக்கம்: ${data['caption']}");
      } else {
        setState(() {
          resultText = "❌ சேவையகம் பிழை: ${response.statusCode}";
          isLoading = false;
        });
        await _speak("சேவையகத்தில் பிழை ஏற்பட்டுள்ளது.");
      }
    } catch (e) {
      setState(() {
        resultText = "⚠️ இணைக்க முடியவில்லை. பிழை: $e";
        isLoading = false;
      });
      await _speak("பின்புல சேவையगத்துடன் இணைக்க முடியவில்லை. உங்கள் வலை இணைப்பை சரிபார்க்கவும்.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("விளைவு")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.file(File(widget.imagePath)),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : Text(resultText, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
