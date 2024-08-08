import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class OcrService {
  final textRecognizer = TextRecognizer();

  Future<String> performOcr(String filePath) async {
    try {
      final inputImage = InputImage.fromFilePath(filePath);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      print("Error during OCR processing: $e");
      return "Error during OCR";
    }
  }

  void dispose() {
    textRecognizer.close();
  }
}