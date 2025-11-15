// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:audio_session/audio_session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // enable webview debug for dev (optional)
  InAppWebViewController.setWebContentsDebuggingEnabled(true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YouTube Browser',
      debugShowCheckedModeBanner: false,
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

class _YouTubeBrowserState extends State<YouTubeBrowser> with WidgetsBindingObserver {
  final MethodChannel _platform = const MethodChannel('pip_channel');
  InAppWebViewController? _controller;
  bool _isFullscreen = false; // tracked via JS
  bool _isPlaying = false;    // tracked via JS
  bool _isInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _initAudioSession();
  }

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      // ignore but audio session improves background audio handling
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    super.dispose();
  }

  // lifecycle observer
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final prev = _isInBackground;
    _isInBackground = state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached;
    if (!prev && _isInBackground) {
      _onAppBackgrounded();
    } else if (prev && !_isInBackground) {
      _onAppForegrounded();
    }
  }

  Future<void> _onAppBackgrounded() async {
    // If video is fullscreen -> enter native PiP
    if (_isFullscreen && _isPlaying) {
      try {
        await _platform.invokeMethod('enterPip');
      } catch (e) {
        // platform not implemented or failed - ignore
      }
    } else {
      // Not fullscreen -> allow webview to continue playing audio in background
      // On Android this usually works automatically.
      // On iOS we must have UIBackgroundModes = audio in Info.plist (see below).
      // Optional: notify page we backgrounded
      try {
        await _controller?.evaluateJavascript(source: "document.dispatchEvent(new Event('flutter_app_background'))");
      } catch (e) {}
    }
  }

  Future<void> _onAppForegrounded() async {
    // if needed we can tell page we resumed
    try {
      await _controller?.evaluateJavascript(source: "document.dispatchEvent(new Event('flutter_app_foreground'))");
    } catch (e) {}
  }

  Future<void> _onWebViewCreated(InAppWebViewController controller) async {
    _controller = controller;

    // register handler to receive notifications from injected JS
    controller.addJavaScriptHandler(handlerName: 'flutterEvent', callback: (args) {
      // args: [eventName, extra]
      if (args.isEmpty) return;
      final name = args[0] as String;
      if (name == 'enter_fullscreen') {
        _isFullscreen = true;
      } else if (name == 'exit_fullscreen') {
        _isFullscreen = false;
      } else if (name == 'playing_state') {
        if (args.length > 1 && args[1] != null) {
          _isPlaying = args[1] as bool;
        }
      }
    });

    // Inject JS: detect fullscreen and video playing state
    await controller.evaluateJavascript(source: """
      (function() {
        function notify(name, extra) {
          try { window.flutter_inappwebview.callHandler('flutterEvent', name, extra); } catch(e){}
        }

        // fullscreen detection
        function fsChange() {
          var isFs = !!(document.fullscreenElement || document.webkitFullscreenElement);
          if (isFs) notify('enter_fullscreen'); else notify('exit_fullscreen');
        }
        document.addEventListener('fullscreenchange', fsChange);
        document.addEventListener('webkitfullscreenchange', fsChange);

        // For YouTube iframe, fullscreen may be inside iframe. Try to detect via video element and webkitDisplayingFullscreen
        setInterval(function() {
          try {
            var v = document.querySelector('video');
            if (v) {
              var playing = !!(v.currentTime > 0 && !v.paused && !v.ended && v.readyState > 2);
              notify('playing_state', playing);

              // webkitDisplayingFullscreen (iOS) or fullscreenElement (Android)
              if (typeof v.webkitDisplayingFullscreen !== 'undefined' && v.webkitDisplayingFullscreen) {
                notify('enter_fullscreen');
              }
            }
          } catch(e){}
        }, 700);
      })();
    """);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri("https://m.youtube.com")),
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            mediaPlaybackRequiresUserGesture: false,
            allowsInlineMediaPlayback: true,
            allowsPictureInPictureMediaPlayback: true,
            useOnDownloadStart: true,
          ),
          onWebViewCreated: _onWebViewCreated,
          shouldOverrideUrlLoading: (controller, navAction) async {
            final url = navAction.request.url?.toString() ?? '';
            if (url.contains('youtube.com')) return NavigationActionPolicy.ALLOW;
            return NavigationActionPolicy.CANCEL;
          },
        ),
      ),
    );
  }
}
