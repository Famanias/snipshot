import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_painter/image_painter.dart';
import 'package:media_projection_screenshot/captured_image.dart';
import 'package:media_projection_screenshot/media_projection_screenshot.dart';
import 'translate_screen.dart';

class SnipScreen extends StatefulWidget {
  const SnipScreen({super.key});

  @override
  State<SnipScreen> createState() => _SnipScreenState();
}

class _SnipScreenState extends State<SnipScreen> {
  Uint8List? _screenshot;
  final _screenshotPlugin = MediaProjectionScreenshot();

  late final ImagePainterController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ImagePainterController(
      strokeWidth: 2.0,
      color: Colors.red,
      mode: PaintMode.freeStyle,
    );
    _takeScreenshot();
  }

  Future<void> _takeScreenshot() async {
    try {
      final result = await _screenshotPlugin.takeCapture(
        x: 0,
        y: 0,
        width: 1080,
        height: 1920,
      );

      setState(() {
        _screenshot = result?.imageBytes;
      });
    } catch (e) {
      debugPrint('Screenshot error: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_screenshot == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Snip & Draw'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              final image = await _controller.exportImage();
              if (image != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TranslateScreen(image: image),
                  ),
                );
              }
            },
          )
        ],
      ),
      body: ImagePainter.memory(
        _screenshot!,
        controller: _controller,
        scalable: true,
        controlsAtTop: false,
      ),
    );
  }
}

extension on CapturedImage? {
  Uint8List? get imageBytes => this?.bytes;
}

