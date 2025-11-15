import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
  InAppWebViewController? controller;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  void enterPipMode() {
    const platform = MethodChannel('pip_channel');
    platform.invokeMethod("enterPip");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: InAppWebView(
                initialUrlRequest:
                    URLRequest(url: WebUri("https://m.youtube.com")),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  mediaPlaybackRequiresUserGesture: false,
                  allowsInlineMediaPlayback: true,
                  allowsPictureInPictureMediaPlayback: true,
                ),
                onWebViewCreated: (c) => controller = c,
                shouldOverrideUrlLoading: (controller, action) async {
                  final url = action.request.url.toString();
                  if (url.contains("youtube.com")) {
                    return NavigationActionPolicy.ALLOW;
                  }
                  return NavigationActionPolicy.CANCEL;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: enterPipMode,
                icon: const Icon(Icons.picture_in_picture),
                label: const Text("Enable PiP"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
