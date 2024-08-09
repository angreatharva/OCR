import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'CameraController.dart';
import 'InbuiltCameraView.dart';
import 'OcrService.dart';
import 'RtspService.dart';
import 'dart:io';

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
                String username = 'admin';
                String password = 'admin@123'; // URL-encoded password
                String ipAddress = '192.168.2.86'; // Replace with your camera's IP address
                String rtspUrl = 'rtsp://$username:$password@$ipAddress/stream';

                try {
                  await rtspService.startStreaming(rtspUrl); // Start streaming

                  // Wait for a brief moment to ensure a frame is captured
                  await Future.delayed(Duration(seconds: 15)); // Adjust as necessary

                  // Construct the path for the captured frame
                  String framePath = '${await rtspService.getOutputDirectory()}/output_0001.png';
                  print("Constructed frame path: $framePath");

                  // Check if the frame exists and perform OCR
                  if (await File(framePath).exists()) {
                    String ocrText = await ocrService.performOcr(framePath);
                    cameraController.updateOcrResult(ocrText);
                  } else {
                    print("Frame not found at path: $framePath");
                    cameraController.updateOcrResult("Frame not found");

                    // Log files in the output directory
                    final outputDirectory = await rtspService.getOutputDirectory();
                    final dir = Directory(outputDirectory);
                    List<FileSystemEntity> files = dir.listSync();
                    for (var file in files) {
                      print("File found: ${file.path}");
                    }
                  }
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