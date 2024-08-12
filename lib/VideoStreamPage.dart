import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VideoStreamPage extends StatefulWidget {
  @override
  _VideoStreamPageState createState() => _VideoStreamPageState();
}

class _VideoStreamPageState extends State<VideoStreamPage> {
  late VideoPlayerController _controller;
  bool _isAuthenticated = false;
  bool _isInitialized = false;

  @override
  void initState(){
    super.initState();
    // _controller = VideoPlayerController.networkUrl(Uri.parse(
    //     'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'))
    //   ..initialize().then((_) {
    //     // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
    //     setState(() {});
    //   });
    authenticateAndInitialize();
  }

  Future<void> authenticateAndInitialize() async {
    // Replace with your actual username and password
    String username = 'admin';
    String password = 'admin@123';

    // Authenticate with the server
    final response = await http.get(
      Uri.parse('http://192.168.2.86/'),
      headers: {
        'Authorization': 'Basic ' + base64Encode(utf8.encode('$username:$password')),
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _isAuthenticated = true;
      });

      try {
        // Initialize the video player controller
        _controller = VideoPlayerController.network(
          // 'http://192.168.2.86/',
          'rtsp://192.168.2.86:554/cam/realmonitor?channel=1&subtype=0&unicast=true&proto=Onvif',
          httpHeaders: {
            'Authorization': 'Basic ' + base64Encode(utf8.encode('$username:$password')),
          },
        )..addListener(() {
          print('Player state: ${_controller.value}');
        });

        print('Authorization Header: ${base64Encode(utf8.encode('$username:$password'))}');

        try {
          await _controller.initialize();
          setState(() {
            _isInitialized = true;
          });
        } catch (error) {
          print('Video player initialization error: $error');
          if (error is PlatformException) {
            print('Error details: ${error.details}');
            print('Error message: ${error.message}');
          }
        }

      } catch (error) {
        print('Video player initialization error: $error');
      }
    } else {
      print('Failed to authenticate: ${response.statusCode}');
    }
  }

  void playVideo() {
    if (_isInitialized) {
      _controller.play();
    } else {
      print('Video is not initialized yet.');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Video Stream'),
      ),
      body: Center(
        child: _isAuthenticated
            ? _isInitialized
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
            ElevatedButton(
              onPressed: playVideo,
              child: Text('Play Video'),
            ),
          ],
        )
            : CircularProgressIndicator()
            : Text('Authenticating...'),
      ),
     /* body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
            : Container(),
      ),*/
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     setState(() {
      //       _controller.value.isPlaying
      //           ? _controller.pause()
      //           : _controller.play();
      //     });
      //   },
      //   child: Icon(
      //     _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
      //   ),
      // ),
    );
  }
}
