import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heat Map Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HeatMapDemoPage(),
    );
  }
}

class HeatMapDemoPage extends StatelessWidget {
  const HeatMapDemoPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    // Generate sample weekly data: 4 weeks (columns), each week has 7 days.
    List<List<UsageCellData>> weeklyData = List.generate(4, (weekIndex) {
      return List.generate(7, (dayIndex) {
        // Sample values: appOpens and wordsUsed vary by week and day.
        return UsageCellData(
          appOpens: (weekIndex + 1) * (dayIndex + 2),
          wordsUsed: (weekIndex + 2) * (dayIndex + 1),
        );
      });
    });
    // Compute the maximum total across all weekly cells.
    int weeklyMaxTotal = weeklyData
        .expand((week) => week)
        .map((cell) => cell.total)
        .reduce((a, b) => a > b ? a : b);
    
    // Generate sample daily data: 24 hours.
    List<UsageCellData> dailyData = List.generate(24, (hour) {
      return UsageCellData(
        appOpens: hour,
        wordsUsed: 24 - hour,
      );
    });
    int dailyMaxTotal = dailyData
        .map((cell) => cell.total)
        .reduce((a, b) => a > b ? a : b);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heat Map Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            WeeklyHeatMapSection(
              title: 'Weekly Usage',
              weeklyData: weeklyData,
              maxTotal: weeklyMaxTotal,
              baseColor: Colors.blue,
            ),
            const SizedBox(height: 32),
            DailyHeatMapSection(
              title: 'Daily Usage',
              hourlyData: dailyData,
              maxTotal: dailyMaxTotal,
              baseColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}

/// A data model for a single heat map cell.
class UsageCellData {
  final int appOpens;
  final int wordsUsed;
  const UsageCellData({
    required this.appOpens,
    required this.wordsUsed,
  });

  /// Returns the aggregate value.
  int get total => appOpens + wordsUsed;
}

/// A heat map section that displays weekly data.
/// Each week is represented as a list of 7 [UsageCellData] (Mon–Sun).
class WeeklyHeatMapSection extends StatelessWidget {
  final String title;
  final List<List<UsageCellData>> weeklyData;
  final int maxTotal;
  final Color baseColor;
  final List<String> dayLabels;

  const WeeklyHeatMapSection({
    super.key,
    required this.title,
    required this.weeklyData,
    required this.maxTotal,
    required this.baseColor,
    this.dayLabels = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  });

  /// Computes the cell color based on the total usage in the cell.
  Color _getCellColor(UsageCellData data) {
    final intensity = maxTotal > 0 ? data.total / maxTotal : 0.0;
    return Color.lerp(Colors.white, baseColor, intensity)!;
  }

  void _showCellDetails(BuildContext context, UsageCellData data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Usage Details'),
        content: Text('App Opened: ${data.appOpens} times\nWords Used: ${data.wordsUsed} times'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      children: [
        const Text("Low", style: TextStyle(fontSize: 12)),
        Expanded(
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, baseColor],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const Text("High", style: TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build 7 rows (days) with one column per week.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day labels.
            Column(
              children: dayLabels
                  .map((day) => SizedBox(
                        width: 40,
                        height: 20,
                        child: Center(
                          child: Text(day, style: const TextStyle(fontSize: 10)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(width: 4),
            // Heat map grid.
            Expanded(
              child: Column(
                children: List.generate(7, (dayIndex) {
                  return Row(
                    children: List.generate(weeklyData.length, (weekIndex) {
                      final cellData = weeklyData[weekIndex][dayIndex];
                      return InkWell(
                        onTap: () => _showCellDetails(context, cellData),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _getCellColor(cellData),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  );
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildLegend(context),
      ],
    );
  }
}

/// A heat map section that displays daily (hourly) data.
/// The [hourlyData] list should contain 24 [UsageCellData] (one for each hour).
class DailyHeatMapSection extends StatelessWidget {
  final String title;
  final List<UsageCellData> hourlyData;
  final int maxTotal;
  final Color baseColor;
  final List<String> hourLabels;

  const DailyHeatMapSection({
    super.key,
    required this.title,
    required this.hourlyData,
    required this.maxTotal,
    required this.baseColor,
    this.hourLabels = const [
      '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11',
      '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23'
    ],
  });

  Color _getCellColor(UsageCellData data) {
    final intensity = maxTotal > 0 ? data.total / maxTotal : 0.0;
    return Color.lerp(Colors.white, baseColor, intensity)!;
  }

  void _showCellDetails(BuildContext context, UsageCellData data) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Usage Details'),
        content: Text('App Opened: ${data.appOpens} times\nWords Used: ${data.wordsUsed} times'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      children: [
        const Text("Low", style: TextStyle(fontSize: 12)),
        Expanded(
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, baseColor],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const Text("High", style: TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build 24 cells for hours with labels underneath.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: List.generate(24, (hour) {
            final cellData = hourlyData[hour];
            return Column(
              children: [
                InkWell(
                  onTap: () => _showCellDetails(context, cellData),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: _getCellColor(cellData),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(hourLabels[hour], style: const TextStyle(fontSize: 8)),
              ],
            );
          }),
        ),
        const SizedBox(height: 8),
        _buildLegend(context),
      ],
    );
  }
}
