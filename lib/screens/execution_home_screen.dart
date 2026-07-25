import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/planner_entry.dart';
import '../providers/app_state.dart';
import '../providers/coach_provider.dart';
import '../providers/planner_provider.dart';

/// Execution-first Home screen.
///
/// Answers "What should I do right now?"
///
/// Sections (top to bottom):
///   1. Greeting — Good Morning/Afternoon/Evening based on time of day
///   2. Continue Mission — visible only when a mission is in progress today
///   3. Today's Plan — max 5 with expand, from PlannerProvider.todayEntries
///   4. Coach Card — single compact message from CoachProvider
///   5. Today's Progress — progress bar, completed/remaining/focus time
class ExecutionHomeScreen extends StatelessWidget {
  const ExecutionHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppState, PlannerProvider>(
      builder: (context, appState, planner, _) {
        return Container(
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.sp24,
                vertical: AppTheme.sp16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1 ── Greeting ─────────────────────────────────────
                      _GreetingSection(appState: appState),
                      const SizedBox(height: AppTheme.sp24),

                      // 2 ── Continue Mission ─────────────────────────────
                      _ContinueMissionBanner(planner: planner),

                      // 3 ── Today's Plan ─────────────────────────────────
                      _TodayPlanSection(planner: planner),
                      const SizedBox(height: AppTheme.sp24),

                      // 4 ── Coach Card ───────────────────────────────────
                      const _CompactCoachCard(),
                      const SizedBox(height: AppTheme.sp24),

                      // 5 ── Today's Progress ─────────────────────────────
                      _TodayProgressSection(
                        planner: planner,
                        appState: appState,
                      ),
                      const SizedBox(height: AppTheme.sp32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── 1. Greeting ──────────────────────────────────────────────────────────────
class _GreetingSection extends StatelessWidget {
  const _GreetingSection({required this.appState});
  final AppState appState;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    if (h < 21) return 'Good Evening';
    return 'Good Night';
  }

  String _dateLine() {
    final today = DateTime.now();
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${weekdays[today.weekday - 1]}, ${today.day} ${months[today.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: AppTheme.displayStyle.copyWith(color: AppTheme.text),
              ),
              const SizedBox(height: 4),
              Text(
                _dateLine(),
                style: AppTheme.bodyStyle.copyWith(color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
        // Streak badge (visible only when streak > 0)
        if (appState.missionStreakCurrent > 0)
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.sp12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppTheme.danger.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department_rounded,
                    color: AppTheme.danger, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${appState.missionStreakCurrent}d',
                  style: AppTheme.subtitleStyle.copyWith(
                      color: AppTheme.danger, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── 2. Continue Mission Banner ───────────────────────────────────────────────
class _ContinueMissionBanner extends StatelessWidget {
  const _ContinueMissionBanner({required this.planner});
  final PlannerProvider planner;

  @override
  Widget build(BuildContext context) {
    final inProgress = planner.todayEntries
        .where((e) => e.status == PlannerEntryStatus.inProgress)
        .toList();

    if (inProgress.isEmpty) return const SizedBox.shrink();

    final entry = inProgress.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.sp24),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.sp16),
        decoration: BoxDecoration(
          color: AppTheme.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: AppTheme.accent.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.play_circle_rounded,
                  color: AppTheme.accent, size: 22),
            ),
            const SizedBox(width: AppTheme.sp16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONTINUE MISSION',
                    style: AppTheme.captionStyle.copyWith(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.targetName,
                    style: AppTheme.titleStyle.copyWith(color: AppTheme.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.estimatedDurationMinutes} min estimated',
                    style: AppTheme.captionStyle
                        .copyWith(color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.sp16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Switch to Planner tab to resume.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Resume'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 3. Today's Plan ──────────────────────────────────────────────────────────
class _TodayPlanSection extends StatefulWidget {
  const _TodayPlanSection({required this.planner});
  final PlannerProvider planner;

  @override
  State<_TodayPlanSection> createState() => _TodayPlanSectionState();
}

class _TodayPlanSectionState extends State<_TodayPlanSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entries = widget.planner.todayEntries;
    const maxVisible = 5;
    final visible =
        _expanded ? entries : entries.take(maxVisible).toList();
    final hasMore = !_expanded && entries.length > maxVisible;
    final completedCount = entries
        .where((e) => e.status == PlannerEntryStatus.completed)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "TODAY'S PLAN",
              style: AppTheme.labelStyle.copyWith(color: AppTheme.textMuted),
            ),
            if (entries.isNotEmpty)
              Text(
                '$completedCount/${entries.length}',
                style: AppTheme.captionStyle
                    .copyWith(color: AppTheme.textMuted),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.sp12),

        if (entries.isEmpty)
          const _HomeEmptyState(
            icon: Icons.today_outlined,
            title: 'Nothing planned today.',
            subtitle: 'Open Planner to create your first mission.',
          )
        else ...[
          ...visible.map((e) => _TodayMissionRow(entry: e)),
          if (hasMore) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _expanded = true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceStrong.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.border.withValues(alpha: 0.2)),
                ),
                child: Text(
                  '+ ${entries.length - maxVisible} more missions',
                  textAlign: TextAlign.center,
                  style: AppTheme.captionStyle.copyWith(
                      color: AppTheme.accent, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _TodayMissionRow extends StatelessWidget {
  const _TodayMissionRow({required this.entry});
  final PlannerEntry entry;

  bool get _isCompleted => entry.status == PlannerEntryStatus.completed;

  Color _statusColor() {
    if (_isCompleted) return AppTheme.success;
    if (entry.status == PlannerEntryStatus.inProgress) return AppTheme.accent;
    return AppTheme.textMuted;
  }

  IconData _statusIcon() {
    if (_isCompleted) return Icons.check_circle_rounded;
    if (entry.status == PlannerEntryStatus.inProgress) {
      return Icons.play_circle_rounded;
    }
    return Icons.radio_button_unchecked_rounded;
  }

  Color _priorityColor() {
    switch (entry.priority) {
      case 'high':
        return AppTheme.danger;
      case 'low':
        return AppTheme.success;
      default:
        return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = _isCompleted;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.sp16, vertical: AppTheme.sp12),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppTheme.surface.withValues(alpha: 0.3)
            : AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted
              ? AppTheme.border.withValues(alpha: 0.1)
              : AppTheme.border.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(_statusIcon(), color: _statusColor(), size: 20),
          const SizedBox(width: AppTheme.sp12),
          Expanded(
            child: Text(
              entry.targetName,
              style: AppTheme.bodyStyle.copyWith(
                color: isCompleted ? AppTheme.textMuted : AppTheme.text,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                fontWeight:
                    entry.status == PlannerEntryStatus.inProgress
                        ? FontWeight.w600
                        : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Priority indicator dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _priorityColor(),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entry.estimatedDurationMinutes}m',
            style: AppTheme.captionStyle.copyWith(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── 4. Coach Card (compact) ──────────────────────────────────────────────────
class _CompactCoachCard extends StatelessWidget {
  const _CompactCoachCard();

  @override
  Widget build(BuildContext context) {
    return Consumer<CoachProvider>(
      builder: (context, coach, _) {
        if (!coach.isEnabled || coach.currentMessage == null) {
          return const SizedBox.shrink();
        }
        final msg = coach.currentMessage!;
        return Container(
          padding: const EdgeInsets.all(AppTheme.sp16),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: AppTheme.border.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.feature.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.psychology_rounded,
                    color: AppTheme.feature, size: 18),
              ),
              const SizedBox(width: AppTheme.sp12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COACH',
                      style: AppTheme.labelStyle.copyWith(
                          color: AppTheme.feature.withValues(alpha: 0.8)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      msg.body,
                      style: AppTheme.bodyStyle.copyWith(color: AppTheme.text),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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

// ── 5. Today's Progress ──────────────────────────────────────────────────────
class _TodayProgressSection extends StatelessWidget {
  const _TodayProgressSection(
      {required this.planner, required this.appState});
  final PlannerProvider planner;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final entries = planner.todayEntries;
    final total = entries.length;
    final completed = entries
        .where((e) => e.status == PlannerEntryStatus.completed)
        .length;
    final remaining = total - completed;
    final progress = total == 0 ? 0.0 : completed / total;

    // Focus time: sum completed mission durations today from mission history
    final today = DateTime.now();
    final todayHistory = appState.missionHistory.where((h) {
      final endDate = h.endTime;
      return endDate.year == today.year &&
          endDate.month == today.month &&
          endDate.day == today.day &&
          h.status == 'completed';
    }).toList();
    final focusMinutes =
        todayHistory.fold(0, (s, h) => s + h.durationSeconds ~/ 60);

    return Container(
      padding: const EdgeInsets.all(AppTheme.sp24),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "TODAY'S PROGRESS",
            style: AppTheme.labelStyle.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: AppTheme.sp16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor:
                  AppTheme.surfaceStrong.withValues(alpha: 0.4),
              valueColor: AlwaysStoppedAnimation<Color>(
                  completed == total && total > 0
                      ? AppTheme.success
                      : AppTheme.accent),
            ),
          ),
          const SizedBox(height: AppTheme.sp16),

          // Stats row
          Row(
            children: [
              _StatPill(
                icon: Icons.check_circle_rounded,
                value: '$completed',
                label: 'Done',
                color: AppTheme.success,
              ),
              const SizedBox(width: AppTheme.sp12),
              _StatPill(
                icon: Icons.pending_rounded,
                value: '$remaining',
                label: 'Left',
                color: remaining > 0
                    ? AppTheme.warning
                    : AppTheme.textMuted,
              ),
              const SizedBox(width: AppTheme.sp12),
              _StatPill(
                icon: Icons.timer_rounded,
                value: '${focusMinutes}m',
                label: 'Focus',
                color: AppTheme.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTheme.titleStyle.copyWith(color: AppTheme.text),
            ),
            Text(
              label,
              style: AppTheme.captionStyle.copyWith(
                  color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared Empty State ───────────────────────────────────────────────────────
class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: AppTheme.sp32, horizontal: AppTheme.sp24),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 36),
          const SizedBox(height: AppTheme.sp12),
          Text(
            title,
            style: AppTheme.subtitleStyle.copyWith(color: AppTheme.text),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTheme.captionStyle.copyWith(color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
