import 'package:flutter/material.dart';
import 'settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLang = SettingsController().targetLanguageCode;
  late TextEditingController _controller;

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
    _controller = TextEditingController(text: SettingsController().shortcutKey);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveShortcut() {
    SettingsController().shortcutKey = _controller.text;
    Navigator.pop(context, true); // Pass `true` to indicate a change
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Select Translation Language:'),
          SizedBox(height: 10),
          DropdownButton<String>(
            hint: Text('Select Translation Language'),
            value: _selectedLang,
            icon: SizedBox.shrink(),
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
          // SizedBox(height: 10),
          // TextField(
          //   controller: _controller,
          //   decoration: InputDecoration(
          //     labelText: 'Custom Shortcut Key',
          //     hintText: 'e.g., Ctrl + Shift + S',
          //   ),
          //   onChanged: (value) {
          //     SettingsController().shortcutKey = value;
          //   },
          // ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            // You can optionally do some validation or saving here
            Navigator.pop(context);
          },
          child: Text('Close'),
        ),
      ],
    );
  }
}
