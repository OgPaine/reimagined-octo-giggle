import 'package:flutter/material.dart';

class StatProgressItem extends StatelessWidget {
  final MapEntry<String, int> entry;
  final int total;
  final Color primaryColor;
  final bool showPercentage;

  const StatProgressItem({
    super.key,
    required this.entry,
    required this.total,
    required this.primaryColor,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (entry.value / total) * 100 : 0;
    final progress = total > 0 ? (entry.value / total).clamp(0.0, 1.0) : 0.0;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  showPercentage
                      ? '${percentage.toStringAsFixed(1)}%'
                      : '${entry.value}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[300],
              color: primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
