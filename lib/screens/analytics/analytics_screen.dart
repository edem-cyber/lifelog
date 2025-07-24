import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../providers/journal_provider.dart';
import '../../models/journal_entry_model.dart';
import '../../theme/app_theme.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(journalProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: entriesAsync.when(
        data: (entries) => _buildAnalytics(context, entries),
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, _) =>
                Center(child: Text('Error loading analytics: $error')),
      ),
    );
  }

  Widget _buildAnalytics(
    BuildContext context,
    List<JournalEntryModel> entries,
  ) {
    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No entries yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Start journaling to see your mood trends!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMoodOverview(context, entries),
          const SizedBox(height: 24),
          _buildMoodTrendChart(context, entries),
          const SizedBox(height: 24),
          _buildMoodDistributionChart(context, entries),
          const SizedBox(height: 24),
          _buildStreaks(context, entries),
        ],
      ),
    );
  }

  Widget _buildMoodOverview(
    BuildContext context,
    List<JournalEntryModel> entries,
  ) {
    final avgMood =
        entries.map((e) => e.mood).reduce((a, b) => a + b) / entries.length;
    final lastEntry = entries.first;
    final totalEntries = entries.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood Overview',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Average Mood',
                  avgMood.toStringAsFixed(1),
                  lastEntry.moodEmoji,
                ),
                _buildStatCard('Total Entries', totalEntries.toString(), '📝'),
                _buildStatCard(
                  'Latest Mood',
                  lastEntry.mood.toString(),
                  lastEntry.moodEmoji,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMoodTrendChart(
    BuildContext context,
    List<JournalEntryModel> entries,
  ) {
    final last30Days = entries.take(30).toList().reversed.toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood Trend (Last 30 Days)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 1,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < last30Days.length &&
                              value.toInt() % 5 == 0) {
                            final entry = last30Days[value.toInt()];
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                DateFormat('M/d').format(entry.date),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        },
                        reservedSize: 32,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey[300]!, width: 1),
                  ),
                  minX: 0,
                  maxX: (last30Days.length - 1).toDouble(),
                  minY: 1,
                  maxY: 5,
                  lineBarsData: [
                    LineChartBarData(
                      spots:
                          last30Days.asMap().entries.map((entry) {
                            return FlSpot(
                              entry.key.toDouble(),
                              entry.value.mood.toDouble(),
                            );
                          }).toList(),
                      isCurved: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.8),
                          AppColors.primary,
                        ],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: AppColors.primary,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.3),
                            AppColors.primary.withOpacity(0.1),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodDistributionChart(
    BuildContext context,
    List<JournalEntryModel> entries,
  ) {
    final moodCounts = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      moodCounts[i] = entries.where((e) => e.mood == i).length;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood Distribution',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Pie Chart
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        startDegreeOffset: -90,
                        sections:
                            moodCounts.entries
                                .where((entry) => entry.value > 0)
                                .map((entry) {
                                  final percentage =
                                      (entry.value / entries.length) * 100;
                                  return PieChartSectionData(
                                    color: _getMoodColor(entry.key),
                                    value: entry.value.toDouble(),
                                    title: '${percentage.toStringAsFixed(1)}%',
                                    radius: 50,
                                    titleStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                })
                                .toList(),
                      ),
                    ),
                  ),
                ),
                // Legend
                Expanded(
                  flex: 3,
                  child: Column(
                    children:
                        moodCounts.entries.map((entry) {
                          final percentage =
                              entries.isEmpty
                                  ? 0.0
                                  : (entry.value / entries.length) * 100;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: _getMoodColor(entry.key),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  JournalEntryModel.getMoodEmoji(entry.key),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    JournalEntryModel.getMoodDescription(
                                      entry.key,
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Text(
                                  '${entry.value}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreaks(BuildContext context, List<JournalEntryModel> entries) {
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    final sortedEntries = List<JournalEntryModel>.from(entries)
      ..sort((a, b) => b.date.compareTo(a.date));

    DateTime? lastDate;
    for (final entry in sortedEntries) {
      if (lastDate == null) {
        tempStreak = 1;
        lastDate = entry.date;
      } else {
        final daysDiff = lastDate.difference(entry.date).inDays;
        if (daysDiff == 1) {
          tempStreak++;
        } else {
          if (tempStreak > longestStreak) longestStreak = tempStreak;
          tempStreak = 1;
        }
        lastDate = entry.date;
      }
    }

    if (tempStreak > longestStreak) longestStreak = tempStreak;

    // Current streak calculation
    final today = DateTime.now();
    if (sortedEntries.isNotEmpty) {
      final daysSinceLastEntry =
          today.difference(sortedEntries.first.date).inDays;
      if (daysSinceLastEntry <= 1) {
        currentStreak = tempStreak;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Journaling Streaks',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Current Streak', '$currentStreak days', '🔥'),
                _buildStatCard('Longest Streak', '$longestStreak days', '🏆'),
                _buildStatCard(
                  'This Month',
                  '${_getThisMonthCount(entries)} days',
                  '📅',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _getThisMonthCount(List<JournalEntryModel> entries) {
    final now = DateTime.now();
    return entries.where((entry) {
      return entry.date.year == now.year && entry.date.month == now.month;
    }).length;
  }

  Color _getMoodColor(int mood) {
    switch (mood) {
      case 1:
        return Colors.red[600]!;
      case 2:
        return Colors.orange[600]!;
      case 3:
        return Colors.yellow[700]!;
      case 4:
        return Colors.lightGreen[600]!;
      case 5:
        return Colors.green[600]!;
      default:
        return AppColors.primary;
    }
  }
}
