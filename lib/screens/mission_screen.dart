import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/theme/app_theme.dart';
import '../models/mission.dart';

import '../models/target_item.dart';
import '../providers/app_state.dart';


class MissionScreen extends StatefulWidget {
  const MissionScreen({super.key});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> with WidgetsBindingObserver {
  Timer? _ticker;
  Duration _elapsed = Duration.zero;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    
    // Set fullscreen mode for Strict and Ultimate modes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Provider.of<AppState>(context, listen: false);
      final mission = appState.activeMission;
      if (mission != null &&
          (mission.type == MissionType.strict || mission.type == MissionType.ultimate)) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    });

    _startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      final appState = Provider.of<AppState>(context, listen: false);
      final mission = appState.activeMission;
      if (mission != null && mission.status == MissionStatus.active && !mission.isPaused) {
        appState.recordInterruption();
      }
    }
  }


  void _startTimer() {
    _updateTime();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateTime();
        });
      }
    });
  }

  void _updateTime() {
    final appState = Provider.of<AppState>(context, listen: false);
    final mission = appState.activeMission;
    if (mission == null) return;

    final now = DateTime.now();
    
    if (mission.status == MissionStatus.completed) {
      _elapsed = Duration(seconds: mission.accumulatedSeconds);
      _remaining = Duration.zero;
    } else {
      int seconds = mission.accumulatedSeconds;
      if (!mission.isPaused && mission.lastResumeTime != null) {
        seconds += now.difference(mission.lastResumeTime!).inSeconds;
      }
      _elapsed = Duration(seconds: seconds);
      final totalSeconds = mission.estimatedDurationMinutes * 60;
      final remainingSeconds = totalSeconds - seconds;
      _remaining = Duration(seconds: remainingSeconds > 0 ? remainingSeconds : 0);
    }
  }


  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final mission = appState.activeMission;

    if (mission == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final target = appState.targets.firstWhere(
      (t) => t.id == mission.targetId,
      orElse: () => _targetFromArchive(appState, mission.targetId),
    );

    final isCompleted = mission.status == MissionStatus.completed || target.solvedCount >= target.targetCount;

    if (isCompleted) {
      return _buildCompletionView(context, appState, mission, target);
    }

    return _buildActiveView(context, appState, mission, target);
  }

  // Fallback in case target is archived
  TargetItem _targetFromArchive(AppState appState, String targetId) {
    return appState.archivedTargets.firstWhere(
      (t) => t.id == targetId,
      orElse: () => TargetItem(id: targetId, title: 'Unknown Target', targetCount: 1),
    );
  }


  Widget _buildActiveView(
    BuildContext context,
    AppState appState,
    Mission mission,
    TargetItem target,
  ) {
    if (mission.type == MissionType.ultimate) {
      return _buildUltimateView(context, appState, mission, target);
    }

    final progress = target.targetCount == 0 ? 0.0 : target.solvedCount / target.targetCount;
    final remainingCount = (target.targetCount - target.solvedCount).clamp(0, target.targetCount);
    
    Color typeColor = AppTheme.success;
    if (mission.type == MissionType.strict) typeColor = AppTheme.warning;

    final animsOn = appState.animationsOn;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: typeColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                mission.type.name.toUpperCase(),
                                style: TextStyle(
                                  color: typeColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Active Mission',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Timer display
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        mission.isPaused
                            ? 'MISSION PAUSED'
                            : (_remaining.inSeconds > 0 ? 'TIME REMAINING' : 'ELAPSED TIME'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: mission.isPaused ? AppTheme.warning : AppTheme.textMuted,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _remaining.inSeconds > 0
                            ? _formatDuration(_remaining)
                            : _formatDuration(_elapsed),
                        style: TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.bold,
                          color: mission.isPaused
                              ? AppTheme.textMuted
                              : (_remaining.inSeconds > 0 ? AppTheme.accent : AppTheme.danger),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Normal mode Pause/Resume control
              if (mission.type == MissionType.normal) ...[
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (mission.isPaused) {
                        appState.resumeActiveMission();
                      } else {
                        appState.pauseActiveMission();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mission.isPaused ? AppTheme.success : AppTheme.warning,
                      foregroundColor: const Color(0xFF030712),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: Icon(mission.isPaused ? Icons.play_arrow : Icons.pause),
                    label: Text(
                      mission.isPaused ? 'Resume Mission' : 'Pause Mission',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],

              const Spacer(),

              // Progress info
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Solved: ${target.solvedCount} / ${target.targetCount}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text,
                        ),
                      ),
                      Text(
                        '$remainingCount remaining',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: animsOn ? 400 : 0),
                    curve: Curves.easeInOut,
                    tween: Tween<double>(begin: 0, end: progress),
                    builder: (context, val, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 16,
                          child: LinearProgressIndicator(
                            value: val,
                            backgroundColor: AppTheme.surfaceStrong.withValues(alpha: 0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Spacer(),

              // Action buttons (+1 and Undo)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 58,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textMuted,
                          side: BorderSide(color: AppTheme.border.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: target.solvedCount > 0
                            ? () => appState.setSolved(target.id, target.solvedCount - 1)
                            : null,
                        icon: const Icon(Icons.undo),
                        label: const Text('Undo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 58,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: const Color(0xFF030712),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                        ),
                        onPressed: () => appState.setSolved(target.id, target.solvedCount + 1),
                        icon: const Icon(Icons.add, size: 24),
                        label: const Text('+1 Solved', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quit option
              Center(
                child: TextButton.icon(
                  onPressed: () => _confirmAbandon(context, appState, mission, target),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.danger.withValues(alpha: 0.7)),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Quit Mission'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUltimateView(
    BuildContext context,
    AppState appState,
    Mission mission,
    TargetItem target,
  ) {
    final progress = target.targetCount == 0 ? 0.0 : target.solvedCount / target.targetCount;
    final remainingCount = (target.targetCount - target.solvedCount).clamp(0, target.targetCount);
    final animsOn = appState.animationsOn;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mission Title (Large & Centered for ultimate focus)
              Center(
                child: Text(
                  mission.name,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),

              // Timer Display
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppTheme.border.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _remaining.inSeconds > 0 ? 'TIME REMAINING' : 'ELAPSED TIME',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _remaining.inSeconds > 0
                            ? _formatDuration(_remaining)
                            : _formatDuration(_elapsed),
                        style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: _remaining.inSeconds > 0 ? AppTheme.accent : AppTheme.danger,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),

              // Progress & Remaining Problems Text
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Solved: ${target.solvedCount} / ${target.targetCount}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.text,
                        ),
                      ),
                      Text(
                        '$remainingCount problems remaining',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.danger.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: animsOn ? 400 : 0),
                    curve: Curves.easeInOut,
                    tween: Tween<double>(begin: 0, end: progress),
                    builder: (context, val, _) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 18,
                          child: LinearProgressIndicator(
                            value: val,
                            backgroundColor: AppTheme.surfaceStrong.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Spacer(),

              // Actions (+1 / Undo)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textMuted,
                          side: BorderSide(color: AppTheme.border.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: target.solvedCount > 0
                            ? () => appState.setSolved(target.id, target.solvedCount - 1)
                            : null,
                        icon: const Icon(Icons.undo),
                        label: const Text('Undo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: const Color(0xFF030712),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                        ),
                        onPressed: () => appState.setSolved(target.id, target.solvedCount + 1),
                        icon: const Icon(Icons.add, size: 24),
                        label: const Text('+1 Solved', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Emergency Exit
              Center(
                child: TextButton.icon(
                  onPressed: () => _confirmAbandon(context, appState, mission, target),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.danger.withValues(alpha: 0.8)),
                  icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                  label: const Text('Emergency Exit', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionView(
    BuildContext context,
    AppState appState,
    Mission mission,
    TargetItem target,
  ) {
    final elapsed = Duration(seconds: mission.accumulatedSeconds);
    final problemsSolved = (target.solvedCount - mission.startSolvedCount).clamp(0, target.targetCount);

    final historyList = appState.missionHistory.where((h) => h.id == mission.id).toList();
    final historyItem = historyList.isNotEmpty ? historyList.last : null;

    final focusScore = historyItem?.focusScore ?? 100;
    final xpEarned = historyItem?.xpEarned ?? 100;

    // Focus Score Classification
    String focusRating = 'AVERAGE';
    Color ratingColor = AppTheme.warning;
    if (focusScore >= 90) {
      focusRating = 'EXCELLENT';
      ratingColor = AppTheme.success;
    } else if (focusScore >= 70) {
      focusRating = 'GOOD';
      ratingColor = AppTheme.accent;
    } else if (focusScore < 50) {
      focusRating = 'POOR';
      ratingColor = AppTheme.danger;
    }

    final previousTotalXp = (appState.totalXp - xpEarned).clamp(0, 999999);
    final previousLevel = previousTotalXp ~/ 1000 + 1;
    final previousXpInLevel = previousTotalXp % 1000;
    final currentXpInLevel = appState.totalXp % 1000;
    final didLevelUp = appState.level > previousLevel;

    final startVal = previousXpInLevel / 1000.0;
    final endVal = didLevelUp ? 1.0 : (currentXpInLevel / 1000.0);
    final animsOn = appState.animationsOn;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon & Celebration Header
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.success.withValues(alpha: 0.3), width: 2),
                  ),
                  child: Icon(Icons.workspace_premium_rounded, color: AppTheme.success, size: 48),
                ),
              ),
              const SizedBox(height: 20),

              Center(
                child: Text(
                  'Mission Complete!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.text,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  mission.name,
                  style: TextStyle(fontSize: 14, color: AppTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),

              // Level Up Overlay / Banner (If Leveled Up!)
              if (didLevelUp) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.accent.withValues(alpha: 0.25), AppTheme.accent.withValues(alpha: 0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.stars_rounded, color: AppTheme.accent, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LEVEL UP! 🎉',
                              style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'You reached Level ${appState.level}! Keep focus high!',
                              style: TextStyle(color: AppTheme.text, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Focus Score Card & Discipline Score Card
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        children: [
                          const Text('FOCUS SCORE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                          const SizedBox(height: 8),
                          Text(
                            '$focusScore',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: ratingColor),
                          ),
                          const SizedBox(height: 4),
                          Text(focusRating, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ratingColor)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
                      ),
                      child: Column(
                        children: [
                          const Text('DISCIPLINE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                          const SizedBox(height: 8),
                          Text(
                            '${appState.disciplineScore}',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.accent),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_upward_rounded, color: AppTheme.success, size: 12),
                              const SizedBox(width: 2),
                              Text('+5 Credit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.success)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // XP Progress Bar & Anim
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Level ${didLevelUp ? previousLevel : appState.level}',
                          style: TextStyle(color: AppTheme.text, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '+$xpEarned XP Earned',
                          style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: animsOn ? 800 : 0),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(begin: startVal, end: endVal),
                      builder: (context, val, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                height: 12,
                                child: LinearProgressIndicator(
                                  value: val,
                                  backgroundColor: AppTheme.surfaceStrong.withValues(alpha: 0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${(val * 1000).round()} / 1000 XP',
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Details Stats Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    _buildStatRow('Duration Spent', _formatDuration(elapsed), Icons.timer_outlined),
                    const Divider(color: Color(0x1A94A3B8), height: 20),
                    _buildStatRow('Mission Type', mission.type.name.toUpperCase(), Icons.style_outlined),
                    const Divider(color: Color(0x1A94A3B8), height: 20),
                    _buildStatRow('Problems Solved', '+$problemsSolved solved', Icons.done_all_rounded),
                    const Divider(color: Color(0x1A94A3B8), height: 20),
                    _buildStatRow('Interruptions', '${mission.interruptionCount}', Icons.warning_amber_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Continue Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: const Color(0xFF030712),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  onPressed: () async {
                    await appState.clearActiveMission();
                  },
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accent, size: 20),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 15)),
        const Spacer(),
        Text(value, style: TextStyle(color: AppTheme.text, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  void _confirmAbandon(
    BuildContext context,
    AppState appState,
    Mission mission,
    TargetItem target,
  ) {
    final remainingCount = (target.targetCount - target.solvedCount).clamp(0, target.targetCount);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.danger, size: 28),
            const SizedBox(width: 10),
            Text(
              mission.type == MissionType.normal ? 'Quit Mission?' : 'EMERGENCY EXIT',
              style: TextStyle(
                color: AppTheme.text,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceStrong.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progress', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      Text('${target.solvedCount} / ${target.targetCount} Solved',
                          style: TextStyle(color: AppTheme.text, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Remaining Problems', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      Text('$remainingCount remaining',
                          style: TextStyle(color: AppTheme.text, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Duration Elapsed', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      Text(_formatDuration(_elapsed),
                          style: TextStyle(color: AppTheme.text, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              mission.type == MissionType.normal
                  ? 'Are you sure you want to end this mission? Your active session progress will close.'
                  : '⚠️ WARNING: This is a strict focus challenge. Exiting now will record an interruption and prematurely end your mission!',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Stay',
              style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (mission.status == MissionStatus.active) {
                await appState.recordInterruption();
              }
              await appState.clearActiveMission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: const Color(0xFF030712),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Emergency Exit', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

