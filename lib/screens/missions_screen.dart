import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../providers/app_state.dart';
import '../providers/behavior_provider.dart';
import '../widgets/target_card.dart';
import 'mission_chains_screen.dart';

/// Missions screen — tabbed container for Mission List and Mission Chains.
///
/// Tabs:
///   Missions — searchable / filterable list of all targets.
///   Chains   — MissionChainsScreen.
class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        floatingActionButton: _NewMissionFab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
                // Tab bar header
                Container(
                  padding: const EdgeInsets.fromLTRB(
                      AppTheme.sp24, AppTheme.sp16, AppTheme.sp24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Targets',
                        style: AppTheme.displayStyle
                            .copyWith(color: AppTheme.text),
                      ),
                      const SizedBox(height: AppTheme.sp12),
                      // Tab pills
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceStrong
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color:
                                  AppTheme.border.withValues(alpha: 0.1)),
                        ),
                        child: TabBar(
                          indicator: BoxDecoration(
                            color: AppTheme.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: const Color(0xFF0F172A),
                          unselectedLabelColor: AppTheme.textMuted,
                          labelStyle: AppTheme.buttonStyle,
                          unselectedLabelStyle: AppTheme.bodyStyle,
                          tabs: const [
                            Tab(text: 'Targets'),
                            Tab(text: 'Chains'),
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
                      _MissionListTab(),
                      MissionChainsScreen(),
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

// ── New Mission FAB ───────────────────────────────────────────────────────────

class _NewMissionFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _NewMissionSheet(),
      ),
      backgroundColor: AppTheme.accent,
      foregroundColor: const Color(0xFF030712),
      elevation: 4,
      icon: const Icon(Icons.add_rounded),
      label: const Text(
        'New Mission',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}

// ── Mission List Tab ──────────────────────────────────────────────────────────

enum _MissionFilter { all, active, completed, archived, overdue }

enum _PriorityFilter { all, high, medium, low }

class _MissionListTab extends StatefulWidget {
  const _MissionListTab();

  @override
  State<_MissionListTab> createState() => _MissionListTabState();
}

class _MissionListTabState extends State<_MissionListTab> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _searchQuery = '';
  _MissionFilter _filter = _MissionFilter.all;
  _PriorityFilter _priorityFilter = _PriorityFilter.all;
  String? _filterCategoryId;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  static const _filterLabels = {
    _MissionFilter.all: 'All',
    _MissionFilter.active: 'Active',
    _MissionFilter.completed: 'Done',
    _MissionFilter.archived: 'Archived',
    _MissionFilter.overdue: 'Overdue',
  };

  static const _priorityLabels = {
    _PriorityFilter.all: 'Any',
    _PriorityFilter.high: 'High',
    _PriorityFilter.medium: 'Medium',
    _PriorityFilter.low: 'Low',
  };

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppState, BehaviorProvider>(
      builder: (context, appState, behavior, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppTheme.sp24, AppTheme.sp16, AppTheme.sp24, AppTheme.sp24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search + filter card
                  _SearchCard(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    searchQuery: _searchQuery,
                    filter: _filter,
                    priorityFilter: _priorityFilter,
                    filterCategoryId: _filterCategoryId,
                    appState: appState,
                    onQueryChanged: (q) =>
                        setState(() => _searchQuery = q),
                    onFilterChanged: (f) =>
                        setState(() => _filter = f),
                    onPriorityChanged: (p) =>
                        setState(() => _priorityFilter = p),
                    onCategoryChanged: (id) =>
                        setState(() => _filterCategoryId = id),
                    filterLabels: _filterLabels,
                    priorityLabels: _priorityLabels,
                  ),
                  const SizedBox(height: AppTheme.sp16),

                  // Mission list
                  _buildMissionList(appState, behavior),

                  // Archived section
                  if (_filter == _MissionFilter.all ||
                      _filter == _MissionFilter.archived) ...[
                    const SizedBox(height: AppTheme.sp24),
                    _buildArchivedList(appState),
                  ],

                  // Bottom padding so FAB doesn't overlap last card
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMissionList(AppState appState, BehaviorProvider behavior) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    var items = appState.sortedTargets;

    // Category filter
    if (_filterCategoryId != null) {
      items = items
          .where((t) => t.categoryId == _filterCategoryId)
          .toList();
    }

    // Status filter
    switch (_filter) {
      case _MissionFilter.active:
        items = items.where((t) => t.solvedCount < t.targetCount).toList();
        break;
      case _MissionFilter.completed:
        items = items
            .where((t) =>
                t.targetCount > 0 && t.solvedCount >= t.targetCount)
            .toList();
        break;
      case _MissionFilter.overdue:
        items = items.where((t) {
          if (t.dueDate == null) return false;
          final due = DateTime(
              t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
          return due.isBefore(todayDate) && t.solvedCount < t.targetCount;
        }).toList();
        break;
      case _MissionFilter.all:
      case _MissionFilter.archived:
        break;
    }

    // Priority filter
    if (_priorityFilter != _PriorityFilter.all) {
      final priorityStr = _priorityFilter.name; // 'high', 'medium', 'low'
      items = items.where((t) => t.priority == priorityStr).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      items = items.where((t) {
        return t.title.toLowerCase().contains(q) ||
            t.notes.toLowerCase().contains(q) ||
            t.tags.any((tag) => tag.toLowerCase().contains(q));
      }).toList();
    }

    if (items.isEmpty) {
      return _EmptyState(
        icon: Icons.rocket_launch_outlined,
        title: 'No missions found.',
        subtitle: _searchQuery.isNotEmpty
            ? 'Try a different search or filter.'
            : 'Tap the + button below to create your first mission.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'MISSIONS',
                  style: AppTheme.labelStyle
                      .copyWith(color: AppTheme.textMuted),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${items.length}',
                    style: AppTheme.captionStyle.copyWith(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Consumer<AppState>(
              builder: (context, state, _) =>
                  DropdownButton<SortOption>(
                value: state.sortOption,
                underline: const SizedBox.shrink(),
                dropdownColor: AppTheme.surface,
                style: AppTheme.captionStyle
                    .copyWith(color: AppTheme.textMuted),
                icon: Icon(Icons.sort,
                    color: AppTheme.textMuted, size: 18),
                items: const [
                  DropdownMenuItem(
                      value: SortOption.newest,
                      child: Text('Newest')),
                  DropdownMenuItem(
                      value: SortOption.oldest,
                      child: Text('Oldest')),
                  DropdownMenuItem(
                      value: SortOption.alphabetical,
                      child: Text('A → Z')),
                  DropdownMenuItem(
                      value: SortOption.deadline,
                      child: Text('Deadline')),
                  DropdownMenuItem(
                      value: SortOption.progress,
                      child: Text('Progress')),
                  DropdownMenuItem(
                      value: SortOption.priority,
                      child: Text('Priority')),
                ],
                onChanged: (v) {
                  if (v != null) state.setSortOption(v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.sp12),
        ...items.map((item) =>
            MissionCard(item: item, searchQuery: _searchQuery)),
      ],
    );
  }

  Widget _buildArchivedList(AppState appState) {
    var items = appState.archivedTargets.toList();
    if (_filterCategoryId != null) {
      items =
          items.where((t) => t.categoryId == _filterCategoryId).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      items = items.where((t) {
        return t.title.toLowerCase().contains(q) ||
            t.notes.toLowerCase().contains(q) ||
            t.tags.any((tag) => tag.toLowerCase().contains(q));
      }).toList();
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ARCHIVED',
              style:
                  AppTheme.labelStyle.copyWith(color: AppTheme.textMuted),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.textMuted.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${items.length}',
                style: AppTheme.captionStyle
                    .copyWith(color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.sp12),
        ...items.map((item) =>
            ArchivedMissionCard(item: item, searchQuery: _searchQuery)),
      ],
    );
  }
}

// ── Search + Filter Card ──────────────────────────────────────────────────────

class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.controller,
    required this.focusNode,
    required this.searchQuery,
    required this.filter,
    required this.priorityFilter,
    required this.filterCategoryId,
    required this.appState,
    required this.onQueryChanged,
    required this.onFilterChanged,
    required this.onPriorityChanged,
    required this.onCategoryChanged,
    required this.filterLabels,
    required this.priorityLabels,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String searchQuery;
  final _MissionFilter filter;
  final _PriorityFilter priorityFilter;
  final String? filterCategoryId;
  final AppState appState;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<_MissionFilter> onFilterChanged;
  final ValueChanged<_PriorityFilter> onPriorityChanged;
  final ValueChanged<String?> onCategoryChanged;
  final Map<_MissionFilter, String> filterLabels;
  final Map<_PriorityFilter, String> priorityLabels;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.sp16),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: AppTheme.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: 'Search missions, notes, tags...',
              prefixIcon: Icon(Icons.search,
                  color: AppTheme.textMuted, size: 20),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close,
                          color: AppTheme.textMuted, size: 18),
                      onPressed: () {
                        controller.clear();
                        onQueryChanged('');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => onQueryChanged(v.trim()),
          ),
          const SizedBox(height: AppTheme.sp12),

          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _MissionFilter.values.map((f) {
                final selected = filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filterLabels[f]!),
                    selected: selected,
                    selectedColor: AppTheme.accent,
                    backgroundColor:
                        AppTheme.surfaceStrong.withValues(alpha: 0.3),
                    labelStyle: AppTheme.captionStyle.copyWith(
                      color: selected
                          ? const Color(0xFF0F172A)
                          : AppTheme.text,
                      fontWeight: selected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                    onSelected: (val) {
                      if (val) onFilterChanged(f);
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Priority filter chips
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Priority:',
                  style: AppTheme.captionStyle.copyWith(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                ..._PriorityFilter.values.map((p) {
                  final selected = priorityFilter == p;
                  final Color chipColor;
                  switch (p) {
                    case _PriorityFilter.high:
                      chipColor = AppTheme.danger;
                      break;
                    case _PriorityFilter.medium:
                      chipColor = AppTheme.warning;
                      break;
                    case _PriorityFilter.low:
                      chipColor = AppTheme.success;
                      break;
                    case _PriorityFilter.all:
                      chipColor = AppTheme.accent;
                      break;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(priorityLabels[p]!),
                      selected: selected,
                      selectedColor: chipColor,
                      backgroundColor:
                          AppTheme.surfaceStrong.withValues(alpha: 0.3),
                      labelStyle: AppTheme.captionStyle.copyWith(
                        color: selected
                            ? (p == _PriorityFilter.all
                                ? const Color(0xFF0F172A)
                                : Colors.white)
                            : AppTheme.text,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                      onSelected: (val) {
                        if (val) onPriorityChanged(p);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          // Category chips (if any)
          if (appState.categories.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(color: Color(0x1A94A3B8)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: filterCategoryId == null,
                    selectedColor: AppTheme.accent,
                    backgroundColor:
                        AppTheme.surfaceStrong.withValues(alpha: 0.3),
                    labelStyle: AppTheme.captionStyle.copyWith(
                      color: filterCategoryId == null
                          ? const Color(0xFF0F172A)
                          : AppTheme.text,
                    ),
                    onSelected: (val) {
                      if (val) onCategoryChanged(null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ...appState.categories.map((cat) {
                    final sel = filterCategoryId == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat.name),
                        selected: sel,
                        selectedColor: Color(cat.colorValue),
                        backgroundColor: AppTheme.surfaceStrong
                            .withValues(alpha: 0.3),
                        labelStyle: AppTheme.captionStyle.copyWith(
                          color: sel ? Colors.white : AppTheme.text,
                        ),
                        onSelected: (val) {
                          if (val) onCategoryChanged(cat.id);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
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
            style:
                AppTheme.subtitleStyle.copyWith(color: AppTheme.text),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: AppTheme.captionStyle
                .copyWith(color: AppTheme.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── New Mission Sheet ─────────────────────────────────────────────────────────

/// Bottom sheet to create a new mission (TargetItem) from scratch.
class _NewMissionSheet extends StatefulWidget {
  const _NewMissionSheet();

  @override
  State<_NewMissionSheet> createState() => _NewMissionSheetState();
}

class _NewMissionSheetState extends State<_NewMissionSheet> {
  final _titleController = TextEditingController();
  int _stepCount = 10;
  String _priority = 'medium';
  String? _categoryId;
  DateTime? _dueDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _createMission(AppState appState) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    setState(() => _isSaving = true);
    appState.addTarget(
      title,
      _stepCount,
      priority: _priority,
      categoryId: _categoryId,
      dueDate: _dueDate,
    );
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        return Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          decoration: BoxDecoration(
            color: AppTheme.bg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
                color: AppTheme.border.withValues(alpha: 0.15),
                width: 1.5),
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

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.add_task_rounded,
                          color: AppTheme.accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Mission',
                          style: AppTheme.titleStyle
                              .copyWith(color: AppTheme.text),
                        ),
                        Text(
                          'Define your next execution target',
                          style: AppTheme.captionStyle
                              .copyWith(color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Mission title
                const _Label('Mission Title'),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  autofocus: true,
                  style: AppTheme.bodyStyle.copyWith(color: AppTheme.text),
                  decoration: const InputDecoration(
                    hintText: 'What are you trying to accomplish?',
                  ),
                  onSubmitted: (_) => _createMission(appState),
                ),
                const SizedBox(height: 20),

                // Step count
                const _Label('Target Steps'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StepperButton(
                      icon: Icons.remove_rounded,
                      onTap: () {
                        if (_stepCount > 1) {
                          setState(() => _stepCount--);
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '$_stepCount',
                      style: AppTheme.headingStyle
                          .copyWith(color: AppTheme.text, fontSize: 24),
                    ),
                    const SizedBox(width: 16),
                    _StepperButton(
                      icon: Icons.add_rounded,
                      onTap: () => setState(() => _stepCount++),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'steps to complete',
                      style: AppTheme.captionStyle
                          .copyWith(color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Priority
                const _Label('Priority'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _PriorityCard(
                      label: 'Low',
                      value: 'low',
                      color: AppTheme.success,
                      selected: _priority == 'low',
                      onTap: () => setState(() => _priority = 'low'),
                    ),
                    const SizedBox(width: 8),
                    _PriorityCard(
                      label: 'Medium',
                      value: 'medium',
                      color: AppTheme.warning,
                      selected: _priority == 'medium',
                      onTap: () =>
                          setState(() => _priority = 'medium'),
                    ),
                    const SizedBox(width: 8),
                    _PriorityCard(
                      label: 'High',
                      value: 'high',
                      color: AppTheme.danger,
                      selected: _priority == 'high',
                      onTap: () => setState(() => _priority = 'high'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Category (optional)
                if (appState.categories.isNotEmpty) ...[
                  const _Label('Category (optional)'),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _CategoryChip(
                          label: 'None',
                          color: AppTheme.textMuted,
                          selected: _categoryId == null,
                          onTap: () =>
                              setState(() => _categoryId = null),
                        ),
                        const SizedBox(width: 8),
                        ...appState.categories.map((cat) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _CategoryChip(
                              label: cat.name,
                              color: Color(cat.colorValue),
                              selected: _categoryId == cat.id,
                              onTap: () =>
                                  setState(() => _categoryId = cat.id),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Due date (optional)
                const _Label('Due Date (optional)'),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now()
                          .add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 365)),
                      builder: (ctx, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: AppTheme.accent,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() => _dueDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceStrong
                          .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppTheme.border
                              .withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            color: AppTheme.textMuted, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          _dueDate == null
                              ? 'Pick a deadline...'
                              : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                          style: AppTheme.bodyStyle.copyWith(
                            color: _dueDate == null
                                ? AppTheme.textMuted
                                : AppTheme.text,
                          ),
                        ),
                        const Spacer(),
                        if (_dueDate != null)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _dueDate = null),
                            child: Icon(Icons.close_rounded,
                                color: AppTheme.textMuted, size: 16),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Create button
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
                    onPressed: _isSaving
                        ? null
                        : () => _createMission(appState),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF030712))),
                          )
                        : const Text(
                            'Create Mission',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── New Mission Sheet helpers ─────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTheme.captionStyle.copyWith(
          color: AppTheme.textMuted,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      );
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.surfaceStrong.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: AppTheme.text, size: 20),
      ),
    );
  }
}

class _PriorityCard extends StatelessWidget {
  const _PriorityCard({
    required this.label,
    required this.value,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String value;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : AppTheme.surfaceStrong.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? color
                  : AppTheme.border.withValues(alpha: 0.15),
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTheme.captionStyle.copyWith(
                  color: selected ? color : AppTheme.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : AppTheme.surfaceStrong.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? color
                : AppTheme.border.withValues(alpha: 0.15),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.captionStyle.copyWith(
            color: selected ? color : AppTheme.textMuted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
