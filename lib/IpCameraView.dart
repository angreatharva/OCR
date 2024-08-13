import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    print('performOcr in IpCameraView');

    // Perform OCR on the IP camera image
    String ipCameraOcrText = await ocrService.performOcr(filePath);

    // Perform OCR on the asset image (you can use a similar method as in InbuiltCameraView)
    String assetOcrText = await performOcrOnAssetImage();

    // Update OCR result in the controller
    cameraController.updateOcrResult(ipCameraOcrText);

    // Compare the OCR results
    cameraController.compareOcrResults(ipCameraOcrText, assetOcrText);
  }

  Future<String> performOcrOnAssetImage() async {
    print('performOcrOnAssetImage in IpCameraView');

    // Assuming you're using the same asset images as in InbuiltCameraView
    final imageBytes = await loadImageFromAssets('Standard1', cameraController.no.value);
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_image_ip.jpg');
    await tempFile.writeAsBytes(imageBytes);

    final ocrAssetImage = await ocrService.performOcr(tempFile.path);
    print('ocrAssetImage in IpCameraView: $ocrAssetImage');

    return ocrAssetImage;
  }

  Future<Uint8List> loadImageFromAssets(String standard, int no) async {
    print('loadImageFromAssets in IpCameraView');

    final ByteData data = await rootBundle.load('assets/$standard/BOOK$no.jpg');
    cameraController.bookNo.value = 'BOOK$no';

    return data.buffer.asUint8List();
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
