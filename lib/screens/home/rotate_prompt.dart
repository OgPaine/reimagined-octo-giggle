import 'package:flutter/material.dart';

class RotatePrompt extends StatelessWidget {
  const RotatePrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.screen_rotation, color: Colors.white, size: 50),
            SizedBox(height: 16),
            Text(
              'Please rotate your device',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
