import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_provider.dart';
import '../widgets/Stats/heat_map_section.dart'; // Exports UsageCellData, WeeklyHeatMapSection & DailyHeatMapSection

class StatisticsScreen extends StatefulWidget {
  final Map<String, int> wordUsage;
  final int totalWordsSpoken;
  final Duration screenTime;
  final Map<String, int> usageEvents;
  final Map<String, int> categoryTapCounts;
  final Map<String, int> wordSequenceCounts;
  final bool initialStatisticsEnabled;

  const StatisticsScreen({
    super.key,
    required this.wordUsage,
    required this.totalWordsSpoken,
    required this.screenTime,
    required this.usageEvents,
    required this.categoryTapCounts,
    required this.wordSequenceCounts,
    this.initialStatisticsEnabled = false,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with AutomaticKeepAliveClientMixin {
  late Duration _liveScreenTime;
  Timer? _timer;
  Timer? _heatMapTimer;

  late String _mostUsedWord;
  late String _mostTappedCategory;
  late int _totalUsageEvents;
  late List<MapEntry<String, int>> _sortedWordUsage;
  late List<MapEntry<String, int>> _sortedCategoryTaps;
  late List<MapEntry<String, int>> _sortedUsageEvents;
  late List<MapEntry<String, int>> _sortedWordSequences;

  late bool _statisticsEnabled;

  // Aggregated heat map data from stored usage.
  List<List<UsageCellData>>? _weeklyHeatMapData;
  List<UsageCellData>? _dailyHeatMapData;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _statisticsEnabled = widget.initialStatisticsEnabled;
    _liveScreenTime = widget.screenTime;
    if (_statisticsEnabled) {
      _processData();
      _startTimer();
      _loadHeatMapData();
      // Start a separate timer to refresh heat map data every 10 seconds.
      _heatMapTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        if (mounted) _loadHeatMapData();
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _liveScreenTime += const Duration(seconds: 1);
        });
      }
    });
  }

  // Process non–heat map statistics.
  void _processData() {
    _sortedWordUsage = widget.wordUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _sortedCategoryTaps = widget.categoryTapCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _sortedUsageEvents = widget.usageEvents.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _sortedWordSequences = widget.wordSequenceCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    _mostUsedWord = _sortedWordUsage.isNotEmpty ? _sortedWordUsage.first.key : 'None';
    _mostTappedCategory =
        _sortedCategoryTaps.isNotEmpty ? _sortedCategoryTaps.first.key : 'None';
    _totalUsageEvents = widget.usageEvents.values.fold(0, (a, b) => a + b);
  }

  // Loads and aggregates real usage data from SharedPreferences.
  Future<void> _loadHeatMapData() async {
    final prefs = await SharedPreferences.getInstance();

    // Aggregate weekly data from app open timestamps.
    final timestamps = prefs.getStringList('appOpenCount_timestamps') ?? [];
    List<DateTime> dateTimes = timestamps.map((s) => DateTime.parse(s)).toList()..sort();

    // Determine the start of the current week (Monday as first day)
    DateTime now = DateTime.now();
    int weekday = now.weekday; // Monday = 1
    DateTime startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: weekday - 1));
    const int numWeeks = 3; // For example, display last 3 weeks.
    List<List<UsageCellData>> weeklyData = List.generate(
      numWeeks,
      (_) => List.generate(7, (_) => const UsageCellData(appOpens: 0, wordsUsed: 0)),
    );

    for (var dt in dateTimes) {
      // Include only events from the last numWeeks.
      if (dt.isBefore(startOfWeek.subtract(Duration(days: 7 * (numWeeks - 1))))) continue;
      int diffDays = startOfWeek.difference(DateTime(dt.year, dt.month, dt.day)).inDays;
      // Negative diffDays indicates dt is on or after startOfWeek.
      int weekIndex = numWeeks - 1 - (-diffDays ~/ 7);
      int dayIndex = dt.weekday - 1; // Monday=0, Sunday=6.
      if (weekIndex >= 0 && weekIndex < numWeeks) {
        weeklyData[weekIndex][dayIndex] = UsageCellData(
          appOpens: weeklyData[weekIndex][dayIndex].appOpens + 1,
          wordsUsed: weeklyData[weekIndex][dayIndex].wordsUsed,
        );
      }
    }

    // Aggregate daily data from button press details.
    String? storedDetails = prefs.getString('buttonPressDetails');
    List<UsageCellData> dailyData = List.generate(
      24,
      (_) => const UsageCellData(appOpens: 0, wordsUsed: 0),
    );
    if (storedDetails != null) {
      List<Map<String, String>> details =
          List<Map<String, String>>.from(jsonDecode(storedDetails));
      for (var detail in details) {
        DateTime dt = DateTime.parse(detail['timestamp']!);
        int hour = dt.hour;
        dailyData[hour] = UsageCellData(
          appOpens: dailyData[hour].appOpens,
          wordsUsed: dailyData[hour].wordsUsed + 1,
        );
      }
    }

    setState(() {
      _weeklyHeatMapData = weeklyData;
      _dailyHeatMapData = dailyData;
    });
  }

  // Getters to compute maximum totals for scaling.
  int get _maxWeeklyValue {
    if (_weeklyHeatMapData == null) return 0;
    int maxVal = 0;
    for (var week in _weeklyHeatMapData!) {
      int weekMax = week.map((cell) => cell.total).reduce(max);
      if (weekMax > maxVal) maxVal = weekMax;
    }
    return maxVal;
  }

  int get _maxDailyValue {
    if (_dailyHeatMapData == null || _dailyHeatMapData!.isEmpty) return 0;
    return _dailyHeatMapData!.map((cell) => cell.total).reduce(max);
  }

  @override
  void didUpdateWidget(covariant StatisticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_statisticsEnabled) {
      if (oldWidget.wordUsage != widget.wordUsage ||
          oldWidget.categoryTapCounts != widget.categoryTapCounts ||
          oldWidget.usageEvents != widget.usageEvents ||
          oldWidget.wordSequenceCounts != widget.wordSequenceCounts) {
        _processData();
      }
      if (oldWidget.screenTime != widget.screenTime) {
        _liveScreenTime = widget.screenTime;
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _heatMapTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final primaryColor = Provider.of<ThemeProvider>(context).primaryColor;
    return Scaffold(
      body: _statisticsEnabled
          ? RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _processData();
                });
                await _loadHeatMapData();
              },
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 150,
                    backgroundColor: primaryColor,
                    flexibleSpace: FlexibleSpaceBar(
                      title: const Text('Statistics'),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor.withAlpha((0.7 * 255).round()),
                              primaryColor,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh statistics',
                        onPressed: () {
                          setState(() {
                            _processData();
                          });
                          _loadHeatMapData();
                        },
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildHeaderSection(),
                        const SizedBox(height: 24),
                        _buildSummaryCards(context, primaryColor),
                        const SizedBox(height: 32),
                        _buildStatSection(
                          title: 'Usage Events',
                          sortedData: _sortedUsageEvents,
                          total: _totalUsageEvents,
                          primaryColor: primaryColor,
                        ),
                        const SizedBox(height: 32),
                        _buildStatSection(
                          title: 'Top Word Sequences',
                          sortedData: _sortedWordSequences,
                          total: widget.totalWordsSpoken,
                          primaryColor: primaryColor,
                          emptyMessage: 'No word sequences recorded.',
                        ),
                        const SizedBox(height: 32),
                        _buildStatSection(
                          title: 'Word Usage Details',
                          sortedData: _sortedWordUsage,
                          total: widget.totalWordsSpoken,
                          primaryColor: primaryColor,
                          showPercentage: true,
                          emptyMessage: 'No word usage statistics available.',
                        ),
                        const SizedBox(height: 32),
                        // Heat Map Sections with placeholders.
                        _weeklyHeatMapData != null
                            ? WeeklyHeatMapSection(
                                title: 'Weekly Usage Heat Map',
                                weeklyData: _weeklyHeatMapData!,
                                maxTotal: _maxWeeklyValue,
                                baseColor: primaryColor,
                              )
                            : const Center(child: CircularProgressIndicator()),
                        const SizedBox(height: 32),
                        _dailyHeatMapData != null
                            ? DailyHeatMapSection(
                                title: 'Daily Usage Heat Map',
                                hourlyData: _dailyHeatMapData!,
                                maxTotal: _maxDailyValue,
                                baseColor: primaryColor,
                              )
                            : const Center(child: CircularProgressIndicator()),
                      ]),
                    ),
                  ),
                ],
              ),
            )
          : Center(
              child: Text(
                'Statistics are currently disabled',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        Text(
          'Live Statistics',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.circle, color: Colors.green, size: 12),
            const SizedBox(width: 8),
            Text(
              'Tracking in real-time...',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCards(BuildContext context, Color primaryColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWide = constraints.maxWidth > 600;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Words',
                  widget.totalWordsSpoken.toString(),
                  Icons.chat_bubble_outline,
                  primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Most Used Word',
                  _mostUsedWord,
                  Icons.star_outline,
                  primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Most Used Category',
                  _mostTappedCategory,
                  Icons.category_outlined,
                  primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildScreenTimeCard(primaryColor)),
            ],
          );
        } else {
          return Column(
            children: [
              _buildSummaryCard(
                'Total Words',
                widget.totalWordsSpoken.toString(),
                Icons.chat_bubble_outline,
                primaryColor,
              ),
              const SizedBox(height: 16),
              _buildSummaryCard(
                'Most Used Word',
                _mostUsedWord,
                Icons.star_outline,
                primaryColor,
              ),
              const SizedBox(height: 16),
              _buildSummaryCard(
                'Most Used Category',
                _mostTappedCategory,
                Icons.category_outlined,
                primaryColor,
              ),
              const SizedBox(height: 16),
              _buildScreenTimeCard(primaryColor),
            ],
          );
        }
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color primaryColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 40, color: primaryColor),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScreenTimeCard(Color primaryColor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.timer_outlined, size: 40, color: primaryColor.withAlpha(204)),
            const SizedBox(height: 16),
            Text(
              _formatDuration(_liveScreenTime),
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

  Widget _buildStatSection({
    required String title,
    required List<MapEntry<String, int>> sortedData,
    required int total,
    required Color primaryColor,
    bool showPercentage = false,
    String emptyMessage = 'No data available.',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        const SizedBox(height: 8),
        if (sortedData.isEmpty)
          _buildEmptyMessage(emptyMessage)
        else
          ...sortedData
              .take(10)
              .map((entry) => _buildProgressItem(entry, total, primaryColor, showPercentage: showPercentage)),
        if (sortedData.length > 10)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Center(
              child: TextButton.icon(
                icon: const Icon(Icons.more_horiz),
                label: Text('${sortedData.length - 10} more items'),
                onPressed: () {
                  // Optionally implement a full list view.
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        const Expanded(child: Divider()),
      ],
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: Text(message, style: TextStyle(color: Colors.grey[600]))),
      ),
    );
  }

  Widget _buildProgressItem(MapEntry<String, int> entry, int total, Color primaryColor, {bool showPercentage = false}) {
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
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  showPercentage ? '${percentage.toStringAsFixed(1)}%' : '${entry.value}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                color: primaryColor,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              showPercentage ? '${entry.value} times' : '${entry.value} / $total',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}