import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/target_item.dart';
import '../providers/app_state.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayMonth = DateTime(now.year, now.month);
  }

  void _prevMonth() => setState(() {
        _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
      });

  // ── Helpers ──────────────────────────────────────────────────────────────────
  String _dateString(int year, int month, int day) =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  String _todayString() {
    final now = DateTime.now();
    return _dateString(now.year, now.month, now.day);
  }

  int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.surface.withValues(alpha: 0.9),
        elevation: 0,
        title: const Text('Activity Calendar'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.surface.withValues(alpha: 0.4), AppTheme.bg],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Consumer<AppState>(
          builder: (context, appState, _) {
            final activity  = appState.dailyActivity;
            final allTargets = [
              ...appState.targets,
              ...appState.archivedTargets,
            ];
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    children: [
                      _buildMonthHeader(),
                      const SizedBox(height: 20),
                      _buildCalendarGrid(activity),
                      const SizedBox(height: 20),
                      _buildLegend(),
                      const SizedBox(height: 20),
                      _buildMonthSummary(activity, allTargets),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Month header ─────────────────────────────────────────────────────────────
  Widget _buildMonthHeader() {
    return _calCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: AppTheme.accent, size: 28),
            onPressed: _prevMonth,
          ),
          Text(
            '${_monthNames[_displayMonth.month - 1]} ${_displayMonth.year}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.text,
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: AppTheme.accent, size: 28),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  // ── Calendar grid ─────────────────────────────────────────────────────────────
  Widget _buildCalendarGrid(Map<String, List<String>> activity) {
    final year        = _displayMonth.year;
    final month       = _displayMonth.month;
    final offset      = DateTime(year, month, 1).weekday - 1; // Mon=0 … Sun=6
    final daysInMonth = _daysInMonth(year, month);
    final todayStr    = _todayString();

    return _calCard(
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: _weekdays
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          // Day grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1,
            ),
            itemCount: offset + daysInMonth,
            itemBuilder: (context, index) {
              if (index < offset) return const SizedBox.shrink();

              final day     = index - offset + 1;
              final dateStr = _dateString(year, month, day);
              final ids     = activity[dateStr] ?? [];
              final hasAct  = ids.isNotEmpty;
              final isToday = dateStr == todayStr;
              final highAct = ids.length >= 3; // "high activity" threshold

              return GestureDetector(
                onTap: () => _showDayDetail(context, dateStr, day, ids),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: hasAct
                        ? AppTheme.accent.withValues(alpha: 0.15)
                        : AppTheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isToday
                          ? AppTheme.accent
                          : hasAct
                              ? AppTheme.accent.withValues(alpha: 0.4)
                              : AppTheme.border.withValues(alpha: 0.15),
                      width: isToday ? 2 : 1,
                    ),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            color: isToday
                                ? AppTheme.accent
                                : hasAct
                                    ? AppTheme.text
                                    : AppTheme.textMuted,
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (hasAct)
                        Positioned(
                          bottom: 3,
                          right: 3,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: highAct
                                  ? AppTheme.success
                                  : AppTheme.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Legend ───────────────────────────────────────────────────────────────────
  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 10,
      children: [
        _legendDot(AppTheme.accent, AppTheme.accent.withValues(alpha: 0.15), 'Has Activity'),
        _legendDot(AppTheme.success, AppTheme.accent.withValues(alpha: 0.15), 'High Activity (3+)'),
        _legendDot(AppTheme.accent, AppTheme.surface.withValues(alpha: 0.5), 'Today',
            isToday: true),
      ],
    );
  }

  Widget _legendDot(Color borderColor, Color bg, String label,
      {bool isToday = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: isToday ? 2 : 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      ],
    );
  }

  // ── Month summary ─────────────────────────────────────────────────────────────
  Widget _buildMonthSummary(
    Map<String, List<String>> activity,
    List<TargetItem> allTargets,
  ) {
    final monthPrefix =
        '${_displayMonth.year}-${_displayMonth.month.toString().padLeft(2, '0')}';
    final monthKeys = activity.keys.where((k) => k.startsWith(monthPrefix));
    final activeDays = monthKeys.length;
    final uniqueIds  = monthKeys.expand((k) => activity[k] ?? []).toSet();

    return _calCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Month Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: 16),
          activeDays == 0
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No activity recorded this month.',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ),
                )

              : Row(
                  children: [
                    Expanded(
                      child: _summaryBox(
                          '$activeDays', 'Active Days', AppTheme.accent),
                    ),
                    Expanded(
                      child: _summaryBox(
                          '${uniqueIds.length}',
                          'Targets Worked',
                          AppTheme.success),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _summaryBox(String value, String label, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 32, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
      ],
    );
  }

  // ── Day detail dialog ─────────────────────────────────────────────────────────
  void _showDayDetail(
    BuildContext context,
    String dateStr,
    int day,
    List<String> targetIds,
  ) {
    final appState     = context.read<AppState>();
    final allTargets   = [...appState.targets, ...appState.archivedTargets];
    final monthLabel   = _monthNames[_displayMonth.month - 1];
    final dateLabel    = '$day $monthLabel ${_displayMonth.year}';

    final workedTargets = targetIds
        .map((id) {
          try {
            return allTargets.firstWhere((t) => t.id == id);
          } catch (_) {
            return null;
          }
        })
        .whereType<TargetItem>()
        .toList();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.calendar_today, color: AppTheme.accent, size: 20),
            const SizedBox(width: 10),
            Text(dateLabel,
                style: TextStyle(color: AppTheme.text, fontSize: 17)),
          ],
        ),
        content: targetIds.isEmpty
            ? Text('No activity on this day.',
                style: TextStyle(color: AppTheme.textMuted))
            : SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${targetIds.length} target${targetIds.length == 1 ? '' : 's'} had progress:',
                      style: TextStyle(
                          color: AppTheme.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ...workedTargets.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppTheme.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                t.title,
                                style: TextStyle(
                                    color: AppTheme.text, fontSize: 15),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceStrong.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${t.solvedCount}/${t.targetCount}',
                                style: TextStyle(
                                    color: AppTheme.accent, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (workedTargets.length < targetIds.length)
                      Text(
                        '+${targetIds.length - workedTargets.length} deleted target(s)',
                        style: TextStyle(
                            color: AppTheme.textMuted, fontSize: 12),
                      ),
                  ],
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ── Card wrapper ─────────────────────────────────────────────────────────────
  Widget _calCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.2)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x3D000000), blurRadius: 60, offset: Offset(0, 20)),
        ],
      ),
      child: child,
    );
  }
}
