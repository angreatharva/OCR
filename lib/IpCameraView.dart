import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'OcrService.dart';
import 'CameraController.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';

class IpCameraView extends StatefulWidget {
  @override
  _IpCameraViewState createState() => _IpCameraViewState();
}

class _IpCameraViewState extends State<IpCameraView> {
  final OcrService ocrService = OcrService();
  final CameraController cameraController = Get.put(CameraController());
  VlcPlayerController? _vlcPlayerController;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    initializePlayer();
    startFrameAnalysis();
  }

  void initializePlayer() {
    String username = 'admin';
    String password = 'admin@123';
    String ipAddress = '192.168.2.86';
    String rtspUrl = 'rtsp://$username:$password@$ipAddress/cam/realmonitor?channel=1&subtype=0&unicast=true&proto=Onvif';

    _vlcPlayerController = VlcPlayerController.network(
      rtspUrl,
      autoPlay: true,
      options: VlcPlayerOptions(),
    );
  }

  void startFrameAnalysis() {
    Future.delayed(Duration(seconds: 1), analyzeFrame);
  }

  Future<void> analyzeFrame() async {
    if (_vlcPlayerController != null && !_processing) {
      _processing = true;
      Uint8List? snapshot = await _vlcPlayerController?.takeSnapshot();
      if (snapshot != null) {
        String filePath = await _saveImageToFile(snapshot);
        await performOcr(filePath);
      }
      _processing = false;
    }
    startFrameAnalysis(); // Continue the loop
  }

  Future<String> _saveImageToFile(Uint8List imageBytes) async {
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);
    return filePath;
  }

  Future<void> performOcr(String filePath) async {
    String ocrText = await ocrService.performOcr(filePath);
    cameraController.updateOcrResult(ocrText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('IP Camera with OCR'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: VlcPlayer(
              controller: _vlcPlayerController!,
              aspectRatio: 16 / 9,
              placeholder: Center(child: CircularProgressIndicator()),
            ),
          ),
          Obx(() => Text('OCR Result: ${cameraController.ocrResult}')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    ocrService.dispose();
    _vlcPlayerController?.dispose();
    super.dispose();
  }
}
