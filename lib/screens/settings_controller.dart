class SettingsController {
  static final SettingsController _instance = SettingsController._internal();
  factory SettingsController() => _instance;
  SettingsController._internal();

  String targetLanguageCode = 'en'; // default to English
}
