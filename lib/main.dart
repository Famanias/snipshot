import 'dart:io' show Platform, File, Process;
import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import './screens/settings_controller.dart';
import './screens/settings.dart';
import './screens/help.dart';
import './screens/translate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize desktop-specific plugins
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    await hotKeyManager.unregisterAll();

    const windowOptions = WindowOptions(
      size: Size(500, 400),
      minimumSize: Size(500, 400),
      center: true,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.setResizable(true);
      await windowManager.focus();
    });
  }

  runApp(const SnipShotApp());
}

class SnipShotApp extends StatelessWidget {
  const SnipShotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: MaterialApp(
        title: 'SnipShot',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const SnipScreen(),
      ),
    );
  }
}

class SnipScreen extends StatefulWidget {
  const SnipScreen({super.key});

  @override
  _SnipScreenState createState() => _SnipScreenState();
}

class _SnipScreenState extends State<SnipScreen> with WidgetsBindingObserver {
  bool _isBubbleVisible = false;
  HotKey? currentHotKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _registerHotKeyFromSettings();
    } else if (Platform.isAndroid) {
      _requestPermissions();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _unregisterHotKey();
    }
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.systemAlertWindow.request().isGranted) {
      setState(() {
        _isBubbleVisible = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Overlay permission denied')),
      );
    }
  }

  Future<void> _registerHotKeyFromSettings() async {
    final shortcutStr = SettingsController().shortcutKey;
    final hotKey = _parseShortcut(shortcutStr);

    if (hotKey != null) {
      await hotKeyManager.unregisterAll();
      await hotKeyManager.register(hotKey, keyDownHandler: (_) {
        if (mounted) startSnipping(context);
      });
      currentHotKey = hotKey;
    }
  }

  Future<void> _unregisterHotKey() async {
    if (currentHotKey != null) {
      await hotKeyManager.unregister(currentHotKey!);
      currentHotKey = null;
    }
  }

  HotKey? _parseShortcut(String shortcut) {
    final parts = shortcut.toLowerCase().replaceAll(' ', '').split('+');
    bool ctrl = false, shift = false, alt = false, meta = false;
    LogicalKeyboardKey? mainKey;

    for (final part in parts) {
      switch (part) {
        case 'ctrl':
        case 'control':
          ctrl = true;
          break;
        case 'shift':
          shift = true;
          break;
        case 'alt':
          alt = true;
          break;
        case 'cmd':
        case 'meta':
        case 'super':
          meta = true;
          break;
        default:
          mainKey = _stringToLogicalKey(part);
      }
    }

    if (mainKey == null) return null;

    return HotKey(
      key: mainKey,
      modifiers: [
        if (ctrl) HotKeyModifier.control,
        if (shift) HotKeyModifier.shift,
        if (alt) HotKeyModifier.alt,
        if (meta) HotKeyModifier.meta,
      ],
    );
  }

  LogicalKeyboardKey? _stringToLogicalKey(String keyStr) {
    const specialKeys = {
      'printscreen': LogicalKeyboardKey.printScreen,
      'prtsc': LogicalKeyboardKey.printScreen,
      'enter': LogicalKeyboardKey.enter,
      'space': LogicalKeyboardKey.space,
      'escape': LogicalKeyboardKey.escape,
      'esc': LogicalKeyboardKey.escape,
      'tab': LogicalKeyboardKey.tab,
    };

    if (specialKeys.containsKey(keyStr)) return specialKeys[keyStr];

    if (RegExp(r'^[a-z]$').hasMatch(keyStr)) {
      return LogicalKeyboardKey(keyStr.toUpperCase().codeUnitAt(0));
    }

    if (RegExp(r'^[0-9]$').hasMatch(keyStr)) {
      return LogicalKeyboardKey(LogicalKeyboardKey.digit0.keyId + int.parse(keyStr));
    }

    return null;
  }

  void _toggleBubble() {
    setState(() {
      _isBubbleVisible = !_isBubbleVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SnipShot'),
        actions: Platform.isAndroid
            ? [
                IconButton(
                  icon: Icon(_isBubbleVisible ? Icons.bubble_chart : Icons.bubble_chart_outlined),
                  onPressed: _toggleBubble,
                  tooltip: 'Toggle Floating Bubble',
                ),
              ]
            : null,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'SnipShot - Snip & Translate',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Capture, extract text via OCR, and translate instantly'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => startSnipping(context),
              child: const Text('Snip Screen'),
            ),
            const SizedBox(height: 20),
            Text(
              Platform.isWindows || Platform.isLinux || Platform.isMacOS
                  ? 'Shortcut key: ${SettingsController().shortcutKey}'
                  : 'Use the floating bubble to snip from any app',
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          BottomNavigationBarItem(icon: Icon(Icons.help_outline), label: 'Help'),
        ],
        onTap: (index) {
          if (index == 1) {
            showDialog(
              context: context,
              builder: (context) => const SettingsScreen(),
            ).then((_) {
              if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
                _registerHotKeyFromSettings();
              }
            });
          } else if (index == 2) {
            showDialog(
              context: context,
              builder: (context) => const HelpScreen(),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => startSnipping(context),
        tooltip: 'Snip Screen',
        child: const Icon(Icons.cut),
      ),
    );
  }
}

