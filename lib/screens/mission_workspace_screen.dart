import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/category_item.dart';
import '../models/checklist_item.dart';
import '../models/mission_behavior_analysis.dart';
import '../models/mission_chain.dart';
import '../models/mission_timeline_event.dart';
import '../models/mission_workspace_data.dart';
import '../models/target_item.dart';
import '../providers/app_state.dart';
import '../providers/behavior_provider.dart';
import '../providers/planner_provider.dart';
import '../services/mission_details_service.dart';
import '../services/mission_history_service.dart';
import '../services/mission_statistics_service.dart';
import '../widgets/mission_setup_sheet.dart';
import 'mission_chains_screen.dart';

/// Mission Workspace Screen — The primary centered workspace for executing,
/// tracking, and analyzing a mission.
class MissionWorkspaceScreen extends StatefulWidget {
  final String targetId;
  final bool isArchived;

  const MissionWorkspaceScreen({
    super.key,
    required this.targetId,
    this.isArchived = false,
  });

  @override
  State<MissionWorkspaceScreen> createState() => _MissionWorkspaceScreenState();
}

class _MissionWorkspaceScreenState extends State<MissionWorkspaceScreen> {
  late TextEditingController _notesController;
  late TextEditingController _addStepController;

  Timer? _autoSaveDebounce;
  Timer? _savedFeedbackTimer;
  DateTime? _notesLastEdited;
  List<MissionTimelineEvent> _timelineEvents = [];
  MissionWorkspaceData _workspaceData = MissionWorkspaceData.empty('');
  bool _isLoadingWorkspace = true;

