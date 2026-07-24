import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/learning_provider.dart';

/// Clean Statistics & Learning Engine screen.
///
/// Features:
///   - Fact-backed Learning Insights section.
///   - Top Overview Grid (Completion %, Planning Accuracy Diff, Best Working Period, Longest Streak).
///   - Today's, Weekly & Monthly Completion Progress.
///   - Category Duration & Frequency Analysis.
///   - Carry Forward & Recovery Usage metrics.
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LearningProvider>(
      builder: (context, learning, _) {
        final stats = learning.statistics;
        final insights = learning.insights;

        final completionPct = (stats.avgCompletionRate * 100).round();
        final accuracyDiff = stats.avgPlanningAccuracyMinutes;
        final accuracyLabel = accuracyDiff == 0
            ? 'Exact'
            : (accuracyDiff > 0 ? '+${accuracyDiff}m' : '${accuracyDiff}m');

        return Scaffold(
          backgroundColor: AppTheme.bg,
          appBar: AppBar(
            backgroundColor: AppTheme.surface,
            elevation: 0,
            title: Text(
              'Statistics & Insights',
              style: TextStyle(
                color: AppTheme.text,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            iconTheme: IconThemeData(color: AppTheme.text),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── 1. Learning Insights ─────────────────────────────────────────
              Text(
                'LEARNING INSIGHTS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              if (insights.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    'Complete more missions to unlock personalized insights.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                )
              else
                ...insights.map((insight) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.accent.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.lightbulb_outline_rounded,
                            color: AppTheme.accent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            insight,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.text,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 24),

              // ── 2. Top Metrics Grid ──────────────────────────────────────────
              Text(
                'PATTERN STATISTICS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                childAspectRatio: 1.4,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _MetricCard(
                    icon: Icons.pie_chart_outline_rounded,
                    title: 'Completion Rate',
                    value: '$completionPct%',
                    color: AppTheme.success,
                  ),
                  _MetricCard(
                    icon: Icons.timer_outlined,
                    title: 'Planning Accuracy',
                    value: accuracyLabel,
                    subtitle: 'Est. vs Actual',
                    color: AppTheme.accent,
                  ),
                  _MetricCard(
                    icon: Icons.wb_sunny_outlined,
                    title: 'Best Working Time',
                    value: stats.bestWorkingPeriod,
                    color: AppTheme.feature,
                  ),
                  _MetricCard(
                    icon: Icons.local_fire_department_rounded,
                    title: 'Longest Streak',
                    value: '${stats.longestStreakDays} days',
                    color: AppTheme.warning,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── 3. Category Durations ────────────────────────────────────────
              if (stats.avgCategoryDurationMinutes.isNotEmpty) ...[
                Text(
                  'AVERAGE MISSION DURATION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.border.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    children: stats.avgCategoryDurationMinutes.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(Icons.category_outlined,
                                size: 16, color: AppTheme.accent),
                            const SizedBox(width: 10),
                            Text(
                              e.key,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.text,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${e.value} min avg',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── 4. Recovery Usage ───────────────────────────────────────────
              Text(
                'RECOVERY USAGE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.border.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              size: 18, color: AppTheme.success),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${stats.totalRecoveryAccepted}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.text,
                                ),
                              ),
                              Text(
                                'Accepted',
                                style: TextStyle(
                                    fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.cancel_outlined,
                              size: 18, color: AppTheme.danger),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${stats.totalRecoveryDismissed}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.text,
                                ),
                              ),
                              Text(
                                'Dismissed',
                                style: TextStyle(
                                    fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.text,
            ),
          ),
          if (subtitle != null) ...[
            Text(
              subtitle!,
              style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