class DraggableFloatingButton extends StatefulWidget {
  final VoidCallback onSnip;

  const DraggableFloatingButton({super.key, required this.onSnip});

  @override
  _DraggableFloatingButtonState createState() => _DraggableFloatingButtonState();
}

class _DraggableFloatingButtonState extends State<DraggableFloatingButton> {
  Offset position = const Offset(50, 50);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Draggable(
        feedback: Material(
          elevation: 4.0,
          shape: const CircleBorder(),
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cut, color: Colors.white),
          ),
        ),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          setState(() {
            position = details.offset;
          });
        },
        child: GestureDetector(
          onTap: widget.onSnip,
          child: Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: const Icon(Icons.cut, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class SnippingWidget extends StatefulWidget {
  final Function(Uint8List?) onCapture;

  const SnippingWidget({super.key, required this.onCapture});

  @override
  _SnippingWidgetState createState() => _SnippingWidgetState();
}

class _SnippingWidgetState extends State<SnippingWidget> {
  Offset? start;
  Offset? end;
  final ScreenshotController controller = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Stack(
        children: [
          GestureDetector(
            onPanStart: (details) {
              setState(() {
                start = details.globalPosition;
                end = start;
              });
            },
            onPanUpdate: (details) {
              setState(() {
                end = details.globalPosition;
              });
            },
            onPanEnd: (details) async {
              if (start != null && end != null) {
                final imageBytes = await controller.capture();
                if (imageBytes != null) {
                  final croppedImage = await _cropImage(imageBytes, start!, end!);
                  widget.onCapture(croppedImage);
                } else {
                  widget.onCapture(null);
                }
              } else {
                widget.onCapture(null);
              }
              Navigator.pop(context);
            },
          ),
          if (start != null && end != null)
            CustomPaint(
              painter: RectanglePainter(start!, end!),
              child: Container(),
            ),
        ],
      ),
    );
  }

  Future<Uint8List?> _cropImage(Uint8List imageBytes, Offset start, Offset end) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return null;

      final x1 = start.dx.toInt();
      final y1 = start.dy.toInt();
      final x2 = end.dx.toInt();
      final y2 = end.dy.toInt();

      final width = (x2 - x1).abs();
      final height = (y2 - y1).abs();
      final cropped = img.copyCrop(image, x: x1, y: y1, width: width, height: height);

      return img.encodePng(cropped);
    } catch (e) {
      debugPrint("Crop error: $e");
      return null;
    }
  }
}

class RectanglePainter extends CustomPainter {
  final Offset start;
  final Offset end;

  RectanglePainter(this.start, this.end);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Rect.fromPoints(start, end);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

Future<void> startSnipping(BuildContext context) async {
  try {
    Uint8List? imageBytes;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Desktop: Use Python script for snipping
      await windowManager.minimize();
      imageBytes = await _runSnipScript();
      await windowManager.restore();
      await windowManager.focus();
    } else {
      // Mobile: Use SnippingWidget for rectangular selection
      imageBytes = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SnippingWidget(
            onCapture: (capturedImage) {
              imageBytes = capturedImage;
            },
          ),
        ),
      );
    }

    if (imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to capture image')),
      );
      return;
    }

    // Show dialog to confirm or cancel
    final proceed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Image Captured'),
        content: Image.memory(imageBytes!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Translate'),
          ),
        ],
      ),
    );

    if (proceed ?? false) {
      final base64Image = base64Encode(imageBytes!);

      final response = await http.post(
        Uri.parse('http://localhost:8000/ocr'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_base64': base64Image}),
      );

      final data = jsonDecode(response.body);
      final extractedText = data['text'];
      final detectedLanguage = data['language'];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TranslateScreen(
            extractedText: extractedText,
            detectedLanguage: detectedLanguage,
          ),
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}

Future<Uint8List?> _runSnipScript() async {
  try {
    final appDir = await getApplicationDocumentsDirectory();
    final scriptPath = '${appDir.path}/snip_tool.py';
    final scriptFile = File(scriptPath);

    if (!await scriptFile.exists()) {
      final bundleScript = await rootBundle.load('assets/snip_tool.py');
      await scriptFile.writeAsBytes(bundleScript.buffer.asUint8List());
    }

    final result = await Process.run('python', [scriptPath]);

    if (result.exitCode != 0) {
      debugPrint("Script error: ${result.stderr}");
      return null;
    }

    final tempPath = Platform.isWindows
        ? '${Platform.environment['TEMP']}\\snip_result.png'
        : '/tmp/snip_result.png';

    final file = File(tempPath);
    return file.existsSync() ? await file.readAsBytes() : null;
  } catch (e) {
    debugPrint("Snip script error: $e");
    return null;
  }
}