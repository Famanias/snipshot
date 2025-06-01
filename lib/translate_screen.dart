// translate_screen.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TranslateScreen extends StatefulWidget {
  final Uint8List image;

  const TranslateScreen({super.key, required this.image});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  String _translated = 'Translating...';

  @override
  void initState() {
    super.initState();
    _translateImage();
  }

  Future<void> _translateImage() async {
    final base64Image = base64Encode(widget.image);

    final ocrRes = await http.post(
      Uri.parse('http://127.0.0.1:8000/ocr'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'image_base64': base64Image}),
    );

    if (ocrRes.statusCode == 200) {
      final text = jsonDecode(ocrRes.body)['text'];

      final transRes = await http.post(
        Uri.parse('http://127.0.0.1:8000/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text, 'target_lang': 'en'}),
      );

      if (transRes.statusCode == 200) {
        final translated = jsonDecode(transRes.body)['translated_text'];
        setState(() => _translated = translated);
      } else {
        setState(() => _translated = 'Translation failed');
      }
    } else {
      setState(() => _translated = 'OCR failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Translated Text')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(_translated, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
