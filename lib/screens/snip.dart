import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'translate.dart';
// import 'dart:typed_data';
import 'package:flutter/services.dart';

class SnipScreen extends StatefulWidget {
  @override
  _SnipScreenState createState() => _SnipScreenState();
}

class _SnipScreenState extends State<SnipScreen> {
  bool isLoading = false;

  Future<Uint8List?> runSnipAndGetImage() async {
    try {
      // Get the application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final scriptPath = '${appDir.path}/snip_tool.py';
      
      // Copy the Python script to a accessible location if not already there
      final scriptFile = File(scriptPath);
      if (!await scriptFile.exists()) {
        final bundleScript = await rootBundle.load('assets/snip_tool.py');
        await scriptFile.writeAsBytes(bundleScript.buffer.asUint8List());
      }

      // Run the Python script
      final result = await Process.run('python', [scriptPath]);
      
      if (result.exitCode != 0) {
        print("Error running script: ${result.stderr}");
        return null;
      }

      // Check for the result file
      final tempPath = Platform.isWindows 
          ? '${Platform.environment['TEMP']}\\snip_result.png'
          : '/tmp/snip_result.png';
          
      final file = File(tempPath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      print("Error in runSnipAndGetImage: $e");
      return null;
    }
  }

  Future<void> startSnipping() async {
    setState(() => isLoading = true);
    try {
      // Minimize the current window
      await windowManager.minimize();

      var imageBytes = await runSnipAndGetImage();

      await windowManager.restore();
      await windowManager.focus();
      
      if (imageBytes != null) {
        // Display the image preview
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Image Captured'),
            content: Image.memory(imageBytes!),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Continue'),
              ),
            ],
          ),
        );

        if (shouldContinue ?? false) {
          // Process the image
          var image = img.decodeImage(imageBytes);
          if (image == null) throw Exception("Failed to decode captured image");
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
          SnackBar(content: Text('Failed to capture image')));
      }
    } catch (e) {
      print("Error in startSnipping: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Snip Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('SnipShot - Snip & Translate'),
            SizedBox(height: 20),
            Text('Capture, OCR, and translate text from your screen'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : startSnipping,
              child: isLoading 
                  ? CircularProgressIndicator(color: Colors.white) 
                  : Text('Snip Screen'),
            ),
            SizedBox(height: 10),
            Text('Shortcut key: Ctrl + PrtScn'),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: Icon(Icons.help), onPressed: () {}),
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => SettingsFrame(),
                    );
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

class SettingsFrame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String defaultLanguage = 'English';
    return AlertDialog(
      title: Text('Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            value: defaultLanguage,
            items: ['English', 'Japanese', 'Korean', 'Simplified Chinese', 'Traditional Chinese']
                .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                .toList(),
            onChanged: (value) {},
          ),
          SwitchListTile(
            title: Text('Offline Mode'),
            value: false,
            onChanged: (value) {},
            subtitle: Text('Coming Soon'),
          ),
          TextField(
            decoration: InputDecoration(labelText: 'Shortcut Key'),
            controller: TextEditingController(text: 'Ctrl + PrtScn'),
            readOnly: true,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Save')),
      ],
    );
  }
}