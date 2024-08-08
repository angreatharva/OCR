import 'dart:io';
import 'package:camera/camera.dart' as cam;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class CameraService {
  cam.CameraController? _controller;
  List<cam.CameraDescription>? _cameras;

  Future<void> initialize() async {
    _cameras = await cam.availableCameras();
    _controller = cam.CameraController(
      _cameras!.first,
      cam.ResolutionPreset.medium, // Choose a resolution
      enableAudio: false, // Disable audio for better performance
    );
    await _controller!.initialize();
  }

  cam.CameraController? get controller => _controller;

  Future<String?> captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    try {
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.png';
      final cam.XFile image = await _controller!.takePicture();
      await image.saveTo(imagePath);
      return imagePath;
    } catch (e) {
      print("Error capturing image: $e");
      return null;
    }
  }

  void startImageStream(Function(cam.CameraImage image) onImageAvailable) {
    _controller?.startImageStream(onImageAvailable);
  }

  void dispose() {
    _controller?.dispose();
  }
}
