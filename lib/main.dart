import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:pip_view/pip_view.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const YouTubeBrowserApp());
}

class YouTubeBrowserApp extends StatelessWidget {
  const YouTubeBrowserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YouTube Browser',
      theme: ThemeData.dark(),
      home: const YouTubeBrowser(),
    );
  }
}

class YouTubeBrowser extends StatefulWidget {
  const YouTubeBrowser({super.key});

  @override
  State<YouTubeBrowser> createState() => _YouTubeBrowserState();
}

class _YouTubeBrowserState extends State<YouTubeBrowser> {
  InAppWebViewController? webViewController;

  final url = WebUri("https://m.youtube.com");

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // Keep screen awake
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PipView(
      builder: (context, isFloating) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: InAppWebView(
                    initialUrlRequest: URLRequest(url: url),
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      allowsInlineMediaPlayback: true,
                      mediaPlaybackRequiresUserGesture: false,
                      allowsPictureInPictureMediaPlayback: true,
                      disallowOverScroll: true,
                    ),
                    onWebViewCreated: (controller) {
                      webViewController = controller;
                    },
                    shouldOverrideUrlLoading: (controller, action) async {
                      final String newUrl = action.request.url.toString();

                      // Allow ONLY YouTube
                      if (newUrl.contains("youtube.com")) {
                        return NavigationActionPolicy.ALLOW;
                      }
                      return NavigationActionPolicy.CANCEL;
                    },
                  ),
                ),

                // 📌 PiP BUTTON
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      PipView.of(context)!.present();
                    },
                    icon: const Icon(Icons.picture_in_picture),
                    label: const Text("Enable PiP"),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
