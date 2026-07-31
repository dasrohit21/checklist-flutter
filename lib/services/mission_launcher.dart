import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/target_item.dart';
import 'mission_session_service.dart';

/// Modal dialog launcher for initiating Target-driven Mission Sessions.
class MissionLauncher {
  static void showLaunchDialog(BuildContext context, TargetItem target) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MissionLaunchSheet(target: target),
    );
  }
}

class _MissionLaunchSheet extends StatefulWidget {
  final TargetItem target;

  const _MissionLaunchSheet({required this.target});

  @override
  State<_MissionLaunchSheet> createState() => _MissionLaunchSheetState();
}

class _MissionLaunchSheetState extends State<_MissionLaunchSheet> {
  int _selectedGoalCount = 3;
  int _estimatedDurationMinutes = 60;
  final List<String> _selectedItemIds = [];

  final List<int> _problemCountOptions = [1, 2, 3, 5, 8, 10];
  final List<int> _durationOptions = [15, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    if (widget.target.type == TargetType.problem) {
      final remaining = widget.target.targetCount - widget.target.solvedCount;
      if (remaining > 0 && remaining < _selectedGoalCount) {
        _selectedGoalCount = remaining;
      }
    } else {
      // For checklist, select uncompleted subitems by default (up to 3)
      final uncompleted = widget.target.checklistSubItems
          .where((i) => !i.completed)
          .take(3)
          .map((i) => i.id)
          .toList();
      _selectedItemIds.addAll(uncompleted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProblem = widget.target.type == TargetType.problem;

    return Container(
      padding: EdgeInsets.only(
        left: AppTheme.sp24,
        right: AppTheme.sp24,
        top: AppTheme.sp24,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.sp24,
      ),
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
            color: AppTheme.border.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            spreadRadius: 4,
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
                  color: AppTheme.textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.sp20),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isProblem ? Icons.code_rounded : Icons.checklist_rtl_rounded,
                    color: AppTheme.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.sp12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.target.title,
                        style: AppTheme.titleStyle.copyWith(
                          color: AppTheme.text,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isProblem
                            ? 'Problem Target • ${widget.target.difficulty}'
                            : 'Checklist Target • ${widget.target.checklistSubItems.length} items',
                        style: AppTheme.captionStyle.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.sp24),

            // Today's Goal Question
            Text(
              isProblem
                  ? 'How many problems would you like to solve today?'
                  : 'What would you like to complete today?',
              style: AppTheme.titleStyle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.text,
              ),
            ),
            const SizedBox(height: AppTheme.sp12),

            if (isProblem) ...[
              // Goal Count Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _problemCountOptions.map((count) {
                  final isSelected = _selectedGoalCount == count;
                  return ChoiceChip(
                    label: Text('$count ${count == 1 ? 'Problem' : 'Problems'}'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedGoalCount = count);
                      }
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
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  );
                }).toList(),
              ),
            ] else ...[
              // Checklist Item selector
              if (widget.target.checklistSubItems.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'No sub-items defined yet for this target. Start mission to work on target tasks.',
                    style: AppTheme.bodyStyle.copyWith(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ] else ...[
                Column(
                  children: widget.target.checklistSubItems.map((item) {
                    final isChecked = _selectedItemIds.contains(item.id);
                    return CheckboxListTile(
                      value: isChecked,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedItemIds.add(item.id);
                          } else {
                            _selectedItemIds.remove(item.id);
                          }
                        });
                      },
                      title: Text(
                        item.text,
                        style: AppTheme.bodyStyle.copyWith(
                          color: item.completed
                              ? AppTheme.textMuted
                              : AppTheme.text,
                          decoration: item.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      dense: true,
                      activeColor: AppTheme.accent,
                      checkColor: AppTheme.bg,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                    );
                  }).toList(),
                ),
              ],
            ],

            const SizedBox(height: AppTheme.sp20),

            // Estimated Duration Selector
            Text(
              'Estimated Duration',
              style: AppTheme.titleStyle.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: AppTheme.sp8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _durationOptions.map((mins) {
                final isSelected = _estimatedDurationMinutes == mins;
                return ChoiceChip(
                  label: Text('$mins mins'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _estimatedDurationMinutes = mins);
                    }
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
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            // Action Button
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
                  Navigator.pop(context);
                  await MissionSessionService.launchSession(
                    context,
                    target: widget.target,
                    durationMinutes: _estimatedDurationMinutes,
                    selectedGoalCount: _selectedGoalCount,
                    selectedItemIds: _selectedItemIds,
                  );
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Start Mission',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
}
