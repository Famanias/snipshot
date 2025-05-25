import 'package:flutter/material.dart';
import 'settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLang = SettingsController().targetLanguageCode;
  late TextEditingController _shortcutController;

  final Map<String, String> languageOptions = {
    'en': 'English',
    'ja': 'Japanese',
    'ko': 'Korean',
    'zh_cn': 'Simplified Chinese',
    'zh_tw': 'Traditional Chinese',
  };

  @override
  void initState() {
    super.initState();
    _shortcutController = TextEditingController(text: SettingsController().shortcutKey);
  }

  @override
  void dispose() {
    _shortcutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Select Translation Language:'),
          const SizedBox(height: 10),
          DropdownButton<String>(
            value: _selectedLang,
            items: languageOptions.entries.map((entry) {
              return DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedLang = value;
                  SettingsController().targetLanguageCode = value;
                });
              }
            },
          ),
          if (SettingsController().isDesktop) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _shortcutController,
              decoration: const InputDecoration(
                labelText: 'Custom Shortcut Key',
                hintText: 'e.g., Ctrl + Shift + S',
              ),
              onChanged: (value) {
                SettingsController().shortcutKey = value;
              },
            ),
          ],
        ],
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