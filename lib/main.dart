import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import './screens/snip.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  await hotKeyManager.unregisterAll();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(500, 400),
    minimumSize: Size(500, 400),
    center: true,
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.setResizable(true);
    await windowManager.focus();
  });

  runApp(const SnipShotApp());
}

class SnipShotApp extends StatelessWidget {
  const SnipShotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnipShot',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SnipScreen(), // No longer uses SnipHome
    );
  }
}
