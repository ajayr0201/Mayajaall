import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mayajaal',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const VideoPlayerScreen(),
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  String currentVideoUrl = 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';
  bool isInitialized = false;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _initIncomingLinks();
    _initPlayer(currentVideoUrl);
  }

  // Incoming deep links ko pakadne ke liye
  void _initIncomingLinks() async {
    try {
      // Agar app link se khula hai
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        _handleUri(initialUri);
      }

      // Agar app already background mein hai aur link click hua
      _sub = uriLinkStream.listen((Uri? uri) {
        if (uri != null) {
          _handleUri(uri);
        }
      }, onError: (err) {
        debugPrint('Failed to receive uri: $err');
      });
    } catch (e) {
      debugPrint('Error handling links: $e');
    }
  }

  void _handleUri(Uri uri) {
    // URL se video parameter nikalna (jaise: mayajaal.com/?video=DIRECT_URL)
    final videoParam = uri.queryParameters['video'];
    if (videoParam != null && videoParam.isNotEmpty) {
      setState(() {
        currentVideoUrl = videoParam;
        isInitialized = false;
      });
      _initPlayer(currentVideoUrl);
    }
  }

  void _initPlayer(String url) {
    _controller?.dispose();
    _controller = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        setState(() {
          isInitialized = true;
        });
        _controller?.play();
      });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Mayajaal Video Streaming'),
        backgroundColor: Colors.grey[900],
      ),
      body: Center(
        child: isInitialized && _controller != null
            ? AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
      floatingActionButton: isInitialized
          ? FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: () {
                setState(() {
                  _controller!.value.isPlaying
                      ? _controller!.pause()
                      : _controller!.play();
                });
              },
              child: Icon(
                _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.black,
              ),
            )
          : null,
    );
  }
}
