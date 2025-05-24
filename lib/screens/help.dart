import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Help'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Getting Started',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Click the "Snip Screen" button or press Print Screen to start capturing text from your screen.'),
            SizedBox(height: 10),
            Text(
              'Capturing Text',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('After clicking "Snip Screen", drag to create a rectangle around the text you want to capture and translate.'),
            SizedBox(height: 10),
            Text(
              'Translation',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Once you\'ve snipped, click "Translate" to extract and translate the text. You can change the target language in the settings.'),
            SizedBox(height: 10),
            Text(
              'Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Configure your target language (English, Japanese, Korean, and Chinese).'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }
}