import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'IpCameraView.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Camera with OCR',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: IpCameraView(),  // Start with IP camera view
    );
  }
}
