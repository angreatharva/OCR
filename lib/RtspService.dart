import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'dart:async';

class RtspService {
  final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();
  StreamSubscription<int>? _subscription;

  void startStreaming(String rtspUrl) {
    try {
      _subscription = _flutterFFmpeg
          .executeWithArguments(['-i', rtspUrl, '-vf', 'fps=1/1', 'output_%04d.png'])
          .asStream()
          .listen(
            (rc) {
          print("FFmpeg process exited with rc: $rc");
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
