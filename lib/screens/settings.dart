import 'package:flutter/material.dart';
import 'settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLang = SettingsController().targetLanguageCode;

  final Map<String, String> languageOptions = {
    'en': 'English',
    'ja': 'Japanese',
    'ko': 'Korean',
    'zh_cn': 'Simplified Chinese',
    'zh_tw': 'Traditional Chinese',
  };

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Target Language'),
      content: DropdownButton<String>(
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close'),
        ),
      ],
    );
  }
}
