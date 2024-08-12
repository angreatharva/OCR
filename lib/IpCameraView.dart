import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'CameraController.dart';
import 'InbuiltCameraView.dart';
import 'OcrService.dart';
import 'RtspService.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:flutter/services.dart';
import 'dart:typed_data';


class IpCameraView extends StatefulWidget {
  @override
  _IpCameraViewState createState() => _IpCameraViewState();
}

class _IpCameraViewState extends State<IpCameraView> {
  final RtspService rtspService = RtspService();
  final OcrService ocrService = OcrService();
  final CameraController cameraController = Get.put(CameraController());

  Uint8List? _lastFrameBytes;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    startStreamingAndAnalysis();
  }

  Future<void> startStreamingAndAnalysis() async {
    String username = 'admin';
    String password = 'admin@123'; // URL-encoded password
    String ipAddress = '192.168.2.86'; // Replace with your camera's IP address
    String rtspUrl = 'rtsp://$username:$password@$ipAddress/cam/realmonitor?channel=1&subtype=0&unicast=true&proto=Onvif';

    try {
      await rtspService.startStreaming(rtspUrl);

      while (mounted) {
        await Future.delayed(Duration(milliseconds: 100)); // Adjust delay as necessary

        String framePath = '${await rtspService.getOutputDirectory()}/output_0001.png';
        if (await File(framePath).exists()) {
          final bytes = await File(framePath).readAsBytes();

          if (_lastFrameBytes == null || _hasFrameChanged(bytes)) {
            _lastFrameBytes = bytes;
            await performOcr(framePath);
          }
        } else {
          print("Frame not found at path: $framePath");
        }
      }
    } catch (e) {
      print("Error during streaming and OCR: $e");
      cameraController.updateOcrResult("Error during streaming and OCR");
    }
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

  Future<void> performOcr(String framePath) async {
    if (!_processing) {
      _processing = true;

      String ocrText = await ocrService.performOcr(framePath);
      cameraController.updateOcrResult(ocrText);

      _processing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('IP Camera with OCR'),
        actions: [
          IconButton(
            icon: Icon(Icons.camera),
            onPressed: () {
              Get.to(() => InbuiltCameraView());
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                startStreamingAndAnalysis();
              },
              child: Text('Start Streaming and OCR'),
            ),
            Obx(() => Text('OCR Result: ${cameraController.ocrResult}')),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    rtspService.stopStreaming();
    ocrService.dispose();
    super.dispose();
  }
}
