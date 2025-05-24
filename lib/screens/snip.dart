import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import 'translate.dart';
import 'snip_button.dart';
import 'settings.dart';
import 'settings_controller.dart';
import 'help.dart';

class SnipScreen extends StatefulWidget {
  @override
  _SnipScreenState createState() => _SnipScreenState();
}

class _SnipScreenState extends State<SnipScreen> with WidgetsBindingObserver {
  bool isLoading = false;
  HotKey? currentHotKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _registerHotKeyFromSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _unregisterHotKey();
    super.dispose();
  }

  Future<void> _registerHotKeyFromSettings() async {
    final shortcutStr = SettingsController().shortcutKey;
    final hotKey = _parseShortcut(shortcutStr);

    if (hotKey != null) {
      await hotKeyManager.unregisterAll();
      await hotKeyManager.register(hotKey, keyDownHandler: (_) {
        if (mounted) startSnipping();
      });
      currentHotKey = hotKey;
      // debugPrint('Registered hotkey: $shortcutStr');
    } else {
      debugPrint('Invalid shortcut format: $shortcutStr');
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

  Future<void> startSnipping() async {
    setState(() => isLoading = true);

    try {
      await windowManager.minimize();
      final imageBytes = await _runSnipScript();
      await windowManager.restore();
      await windowManager.focus();

      if (imageBytes == null) {
        _showSnackBar('Failed to capture image');
        return;
      }

      final proceed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Image Captured'),
          content: Image.memory(imageBytes),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Translate')),
          ],
        ),
      );

      if (proceed ?? false) {
        final decodedImage = img.decodeImage(imageBytes);
        if (decodedImage == null) throw Exception("Failed to decode image");

        final base64Image = base64Encode(img.encodePng(decodedImage));

        final response = await http.post(
          Uri.parse('https://snipshot-backend.onrender.com/ocr'),
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
      debugPrint("Snipping error: $e");
      _showSnackBar('Error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SnipShot')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('SnipShot - Snip & Translate', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Capture, extract text via OCR, and translate instantly'),
            SizedBox(height: 20),
            SnipButton(),
            SizedBox(height: 10),
            // Text('Shortcut key: ${SettingsController().shortcutKey}'),
            Text('Shortcut key: Print Screen'),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.help_outline),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => HelpScreen(),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () async {
                    await showDialog(context: context, builder: (_) => SettingsScreen());
                    _registerHotKeyFromSettings(); // Re-register if shortcut was updated
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
