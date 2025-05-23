import 'package:flutter/material.dart';
import 'snip_logic.dart';

class SnipButton extends StatefulWidget {
  final VoidCallback? onCompleted;

  const SnipButton({this.onCompleted});

  @override
  _SnipButtonState createState() => _SnipButtonState();
}

class _SnipButtonState extends State<SnipButton> {
  bool isLoading = false;

  Future<void> _handleSnip() async {
    setState(() => isLoading = true);
    try {
      await startSnipping(context);
      widget.onCompleted?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : _handleSnip,
      child: isLoading
          ? CircularProgressIndicator(color: Colors.white)
          : Text('Snip Screen'),
    );
  }
}
