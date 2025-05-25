import 'dart:io' show Platform;

class SettingsController {
  static final SettingsController _instance = SettingsController._internal();
  factory SettingsController() => _instance;
  SettingsController._internal();

  String targetLanguageCode = 'en'; // Default to English
  String shortcutKey = 'printScreen'; // Default shortcut key for desktop

  bool get isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}