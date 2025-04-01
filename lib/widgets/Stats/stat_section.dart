import 'package:flutter/material.dart';
import 'stat_progress_item.dart';

class StatSection extends StatelessWidget {
  final String title;
  final List<MapEntry<String, int>> sortedData;
  final int total;
  final Color primaryColor;
  final bool showPercentage;
  final String emptyMessage;

  const StatSection({
    super.key,
    required this.title,
    required this.sortedData,
    required this.total,
    required this.primaryColor,
    this.showPercentage = false,
    this.emptyMessage = 'No data available.',
  });

  Widget _buildSectionTitle() {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildEmptyMessage() {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            emptyMessage,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(),
        const SizedBox(height: 8),
        if (sortedData.isEmpty)
          _buildEmptyMessage()
        else
          ...sortedData.take(10).map((entry) => StatProgressItem(
                entry: entry,
                total: total,
                primaryColor: primaryColor,
                showPercentage: showPercentage,
              )),
        if (sortedData.length > 10)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Center(
              child: TextButton.icon(
                icon: const Icon(Icons.more_horiz),
                label: Text('${sortedData.length - 10} more items'),
                onPressed: () {
                  // TODO: Implement expanding section if desired.
                },
              ),
            ),
          ),
      ],
    );
  }
}