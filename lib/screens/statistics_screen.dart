import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../providers/word_provider.dart';
import '../providers/category_provider.dart';
import '../models/word_button.dart';
import '../models/category.dart';
import '../theme/theme_provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _timeRange = 7;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usage Statistics'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: colorScheme.primary,
          tabs: const [
            Tab(text: 'Most Used'),
            Tab(text: 'Categories'),
            Tab(text: 'Activity'),
          ],
        ),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Select time range',
            onSelected: (value) {
              setState(() {
                _timeRange = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text('Last 7 days')),
              const PopupMenuItem(value: 30, child: Text('Last 30 days')),
              const PopupMenuItem(value: 90, child: Text('Last 3 months')),
              const PopupMenuItem(value: 0, child: Text('All time')),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMostUsedWordsTab(),
          _buildCategoriesTab(),
          _buildActivityTab(),
        ],
      ),
    );
  }

  String _getTimeRangeText() {
    switch (_timeRange) {
      case 0:
        return 'All time';
      case 7:
        return 'Last 7 days';
      case 30:
        return 'Last 30 days';
      case 90:
        return 'Last 3 months';
      default:
        return 'Last $_timeRange days';
    }
  }

  Widget _buildMostUsedWordsTab() {
    final wordProvider = Provider.of<WordProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    List<WordButton> allWords = [];

    for (var category in categoryProvider.categories) {
      allWords.addAll(wordProvider.getWordsForCategory(category.id));
    }

    if (_timeRange > 0) {
      final cutoff = DateTime.now().subtract(Duration(days: _timeRange));
      allWords = allWords.where((w) => w.lastUsed.isAfter(cutoff)).toList();
    }

    allWords.sort((a, b) => b.useCount.compareTo(a.useCount));
    final topWords = allWords.take(10).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Most Used Words', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_getTimeRangeText(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 16),
          Expanded(child: _buildWordUsageChart(topWords, categoryProvider)),
        ],
      ),
    );
  }

  Widget _buildWordUsageChart(List<WordButton> words, CategoryProvider categoryProvider) {
    final maxCount = words.isEmpty ? 1 : words.first.useCount;
    return BarChart(
      BarChartData(
        maxY: maxCount * 1.2,
        barGroups: List.generate(words.length, (i) {
          final word = words[i];
          final category = categoryProvider.categories.firstWhere(
            (cat) => cat.id == word.categoryId,
            orElse: () => Category(id: '', name: 'Unknown', icon: '?', color: Colors.grey, order: 0),
          );
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: word.useCount.toDouble(),
                width: 18,
                color: category.color,
                borderRadius: BorderRadius.circular(6),
              )
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < words.length) {
                  return Text(words[value.toInt()].word, style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
              reservedSize: 32,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: true),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    final wordProvider = Provider.of<WordProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    final categories = categoryProvider.categories;

    final usage = <String, int>{};
    int total = 0;

    for (var category in categories) {
      var words = wordProvider.getWordsForCategory(category.id);
      if (_timeRange > 0) {
        final cutoff = DateTime.now().subtract(Duration(days: _timeRange));
        words = words.where((w) => w.lastUsed.isAfter(cutoff)).toList();
      }
      final count = words.fold(0, (sum, w) => sum + w.useCount);
      usage[category.id] = count;
      total += count;
    }

    if (total == 0) {
      return const Center(child: Text('No data available.'));
    }

    final sortedCategories = categories.toList()
      ..sort((a, b) => (usage[b.id] ?? 0).compareTo(usage[a.id] ?? 0));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Category Usage', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_getTimeRangeText(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 16),
          Expanded(child: _buildPieChart(sortedCategories, usage, total)),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<Category> categories, Map<String, int> usage, int total) {
    return PieChart(
      PieChartData(
        sections: categories.map((cat) {
          final count = usage[cat.id] ?? 0;
          final percent = total > 0 ? count / total : 0;
          return PieChartSectionData(
            color: cat.color,
            value: percent,
            title: '${(percent * 100).toStringAsFixed(1)}%',
            titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 0,
      ),
    );
  }

  Widget _buildActivityTab() {
    final wordProvider = Provider.of<WordProvider>(context);
    final categoryProvider = Provider.of<CategoryProvider>(context);
    List<WordButton> allWords = [];

    for (var category in categoryProvider.categories) {
      allWords.addAll(wordProvider.getWordsForCategory(category.id));
    }

    if (_timeRange > 0) {
      final cutoff = DateTime.now().subtract(Duration(days: _timeRange));
      allWords = allWords.where((w) => w.lastUsed.isAfter(cutoff)).toList();
    }

    allWords.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));

    final grouped = <String, List<WordButton>>{};
    final formatter = DateFormat('yyyy-MM-dd');

    for (var word in allWords) {
      final dateStr = formatter.format(word.lastUsed);
      grouped.putIfAbsent(dateStr, () => []).add(word);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((entry) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.value.map((word) {
                    return Chip(
                      label: Text(word.word),
                      avatar: CircleAvatar(
                        backgroundColor: Colors.grey.shade300,
                        child: Text(word.useCount.toString(), style: const TextStyle(fontSize: 12)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
