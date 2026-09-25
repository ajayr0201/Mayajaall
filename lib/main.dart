import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  String? _incomingUrl;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handleLink(initialUri);
    } catch (e) {
      debugPrint("Initial link error: $e");
    }
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) => _handleLink(uri),
      onError: (err) => debugPrint("Link stream error: $err"),
    );
  }

  void _handleLink(Uri uri) {
    debugPrint("Link aaya: $uri");

    String finalUrl = uri.toString();

    // Agar custom scheme (mayajaall://) hai, toh usme se url nikaalo
    if (uri.scheme == 'mayajaall') {
      if (uri.queryParameters.containsKey('url')) {
        finalUrl = uri.queryParameters['url']!;
      } else if (uri.path.isNotEmpty) {
        finalUrl = 'https://live-score-website-alpha.vercel.app${uri.path}';
      }
    }

    setState(() => _incomingUrl = finalUrl);
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mayajaall',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple, useMaterial3: true),
      home: _incomingUrl == null
          ? const HomeScreen()
          : WebViewScreen(url: _incomingUrl!),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mayajaall"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.link, size: 80, color: Colors.deepPurple),
              SizedBox(height: 20),
              Text("Mayajaall",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("Koi link open karo app mein aane ke liye",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  final String url;
  const WebViewScreen({super.key, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => setState(() => _isLoading = true),
          onPageFinished: (url) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mayajaall"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
