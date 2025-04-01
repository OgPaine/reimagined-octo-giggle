import 'package:flutter/material.dart';

class ScreenTimeCard extends StatelessWidget {
  final Duration liveScreenTime;
  final Color primaryColor;

  const ScreenTimeCard({
    super.key,
    required this.liveScreenTime,
    required this.primaryColor,
  });

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: primaryColor.withAlpha(13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.timer_outlined, size: 40, color: primaryColor.withAlpha(204)),
            const SizedBox(height: 16),
            Text(
              _formatDuration(liveScreenTime),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Screen Time',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const LinearProgressIndicator(value: null, minHeight: 3),
          ],
        ),
      ),
    );
  }
}