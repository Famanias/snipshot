import 'package:flutter/material.dart';
import './screens/snip.dart';

void main() => runApp(SnipShotApp());

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