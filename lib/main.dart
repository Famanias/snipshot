import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import './screens/snip.dart';
import 'window_setup.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await setupWindow();
  }

  runApp(const SnipShotApp());
}

class SnipShotApp extends StatelessWidget {
  const SnipShotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SnipShot',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SnipScreen(),
    );
  }
}
