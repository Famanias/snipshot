import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:file_picker/file_picker.dart';
import 'translate.dart';
import 'dart:typed_data';

class SnipScreen extends StatefulWidget {
  @override
  _SnipScreenState createState() => _SnipScreenState();
}

class _SnipScreenState extends State<SnipScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool isLoading = false;


  Future<Uint8List?> runSnipAndGetImage() async {
    final result = await Process.run('python', ['path/to/snip_tool.py']);
      
    final tempPath = '${Platform.environment['TEMP']}\\snip_result.png';
    final file = File(tempPath);
    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  }

  Future<void> startSnipping() async {

    ElevatedButton(
      onPressed: () async {
        final imageBytes = await runSnipAndGetImage();
        if (imageBytes != null) {
          // Display the image
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              content: Image.memory(imageBytes),
            ),
          );
        } else {
          print("No image captured.");
        }
      },
      child: Text("Snip Screen"),
    );
    setState(() => isLoading = true);
    try {
      Uint8List? imageBytes = await _screenshotController.capture();
      if (imageBytes != null) {
        print("Captured image bytes length: ${imageBytes.length}");
        var image = img.decodeImage(imageBytes);
        if (image == null) throw Exception("Failed to decode captured image");
        imageBytes = img.encodePng(image);
        String base64Image = base64Encode(imageBytes);
        var request = http.MultipartRequest('POST', Uri.parse('http://localhost:8000/ocr'));
        request.files.add(http.MultipartFile.fromBytes('image_bytes', imageBytes, filename: 'capture.png'));
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Capture failed, no image data')));
      }
    } catch (e) {
      print("Error in startSnipping: $e");
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: _screenshotController,
      child: Scaffold(
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
                child: isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Snip Screen'),
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
            items: ['English', 'Japanese', 'Korean', 'Chinese (Simplified)']
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