import 'package:flutter/services.dart';

class ScreenshotController {
  static const _channel = MethodChannel('screenshot_channel');

  static Future<void> startSnipping() async {
    try {
      await _channel.invokeMethod('startSnipping');
    } on PlatformException catch (e) {
      print("Failed to start snipping: ${e.message}");
    }
  }
}