  // UX state
  bool _isSavingNotes = false;
  bool _notesSavedRecently = false;
  bool _showCompletedSteps = false;
  bool _showAllTimeline = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _addStepController = TextEditingController();
    _loadWorkspaceData();
  }

  @override
  void dispose() {
    _autoSaveDebounce?.cancel();
    _savedFeedbackTimer?.cancel();
    _notesController.dispose();
    _addStepController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkspaceData() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final target = _getTarget(appState);
    final title = target?.title ?? 'Mission';

    final data = await MissionDetailsService.loadWorkspaceData(widget.targetId);
    final timeline = await MissionHistoryService.ensureCreatedEvent(
      targetId: widget.targetId,
      targetName: title,
    );

    if (mounted) {
      setState(() {
        _workspaceData = data;
        _notesLastEdited = data.notesLastEdited;
        _timelineEvents = timeline;
        if (target != null && _notesController.text.isEmpty) {
          _notesController.text = target.notes;
        }
        _isLoadingWorkspace = false;
      });
    }
  }

  TargetItem? _getTarget(AppState appState) {
    if (widget.isArchived) {
      return appState.archivedTargets.firstWhere(
        (t) => t.id == widget.targetId,
        orElse: () => TargetItem(id: widget.targetId, title: 'Unknown Mission', targetCount: 1),
      );
    }
    return appState.targets.firstWhere(
      (t) => t.id == widget.targetId,
      orElse: () => appState.archivedTargets.firstWhere(
        (t) => t.id == widget.targetId,
        orElse: () => TargetItem(id: widget.targetId, title: 'Unknown Mission', targetCount: 1),
      ),
    );
  }

  void _onNotesChanged(String text) {
    if (!_isSavingNotes) {
      setState(() {
        _isSavingNotes = true;
        _notesSavedRecently = false;
      });
    }
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(const Duration(milliseconds: 800), () async {
      final appState = Provider.of<AppState>(context, listen: false);
      final target = _getTarget(appState);
      if (target == null) return;

      await appState.updateTarget(
        target.id,
        target.title,
        target.targetCount,
        dueDate: target.dueDate,
        priority: target.priority,
        notes: text,
        tags: target.tags,
        categoryId: target.categoryId,
        links: target.links,
      );

      final updatedData = await MissionDetailsService.autoSaveNotes(
        targetId: widget.targetId,
        notes: text,
      );

      if (mounted) {
        setState(() {
          _workspaceData = updatedData;
          _notesLastEdited = updatedData.notesLastEdited;
          _isSavingNotes = false;
          _notesSavedRecently = true;
        });
        _savedFeedbackTimer?.cancel();
        _savedFeedbackTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) setState(() => _notesSavedRecently = false);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AppState, BehaviorProvider, PlannerProvider>(
      builder: (context, appState, behavior, planner, _) {
        final target = _getTarget(appState);
        if (target == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Mission Workspace')),
            body: const Center(child: Text('Mission not found.')),
          );
        }

        final activeMission = appState.activeMission;
        final isMissionActive = activeMission != null && activeMission.targetId == target.id;
        final statusLabel = MissionDetailsService.getMissionStatusLabel(
          target: target,
          isArchived: widget.isArchived,
          activeMission: activeMission,
        );

        final analysis = behavior.missionHealthMap[target.id];
        final health = analysis?.healthStatus ??
            (target.solvedCount >= target.targetCount && target.targetCount > 0
                ? MissionHealthStatus.excellent
                : MissionHealthStatus.good);
        final healthExplanation = MissionDetailsService.getHealthExplanation(health, analysis);

        final parentChain = MissionDetailsService.findParentChain(target.id, appState.chains);
        final stats = MissionStatisticsService.computeStats(
          target: target,
          missionHistory: appState.missionHistory,
          behaviorAnalysis: analysis,
          workspaceData: _workspaceData,
        );

        final checklistItems =
            appState.checklistItems.where((i) => i.type == target.id).toList();

        return Scaffold(
          backgroundColor: AppTheme.bg,
          appBar: _buildAppBar(context, appState, target, statusLabel, health),
          body: _isLoadingWorkspace
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.sp24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Hero Section (action + overview + progress merged)
                          _buildHeroSection(context, appState, target, isMissionActive, activeMission, statusLabel),
                          const SizedBox(height: AppTheme.sp20),

                          // 2. Parent Chain Banner (if applicable)
                          if (parentChain != null) ...[
                            _buildChainBanner(context, parentChain),
                            const SizedBox(height: AppTheme.sp20),
                          ],

                          // 3. Execution Timing
                          _buildExecutionProgressCard(target, activeMission, isMissionActive),
                          const SizedBox(height: AppTheme.sp20),

                          // 4. Mission Steps
                          _buildChecklistCard(context, appState, target, checklistItems),
                          const SizedBox(height: AppTheme.sp20),

                          // 5. Mission Notes
                          _buildNotesCard(context),
                          const SizedBox(height: AppTheme.sp20),

                          // 6. Mission Health
                          _buildHealthCard(health, healthExplanation),
                          const SizedBox(height: AppTheme.sp20),

                          // 7. Behavior Insights
                          _buildBehaviorCard(behavior),
                          const SizedBox(height: AppTheme.sp20),

                          // 8. Mission Statistics
                          _buildStatisticsGrid(stats),
                          const SizedBox(height: AppTheme.sp20),

                          // 9. Mission Timeline
                          _buildTimelineCard(),
                          const SizedBox(height: AppTheme.sp32),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AppState appState,
    TargetItem target,
    String statusLabel,
    MissionHealthStatus health,
  ) {
    return AppBar(
      backgroundColor: AppTheme.surface.withValues(alpha: 0.95),
      elevation: 0,
      title: Text(
        target.title.length > 26
            ? '${target.title.substring(0, 24)}…'
            : target.title,
        style: AppTheme.subtitleStyle.copyWith(
          color: AppTheme.text,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      actions: [
        // Health badge in app bar
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: health.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: health.color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(health.icon, size: 14, color: health.color),
              const SizedBox(width: 4),
              Text(
                health.displayName,
                style: AppTheme.captionStyle.copyWith(
                  color: health.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Kebab menu
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: AppTheme.text),
          color: AppTheme.surface,
          onSelected: (value) => _handleMenuAction(context, appState, target, value),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, size: 18, color: AppTheme.warning),
                  const SizedBox(width: 10),
                  const Text('Edit Mission'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [
                  Icon(Icons.copy_rounded, size: 18, color: AppTheme.accent),
                  const SizedBox(width: 10),
                  const Text('Duplicate Mission'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  Icon(
                    widget.isArchived ? Icons.unarchive_rounded : Icons.archive_rounded,
                    size: 18,
                    color: AppTheme.feature,
                  ),
                  const SizedBox(width: 10),
                  Text(widget.isArchived ? 'Restore Mission' : 'Archive Mission'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_forever_rounded, size: 18, color: AppTheme.danger),
                  const SizedBox(width: 10),
                  Text('Delete Mission', style: TextStyle(color: AppTheme.danger)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _handleMenuAction(
    BuildContext context,
    AppState appState,
    TargetItem target,
    String action,
  ) {
    switch (action) {
      case 'edit':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => MissionSetupSheet(target: target),
        );
        break;
      case 'duplicate':
        appState.addTarget(
          '${target.title} (Copy)',
          target.targetCount,
          dueDate: target.dueDate,
          priority: target.priority,
          notes: target.notes,
          tags: target.tags,
          categoryId: target.categoryId,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mission duplicated!')),
        );
        break;
      case 'archive':
        if (widget.isArchived) {
          appState.restoreTarget(target.id);
          Navigator.pop(context);
        } else {
          _confirmAction(
            context: context,
            title: 'Archive Mission',
            message: 'Are you sure you want to archive "${target.title}"?',
            onConfirm: () async {
              await appState.archiveTarget(target.id);
              if (!mounted) return;
              Navigator.pop(this.context);
            },
          );
        }
        break;
      case 'delete':
        _confirmAction(
          context: context,
          title: 'Delete Mission',
          message: 'Are you sure you want to permanently delete "${target.title}"? This cannot be undone.',
          isDangerous: true,
          onConfirm: () async {
            if (widget.isArchived) {
              await appState.deleteArchivedTarget(target.id);
            } else {
              await appState.deleteTarget(target.id);
            }
            if (!mounted) return;
            Navigator.pop(this.context);
          },
        );
        break;
    }
  }

  void _confirmAction({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    bool isDangerous = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(title, style: AppTheme.titleStyle.copyWith(color: AppTheme.text)),
        content: Text(message, style: AppTheme.bodyStyle.copyWith(color: AppTheme.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDangerous ? AppTheme.danger : AppTheme.accent,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: Text(isDangerous ? 'Delete' : 'Confirm'),
          ),
        ],
      ),
    );
  }

  // ── 1. Hero Section ────────────────────────────────────────────────────────
  Widget _buildHeroSection(
    BuildContext context,
    AppState appState,
    TargetItem target,
    bool isMissionActive,
    dynamic activeMission,
    String statusLabel,
  ) {
    final isCompleted =
        target.solvedCount >= target.targetCount && target.targetCount > 0;
    final isPaused = isMissionActive && activeMission != null && activeMission.isPaused;
    final pct = target.targetCount == 0
        ? 0.0
        : (target.solvedCount / target.targetCount).clamp(0.0, 1.0);

    Color priorityColor = AppTheme.warning;
    if (target.priority == 'high') priorityColor = AppTheme.danger;
    if (target.priority == 'low') priorityColor = AppTheme.success;

    final category = appState.categories.firstWhere(
      (c) => c.id == target.categoryId,
      orElse: () => CategoryItem(
          id: 'general', name: 'General', colorValue: 0xFF94A3B8),
    );

    final Color statusColor;
    final String statusText;
    if (isCompleted) {
      statusColor = AppTheme.success;
      statusText = 'COMPLETED';
    } else if (isMissionActive) {
      statusColor = isPaused ? AppTheme.warning : AppTheme.accent;
      statusText = isPaused ? 'PAUSED' : 'IN PROGRESS';
    } else {
      statusColor = AppTheme.textMuted;
      statusText = 'READY TO EXECUTE';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: statusColor.withValues(
              alpha: isMissionActive ? 0.4 : 0.15),
          width: isMissionActive ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (isMissionActive && !isPaused)
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header bar
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.sp20, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  statusText,
                  style:
                      AppTheme.labelStyle.copyWith(color: statusColor),
                ),
                const Spacer(),
                if (target.dueDate != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 13, color: AppTheme.danger),
                      const SizedBox(width: 4),
                      Text(
                        'Due ${target.dueDate!.day}/${target.dueDate!.month}/${target.dueDate!.year}',
                        style: AppTheme.captionStyle.copyWith(
                            color: AppTheme.danger, fontSize: 11),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(AppTheme.sp20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mission title
                Text(
                  target.title,
                  style: AppTheme.headingStyle.copyWith(
                    color: AppTheme.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.sp12),

                // Chips: category + priority
                Row(
                  children: [
                    _WorkspaceChip(
                        label: category.name,
                        color: Color(category.colorValue)),
                    const SizedBox(width: 6),
                    _WorkspaceChip(
                        label:
                            '${target.priority.toUpperCase()} PRIORITY',
                        color: priorityColor),
                  ],
                ),
                const SizedBox(height: AppTheme.sp20),

                // Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${target.solvedCount} of ${target.targetCount} steps',
                      style: AppTheme.captionStyle
                          .copyWith(color: AppTheme.textMuted),
                    ),
                    Text(
                      '${(pct * 100).round()}%',
                      style: AppTheme.subtitleStyle.copyWith(
                        color: isCompleted ? AppTheme.success : statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor:
                        AppTheme.surfaceStrong.withValues(alpha: 0.4),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted ? AppTheme.success : statusColor,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.sp20),

                // Action buttons
                if (!isCompleted)
                  Row(
                    children: [
                      if (isMissionActive) ...[
                        if (isPaused)
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accent,
                                foregroundColor:
                                    const Color(0xFF0F172A),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                              ),
                              icon: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 20),
                              label:
                                  const Text('Resume Mission'),
                              onPressed: () =>
                                  appState.resumeActiveMission(),
                            ),
                          )
                        else ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.warning,
                                side: BorderSide(
                                    color: AppTheme.warning
                                        .withValues(alpha: 0.5)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.pause_rounded,
                                  size: 18),
                              label: const Text('Pause'),
                              onPressed: () =>
                                  appState.pauseActiveMission(),
                            ),
                          ),
                          const SizedBox(width: AppTheme.sp12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.success,
                              foregroundColor:
                                  const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.add_rounded,
                                size: 18),
                            label: const Text('+1 Done'),
                            onPressed: () => appState.setSolved(
                                target.id,
                                target.solvedCount + 1),
                          ),
                        ],
                      ] else
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              foregroundColor:
                                  const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                            ),
                            icon: const Icon(
                                Icons.rocket_launch_rounded,
                                size: 20),
                            label: const Text('Start Mission'),
                            onPressed: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) =>
                                  MissionSetupSheet(target: target),
                            ),
                          ),
                        ),
                    ],
                  )
                else
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color:
                          AppTheme.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.success
                              .withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: AppTheme.success, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Mission Completed',
                          style: AppTheme.buttonStyle
                              .copyWith(color: AppTheme.success),
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
  }

  // ── 2. Parent Chain Banner ─────────────────────────────────────────────────
  Widget _buildChainBanner(BuildContext context, MissionChain chain) {
    final solved = chain.completedTargetIds.length;
    final total = chain.targetIds.length;
    final pct = total == 0 ? 0.0 : solved / total;

    return Container(
      padding: const EdgeInsets.all(AppTheme.sp16),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.link_rounded, color: AppTheme.accent, size: 24),
          const SizedBox(width: AppTheme.sp12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BELONGS TO MISSION CHAIN', style: AppTheme.labelStyle.copyWith(color: AppTheme.accent)),
                const SizedBox(height: 2),
                Text(chain.title, style: AppTheme.subtitleStyle.copyWith(fontWeight: FontWeight.bold)),
                Text('$solved of $total steps completed (${(pct * 100).round()}%)',
                    style: AppTheme.captionStyle.copyWith(color: AppTheme.textMuted)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MissionChainsScreen()),
              );
            },
            child: const Text('Open Chain'),
          ),
        ],
      ),
    );
  }



  // ── 3. Execution Timing (compact row) ─────────────────────────────────────
  Widget _buildExecutionProgressCard(
      TargetItem target, dynamic activeMission, bool isMissionActive) {
    final elapsedSec =
        isMissionActive && activeMission != null && activeMission.targetId == target.id
            ? activeMission.accumulatedSeconds as int
            : 0;
    final elapsedMins = elapsedSec ~/ 60;
    final estMins =
        (activeMission?.estimatedDurationMinutes as int?) ?? 60;
    final remainingMins = (estMins - elapsedMins).clamp(0, estMins);
    final sessions = _workspaceData.totalSessions;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.sp20, vertical: AppTheme.sp16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Text(
            'EXECUTION',
            style:
                AppTheme.labelStyle.copyWith(color: AppTheme.textMuted),
          ),
          const Spacer(),
          _MiniStatBox('${elapsedMins}m', 'Elapsed', AppTheme.accent),
          const SizedBox(width: AppTheme.sp24),
          _MiniStatBox(
              '~${remainingMins}m', 'Remaining', AppTheme.warning),
          const SizedBox(width: AppTheme.sp24),
          _MiniStatBox('$sessions', 'Sessions', AppTheme.success),
        ],
      ),
    );
  }

  // ── 4. Mission Steps ────────────────────────────────────────────────────────
  Widget _buildChecklistCard(
    BuildContext context,
    AppState appState,
    TargetItem target,
    List<ChecklistItem> items,
  ) {
    final pending = items.where((i) => !i.completed).toList();
    final done = items.where((i) => i.completed).toList();

    return Container(
      padding: const EdgeInsets.all(AppTheme.sp20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppTheme.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MISSION STEPS',
                style: AppTheme.labelStyle
                    .copyWith(color: AppTheme.textMuted),
              ),
              Text(
                '${done.length}/${items.length} done',
                style: AppTheme.captionStyle
                    .copyWith(color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.sp12),

          // Add step row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _addStepController,
                  style:
                      AppTheme.bodyStyle.copyWith(color: AppTheme.text),
                  decoration: const InputDecoration(
                    hintText: 'Add a new mission step...',
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                  ),
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      appState.addChecklistItem(val.trim(), target.id);
                      _addStepController.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: const Color(0xFF0F172A),
                ),
                icon: const Icon(Icons.add, size: 20),
                onPressed: () {
                  if (_addStepController.text.trim().isNotEmpty) {
                    appState.addChecklistItem(
                        _addStepController.text.trim(), target.id);
                    _addStepController.clear();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppTheme.sp12),

          // Pending steps
          if (pending.isEmpty && done.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No steps added yet. Add one above.',
                  style: AppTheme.captionStyle
                      .copyWith(color: AppTheme.textMuted),
                ),
              ),
            )
          else if (pending.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pending.length,
              onReorderItem: (int oldIdx, int newIdx) {
                // Reorder only within pending; compute global indices
                final globalOld =
                    items.indexOf(pending[oldIdx]);
                var globalNew =
                    items.indexOf(pending[newIdx < pending.length
                        ? newIdx
                        : newIdx - 1]);
                if (newIdx > oldIdx) globalNew++;
                appState.reorderChecklistItems(
                    globalOld, globalNew, target.id);
              },
              itemBuilder: (context, idx) {
                final item = pending[idx];
                return _buildStepRow(
                    context, appState, target, item, idx,
                    isPending: true);
              },
            ),

          // Completed steps (collapsible)
          if (done.isNotEmpty) ...[
            const SizedBox(height: AppTheme.sp12),
            GestureDetector(
              onTap: () => setState(
                  () => _showCompletedSteps = !_showCompletedSteps),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: AppTheme.success, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${done.length} completed',
                    style: AppTheme.captionStyle.copyWith(
                      color: AppTheme.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _showCompletedSteps
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppTheme.success,
                    size: 18,
                  ),
                ],
              ),
            ),
            if (_showCompletedSteps) ...[
              const SizedBox(height: AppTheme.sp8),
              ...done.asMap().entries.map((e) => _buildStepRow(
                  context, appState, target, e.value, e.key,
                  isPending: false)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStepRow(
    BuildContext context,
    AppState appState,
    TargetItem target,
    ChecklistItem item,
    int idx, {
    required bool isPending,
  }) {
    return Container(
      key: ValueKey(item.id),
      margin: const EdgeInsets.only(bottom: 6),
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: item.completed
            ? AppTheme.surface.withValues(alpha: 0.3)
            : AppTheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.completed
              ? AppTheme.success.withValues(alpha: 0.15)
              : AppTheme.border.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          if (isPending)
            ReorderableDragStartListener(
              index: idx,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.drag_handle_rounded,
                    color: AppTheme.textMuted, size: 18),
              ),
            ),
          Checkbox(
            value: item.completed,
            activeColor: AppTheme.success,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            onChanged: (_) =>
                appState.toggleChecklistItem(item.id),
          ),
          Expanded(
            child: Text(
              item.text,
              style: AppTheme.bodyStyle.copyWith(
                color: item.completed
                    ? AppTheme.textMuted
                    : AppTheme.text,
                decoration: item.completed
                    ? TextDecoration.lineThrough
                    : null,
                fontSize: 14,
              ),
            ),
          ),
          // Edit button
          if (isPending)
            GestureDetector(
              onTap: () => _showEditStepDialog(
                  context, appState, item, target),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.edit_outlined,
                    size: 16, color: AppTheme.textMuted),
              ),
            ),
          // Delete button
          GestureDetector(
            onTap: () =>
                appState.deleteChecklistItem(item.id),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(Icons.close_rounded,
                  size: 16, color: AppTheme.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditStepDialog(
    BuildContext context,
    AppState appState,
    ChecklistItem item,
    TargetItem target,
  ) {
    final ctrl = TextEditingController(text: item.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text('Edit Step',
            style:
                AppTheme.titleStyle.copyWith(color: AppTheme.text)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: AppTheme.bodyStyle.copyWith(color: AppTheme.text),
          decoration: InputDecoration(
            hintText: 'Step description...',
            hintStyle:
                TextStyle(color: AppTheme.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: const Color(0xFF0F172A)),
            onPressed: () {
              final newText = ctrl.text.trim();
              if (newText.isNotEmpty && newText != item.text) {
                appState.deleteChecklistItem(item.id);
                appState.addChecklistItem(newText, target.id);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── 5. Mission Notes ────────────────────────────────────────────────────────
  Widget _buildNotesCard(BuildContext context) {
    // Build save-status label
    final Widget statusWidget;
    if (_isSavingNotes) {
      statusWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppTheme.textMuted),
            ),
          ),
          const SizedBox(width: 5),
          Text('Saving...',
              style: AppTheme.captionStyle
                  .copyWith(color: AppTheme.textMuted)),
        ],
      );
    } else if (_notesSavedRecently) {
      statusWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_rounded,
              size: 13, color: AppTheme.success),
          const SizedBox(width: 4),
          Text('Saved',
              style: AppTheme.captionStyle
                  .copyWith(color: AppTheme.success)),
        ],
      );
    } else {
      String lastEditedStr = 'Auto-saved';
      if (_notesLastEdited != null) {
        lastEditedStr =
            _relativeTime(_notesLastEdited!);
      }
      statusWidget = Text(
        lastEditedStr,
        style: AppTheme.captionStyle
            .copyWith(color: AppTheme.textMuted),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.sp20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MISSION NOTES',
                style: AppTheme.labelStyle
                    .copyWith(color: AppTheme.textMuted),
              ),
              statusWidget,
            ],
          ),
          const SizedBox(height: AppTheme.sp12),
          TextField(
            controller: _notesController,
            maxLines: 4,
            style:
                AppTheme.bodyStyle.copyWith(color: AppTheme.text),
            decoration: InputDecoration(
              hintText:
                  'Add mission context, key learnings, or notes here...',
              fillColor: AppTheme.bg.withValues(alpha: 0.4),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color:
                        AppTheme.border.withValues(alpha: 0.2)),
              ),
            ),
            onChanged: _onNotesChanged,
          ),
        ],
      ),
    );
  }

  // ── 6. Mission Health ────────────────────────────────────────────────────────
  Widget _buildHealthCard(
      MissionHealthStatus health, String healthExplanation) {
    return Container(
      decoration: BoxDecoration(
        color: health.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: health.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.sp20, vertical: 10),
            decoration: BoxDecoration(
              color: health.color.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Icon(health.icon, size: 16, color: health.color),
                const SizedBox(width: 8),
                Text(
                  'MISSION HEALTH',
                  style: AppTheme.labelStyle
                      .copyWith(color: health.color),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(AppTheme.sp20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        health.color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(health.icon,
                      color: health.color, size: 22),
                ),
                const SizedBox(width: AppTheme.sp16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        health.displayName,
                        style: AppTheme.titleStyle.copyWith(
                          color: health.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        healthExplanation,
                        style: AppTheme.bodyStyle
                            .copyWith(color: AppTheme.text),
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
  }

  // ── 7. Behavior Insights ────────────────────────────────────────────────────
  Widget _buildBehaviorCard(BehaviorProvider behavior) {
    final recs = behavior.recommendations;

    return Container(
      padding: const EdgeInsets.all(AppTheme.sp20),
      decoration: BoxDecoration(
        color: AppTheme.feature.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppTheme.feature.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  color: AppTheme.learning, size: 16),
              const SizedBox(width: 8),
              Text(
                'BEHAVIOR INSIGHTS',
                style: AppTheme.labelStyle
                    .copyWith(color: AppTheme.learning),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.sp12),
          if (recs.isEmpty)
            Text(
              'Behavior analysis runs after your first completed session.',
              style: AppTheme.bodyStyle
                  .copyWith(color: AppTheme.textMuted),
            )
          else
            ...recs.take(4).map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.learning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          rec,
                          style: AppTheme.bodyStyle
                              .copyWith(color: AppTheme.text),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  // ── 8. Mission Statistics ───────────────────────────────────────────────────
  Widget _buildStatisticsGrid(MissionWorkspaceStats stats) {
    final errLabel = stats.avgEstimationErrorMinutes == 0
        ? 'Exact'
        : (stats.avgEstimationErrorMinutes > 0
            ? '+${stats.avgEstimationErrorMinutes}m'
            : '${stats.avgEstimationErrorMinutes}m');

    return Container(
      padding: const EdgeInsets.all(AppTheme.sp20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppTheme.border.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MISSION STATISTICS',
            style: AppTheme.labelStyle
                .copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: AppTheme.sp16),
          Wrap(
            spacing: AppTheme.sp12,
            runSpacing: AppTheme.sp12,
            children: [
              _StatBox('${stats.avgCompletionTimeMinutes}m',
                  'Avg Duration', AppTheme.accent),
              _StatBox(errLabel, 'Est. Error', AppTheme.warning),
              _StatBox('${stats.totalSessions}', 'Sessions',
                  AppTheme.success),
              _StatBox(
                  '${(stats.completionPercentage * 100).round()}%',
                  'Completion',
                  AppTheme.success),
              _StatBox('${stats.recoveryCount}', 'Recoveries',
                  AppTheme.feature),
              _StatBox('${stats.postponementCount}', 'Postponed',
                  AppTheme.danger),
            ],
          ),
        ],
      ),
    );
  }

  // ── 9. Mission Timeline ─────────────────────────────────────────────────────
  Widget _buildTimelineCard() {
    // Most recent first; cap at 10 unless expanded
    final allEvents = _timelineEvents.reversed.toList();
    final events =
        _showAllTimeline ? allEvents : allEvents.take(10).toList();

    return Container(
      padding: const EdgeInsets.all(AppTheme.sp20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MISSION TIMELINE',
                style: AppTheme.labelStyle
                    .copyWith(color: AppTheme.textMuted),
              ),
              if (allEvents.length > 10)
                GestureDetector(
                  onTap: () => setState(
                      () => _showAllTimeline = !_showAllTimeline),
                  child: Text(
                    _showAllTimeline ? 'Show less' : 'Show all',
                    style: AppTheme.captionStyle
                        .copyWith(color: AppTheme.accent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.sp16),
          if (events.isEmpty)
            Text(
              'No timeline history recorded.',
              style: AppTheme.captionStyle
                  .copyWith(color: AppTheme.textMuted),
            )
          else
            ...events.asMap().entries.map((e) => _TimelineEventRow(
                  event: e.value,
                  isLast: e.key == events.length - 1,
                )),
        ],
      ),
    );
  }

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _MiniStatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _MiniStatBox(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTheme.titleStyle.copyWith(fontWeight: FontWeight.bold, color: color)),
        Text(label, style: AppTheme.captionStyle.copyWith(color: AppTheme.textMuted)),
      ],
    );
  }
}

/// Stat tile with colored top accent line — used in statistics Wrap.
class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatBox(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    // Responsive width: 2 columns on small, 3 on large
    final tileW = (screenW > 500 ? (screenW - 96) / 3 : (screenW - 80) / 2)
        .clamp(90.0, 160.0);

    return Container(
      width: tileW,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored accent line
          Container(
            width: 28,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.titleStyle.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.captionStyle.copyWith(
              color: AppTheme.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact label chip used in the workspace hero section.
class _WorkspaceChip extends StatelessWidget {
  const _WorkspaceChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: AppTheme.captionStyle.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// Timeline event row with vertical connector line.
class _TimelineEventRow extends StatelessWidget {
  const _TimelineEventRow({
    required this.event,
    required this.isLast,
  });
  final MissionTimelineEvent event;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final relTime = _relativeTime(event.timestamp);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator column
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: event.type.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                    color: event.type.color.withValues(alpha: 0.4)),
              ),
              child: Icon(event.type.icon,
                  size: 15, color: event.type.color),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: AppTheme.border.withValues(alpha: 0.25),
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.description,
                  style: AppTheme.bodyStyle
                      .copyWith(color: AppTheme.text),
                ),
                const SizedBox(height: 2),
                Text(
                  relTime,
                  style: AppTheme.captionStyle
                      .copyWith(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
