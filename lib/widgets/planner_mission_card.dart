import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/mission_context.dart';
import '../models/planner_entry.dart';

/// A reusable card that represents a single mission entry in the Planner.
///
/// Shows target name, progress, estimated duration, status chip, and an
/// optional "Carry Forward" badge.
class PlannerMissionCard extends StatelessWidget {
  final PlannerEntry entry;
  final MissionContext? missionContext;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  /// When set, a small "Move to Tomorrow" button appears in the card footer.
  /// Only shown on non-completed entries.
  final VoidCallback? onMoveToTomorrow;

  /// Quick Action callbacks for reordering & moving
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onMoveToToday;

  const PlannerMissionCard({
    super.key,
    required this.entry,
    this.missionContext,
    this.onTap,
    this.onRemove,
    this.onMoveToTomorrow,
    this.onMoveUp,
    this.onMoveDown,
    this.onMoveToToday,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _borderColor.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 10),
            _buildProgressRow(),
            const SizedBox(height: 10),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ── Header: name + badges ──────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Leading icon
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _borderColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_statusIcon, color: _borderColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target name + optional "continue" hint
              Text(
                entry.targetName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.text,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (missionContext != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Last opened: ${_formatRelativeTime(missionContext!.lastOpenedTime)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Badge row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entry.isCarryForward) _buildBadge('Carry Forward', AppTheme.warning),
            const SizedBox(width: 4),
            if (onRemove != null)
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppTheme.textMuted,
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ── Progress row ───────────────────────────────────────────────────────────

  Widget _buildProgressRow() {
    final progress = missionContext?.progress ?? 0.0;
    final pct = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            Text(
              '$pct%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _progressColor(progress),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: AppTheme.surfaceStrong,
            valueColor: AlwaysStoppedAnimation<Color>(_progressColor(progress)),
          ),
        ),
      ],
    );
  }

  // ── Footer: duration + status chip + optional move/quick action buttons ────

  Widget _buildFooter() {
    final canMove = onMoveToTomorrow != null &&
        entry.status != PlannerEntryStatus.completed;
    final hasQuickActions =
        onMoveUp != null || onMoveDown != null || onMoveToToday != null;

    return Row(
      children: [
        Icon(Icons.timer_outlined, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          '${entry.estimatedDurationMinutes} min',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        const Spacer(),
        if (canMove) ...[
          _MoveToTomorrowButton(onTap: onMoveToTomorrow!),
          const SizedBox(width: 8),
        ],
        if (hasQuickActions) ...[
          _QuickActionsToolbar(
            onMoveUp: onMoveUp,
            onMoveDown: onMoveDown,
            onMoveToToday: onMoveToToday,
            onRemove: onRemove,
          ),
          const SizedBox(width: 8),
        ],
        _buildStatusChip(),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    final label = switch (entry.status) {
      PlannerEntryStatus.pending => 'Pending',
      PlannerEntryStatus.inProgress => 'In Progress',
      PlannerEntryStatus.completed => 'Completed',
    };
    final color = switch (entry.status) {
      PlannerEntryStatus.pending => AppTheme.textMuted,
      PlannerEntryStatus.inProgress => AppTheme.accent,
      PlannerEntryStatus.completed => AppTheme.success,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Color get _borderColor => switch (entry.status) {
        PlannerEntryStatus.pending => AppTheme.border,
        PlannerEntryStatus.inProgress => AppTheme.accent,
        PlannerEntryStatus.completed => AppTheme.success,
      };

  IconData get _statusIcon => switch (entry.status) {
        PlannerEntryStatus.pending => Icons.radio_button_unchecked,
        PlannerEntryStatus.inProgress => Icons.play_circle_outline_rounded,
        PlannerEntryStatus.completed => Icons.check_circle_outline_rounded,
      };

  Color _progressColor(double progress) {
    if (progress >= 0.8) return AppTheme.success;
    if (progress >= 0.4) return AppTheme.warning;
    return AppTheme.accent;
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Move-to-tomorrow button ───────────────────────────────────────────────────

/// Small inline button shown in the card footer when [onTap] is provided.
class _MoveToTomorrowButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MoveToTomorrowButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.feature.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.feature.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_forward_rounded,
                size: 12, color: AppTheme.feature),
            const SizedBox(width: 4),
            Text(
              'Tomorrow',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.feature,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick Actions Toolbar ────────────────────────────────────────────────────

/// Inline button group for reordering (Move Up, Move Down) and transferring (Move to Today, Remove).
class _QuickActionsToolbar extends StatelessWidget {
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback? onMoveToToday;
  final VoidCallback? onRemove;

  const _QuickActionsToolbar({
    this.onMoveUp,
    this.onMoveDown,
    this.onMoveToToday,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onMoveUp != null)
          _actionBtn(
            icon: Icons.arrow_upward_rounded,
            tooltip: 'Move Up',
            onTap: onMoveUp,
          ),
        if (onMoveDown != null)
          _actionBtn(
            icon: Icons.arrow_downward_rounded,
            tooltip: 'Move Down',
            onTap: onMoveDown,
          ),
        if (onMoveToToday != null)
          _actionBtn(
            icon: Icons.today_rounded,
            label: '← Today',
            tooltip: 'Move to Today',
            onTap: onMoveToToday,
            color: AppTheme.accent,
          ),
        if (onRemove != null && (onMoveUp != null || onMoveToToday != null))
          _actionBtn(
            icon: Icons.close_rounded,
            tooltip: 'Remove from Plan',
            onTap: onRemove,
            color: AppTheme.danger,
          ),
      ],
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
    String? label,
    Color? color,
  }) {
    final themeColor = color ?? AppTheme.textMuted;
    final isEnabled = onTap != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: isEnabled ? 0.12 : 0.05),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: themeColor.withValues(alpha: isEnabled ? 0.25 : 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isEnabled ? themeColor : themeColor.withValues(alpha: 0.3),
              ),
              if (label != null) ...[
                const SizedBox(width: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isEnabled ? themeColor : themeColor.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

