import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Help'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Getting Started',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('Tap the floating bubble or the "Snip Screen" button to start capturing text from your screen.'),
            const SizedBox(height: 10),
            const Text(
              'Capturing Text',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('After tapping "Snip Screen", the app will capture the current screen. Confirm to proceed with translation.'),
            const SizedBox(height: 10),
            const Text(
              'Translation',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('Once captured, tap "Translate" to extract and translate the text. You can change the target language in the settings.'),
            const SizedBox(height: 10),
            const Text(
              'Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('Configure your target language (English, Japanese, Korean, and Chinese).'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}