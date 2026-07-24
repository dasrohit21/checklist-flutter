import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/coach_message.dart';
import '../models/coach_personality.dart';
import '../models/mission_context.dart';
import '../models/mission.dart';
import '../models/planner_entry.dart';
import '../models/planning_summary.dart';
import '../models/recovery_plan.dart';
import '../models/target_item.dart';
import '../providers/app_state.dart';
import '../providers/coach_provider.dart';
import '../providers/planner_provider.dart';
import '../services/planner_service.dart';
import '../widgets/planner_mission_card.dart';
import 'coach_settings_screen.dart';

/// The daily command-center screen.
///
/// Sections:
///   1. Continue Mission — active mission banner (shown when applicable).
///   2. Today's Missions — entries planned for today.
///   3. Carry Forward   — unfinished missions from previous days.
///   4. Tomorrow Preview — read-only compact view of tomorrow.
class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure data is fresh whenever the screen becomes active.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final planner = context.read<PlannerProvider>();
        planner.refresh().then((_) {
          if (mounted) {
            context.read<CoachProvider>().evaluate(planner);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppState, PlannerProvider>(
      builder: (context, appState, planner, _) {
        if (planner.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.accent),
          );
        }

        return Scaffold(
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
              child: CustomScrollView(
                slivers: [
                  // ── Page header ──────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                      child: _PlannerHeader(appState: appState),
                    ),
                  ),

                  // ── 0. Coach Card ────────────────────────────────────────────────
                  Consumer<CoachProvider>(
                    builder: (context, coach, _) {
                      if (!coach.isEnabled || coach.currentMessage == null) {
                        return const SliverToBoxAdapter(
                            child: SizedBox.shrink());
                      }
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                          child: _CoachCard(
                            message: coach.currentMessage!,
                            personality: coach.personality,
                            onOpenSettings: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CoachSettingsScreen(),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // ── 0.5. Daily Summary ──────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: _DailySummaryCard(
                        planner: planner,
                        onEditAvailableTime: () =>
                            _showAvailableTimeSheet(context, planner),
                      ),
                    ),
                  ),

                  // ── 0.5. Recovery Plan ───────────────────────────────────
                  if (planner.shouldShowRecoveryCard)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                        child: _RecoveryCard(planner: planner),
                      ),
                    ),

                  // ── 1. Continue Mission ──────────────────────────────────
                  if (appState.activeMission != null &&
                      appState.activeMission!.status == MissionStatus.active)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                        child: _ContinueMissionBanner(
                          mission: appState.activeMission!,
                          appState: appState,
                        ),
                      ),
                    ),

                  // ── 2. Today's Missions ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: _SectionHeader(
                        icon: Icons.today_rounded,
                        title: "Today's Missions",
                        count: planner.todayEntries.length,
                        action: TextButton.icon(
                          icon: Icon(Icons.add_rounded,
                              size: 18, color: AppTheme.accent),
                          label: Text(
                            'Add',
                            style: TextStyle(color: AppTheme.accent),
                          ),
                          onPressed: () =>
                              _showAddEntrySheet(context, appState, planner),
                        ),
                      ),
                    ),
                  ),
                  if (planner.todayEntries.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, 10, 24, 0),
                        child: _EmptyState(
                          icon: Icons.event_note_outlined,
                          message: "No missions planned for today.\nTap 'Add' to schedule one.",
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final entry = planner.todayEntries[index];
                            return _EntryCardLoader(
                              key: ValueKey(entry.id),
                              entry: entry,
                              appState: appState,
                              planner: planner,
                              showMoveToTomorrow: true,
                            );
                          },
                          childCount: planner.todayEntries.length,
                        ),
                      ),
                    ),

                  // ── 3. Carry Forward ─────────────────────────────────────
                  if (planner.carryForwardEntries.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: _SectionHeader(
                          icon: Icons.history_rounded,
                          title: 'Carry Forward',
                          count: planner.carryForwardEntries.length,
                          iconColor: AppTheme.warning,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final entry = planner.carryForwardEntries[index];
                            return _EntryCardLoader(
                              key: ValueKey(entry.id),
                              entry: entry,
                              appState: appState,
                              planner: planner,
                              showMoveToTomorrow: true,
                            );
                          },
                          childCount: planner.carryForwardEntries.length,
                        ),
                      ),
                    ),
                  ],

                  // ── 4. Tomorrow Preview ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: _SectionHeader(
                        icon: Icons.wb_sunny_outlined,
                        title: 'Tomorrow Preview',
                        count: planner.tomorrowEntries.length,
                        iconColor: AppTheme.feature,
                        readOnly: true,
                        sublabel: 'recommended order',
                      ),
                    ),
                  ),

                  // Smart Overflow Warning ("Tomorrow Looks Busy")
                  if (planner.isTomorrowOverflowed)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                        child: _TomorrowLooksBusyCard(planner: planner),
                      ),
                    ),

                  if (planner.tomorrowEntries.isEmpty)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(24, 10, 24, 0),
                        child: _EmptyState(
                          icon: Icons.calendar_today_outlined,
                          message: 'Nothing planned for tomorrow yet.',
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final entry = planner.tomorrowEntries[index];
                            return PlannerMissionCard(
                              key: ValueKey(entry.id),
                              entry: entry,
                              onMoveUp: index > 0
                                  ? () => planner.moveTomorrowEntryUp(entry.id)
                                  : null,
                              onMoveDown: index < planner.tomorrowEntries.length - 1
                                  ? () => planner.moveTomorrowEntryDown(entry.id)
                                  : null,
                              onMoveToToday: () =>
                                  planner.moveTomorrowEntryToToday(entry.id),
                              onRemove: () =>
                                  planner.removeTomorrowEntry(entry.id),
                            );
                          },
                          childCount: planner.tomorrowEntries.length,
                        ),
                      ),
                    ),

                  // Bottom padding
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Add-entry sheet ────────────────────────────────────────────────────────

  void _showAddEntrySheet(
    BuildContext context,
    AppState appState,
    PlannerProvider planner,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEntrySheet(
        targets: appState.targets,
        planner: planner,
      ),
    );
  }

  void _showAvailableTimeSheet(
    BuildContext context,
    PlannerProvider planner,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AvailableTimeSheet(planner: planner),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

/// Page header with date and greeting.
class _PlannerHeader extends StatelessWidget {
  final AppState appState;

  const _PlannerHeader({required this.appState});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final dateLabel =
        '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accent.withValues(alpha: 0.2),
                    AppTheme.feature.withValues(alpha: 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.view_timeline_rounded,
                  color: AppTheme.accent, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Execution Planner',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                    ),
                  ),
                  Text(
                    dateLabel,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Section header with icon, title, count badge and optional action.
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final Widget? action;
  final Color? iconColor;
  final bool readOnly;
  final String? sublabel;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
    this.action,
    this.iconColor,
    this.readOnly = false,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppTheme.accent;

    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.text,
          ),
        ),
        const SizedBox(width: 8),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        if (sublabel != null) ...[
          const SizedBox(width: 6),
          Text(
            '($sublabel)',
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ] else if (readOnly) ...[
          const SizedBox(width: 6),
          Text(
            '(read-only)',
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
        const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}

/// Empty-state placeholder shown when a list is empty.
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.border.withValues(alpha: 0.15),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner shown at the top when there is an active (in-progress) mission.
class _ContinueMissionBanner extends StatelessWidget {
  final Mission mission;
  final AppState appState;

  const _ContinueMissionBanner({
    required this.mission,
    required this.appState,
  });

  @override
  Widget build(BuildContext context) {
    // Compute current elapsed seconds.
    final now = DateTime.now();
    final elapsedSeconds = mission.accumulatedSeconds +
        (mission.isPaused || mission.lastResumeTime == null
            ? 0
            : now.difference(mission.lastResumeTime!).inSeconds);
    final estimatedSeconds = mission.estimatedDurationMinutes * 60;
    final remainingSeconds =
        (estimatedSeconds - elapsedSeconds).clamp(0, estimatedSeconds);
    final remainingMinutes = (remainingSeconds / 60).ceil();

    // Progress fraction based on problem count.
    final progress = mission.targetCount == 0
        ? 0.0
        : (mission.solvedCount / mission.targetCount).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accent.withValues(alpha: 0.18),
            AppTheme.feature.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Continue Mission',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accent,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Mission name
          Text(
            mission.name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.text,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppTheme.surfaceStrong,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppTheme.accent),
            ),
          ),
          const SizedBox(height: 8),

          // Stats + Resume button
          Row(
            children: [
              _stat(
                Icons.percent_rounded,
                '${(progress * 100).round()}%',
              ),
              const SizedBox(width: 16),
              _stat(
                Icons.timer_outlined,
                remainingMinutes > 0
                    ? '~$remainingMinutes min left'
                    : 'Time up',
              ),
              const Spacer(),
              // Resume navigates back to the existing MissionScreen
              // which is handled globally in HomeScreen.
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: const Color(0xFF030712),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  // Resume (unpause) the mission if it was paused,
                  // then let HomeScreen redirect to MissionScreen.
                  if (mission.isPaused) {
                    appState.resumeActiveMission();
                  }
                  // AppState.activeMission != null triggers HomeScreen
                  // to show MissionScreen automatically.
                },
                child: const Text(
                  'Resume',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}

/// Async wrapper that loads the [MissionContext] for a card before rendering.
class _EntryCardLoader extends StatefulWidget {
  final PlannerEntry entry;
  final AppState appState;
  final PlannerProvider planner;

  /// When true, shows the "Move to Tomorrow" button on the card.
  final bool showMoveToTomorrow;

  const _EntryCardLoader({
    super.key,
    required this.entry,
    required this.appState,
    required this.planner,
    this.showMoveToTomorrow = false,
  });

  @override
  State<_EntryCardLoader> createState() => _EntryCardLoaderState();
}

class _EntryCardLoaderState extends State<_EntryCardLoader> {
  MissionContext? _context;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadContext();
  }

  Future<void> _loadContext() async {
    final ctx =
        await widget.planner.getMissionContext(widget.entry.targetId);
    if (mounted) {
      setState(() {
        _context = ctx;
        _loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const SizedBox(height: 80);
    }
    return PlannerMissionCard(
      entry: widget.entry,
      missionContext: _context,
      onTap: () => _launchMission(context),
      onRemove: () => widget.planner.removeEntry(widget.entry.id),
      onMoveToTomorrow: widget.showMoveToTomorrow
          ? () => _moveToTomorrow(context)
          : null,
    );
  }

  Future<void> _moveToTomorrow(BuildContext context) async {
    await widget.planner.moveMissionToTomorrow(widget.entry.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '"${widget.entry.targetName}" moved to tomorrow.',
          style: TextStyle(color: AppTheme.text),
        ),
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _launchMission(BuildContext context) {
    // Find the target.
    final targets = widget.appState.targets;
    final matchingTargets =
        targets.where((t) => t.id == widget.entry.targetId).toList();

    if (matchingTargets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Target not found. It may have been deleted.',
            style: TextStyle(color: AppTheme.text),
          ),
          backgroundColor: AppTheme.surface,
        ),
      );
      return;
    }

    final target = matchingTargets.first;

    // Save context snapshot before launching.
    final progress = target.targetCount == 0
        ? 0.0
        : (target.solvedCount / target.targetCount).clamp(0.0, 1.0);
    final estimatedRemaining =
        ((1.0 - progress) * widget.entry.estimatedDurationMinutes).round();

    widget.planner.saveMissionContext(
      MissionContext(
        targetId: target.id,
        lastOpenedTime: DateTime.now(),
        progress: progress,
        estimatedRemainingMinutes: estimatedRemaining,
      ),
    );

    // Mark as in-progress.
    widget.planner.updateEntryStatus(
      widget.entry.id,
      PlannerEntryStatus.inProgress,
    );

    // Show the existing MissionSetupSheet.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlannerMissionSetup(
        target: target,
        entry: widget.entry,
        missionContext: _context,
        appState: widget.appState,
        planner: widget.planner,
      ),
    );
  }
}

/// Planner-aware mission setup sheet.
///
/// Reuses the same UI language as the existing MissionSetupSheet, but
/// integrates planner context (shows "Continue Mission" when context exists)
/// and marks the entry as completed when the mission finishes.
class _PlannerMissionSetup extends StatefulWidget {
  final TargetItem target;
  final PlannerEntry entry;
  final MissionContext? missionContext;
  final AppState appState;
  final PlannerProvider planner;

  const _PlannerMissionSetup({
    required this.target,
    required this.entry,
    required this.missionContext,
    required this.appState,
    required this.planner,
  });

  @override
  State<_PlannerMissionSetup> createState() => _PlannerMissionSetupState();
}

class _PlannerMissionSetupState extends State<_PlannerMissionSetup> {
  late TextEditingController _nameController;
  int _durationMinutes = 60;
  MissionType _missionType = MissionType.normal;

  final List<int> _durations = [15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: 'Mission: ${widget.target.title}',
    );
    _durationMinutes = widget.entry.estimatedDurationMinutes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPriorContext = widget.missionContext != null;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: AppTheme.border.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header — shows "Continue" if prior context exists
            Row(
              children: [
                Icon(
                  hasPriorContext
                      ? Icons.play_circle_outline_rounded
                      : Icons.rocket_launch,
                  color: AppTheme.accent,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  hasPriorContext ? 'Continue Mission' : 'Launch Mission',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
                ),
              ],
            ),

            // Prior context summary
            if (hasPriorContext) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.history, size: 16, color: AppTheme.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Last session: '
                        '${(widget.missionContext!.progress * 100).round()}% complete — '
                        '~${widget.missionContext!.estimatedRemainingMinutes} min remaining',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Mission name
            Text(
              'Mission Name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Enter mission name...',
                prefixIcon: Icon(Icons.title_rounded, size: 20),
              ),
              style: TextStyle(color: AppTheme.text),
            ),
            const SizedBox(height: 18),

            // Duration selector
            Text(
              'Estimated Duration',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _durations.map((d) {
                final isSelected = _durationMinutes == d;
                return ChoiceChip(
                  label: Text('$d mins'),
                  selected: isSelected,
                  onSelected: (v) {
                    if (v) setState(() => _durationMinutes = d);
                  },
                  backgroundColor:
                      AppTheme.surfaceStrong.withValues(alpha: 0.3),
                  selectedColor: AppTheme.accent.withValues(alpha: 0.2),
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.accent
                        : AppTheme.border.withValues(alpha: 0.15),
                  ),
                  labelStyle: TextStyle(
                    color:
                        isSelected ? AppTheme.accent : AppTheme.text,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Mission type selector
            Text(
              'Mission Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            _typeCard(MissionType.normal, 'Normal Mode',
                'Solve at your own pace.', Icons.shield_outlined, AppTheme.success),
            const SizedBox(height: 8),
            _typeCard(MissionType.strict, 'Strict Mode',
                'Focus challenge — stays active if app closes.', Icons.lock_outline, AppTheme.warning),
            const SizedBox(height: 8),
            _typeCard(MissionType.ultimate, 'Ultimate Mode',
                'High-intensity timed challenge.', Icons.bolt, AppTheme.danger),
            const SizedBox(height: 24),

            // Start button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: const Color(0xFF030712),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                onPressed: () async {
                  await widget.appState.startMission(
                    widget.target.id,
                    _nameController.text,
                    _durationMinutes,
                    _missionType,
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: Text(
                  hasPriorContext ? 'Continue Challenge' : 'Start Challenge',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeCard(
    MissionType type,
    String title,
    String desc,
    IconData icon,
    Color activeColor,
  ) {
    final isSelected = _missionType == type;
    return GestureDetector(
      onTap: () => setState(() => _missionType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.08)
              : AppTheme.surface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isSelected ? activeColor : AppTheme.border.withValues(alpha: 0.15),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.12)
                    : AppTheme.surfaceStrong,
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  color: isSelected ? activeColor : AppTheme.textMuted,
                  size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? activeColor : AppTheme.text,
                    ),
                  ),
                  Text(
                    desc,
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textMuted, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Entry Sheet ───────────────────────────────────────────────────────────

/// Bottom sheet for scheduling a mission into the daily planner.
class _AddEntrySheet extends StatefulWidget {
  final List<TargetItem> targets;
  final PlannerProvider planner;

  const _AddEntrySheet({required this.targets, required this.planner});

  @override
  State<_AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<_AddEntrySheet> {
  TargetItem? _selectedTarget;
  int _duration = 60;
  bool _forTomorrow = false;

  final List<int> _durations = [15, 30, 45, 60, 90, 120];

  @override
  Widget build(BuildContext context) {
    // Filter targets that haven't been completed yet.
    final available =
        widget.targets.where((t) => t.solvedCount < t.targetCount).toList();

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: AppTheme.border.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Row(
              children: [
                Icon(Icons.add_task_rounded,
                    color: AppTheme.accent, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Schedule Mission',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Target picker
            Text(
              'Select Target',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            if (available.isEmpty)
              Text(
                'No active targets available.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.border.withValues(alpha: 0.2),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TargetItem>(
                    isExpanded: true,
                    value: _selectedTarget,
                    hint: Text(
                      'Pick a target...',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                    dropdownColor: AppTheme.surface,
                    style: TextStyle(color: AppTheme.text, fontSize: 14),
                    items: available
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(
                                t.title,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (t) => setState(() => _selectedTarget = t),
                  ),
                ),
              ),
            const SizedBox(height: 18),

            // Duration
            Text(
              'Estimated Duration',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _durations.map((d) {
                final isSelected = _duration == d;
                return ChoiceChip(
                  label: Text('$d mins'),
                  selected: isSelected,
                  onSelected: (v) {
                    if (v) setState(() => _duration = d);
                  },
                  backgroundColor:
                      AppTheme.surfaceStrong.withValues(alpha: 0.3),
                  selectedColor: AppTheme.accent.withValues(alpha: 0.2),
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.accent
                        : AppTheme.border.withValues(alpha: 0.15),
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.accent : AppTheme.text,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Tomorrow toggle
            Row(
              children: [
                Text(
                  'Schedule for tomorrow',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.text,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _forTomorrow,
                  onChanged: (v) => setState(() => _forTomorrow = v),
                  activeThumbColor: AppTheme.accent,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Add button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: const Color(0xFF030712),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
                onPressed: _selectedTarget == null ? null : _addEntry,
                child: const Text(
                  'Add to Planner',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addEntry() async {
    final target = _selectedTarget!;
    final dateStr = _forTomorrow
        ? PlannerService.tomorrowStr
        : PlannerService.todayStr;

    final entry = PlannerEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      targetId: target.id,
      targetName: target.title,
      scheduledDate: dateStr,
      estimatedDurationMinutes: _duration,
    );

    if (_forTomorrow) {
      // Tomorrow entries use their own list.
      final existing = await PlannerService.loadTomorrowEntries();
      existing.add(entry);
      await PlannerService.saveTomorrowEntries(existing);
      await widget.planner.refresh();
    } else {
      await widget.planner.addEntry(entry);
    }

    if (mounted) Navigator.pop(context);
  }
}

// ── v1.2: Daily Summary Card ──────────────────────────────────────────────────

/// The top-level planning analysis card shown at the very top of the planner.
///
/// Shows:
///   - Today's workload (total estimated minutes, formatted)
///   - Workload status chip (On Track / Near Limit / Overloaded)
///   - Available time row with an edit button
///   - Overplanning warning (only when overloaded)
///   - Planning summary (mission count, carry-forward count)
class _DailySummaryCard extends StatelessWidget {
  final PlannerProvider planner;
  final VoidCallback onEditAvailableTime;

  const _DailySummaryCard({
    required this.planner,
    required this.onEditAvailableTime,
  });

  @override
  Widget build(BuildContext context) {
    final summary = planner.planningSummary;
    final availableH = planner.availableMinutes ~/ 60;
    final availableM = planner.availableMinutes % 60;
    final availableLabel = availableM == 0 ? '${availableH}h' : '${availableH}h ${availableM}m';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _statusColor(summary.status).withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: workload + status chip ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Workload",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary.totalMinutes == 0
                            ? 'No missions yet'
                            : summary.formattedDuration,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text,
                        ),
                      ),
                    ],
                  ),
                ),
                _WorkloadStatusChip(status: summary.status),
              ],
            ),
          ),

          // ── Divider ───────────────────────────────────────────────────────
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: AppTheme.border.withValues(alpha: 0.15),
            indent: 18,
            endIndent: 18,
          ),
          const SizedBox(height: 12),

          // ── Available time row ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Icon(Icons.schedule_outlined,
                    size: 15, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Text(
                  'Available Time',
                  style:
                      TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const Spacer(),
                Text(
                  availableLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onEditAvailableTime,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.edit_outlined,
                        size: 14, color: AppTheme.accent),
                  ),
                ),
              ],
            ),
          ),

          // ── Overplanning warning (only when overloaded) ───────────────────
          if (summary.isOverplanned) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: _OverplanningWarning(
                workloadLabel: summary.formattedDuration,
                availableLabel: availableLabel,
              ),
            ),
          ],

          // ── Planning summary row ──────────────────────────────────────────
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(child: _PlanningSummaryRow(summary: summary)),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(
                        color: AppTheme.warning.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Icon(Icons.auto_fix_high_rounded,
                      size: 14, color: AppTheme.warning),
                  label: Text(
                    'Recover',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.warning,
                    ),
                  ),
                  onPressed: () => planner.generateRecoveryPlan(force: true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _statusColor(PlannerStatus status) => switch (status) {
        PlannerStatus.onTrack => AppTheme.success,
        PlannerStatus.nearLimit => AppTheme.warning,
        PlannerStatus.overloaded => AppTheme.danger,
      };
}

// ── Workload status chip ──────────────────────────────────────────────────────

class _WorkloadStatusChip extends StatelessWidget {
  final PlannerStatus status;

  const _WorkloadStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      PlannerStatus.onTrack => 'On Track',
      PlannerStatus.nearLimit => 'Near Limit',
      PlannerStatus.overloaded => 'Overloaded',
    };
    final color = switch (status) {
      PlannerStatus.onTrack => AppTheme.success,
      PlannerStatus.nearLimit => AppTheme.warning,
      PlannerStatus.overloaded => AppTheme.danger,
    };
    final icon = switch (status) {
      PlannerStatus.onTrack => Icons.check_circle_outline_rounded,
      PlannerStatus.nearLimit => Icons.warning_amber_outlined,
      PlannerStatus.overloaded => Icons.error_outline_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overplanning warning card ─────────────────────────────────────────────────

class _OverplanningWarning extends StatelessWidget {
  final String workloadLabel;
  final String availableLabel;

  const _OverplanningWarning({
    required this.workloadLabel,
    required this.availableLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.danger.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 16, color: AppTheme.danger),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                    fontSize: 12, color: AppTheme.textMuted, height: 1.5),
                children: [
                  const TextSpan(
                      text: "Today's plan requires approximately "),
                  TextSpan(
                    text: workloadLabel,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.danger),
                  ),
                  const TextSpan(text: ' but your available time is '),
                  TextSpan(
                    text: availableLabel,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text),
                  ),
                  const TextSpan(
                      text:
                          '. Consider moving one or two missions to tomorrow.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Planning summary row ──────────────────────────────────────────────────────

class _PlanningSummaryRow extends StatelessWidget {
  final PlanningSummary summary;

  const _PlanningSummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _summaryItem(
          Icons.task_alt_rounded,
          '${summary.totalMissions}',
          'Missions',
          AppTheme.accent,
        ),
        const SizedBox(width: 16),
        _summaryItem(
          Icons.history_rounded,
          '${summary.carryForwardCount}',
          'Carry Fwd',
          AppTheme.warning,
        ),
        const SizedBox(width: 16),
        _summaryItem(
          Icons.timer_outlined,
          summary.formattedDuration,
          'Total',
          AppTheme.feature,
        ),
      ],
    );
  }

  Widget _summaryItem(
      IconData icon, String value, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
            Text(
              label,
              style:
                  TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Available time picker sheet ───────────────────────────────────────────────

/// Bottom sheet for configuring the user's available daily working time.
class _AvailableTimeSheet extends StatefulWidget {
  final PlannerProvider planner;

  const _AvailableTimeSheet({required this.planner});

  @override
  State<_AvailableTimeSheet> createState() => _AvailableTimeSheetState();
}

class _AvailableTimeSheetState extends State<_AvailableTimeSheet> {
  late int _selectedMinutes;

  // Options: 1 h to 16 h in 30-minute steps.
  static const List<int> _options = [
    60, 90, 120, 150, 180, 210, 240, 270, 300,
    330, 360, 390, 420, 480, 540, 600, 660, 720, 780, 840, 900, 960,
  ];

  @override
  void initState() {
    super.initState();
    _selectedMinutes = widget.planner.availableMinutes;
    // Snap to nearest option if not already one.
    if (!_options.contains(_selectedMinutes)) {
      _selectedMinutes = _options.reduce((a, b) =>
          (a - _selectedMinutes).abs() < (b - _selectedMinutes).abs()
              ? a
              : b);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: AppTheme.border.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.textMuted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Row(
            children: [
              Icon(Icons.schedule_rounded, color: AppTheme.accent, size: 26),
              const SizedBox(width: 12),
              Text(
                'Available Time',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'How many hours are you available to work today?',
            style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 20),

          // Time chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _options.map((m) {
              final isSelected = _selectedMinutes == m;
              final h = m ~/ 60;
              final min = m % 60;
              final label = min == 0 ? '${h}h' : '${h}h ${min}m';
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (v) {
                  if (v) setState(() => _selectedMinutes = m);
                },
                backgroundColor: AppTheme.surfaceStrong.withValues(alpha: 0.3),
                selectedColor: AppTheme.accent.withValues(alpha: 0.2),
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.accent
                      : AppTheme.border.withValues(alpha: 0.2),
                ),
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.accent : AppTheme.text,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: const Color(0xFF030712),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              onPressed: () async {
                await widget.planner.setAvailableMinutes(_selectedMinutes);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text(
                'Save',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── v1.3: Recovery Plan Card ──────────────────────────────────────────────────

/// Card displaying the interactive Recovery Plan suggestion.
class _RecoveryCard extends StatelessWidget {
  final PlannerProvider planner;

  const _RecoveryCard({required this.planner});

  @override
  Widget build(BuildContext context) {
    final plan = planner.recoveryPlan;
    if (plan == null) return const SizedBox.shrink();

    final remainingWorkloadH = plan.remainingWorkloadMinutes ~/ 60;
    final remainingWorkloadM = plan.remainingWorkloadMinutes % 60;
    final remainingWorkloadLabel = remainingWorkloadM == 0
        ? '${remainingWorkloadH}h'
        : '${remainingWorkloadH}h ${remainingWorkloadM}m';

    final remainingTimeH = plan.remainingAvailableMinutes ~/ 60;
    final remainingTimeM = plan.remainingAvailableMinutes % 60;
    final remainingTimeLabel = remainingTimeM == 0
        ? '${remainingTimeH}h'
        : '${remainingTimeH}h ${remainingTimeM}m';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.warning.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_fix_high_rounded,
                    color: AppTheme.warning, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Recovery Plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Recommended',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Workload vs Available time summary
          Row(
            children: [
              Expanded(
                child: _metricBox(
                  'Remaining Work',
                  remainingWorkloadLabel,
                  AppTheme.danger,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricBox(
                  'Available Time',
                  remainingTimeLabel,
                  AppTheme.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Text(
            'Recommended Adjustments:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),

          // Recommendations List
          ...plan.items.map((item) {
            final isKeep = item.action == RecoveryItemAction.keep;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    isKeep
                        ? Icons.check_circle_outline_rounded
                        : Icons.arrow_forward_rounded,
                    size: 16,
                    color: isKeep ? AppTheme.success : AppTheme.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isKeep
                          ? '✓ Finish ${item.entry.targetName}'
                          : '→ Move ${item.entry.targetName} to Tomorrow',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isKeep ? AppTheme.text : AppTheme.warning,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          // Action Buttons: Accept / Dismiss
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppTheme.border.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => planner.dismissRecoveryPlan(),
                  child: Text(
                    'Dismiss',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warning,
                    foregroundColor: const Color(0xFF030712),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    await planner.applyRecoveryPlan();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Recovery Plan applied successfully!',
                            style: TextStyle(color: AppTheme.text),
                          ),
                          backgroundColor: AppTheme.surface,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Accept',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── v1.4: Tomorrow Looks Busy Card ───────────────────────────────────────────

/// Smart overflow warning card displayed in Tomorrow Preview when tomorrow's
/// estimated workload exceeds available working hours.
class _TomorrowLooksBusyCard extends StatelessWidget {
  final PlannerProvider planner;

  const _TomorrowLooksBusyCard({required this.planner});

  @override
  Widget build(BuildContext context) {
    final workloadM = planner.tomorrowWorkloadMinutes;
    final workloadH = workloadM ~/ 60;
    final remainingM = workloadM % 60;
    final workloadLabel = remainingM == 0
        ? '${workloadH}h'
        : '${workloadH}h ${remainingM}m';

    final availableM = planner.availableMinutes;
    final availableH = availableM ~/ 60;
    final availableRemM = availableM % 60;
    final availableLabel = availableRemM == 0
        ? '${availableH}h'
        : '${availableH}h ${availableRemM}m';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_busy_rounded,
                  color: AppTheme.warning, size: 18),
              const SizedBox(width: 8),
              Text(
                'Tomorrow Looks Busy',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'Tomorrow contains approximately '),
                TextSpan(
                  text: workloadLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warning,
                  ),
                ),
                const TextSpan(text: ' of work. Your available time is '),
                TextSpan(
                  text: availableLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── v1.5: Coach Engine Card ───────────────────────────────────────────────────

/// Lightweight card displaying the fact-based observation from the Coach Engine.
class _CoachCard extends StatelessWidget {
  final CoachMessage message;
  final CoachPersonality personality;
  final VoidCallback onOpenSettings;

  const _CoachCard({
    required this.message,
    required this.personality,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(personality.icon, color: AppTheme.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Coach · ${personality.displayName}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accent,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onOpenSettings,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.settings_outlined,
                      size: 14, color: AppTheme.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.body,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.text,
              height: 1.4,
            ),
          ),
          if (message.actionRecommendation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message.actionRecommendation,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


