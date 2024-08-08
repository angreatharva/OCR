import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'CameraController.dart';
import 'InbuiltCameraView.dart';
import 'OcrService.dart';
import 'RtspService.dart';
// import 'camera_controller.dart' as custom; // Custom CameraController

class IpCameraView extends StatelessWidget {
  final RtspService rtspService = RtspService();
  final OcrService ocrService = OcrService();
  final CameraController cameraController = Get.put(CameraController());

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
                try {
                  rtspService.startStreaming('rtsp://your_camera_ip/stream');
                  String ocrText = await ocrService.performOcr('path_to_captured_frame');
                  cameraController.updateOcrResult(ocrText);
                } catch (e) {
                  print("Error during streaming and OCR: $e");
                  cameraController.updateOcrResult("Error during streaming and OCR");
                }
              },
              child: Text('Start Streaming and OCR'),
            ),
            Obx(() => Text('OCR Result: ${cameraController.ocrResult}')),
          ],
        ),
      ),
    );
  }
}
