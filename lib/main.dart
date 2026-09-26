import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

// ✅ SUPABASE DETAILS
const String supabaseUrl = 'https://inxlnctaixbkfblwlmhr.supabase.co';
const String supabaseAnonKey = 'sb_publishable_6b9xe3mDBduO-soZTk3t2A_W1sQpD5K';

// ✅ GOOGLE WEB CLIENT ID
const String webClientId = '985001671962-rok8qnng0rumjsd8mgr8uhr92o5vhs4n.apps.googleusercontent.com';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
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
    String finalUrl = uri.toString();
    if (uri.scheme == 'mayajaall') {
      if (uri.queryParameters.containsKey('url')) {
        finalUrl = uri.queryParameters['url']!;
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
          ? const AuthGate()
          : VideoPlayerScreen(url: _incomingUrl!),
    );
  }
}

// AUTH GATE
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) return const HomeScreen();
        return const LoginScreen();
      },
    );
  }
}

// LOGIN SCREEN
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String _error = '';

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(serverClientId: webClientId);
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) { setState(() => _loading = false); return; }
      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) throw 'No ID Token found.';
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.movie, size: 100, color: Colors.deepPurple),
              const SizedBox(height: 20),
              const Text("Mayajaall", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Login to continue", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _loading ? null : _signInWithGoogle,
                icon: const Icon(Icons.login),
                label: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text("Sign in with Google"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(_error, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// HOME SCREEN - SEARCH BAR + PERMISSIONS
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TextEditingController _linkController = TextEditingController();
  List<String> _history = [];
  bool _permissionsChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHistory();
    // ✅ Permissions ko 1 second baad maango (taaki UI load ho jaye)
    Future.delayed(const Duration(seconds: 1), () {
      _requestPermissions();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ✅ PERMISSIONS MANGAO (Android 15 ke hisaab se)
  Future<void> _requestPermissions() async {
    if (_permissionsChecked) return;
    _permissionsChecked = true;

    // Pehle Notification maango
    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }

    // Phir Camera maango
    if (!await Permission.camera.isGranted) {
      await Permission.camera.request();
    }

    // Phir Storage maango (agar supported ho)
    if (!await Permission.storage.isGranted) {
      await Permission.storage.request();
    }
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _history = prefs.getStringList('watch_history') ?? []);
  }

  Future<void> _saveToHistory(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('watch_history') ?? [];
    if (!history.contains(url)) {
      history.insert(0, url);
      if (history.length > 50) history.removeLast();
      await prefs.setStringList('watch_history', history);
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    await GoogleSignIn().signOut();
  }

  void _searchAndPlay() {
    String input = _linkController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please paste a Mayajaall link first!")),
      );
      return;
    }

    if (input.startsWith('mayajaall://')) {
      input = input.replaceFirst('mayajaall://', 'https://live-score-website-alpha.vercel.app/');
    }

    _saveToHistory(input);
    _linkController.clear();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VideoPlayerScreen(url: input)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mayajaall"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome, ${user?.email ?? 'User'}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // SEARCH BAR
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.deepPurple, width: 1.5),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.search, color: Colors.deepPurple),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _linkController,
                      decoration: const InputDecoration(
                        hintText: "Paste Mayajaall link URL here...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_circle_fill, color: Colors.deepPurple, size: 35),
                    onPressed: _searchAndPlay,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            const Text("Watch History:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Expanded(
              child: _history.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 60, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("No history yet", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const Icon(Icons.play_circle_outline, color: Colors.deepPurple),
                            title: Text(
                              _history[index].length > 60
                                  ? "${_history[index].substring(0, 60)}..."
                                  : _history[index],
                              style: const TextStyle(fontSize: 13),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoPlayerScreen(url: _history[index]),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// VIDEO PLAYER SCREEN
class VideoPlayerScreen extends StatefulWidget {
  final String url;
  const VideoPlayerScreen({super.key, required this.url});
  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              launchUrl(Uri.parse(
                  'https://github.com/ajayr0201/Mayajaall/releases/latest/download/app-release.apk'));
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
