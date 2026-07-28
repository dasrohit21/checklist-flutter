import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/mission_behavior_analysis.dart';
import '../providers/app_state.dart';
import '../providers/behavior_provider.dart';
import '../providers/learning_provider.dart';

/// Insights screen — unified learning statistics, behavior health, and
/// productivity history.
///
/// Tabs:
///   Learning    — planner patterns, completion rate, planning accuracy,
///                 best working period, behavior health, recovery usage.
///   Productivity — XP/level, streaks, focus stats, achievements,
///                  mission history.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.surface.withValues(alpha: 0.4),
                AppTheme.bg,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header + tabs
                Container(
                  padding: const EdgeInsets.fromLTRB(
                      AppTheme.sp24, AppTheme.sp16, AppTheme.sp24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Insights',
                        style: AppTheme.displayStyle
                            .copyWith(color: AppTheme.text),
                      ),
                      const SizedBox(height: AppTheme.sp12),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color:
                              AppTheme.surfaceStrong.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppTheme.border.withValues(alpha: 0.1)),
                        ),
                        child: TabBar(
                          indicator: BoxDecoration(
                            color: AppTheme.learning,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.white,
                          unselectedLabelColor: AppTheme.textMuted,
                          labelStyle: AppTheme.buttonStyle,
                          unselectedLabelStyle: AppTheme.bodyStyle,
                          tabs: const [
                            Tab(text: 'Learning'),
                            Tab(text: 'Productivity'),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.sp8),
                    ],
                  ),
                ),
                // Tab content
                const Expanded(
                  child: TabBarView(
                    children: [
                      _LearningTab(),
                      _ProductivityTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Learning Tab ─────────────────────────────────────────────────────────────
class _LearningTab extends StatelessWidget {
  const _LearningTab();

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

        return ListView(
          padding: const EdgeInsets.all(AppTheme.sp24),
          children: [
            // Learning Insights
            _SectionLabel(label: 'LEARNING INSIGHTS', color: AppTheme.learning),
            const SizedBox(height: AppTheme.sp12),
            if (insights.isEmpty)
              _InsightsEmptyState()
            else
              ...insights.map((insight) => _InsightCard(text: insight)),
            const SizedBox(height: AppTheme.sp24),

            // Pattern Statistics grid
            _SectionLabel(label: 'PATTERN STATISTICS', color: AppTheme.learning),
            const SizedBox(height: AppTheme.sp12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: AppTheme.sp12,
              mainAxisSpacing: AppTheme.sp12,
              shrinkWrap: true,
              childAspectRatio: 1.4,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _MetricTile(
                  icon: Icons.pie_chart_outline_rounded,
                  title: 'Completion Rate',
                  value: '$completionPct%',
                  color: AppTheme.success,
                ),
                _MetricTile(
                  icon: Icons.timer_outlined,
                  title: 'Planning Accuracy',
                  value: accuracyLabel,
                  subtitle: 'Est. vs Actual',
                  color: AppTheme.accent,
                ),
                _MetricTile(
                  icon: Icons.wb_sunny_outlined,
                  title: 'Best Working Time',
                  value: stats.bestWorkingPeriod,
                  color: AppTheme.learning,
                ),
                _MetricTile(
                  icon: Icons.local_fire_department_rounded,
                  title: 'Longest Streak',
                  value: '${stats.longestStreakDays} days',
                  color: AppTheme.warning,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.sp24),

            // Category durations
            if (stats.avgCategoryDurationMinutes.isNotEmpty) ...[
              const _SectionLabel(label: 'AVERAGE MISSION DURATION'),
              const SizedBox(height: AppTheme.sp12),
              _SurfaceCard(
                child: Column(
                  children: stats.avgCategoryDurationMinutes.entries
                      .map((e) => _CategoryDurationRow(name: e.key, minutes: e.value))
                      .toList(),
                ),
              ),
              const SizedBox(height: AppTheme.sp24),
            ],

            // Recovery usage
            const _SectionLabel(label: 'RECOVERY USAGE'),
            const SizedBox(height: AppTheme.sp12),
            _SurfaceCard(
              child: Row(
                children: [
                  _RecoveryStatCol(
                    icon: Icons.check_circle_outline_rounded,
                    color: AppTheme.success,
                    value: '${stats.totalRecoveryAccepted}',
                    label: 'Accepted',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppTheme.border.withValues(alpha: 0.2),
                    margin: const EdgeInsets.symmetric(horizontal: AppTheme.sp16),
                  ),
                  _RecoveryStatCol(
                    icon: Icons.cancel_outlined,
                    color: AppTheme.danger,
                    value: '${stats.totalRecoveryDismissed}',
                    label: 'Dismissed',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.sp24),

            // Behavior Intelligence
            Consumer<BehaviorProvider>(
              builder: (context, behavior, _) {
                final recs = behavior.recommendations;
                final healthMap = behavior.missionHealthMap;

                int excellent = 0, good = 0, warning = 0, critical = 0;
                healthMap.forEach((_, analysis) {
                  switch (analysis.healthStatus) {
                    case MissionHealthStatus.excellent:
                      excellent++;
                      break;
                    case MissionHealthStatus.good:
                      good++;
                      break;
                    case MissionHealthStatus.warning:
                      warning++;
                      break;
                    case MissionHealthStatus.critical:
                      critical++;
                      break;
                  }
                });

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel(label: 'MISSION HEALTH'),
                    const SizedBox(height: AppTheme.sp12),
                    _SurfaceCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _HealthCount(label: 'Excellent', count: excellent, color: AppTheme.success),
                          _HealthCount(label: 'Good', count: good, color: AppTheme.accent),
                          _HealthCount(label: 'Warning', count: warning, color: AppTheme.warning),
                          _HealthCount(label: 'Critical', count: critical, color: AppTheme.danger),
                        ],
                      ),
                    ),
                    if (recs.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.sp24),
                      _SectionLabel(label: 'BEHAVIORAL RECOMMENDATIONS', color: AppTheme.learning),
                      const SizedBox(height: AppTheme.sp12),
                      ...recs.map((rec) => _RecommendationCard(text: rec)),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: AppTheme.sp32),
          ],
        );
      },
    );
  }
}

// ── Productivity Tab ─────────────────────────────────────────────────────────
class _ProductivityTab extends StatelessWidget {
  const _ProductivityTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final history = appState.missionHistory;
        final completed =
            history.where((m) => m.status == 'completed').toList();
        final abandoned =
            history.where((m) => m.status == 'abandoned').toList();
        final totalMissions = history.length;
        final completionRate =
            totalMissions == 0 ? 0.0 : completed.length / totalMissions;

        final totalSeconds =
            completed.fold(0, (s, m) => s + m.durationSeconds);
        final deepWorkHours = totalSeconds / 3600.0;

        final totalFocus =
            history.fold(0, (s, m) => s + m.focusScore);
        final avgFocus =
            totalMissions == 0 ? 0 : totalFocus ~/ totalMissions;

        final longestMinutes = appState.longestSessionSeconds ~/ 60;
        final xpInLevel = appState.totalXp % 1000;
        final levelProgress = xpInLevel / 1000.0;

        return ListView(
          padding: const EdgeInsets.all(AppTheme.sp24),
          children: [
            // Level & XP
            const _SectionLabel(label: 'PRODUCTIVITY TIER'),
            const SizedBox(height: AppTheme.sp12),
            _SurfaceCard(
              child: Row(
                children: [
                  _LevelBadge(level: appState.level),
                  const SizedBox(width: AppTheme.sp16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Level ${appState.level}',
                              style: AppTheme.subtitleStyle
                                  .copyWith(color: AppTheme.text, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '$xpInLevel / 1000 XP',
                              style: AppTheme.captionStyle
                                  .copyWith(color: AppTheme.accent, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: levelProgress,
                            minHeight: 8,
                            backgroundColor:
                                AppTheme.surfaceStrong.withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.sp24),

            // Streaks
            const _SectionLabel(label: 'MISSION STREAKS'),
            const SizedBox(height: AppTheme.sp12),
            _SurfaceCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StreakColumn(
                    icon: Icons.local_fire_department_rounded,
                    color: AppTheme.danger,
                    value: '${appState.missionStreakCurrent}',
                    label: 'Current Streak',
                    unit: 'days',
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: AppTheme.border.withValues(alpha: 0.2),
                  ),
                  _StreakColumn(
                    icon: Icons.emoji_events_rounded,
                    color: AppTheme.warning,
                    value: '${appState.missionStreakBest}',
                    label: 'Longest Streak',
                    unit: 'days',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.sp24),

            // Focus stats grid
            const _SectionLabel(label: 'FOCUS ANALYTICS'),
            const SizedBox(height: AppTheme.sp12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 600 ? 3 : 2;
                final width =
                    (constraints.maxWidth - (AppTheme.sp12 * (columns - 1))) /
                        columns;
                return Wrap(
                  spacing: AppTheme.sp12,
                  runSpacing: AppTheme.sp12,
                  children: [
                    _FocusStatCard('${completed.length}', 'Completed', 'Successful runs', AppTheme.success, Icons.check_circle_rounded, width),
                    _FocusStatCard('${abandoned.length}', 'Abandoned', 'Failed sessions', AppTheme.danger, Icons.cancel_rounded, width),
                    _FocusStatCard('${(completionRate * 100).toStringAsFixed(0)}%', 'Success Rate', 'Overall efficiency', AppTheme.accent, Icons.donut_large, width),
                    _FocusStatCard('${deepWorkHours.toStringAsFixed(1)}h', 'Deep Work', 'Total focus time', AppTheme.success, Icons.timer_rounded, width),
                    _FocusStatCard('$avgFocus', 'Avg Focus', 'Focus score /100', AppTheme.warning, Icons.track_changes_rounded, width),
                    _FocusStatCard('${longestMinutes}m', 'Longest', 'Personal record', AppTheme.accent, Icons.workspace_premium_rounded, width),
                  ],
                );
              },
            ),
            const SizedBox(height: AppTheme.sp24),

            // Achievements
            const _SectionLabel(label: 'ACHIEVEMENTS'),
            const SizedBox(height: AppTheme.sp12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 500;
                final achievements = appState.achievements;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 3 : 2,
                    crossAxisSpacing: AppTheme.sp12,
                    mainAxisSpacing: AppTheme.sp12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: achievements.length,
                  itemBuilder: (context, idx) {
                    final ach = achievements[idx];
                    return Container(
                      padding: const EdgeInsets.all(AppTheme.sp12),
                      decoration: BoxDecoration(
                        color: ach.isUnlocked
                            ? AppTheme.accent.withValues(alpha: 0.08)
                            : AppTheme.surface.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: ach.isUnlocked
                              ? AppTheme.accent
                              : AppTheme.border.withValues(alpha: 0.1),
                          width: ach.isUnlocked ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            ach.icon,
                            color: ach.isUnlocked
                                ? AppTheme.accent
                                : AppTheme.textMuted,
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ach.title,
                            style: AppTheme.captionStyle.copyWith(
                              fontWeight: FontWeight.w700,
                              color: ach.isUnlocked
                                  ? AppTheme.text
                                  : AppTheme.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ach.description,
                            style: AppTheme.captionStyle.copyWith(
                              fontSize: 9,
                              color: AppTheme.textMuted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: AppTheme.sp24),

            // Mission history
            const _SectionLabel(label: 'MISSION HISTORY'),
            const SizedBox(height: AppTheme.sp12),
            if (history.isEmpty)
              const _EmptyInsightState(
                icon: Icons.history_rounded,
                message: 'No missions completed yet.\nLaunch a mission to begin.',
              )
            else ...[
              ...history.reversed.take(8).map((item) {
                final isCompleted = item.status == 'completed';
                final durationMins = item.durationSeconds ~/ 60;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(AppTheme.sp12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppTheme.success.withValues(alpha: 0.1)
                              : AppTheme.danger.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check_rounded : Icons.close_rounded,
                          color: isCompleted ? AppTheme.success : AppTheme.danger,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: AppTheme.sp12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: AppTheme.bodyStyle.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.text),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$durationMins min • ${item.interruptions} interrupts',
                              style: AppTheme.captionStyle
                                  .copyWith(color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isCompleted ? '+${item.xpEarned} XP' : '0 XP',
                            style: AppTheme.captionStyle.copyWith(
                              color: isCompleted
                                  ? AppTheme.accent
                                  : AppTheme.textMuted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            isCompleted
                                ? 'Focus: ${item.focusScore}'
                                : 'Abandoned',
                            style: AppTheme.captionStyle.copyWith(
                              color: isCompleted
                                  ? AppTheme.success
                                  : AppTheme.danger,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: AppTheme.sp32),
          ],
        );
      },
    );
  }
}

// ── Shared Widgets ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTheme.labelStyle.copyWith(color: color ?? AppTheme.textMuted),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.sp16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
      ),
      child: child,
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppTheme.sp12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.lightbulb_outline_rounded,
                color: AppTheme.accent, size: 15),
          ),
          const SizedBox(width: AppTheme.sp12),
          Expanded(
            child: Text(text, style: AppTheme.bodyStyle.copyWith(color: AppTheme.text)),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppTheme.sp12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.learning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.recommend_rounded, color: AppTheme.learning, size: 18),
          const SizedBox(width: AppTheme.sp12),
          Expanded(
            child: Text(text, style: AppTheme.bodyStyle.copyWith(color: AppTheme.text)),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.sp12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.captionStyle.copyWith(color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(value, style: AppTheme.titleStyle.copyWith(color: AppTheme.text)),
          if (subtitle != null)
            Text(subtitle!,
                style: AppTheme.captionStyle.copyWith(fontSize: 10, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

class _CategoryDurationRow extends StatelessWidget {
  const _CategoryDurationRow({required this.name, required this.minutes});
  final String name;
  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.category_outlined, size: 14, color: AppTheme.accent),
          const SizedBox(width: 10),
          Text(name, style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.w600, color: AppTheme.text)),
          const Spacer(),
          Text('$minutes min avg',
              style: AppTheme.captionStyle.copyWith(color: AppTheme.textMuted, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _RecoveryStatCol extends StatelessWidget {
  const _RecoveryStatCol({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: AppTheme.titleStyle.copyWith(
                      fontWeight: FontWeight.w700, color: AppTheme.text)),
              Text(label,
                  style: AppTheme.captionStyle.copyWith(color: AppTheme.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthCount extends StatelessWidget {
  const _HealthCount({
    required this.label,
    required this.count,
    required this.color,
  });
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('$count',
              style: AppTheme.subtitleStyle.copyWith(
                  fontWeight: FontWeight.w700, color: color)),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTheme.captionStyle.copyWith(color: AppTheme.textMuted)),
      ],
    );
  }
}

class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppTheme.accent, AppTheme.accent.withValues(alpha: 0.6)],
        ),
        boxShadow: [
          BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 2)
        ],
      ),
      child: Center(
        child: Text(
          'Lv$level',
          style: AppTheme.captionStyle.copyWith(
              color: const Color(0xFF030712), fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _StreakColumn extends StatelessWidget {
  const _StreakColumn({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.unit,
  });
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 6),
        Text('$value $unit',
            style: AppTheme.headingStyle.copyWith(color: AppTheme.text)),
        Text(label,
            style: AppTheme.captionStyle.copyWith(color: AppTheme.textMuted)),
      ],
    );
  }
}

class _FocusStatCard extends StatelessWidget {
  const _FocusStatCard(
      this.value, this.title, this.subtitle, this.color, this.icon, this.width);
  final String value;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(AppTheme.sp12),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 18),
              Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: AppTheme.titleStyle.copyWith(fontWeight: FontWeight.w700, color: AppTheme.text)),
          const SizedBox(height: 2),
          Text(title, style: AppTheme.captionStyle.copyWith(fontWeight: FontWeight.w600, color: AppTheme.text)),
          Text(subtitle, style: AppTheme.captionStyle.copyWith(fontSize: 10, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

class _InsightsEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.sp24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(Icons.insights_outlined, color: AppTheme.textMuted, size: 32),
          const SizedBox(height: AppTheme.sp12),
          Text(
            'Insights unlock after completing missions.',
            style: AppTheme.bodyStyle.copyWith(color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyInsightState extends StatelessWidget {
  const _EmptyInsightState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.sp24),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 32),
          const SizedBox(height: AppTheme.sp12),
          Text(
            message,
            style: AppTheme.bodyStyle.copyWith(color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
