import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import '/main.dart';
import 'settings_controller.dart';
import 'settings.dart';
import 'help.dart';

class TranslateScreen extends StatefulWidget {
  final String extractedText;
  final String detectedLanguage;

  const TranslateScreen({super.key, required this.extractedText, required this.detectedLanguage});

  @override
  _TranslateScreenState createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  String translatedText = '';
  String targetLanguage = 'en';

  @override
  void initState() {
    super.initState();
    targetLanguage = SettingsController().targetLanguageCode;
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

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SnipShot - Snip & Translate'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Extracted Text:'),
                            IconButton(
                              onPressed: () => _copyToClipboard(widget.extractedText),
                              icon: const Icon(Icons.copy, size: 16),
                              tooltip: 'Copy',
                            ),
                          ],
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: SelectableText(widget.extractedText),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Translation:'),
                            IconButton(
                              onPressed: () => _copyToClipboard(translatedText),
                              icon: const Icon(Icons.copy, size: 16),
                              tooltip: 'Copy',
                            ),
                          ],
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: SelectableText(translatedText),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => startSnipping(context),
                  child: const Text('Snip Again'),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const HelpScreen(),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const SettingsScreen(),
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