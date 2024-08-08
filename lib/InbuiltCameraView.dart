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
    print('InbuiltCameraView init');
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    print('initializeCamera');
    await cameraService.initialize();
    setState(() {});
    startFrameAnalysis();
  }

  void startFrameAnalysis() {
    print('startFrameAnalysis');
    cameraService.controller?.startImageStream((image) {
      if (!_processing) {
        _processing = true;
        _analyzeFrame(image);
      }
    });
  }

  Future<void> _analyzeFrame(cam.CameraImage image) async {
    print('_analyzeFrame');
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
    print('_concatenatePlanes');
    final WriteBuffer allBytes = WriteBuffer();
    for (cam.Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  bool _hasFrameChanged(Uint8List currentFrameBytes) {
    print('_hasFrameChanged');
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

  Future<String> captureImage() async {
    print('captureImage');
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

  Future<void> performOcr() async {
    print('performOcr');
    if(cameraController.no.value <= 10){
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
    else{
      cameraController.updateOcrResult("Scanning Complete");
    }

  }

  Future<Uint8List> loadImageFromAssets(standard,no) async {
    print('loadImageFromAssets');
    print('loadImageFromAssets: ${'assets/$standard/BOOK${cameraController.no.value}.jpg'}');
    final ByteData data = await rootBundle.load('assets/$standard/BOOK${cameraController.no.value}.jpg');
    cameraController.bookNo.value = 'BOOK$no';
    return data.buffer.asUint8List();
  }

  Future<String> performOcrOnAssetImage() async {
    print('performOcrOnAssetImage');
    final imageBytes = await loadImageFromAssets('Standard1',cameraController.no.value);
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_image.jpg');
    await tempFile.writeAsBytes(imageBytes);
    final ocrAssetImage = await ocrService.performOcr(tempFile.path);
    print('ocrAssetImage: ${ocrAssetImage}');
    return ocrAssetImage;
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
          ElevatedButton(onPressed: (){
            cameraController.bookNo.value = '';
            cameraController.no.value = 1;

            cameraController.oneBookScanned.value = false;
            cameraController.twoBookScanned.value = false;
            cameraController.threeBookScanned.value = false;
            cameraController.fourBookScanned.value = false;
            cameraController.fiveBookScanned.value = false;
            cameraController.sixBookScanned.value = false;
            cameraController.sevenBookScanned.value = false;
            cameraController.eightBookScanned.value = false;
            cameraController.nineBookScanned.value = false;
            cameraController.tenBookScanned.value = false;
          }, child: Text('Reset')),
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
                    child: Text(
                        'Assets OCR Result: ${cameraController.matchOcrResult.value }\n'
                        'OCR Result: ${cameraController.ocrResult}\n'),
                  ),
                )),
              ],
            ),
          ),
          Obx(() {
            if (cameraController.tenBookScanned.value) {
              return Text('10 Scanned');
            } else if (cameraController.nineBookScanned.value) {
              return Text('9 Scanned');
            } else if (cameraController.eightBookScanned.value) {
              return Text('8 Scanned');
            } else if (cameraController.sevenBookScanned.value) {
              return Text('7 Scanned');
            } else if (cameraController.sixBookScanned.value) {
              return Text('6 Scanned');
            } else if (cameraController.fiveBookScanned.value) {
              return Text('5 Scanned');
            } else if (cameraController.fourBookScanned.value) {
              return Text('4 Scanned');
            } else if (cameraController.threeBookScanned.value) {
              return Text('3 Scanned');
            } else if (cameraController.twoBookScanned.value) {
              return Text('2 Scanned');
            } else if (cameraController.oneBookScanned.value) {
              return Text('1 Scanned');
            } else {
              return Text('Nothing Scanned');
            }
          })


        ],
      ),
    );
  }
}
