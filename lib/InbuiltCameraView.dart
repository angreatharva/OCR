import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart' as cam;
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'CameraController.dart';
import 'CameraService.dart';
import 'IpCameraView.dart';
import 'OcrService.dart';

class InbuiltCameraView extends StatefulWidget {
  @override
  _InbuiltCameraViewState createState() => _InbuiltCameraViewState();
}

class _InbuiltCameraViewState extends State<InbuiltCameraView> {
  final CameraService cameraService = CameraService();
  final OcrService ocrService = OcrService();
  final CameraController cameraController = Get.put(CameraController());
  Uint8List? _lastFrameBytes;
  bool _processing = false;
  List<String> matchedBooks = [];

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    await cameraService.initialize();
    setState(() {});
    startFrameAnalysis();
  }

  void startFrameAnalysis() {
    cameraService.controller?.startImageStream((image) {
      if (!_processing) {
        _processing = true;
        _analyzeFrame(image);
      }
    });
  }

  Future<void> _analyzeFrame(cam.CameraImage image) async {
    final bytes = _concatenatePlanes(image.planes);
    final imageWidth = image.width;
    final imageHeight = image.height;

    if (_lastFrameBytes == null || _hasFrameChanged(bytes)) {
      _lastFrameBytes = bytes;
      await performOcr();
    }

    _processing = false;
  }

  Uint8List _concatenatePlanes(List<cam.Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (cam.Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  bool _hasFrameChanged(Uint8List currentFrameBytes) {
    if (_lastFrameBytes == null) return true;
    if (_lastFrameBytes!.length != currentFrameBytes.length) return true;

    // Compare a sample of pixels (e.g., every 100th pixel)
    for (int i = 0; i < _lastFrameBytes!.length; i += 10000) {
      if (_lastFrameBytes![i] != currentFrameBytes[i]) {
        return true;
      }
    }
    return false;
  }

  Future<void> performOcr() async {
    final imagePath = await captureImage(); // Implement this method to capture image
    if (imagePath != null) {
      String cameraOcrText = await ocrService.performOcr(imagePath);
      String assetOcrText = await performOcrOnAssetImage();

      cameraController.updateOcrResult(cameraOcrText);
      cameraController.compareOcrResults(cameraOcrText, assetOcrText,);
    } else {
      cameraController.updateOcrResult("Error capturing image");
    }
  }

  Future<String> captureImage() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final xFile = await cameraService.controller?.takePicture();
      if (xFile != null) {
        final filePath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await xFile.saveTo(filePath);
        return filePath;
      } else {
        return '';
      }
    } catch (e) {
      print("Error capturing image: $e");
      return '';
    }
  }

  Future<Uint8List> loadImageFromAssets() async {
    final ByteData data = await rootBundle.load('assets/images/imageS1.jpg');
    return data.buffer.asUint8List();
  }

  Future<String> performOcrOnAssetImage() async {
    final imageBytes = await loadImageFromAssets();
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_image.jpg');
    await tempFile.writeAsBytes(imageBytes);
    return await ocrService.performOcr(tempFile.path);
  }

  Future<String> getColorCode(String imagePath) async {
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);

    final centerX = decodedImage!.width ~/ 2;
    final centerY = decodedImage.height ~/ 2;
    final pixel = decodedImage.getPixel(centerX, centerY);

    final r = img.getRed(pixel);
    final g = img.getGreen(pixel);
    final b = img.getBlue(pixel);

    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
  }

  @override
  void dispose() {
    cameraService.dispose();
    ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mobile Camera with OCR'),
        actions: [
          IconButton(
            icon: Icon(Icons.network_wifi),
            onPressed: () {
              Get.to(() => IpCameraView());
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: cameraService.controller == null || !cameraService.controller!.value.isInitialized
                ? Center(child: CircularProgressIndicator())
                : cam.CameraPreview(cameraService.controller!),
          ),
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Obx(() => Container(
                  width: Get.width,
                  height: Get.height * 0.2,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text('OCR Result: ${cameraController.ocrResult}\nAssets OCR Result: ${cameraController.matchOcrResult.value}'),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
