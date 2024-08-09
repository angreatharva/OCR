import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';

class RtspService {
  final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();
  StreamSubscription<int>? _subscription;

  Future<String> getOutputDirectory() async {
    final directory = Directory('/storage/emulated/0/Download/ReConnect');
    final outputDirectory = Directory('${directory.path}/captured_frames');

    // Check if the directory exists, if not, create it
    if (!await outputDirectory.exists()) {
      print("Creating directory: ${outputDirectory.path}");
      await outputDirectory.create(recursive: true);
    } else {
      print("Directory already exists: ${outputDirectory.path}");
    }

    return outputDirectory.path; // Returns the path to the documents directory
  }

  Future<void> startStreaming(String rtspUrl) async {
    String outputDirectory = await getOutputDirectory();
    String outputPath = '$outputDirectory/output_%04d.png';

    print("Output path for frames: $outputPath"); // Log the output path

    try {
      _subscription = _flutterFFmpeg
          .executeWithArguments(['-loglevel', 'debug', '-i', rtspUrl, '-timeout', '10000000', '-vf', 'fps=1/1', outputPath])
          .asStream()
          .listen(
            (rc) {
          print("FFmpeg process exited with rc: $rc");
          if (rc == 0) {
            print("Frames should be saved successfully.");
          } else {
            print("Error in FFmpeg execution.");
          }
        },
        onError: (error) {
          print("Error during FFmpeg execution: $error");
        },
      );
    } catch (e) {
      print("Exception during streaming: $e");
    }
  }

  void stopStreaming() {
    _subscription?.cancel();
  }
}