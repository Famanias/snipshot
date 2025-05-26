import 'package:flutter/material.dart';
import 'package:bubble_head/bubble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bubble Head Demo',
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

class _BubbleHeadDemoState extends State<BubbleHeadDemo> {
  final Bubble _bubble = Bubble(
    shouldBounce: true,
    allowDragToClose: true,
    showCloseButton: false,
  );

  bool _hasOverlayPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
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
    if (!_hasOverlayPermission) {
      await _requestPermission();
      if (!_hasOverlayPermission) return;
    }

    try {
      await _bubble.startBubbleHead(sendAppToBackground: true);
    } on PlatformException catch (e) {
      debugPrint('Failed to start bubble: ${e.message}');
    }
  }

  Future<void> _stopBubble() async {
    try {
      await _bubble.stopBubbleHead();
    } on PlatformException catch (e) {
      debugPrint('Failed to stop bubble: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bubble Head Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bubble Head Demo',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            if (!_hasOverlayPermission)
              ElevatedButton(
                onPressed: _requestPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                child: const Text('Grant Overlay Permission'),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startBubble,
              child: const Text('Start Bubble'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _stopBubble,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Stop Bubble'),
            ),
          ],
        ),
      ),
    );
  }
}