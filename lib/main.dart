import 'package:flutter/material.dart';
import 'package:bubble_head/bubble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'snip_screen.dart';
import 'translate_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnipShot',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BubbleHeadDemo(),
    );
  }
}

class BubbleHeadDemo extends StatefulWidget {
  const BubbleHeadDemo({super.key});

  @override
  State<BubbleHeadDemo> createState() => _BubbleHeadDemoState();
}

class _BubbleHeadDemoState extends State<BubbleHeadDemo> with WidgetsBindingObserver {
  final Bubble _bubble = Bubble(
    shouldBounce: true,
    allowDragToClose: true,
    showCloseButton: false,
  );

  bool _hasOverlayPermission = false;
  bool _bubbleRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Start observing lifecycle changes
    _initializeBubble();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Stop observing when widget is disposed
    _stopBubble(); // Ensure bubble is stopped when app is closed
    super.dispose();
  }

  Future<void> _initializeBubble() async {
    await _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.systemAlertWindow.status;
    setState(() {
      _hasOverlayPermission = status.isGranted;
    });
  }

  Future<void> _requestPermission() async {
    final status = await Permission.systemAlertWindow.request();
    setState(() {
      _hasOverlayPermission = status.isGranted;
    });
  }

  Future<void> _startBubble() async {
    if (!_hasOverlayPermission || _bubbleRunning) return;

    try {
      // Set sendAppToBackground to false to avoid redirecting to home screen
      await _bubble.startBubbleHead(sendAppToBackground: false);
      setState(() {
        _bubbleRunning = true;
      });
    } on PlatformException catch (e) {
      debugPrint('Failed to start bubble: ${e.message}');
    }
  }

  Future<void> _stopBubble() async {
    if (!_bubbleRunning) return;

    try {
      await _bubble.stopBubbleHead();
      setState(() {
        _bubbleRunning = false;
      });
    } on PlatformException catch (e) {
      debugPrint('Failed to stop bubble: ${e.message}');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      // App is sent to the background
      _startBubble();
    } else if (state == AppLifecycleState.resumed) {
      // App is brought back to the foreground
      _stopBubble();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const SnipScreen(),
        ),
      );
      
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SnipShot'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'SnipShot',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            if (!_hasOverlayPermission)
              ElevatedButton(
                onPressed: () async {
                  await _requestPermission();
                  if (_hasOverlayPermission) {
                    await _startBubble();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Grant Overlay Permission'),
              )
          ],
        ),
      ),
    );
  }
}