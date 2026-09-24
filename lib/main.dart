import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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
  final TextEditingController _urlController = TextEditingController();
  
  // Default test video
  String currentVideoUrl = 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = currentVideoUrl;
    _initPlayer(currentVideoUrl);
  }

  void _initPlayer(String url) {
    _controller?.dispose();
    setState(() {
      isInitialized = false;
    });

    _controller = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        setState(() {
          isInitialized = true;
        });
        _controller?.play();
      }).catchError((error) {
        debugPrint("Error loading video: $error");
      });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _urlController.dispose();
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
      body: Column(
        children: [
          // URL Input Section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter Vercel Video Link...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[850],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onPressed: () {
                    if (_urlController.text.isNotEmpty) {
                      _initPlayer(_urlController.text.trim());
                    }
                  },
                  child: const Text('Play', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          
          // Video Player Section
          Expanded(
            child: Center(
              child: isInitialized && _controller != null
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            ),
          ),
        ],
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
