import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'InbuiltCameraView.dart';
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
      home: InbuiltCameraView(),
      // home: InbuiltCameraView(),
      builder: EasyLoading.init(),
    );
  }
}
