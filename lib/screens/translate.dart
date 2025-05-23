import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'snip_button.dart';

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
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('SnipShot - Snip & Translate'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText('Detected Language: ${widget.detectedLanguage}'),
                      SizedBox(height: 10),
                      SelectableText(widget.extractedText),
                    ],
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText('Translation:'),
                      SizedBox(height: 10),
                      SelectableText(translatedText),
                    ],
                  ),
                ),
              ],
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SnipButton(),
                SizedBox(width: 10),
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