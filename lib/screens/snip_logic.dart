import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';

import 'translate.dart';

Future<Uint8List?> runSnipAndGetImage() async {
  try {
    final appDir = await getApplicationDocumentsDirectory();
    final scriptPath = '${appDir.path}/snip_tool.py';

    final scriptFile = File(scriptPath);
    if (!await scriptFile.exists()) {
      final bundleScript = await rootBundle.load('backend/snip_tool.py');
      await scriptFile.writeAsBytes(bundleScript.buffer.asUint8List());
    }

    final result = await Process.run('python', [scriptPath]);
    if (result.exitCode != 0) {
      print("Error running script: ${result.stderr}");
      return null;
    }

    final tempPath = Platform.isWindows
        ? '${Platform.environment['TEMP']}\\snip_result.png'
        : '/tmp/snip_result.png';

    final file = File(tempPath);
    return await file.exists() ? await file.readAsBytes() : null;
  } catch (e) {
    print("Error in runSnipAndGetImage: $e");
    return null;
  }
}

Future<void> startSnipping(BuildContext context) async {
  await windowManager.minimize();
  var imageBytes = await runSnipAndGetImage();
  await windowManager.restore();
  await windowManager.focus();

  if (imageBytes != null) {
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Image Captured'),
        content: Image.memory(imageBytes!),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Translate')),
        ],
      ),
    );

    if (shouldContinue ?? false) {
      var image = img.decodeImage(imageBytes);
      if (image == null) throw Exception("Failed to decode image");
      imageBytes = img.encodePng(image);
      String base64Image = base64Encode(imageBytes);

      var response = await http.post(
        Uri.parse('http://localhost:8000/ocr'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_base64': base64Image}),
      );

      var data = jsonDecode(response.body);
      String extractedText = data['text'];
      String detectedLanguage = data['language'];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TranslateScreen(
            extractedText: extractedText,
            detectedLanguage: detectedLanguage,
          ),
        ),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to capture image')),
    );
  }
}
