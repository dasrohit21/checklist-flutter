import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/category_item.dart';
import '../models/mission_behavior_analysis.dart';
import '../models/target_item.dart';
import '../providers/app_state.dart';
import '../providers/behavior_provider.dart';
import '../screens/mission_workspace_screen.dart';
import '../services/mission_details_service.dart';
import '../services/mission_launcher.dart';
import 'highlight_text.dart';

// ── Mission Card ──────────────────────────────────────────────────────────────

/// Primary card widget for the Mission list.
///
/// Design principles:
///   - Left stripe instantly communicates state (accent = active, success = done,
///     warning = paused, muted = not started).
///   - Readable in under 3 seconds: title → state → progress → action.
///   - Entire card tappable → opens [MissionWorkspaceScreen].
class MissionCard extends StatelessWidget {
  final TargetItem item;
  final String searchQuery;

  const MissionCard({
    super.key,
    required this.item,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppState, BehaviorProvider>(
      builder: (context, appState, behavior, _) {
        final category = appState.categories
            .cast<CategoryItem?>()
            .firstWhere((c) => c?.id == item.categoryId, orElse: () => null);

        final activeMission = appState.activeMission;
        final isMissionActive =
            activeMission != null && activeMission.targetId == item.id;
        final isPaused = isMissionActive && activeMission.isPaused;
        final isCompleted =
            item.targetCount > 0 && item.solvedCount >= item.targetCount;

        final statusLabel = MissionDetailsService.getMissionStatusLabel(
          target: item,
          isArchived: false,
          activeMission: activeMission,
        );

        final analysis = behavior.missionHealthMap[item.id];
        final health = analysis?.healthStatus ??
            (isCompleted
                ? MissionHealthStatus.excellent
                : MissionHealthStatus.good);

        Color priorityColor = AppTheme.warning;
        if (item.priority == 'high') priorityColor = AppTheme.danger;
        if (item.priority == 'low') priorityColor = AppTheme.success;

        final progress = item.targetCount == 0
            ? 0.0
            : (item.solvedCount / item.targetCount).clamp(0.0, 1.0);

        // Left stripe color encodes mission state
        final Color stripeColor;
        if (isCompleted) {
          stripeColor = AppTheme.success;
        } else if (isMissionActive) {
          stripeColor = isPaused ? AppTheme.warning : AppTheme.accent;
        } else {
          stripeColor = AppTheme.border.withValues(alpha: 0.5);
        }

        // Card surface
        Color cardBg = AppTheme.surface.withValues(alpha: 0.75);
        if (isCompleted) cardBg = AppTheme.surface.withValues(alpha: 0.35);
        if (isMissionActive && !isPaused) cardBg = AppTheme.surface;

        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.sp12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MissionWorkspaceScreen(targetId: item.id),
                ),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isMissionActive && !isPaused
                        ? AppTheme.accent.withValues(alpha: 0.35)
                        : AppTheme.border.withValues(alpha: 0.15),
                    width: isMissionActive && !isPaused ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    if (isMissionActive && !isPaused)
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.1),
                        blurRadius: 14,
                        offset: const Offset(0, 3),
                      ),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── State stripe ──────────────────────────────────────
                      Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: stripeColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            bottomLeft: Radius.circular(18),
                          ),
                        ),
                      ),
                      // ── Card content ──────────────────────────────────────
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Row 1: category + priority → health dot + status
                              Row(
                                children: [
                                  _MiniChip(
                                    label: item.type == TargetType.checklist ? 'CHECKLIST' : 'PROBLEM',
                                    color: item.type == TargetType.checklist ? AppTheme.feature : AppTheme.accent,
                                  ),
                                  const SizedBox(width: 5),
                                  if (category != null) ...[
                                    _MiniChip(
                                      label: category.name,
                                      color: Color(category.colorValue),
                                    ),
                                    const SizedBox(width: 5),
                                  ],
                                  _MiniChip(
                                    label: item.priority.toUpperCase(),
                                    color: priorityColor,
                                  ),
                                  const Spacer(),
                                  // Health indicator dot
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: health.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    statusLabel,
                                    style: AppTheme.captionStyle.copyWith(
                                      color: isCompleted
                                          ? AppTheme.success
                                          : (isMissionActive
                                              ? AppTheme.accent
                                              : AppTheme.textMuted),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.sp10),

                              // Row 2: Mission title
                              HighlightText(
                                text: item.title,
                                query: searchQuery,
                                style: AppTheme.subtitleStyle.copyWith(
                                  color: isCompleted
                                      ? AppTheme.textMuted
                                      : AppTheme.text,
                                  fontWeight: FontWeight.w700,
                                  decoration: isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  fontSize: 16,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: AppTheme.sp12),

                              // Row 3: Progress bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 5,
                                  backgroundColor: AppTheme.surfaceStrong
                                      .withValues(alpha: 0.35),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isCompleted
                                        ? AppTheme.success
                                        : stripeColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Row 4: steps count + action button
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item.solvedCount} of ${item.targetCount} steps · ${(progress * 100).round()}%',
                                    style: AppTheme.captionStyle.copyWith(
                                      color: AppTheme.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (!isCompleted)
                                    _CardActionButton(
                                      isMissionActive: isMissionActive,
                                      isPaused: isPaused,
                                      item: item,
                                    )
                                  else
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle_rounded,
                                            color: AppTheme.success, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Done',
                                          style: AppTheme.captionStyle.copyWith(
                                            color: AppTheme.success,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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

// ── Shared helpers ────────────────────────────────────────────────────────────

/// Compact label chip used in MissionCard rows.
class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: AppTheme.captionStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Small action button at the bottom-right of a MissionCard.
class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.isMissionActive,
    required this.isPaused,
    required this.item,
  });
  final bool isMissionActive;
  final bool isPaused;
  final TargetItem item;

  @override
  Widget build(BuildContext context) {
    final Color btnColor;
    final IconData btnIcon;
    final String btnLabel;
    final VoidCallback onTap;

    if (isMissionActive) {
      btnColor = isPaused ? AppTheme.warning : AppTheme.accent;
      btnIcon = isPaused
          ? Icons.play_arrow_rounded
          : Icons.arrow_forward_rounded;
      btnLabel = isPaused ? 'Resume' : 'Continue';
      onTap = () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  MissionWorkspaceScreen(targetId: item.id),
            ),
          );
    } else {
      btnColor = AppTheme.accent;
      btnIcon = Icons.rocket_launch_rounded;
      btnLabel = 'Start Mission';
      onTap = () => MissionLauncher.showLaunchDialog(context, item);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: btnColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: btnColor.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(btnIcon, size: 13, color: btnColor),
            const SizedBox(width: 4),
            Text(
              btnLabel,
              style: AppTheme.captionStyle.copyWith(
                color: btnColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Archived Mission Card ─────────────────────────────────────────────────────

/// Compact archived row with muted stripe + restore CTA.
class ArchivedMissionCard extends StatelessWidget {
  final TargetItem item;
  final String searchQuery;

  const ArchivedMissionCard({
    super.key,
    required this.item,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final progress = item.targetCount == 0
            ? 0.0
            : (item.solvedCount / item.targetCount).clamp(0.0, 1.0);

        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.sp10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MissionWorkspaceScreen(
                    targetId: item.id,
                    isArchived: true,
                  ),
                ),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppTheme.border.withValues(alpha: 0.1)),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Muted stripe
                      Container(
                        width: 3,
                        decoration: BoxDecoration(
                          color: AppTheme.textMuted.withValues(alpha: 0.3),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(14),
                            bottomLeft: Radius.circular(14),
                          ),
                        ),
                      ),
                      // Content
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(12, 12, 12, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    HighlightText(
                                      text: item.title,
                                      query: searchQuery,
                                      style: AppTheme.bodyStyle.copyWith(
                                        color: AppTheme.textMuted,
                                        decoration:
                                            TextDecoration.lineThrough,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(3),
                                            child: LinearProgressIndicator(
                                              value: progress,
                                              minHeight: 3,
                                              backgroundColor:
                                                  AppTheme.surfaceStrong
                                                      .withValues(
                                                          alpha: 0.3),
                                              valueColor:
                                                  AlwaysStoppedAnimation<
                                                      Color>(
                                                AppTheme.textMuted
                                                    .withValues(alpha: 0.4),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${item.solvedCount}/${item.targetCount}',
                                          style: AppTheme.captionStyle
                                              .copyWith(
                                                  color:
                                                      AppTheme.textMuted),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppTheme.sp8),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.accent,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () =>
                                    appState.restoreTarget(item.id),
                                child: const Text(
                                  'Restore',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
