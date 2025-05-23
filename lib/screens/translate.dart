import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TranslateScreen extends StatefulWidget {
  final String extractedText;
  final String detectedLanguage;

  TranslateScreen({required this.extractedText, required this.detectedLanguage});

  @override
  _TranslateScreenState createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  String translatedText = '';
  String targetLanguage = 'en_XX';

  @override
  void initState() {
    super.initState();
    _translateText();
  }

  Future<void> _translateText() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': widget.extractedText, 'target_lang': targetLanguage}),
      );
      final data = jsonDecode(response.body);
      if (data.containsKey('error')) {
        setState(() {
          translatedText = 'Translation error: ${data['error']}';
        });
      } else {
        setState(() {
          translatedText = data['translated_text'];
        });
      }
    } catch (e) {
      setState(() {
        translatedText = 'Translation error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Translate')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('Detected Language: ${widget.detectedLanguage}'),
            SizedBox(height: 10),
            Text('Extracted Text: ${widget.extractedText}'),
            SizedBox(height: 10),
            Text('Translation: $translatedText'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Change Language'),
                    content: DropdownButton<String>(
                      value: targetLanguage,
                      items: ['en_XX', 'ja_XX', 'ko_KR']
                          .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            targetLanguage = value;
                            _translateText();
                          });
                        }
                        Navigator.pop(context);
                      },
                    ),
                    actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('Close'))],
                  ),
                );
              },
              child: Text('Change Language'),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: Icon(Icons.help), onPressed: () {}),
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    showDialog(context: context, builder: (context) => SettingsFrame());
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
    return AlertDialog(
      title: Text('Settings'),
      content: Text('Settings go here.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }
}
