import 'package:get/get.dart';
import 'package:string_similarity/string_similarity.dart';

class CameraController extends GetxController {
  var ocrResult = ''.obs;
  var matchOcrResult = ''.obs;

  var scanCounter = 1.obs;
  var colorInRange = false.obs;

  var one = '1'.obs;
  var oneColor = '#70AD47'.obs;
  var oneColorScanned = false.obs;
  var oneScanned = false.obs;

  var two = '2'.obs;
  var towColor = '#2E75B6'.obs;
  var twoColorScanned = false.obs;
  var twoScanned = false.obs;

  var three = '3'.obs;
  var threeColor = '#FFD966'.obs;
  var threeColorScanned = false.obs;
  var threeScanned = false.obs;

  var four = '4'.obs;
  var fourColor = '#C55A11'.obs;
  var fourColorScanned = false.obs;
  var fourScanned = false.obs;

  var five = '5'.obs;
  var fiveColor = '#7030A0'.obs;
  var fiveColorScanned = false.obs;
  var fiveScanned = false.obs;

  void updateOcrResult(String result) {
    ocrResult.value = result;
    print('ocrResult.value: ${ocrResult.value}');
  }

  bool areStringsSimilar(String s1, String s2, double threshold) {
    double similarity = s1.similarityTo(s2);
    return similarity >= threshold;
  }

  void compareOcrResults(String cameraOcrText, String assetOcrText) {
    print('cameraOcrText: $cameraOcrText');
    print('assetOcrText: $assetOcrText');

    double similarity = cameraOcrText.similarityTo(assetOcrText);
    double matchPercentage = similarity * 100;

    if (matchPercentage >= 80) {
      matchOcrResult.value = 'OCR results match! (${matchPercentage.toStringAsFixed(2)}% similarity)';
      print('OCR results match! (${matchPercentage.toStringAsFixed(2)}% similarity)');
    } else {
      matchOcrResult.value = 'OCR results do not match. (${matchPercentage.toStringAsFixed(2)}% similarity)';
      print('OCR results do not match. (${matchPercentage.toStringAsFixed(2)}% similarity)');
    }
  }

  void compareColorCodes(String colorCode1, String colorCode2, {int tolerance = 25}) {
    // Function to parse color code and extract RGB components
    List<int> parseColorCode(String code) {
      code = code.replaceAll('#', '');
      int color = int.parse(code, radix: 16);
      return [
        (color >> 16) & 0xFF,  // R
        (color >> 8) & 0xFF,   // G
        color & 0xFF           // B
      ];
    }

    // Parse both color codes
    List<int> rgb1 = parseColorCode(colorCode1);
    List<int> rgb2 = parseColorCode(colorCode2);

    // Compare RGB components
    bool inRange = true;
    for (int i = 0; i < 3; i++) {
      if ((rgb1[i] - rgb2[i]).abs() > tolerance) {
        inRange = false;
        break;
      }
    }

    if (inRange) {
      print('Color codes are within a similar range');
      colorInRange.value = true;
    } else {
      print('Color codes are not within a similar range');
      colorInRange.value = false;
    }
  }

}
