import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import './screens/snip.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = WindowOptions(
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

  runApp(SnipShotApp());
}

class SnipShotApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnipShot',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SnipScreen(),
    );
  }
}