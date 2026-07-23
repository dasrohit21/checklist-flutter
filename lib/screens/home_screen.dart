import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';


import '../core/theme/app_theme.dart';
import '../providers/app_state.dart';
import '../providers/theme_provider.dart';
import '../widgets/highlight_text.dart';
import '../widgets/target_card.dart';
import '../services/pdf_export_service.dart';
import 'calendar_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'mission_screen.dart';


enum TargetFilter { all, active, completed, archived, overdue }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Wrap HomeScreen in ThemeProvider so the whole screen reacts to theme switches
    return ChangeNotifierProvider<ThemeProvider>(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Theme(
            data: AppTheme.buildTheme(),
            child: Builder(
              builder: (context) {
                final appState = Provider.of<AppState>(context);
                if (appState.activeMission != null) {
                  return const MissionScreen();
                }
                
                final List<Widget> screens = [
                  const DashboardScreen(),
                  const HomeContent(),
                  const SettingsScreen(),
                ];


                final List<String> titles = [
                  'Dashboard',
                  'Problem Target Checklist',
                  'Settings',
                ];

                return Focus(
                  autofocus: true,
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent) {
                      final isControl = event.logicalKey == LogicalKeyboardKey.controlLeft ||
                                        event.logicalKey == LogicalKeyboardKey.controlRight ||
                                        HardwareKeyboard.instance.isControlPressed;

                      if (isControl && event.logicalKey == LogicalKeyboardKey.keyN) {
                        // Switch to targets tab and focus add target
                        setState(() => _currentIndex = 1);
                        return KeyEventResult.handled;
                      }
                      if (isControl && event.logicalKey == LogicalKeyboardKey.keyF) {
                        setState(() => _currentIndex = 1);
                        return KeyEventResult.handled;
                      }
                      if (isControl && event.logicalKey == LogicalKeyboardKey.keyS) {
                        // Backup to clipboard
                        appState.exportBackup().then((backup) {
                          Clipboard.setData(ClipboardData(text: backup));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Data backup copied to clipboard!')),
                          );
                        });

                        return KeyEventResult.handled;
                      }
                      if (event.logicalKey == LogicalKeyboardKey.escape) {
                        FocusScope.of(context).unfocus();
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Scaffold(
                    backgroundColor: AppTheme.bg,
                    appBar: AppBar(
                      backgroundColor: AppTheme.surface.withValues(alpha: 0.9),
                      elevation: 0,
                      title: Text(titles[_currentIndex], style: TextStyle(color: AppTheme.text, fontWeight: FontWeight.bold)),
                      centerTitle: true,
                      actions: [
                        IconButton(
                          icon: Icon(Icons.picture_as_pdf, color: AppTheme.accent),
                          tooltip: 'Export Report to PDF',
                          onPressed: () async {
                            await PdfExportService.exportReport(
                              targets: appState.targets,
                              archivedTargets: appState.archivedTargets,
                              checklistItems: appState.checklistItems,
                              streak: appState.currentStreak,
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.calendar_month, color: AppTheme.accent),
                          tooltip: 'Activity Calendar',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CalendarScreen()),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    body: AnimatedSwitcher(
                      duration: Duration(milliseconds: appState.animationsOn ? 300 : 0),
                      child: screens[_currentIndex],
                    ),
                    bottomNavigationBar: BottomNavigationBar(
                      currentIndex: _currentIndex,
                      backgroundColor: AppTheme.surface,
                      selectedItemColor: AppTheme.accent,
                      unselectedItemColor: AppTheme.textMuted,
                      selectedFontSize: 13,
                      unselectedFontSize: 12,
                      elevation: 8,
                      type: BottomNavigationBarType.fixed,
                      onTap: (index) => setState(() => _currentIndex = index),
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.dashboard_outlined),
                          activeIcon: Icon(Icons.dashboard),
                          label: 'Dashboard',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.check_box_outlined),
                          activeIcon: Icon(Icons.check_box),
                          label: 'Targets',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.settings_outlined),
                          activeIcon: Icon(Icons.settings),
                          label: 'Settings',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ── HomeContent Widget ────────────────────────────────────────────────────────
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final _titleController = TextEditingController();
  final _countController = TextEditingController(text: '5');
  final _notesController = TextEditingController();
  final _tagsController = TextEditingController();
  final _checkTextController = TextEditingController();
  
  String _checkType = 'task';
  DateTime? _dueDate;
  String _selectedPriority = 'medium';
  String? _selectedCategoryId;
  
  // Search
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _searchQuery = '';
  TargetFilter _selectedFilter = TargetFilter.all;
  String? _filterCategoryId; // filter by specific category ID

  @override
  void dispose() {
    _titleController.dispose();
    _countController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    _checkTextController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showActive = _selectedFilter != TargetFilter.archived;
    final showArchived = _selectedFilter == TargetFilter.all || _selectedFilter == TargetFilter.archived;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Search & Filters row
              _buildSearchFilterCard(),
              const SizedBox(height: 18),

              // Checklist Section
              if (showActive) ...[
                _buildChecklistCard(),
                const SizedBox(height: 18),
                _buildNewTargetCard(),
                const SizedBox(height: 18),
                _buildTargetsCard(),
              ],

              if (showArchived) ...[
                const SizedBox(height: 18),
                _buildArchivedCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.2), width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 40, offset: Offset(0, 15)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSearchFilterCard() {
    final appState = Provider.of<AppState>(context);
    const filterLabels = {
      TargetFilter.all: 'All',
      TargetFilter.active: 'Active',
      TargetFilter.completed: 'Completed',
      TargetFilter.archived: 'Archived',
      TargetFilter.overdue: 'Overdue',
    };

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: InputDecoration(
              hintText: 'Search targets, notes, tags or checklist...',
              prefixIcon: Icon(Icons.search, color: AppTheme.textMuted, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close, color: AppTheme.textMuted, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
          ),
          const SizedBox(height: 14),

          // Filters view
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TargetFilter.values.map((f) {
                final selected = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filterLabels[f]!),
                    selected: selected,
                    selectedColor: AppTheme.accent,
                    backgroundColor: AppTheme.surfaceStrong.withValues(alpha: 0.3),
                    labelStyle: TextStyle(
                      color: selected ? const Color(0xFF0F172A) : AppTheme.text,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _selectedFilter = f);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          
          if (appState.categories.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0x1A94A3B8)),
            const SizedBox(height: 8),
            // Category filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Categories'),
                    selected: _filterCategoryId == null,
                    selectedColor: AppTheme.accent,
                    backgroundColor: AppTheme.surfaceStrong.withValues(alpha: 0.3),
                    labelStyle: TextStyle(
                      color: _filterCategoryId == null ? const Color(0xFF0F172A) : AppTheme.text,
                      fontWeight: _filterCategoryId == null ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _filterCategoryId = null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ...appState.categories.map((cat) {
                    final isSelected = _filterCategoryId == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        selectedColor: Color(cat.colorValue),
                        backgroundColor: AppTheme.surfaceStrong.withValues(alpha: 0.3),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.text,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (val) {
                          if (val) setState(() => _filterCategoryId = cat.id);
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

  Widget _buildChecklistCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Checklist', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Manage small tasks alongside your targets.', style: TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 640;
              return Column(
                children: [
                  if (wide)
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _checkTextController,
                            decoration: const InputDecoration(hintText: 'Enter task...'),
                            onSubmitted: (_) => _addChecklistItem(),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _checkType,
                            decoration: const InputDecoration(),
                            items: const [
                              DropdownMenuItem(value: 'task', child: Text('Task')),
                              DropdownMenuItem(value: 'bug', child: Text('Bug fix')),
                              DropdownMenuItem(value: 'feature', child: Text('Feature')),
                              DropdownMenuItem(value: 'study', child: Text('Study')),
                            ],
                            onChanged: (val) => setState(() => _checkType = val ?? 'task'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: const Color(0xFF0F172A),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _addChecklistItem,
                          child: const Text('Add Item'),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        TextField(
                          controller: _checkTextController,
                          decoration: const InputDecoration(hintText: 'Enter task...'),
                          onSubmitted: (_) => _addChecklistItem(),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _checkType,
                          decoration: const InputDecoration(),
                          items: const [
                            DropdownMenuItem(value: 'task', child: Text('Task')),
                            DropdownMenuItem(value: 'bug', child: Text('Bug fix')),
                            DropdownMenuItem(value: 'feature', child: Text('Feature')),
                            DropdownMenuItem(value: 'study', child: Text('Study')),
                          ],
                          onChanged: (val) => setState(() => _checkType = val ?? 'task'),
                        ),

                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent,
                              foregroundColor: const Color(0xFF0F172A),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _addChecklistItem,
                            child: const Text('Add Item'),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 18),
                  Consumer<AppState>(
                    builder: (context, appState, _) {
                      final query = _searchQuery.toLowerCase();
                      final items = query.isEmpty
                          ? appState.checklistItems
                          : appState.checklistItems.where((i) => i.text.toLowerCase().contains(query)).toList();

                      if (items.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              _searchQuery.isNotEmpty ? 'No matches found.' : 'No checklist items yet.',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: items.map((i) => _buildChecklistRow(i)).toList(),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistRow(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceStrong.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: AppTheme.typeColor(item.type), width: 5)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: item.completed,
            activeColor: AppTheme.accent,
            onChanged: (val) async {
              await Provider.of<AppState>(context, listen: false).toggleChecklistItem(item.id);
            },
          ),
          Expanded(
            child: buildHighlightedText(
              item.text,
              _searchQuery,
              TextStyle(color: AppTheme.text, fontSize: 16, decoration: item.completed ? TextDecoration.lineThrough : null),
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => _editChecklistItem(item),
                child: Text('Edit', style: TextStyle(color: AppTheme.warning)),
              ),
              TextButton(
                onPressed: () => Provider.of<AppState>(context, listen: false).deleteChecklistItem(item.id),
                child: Text('Delete', style: TextStyle(color: AppTheme.danger)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewTargetCard() {
    final appState = Provider.of<AppState>(context);
    
    // Set default category
    if (_selectedCategoryId == null && appState.categories.isNotEmpty) {
      _selectedCategoryId = appState.defaultCategoryId;
    }

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Target', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Enter details to create an interactive learning or problem checklist target.', style: TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 768;
              return Wrap(
                runSpacing: 14,
                spacing: 14,
                children: [
                  SizedBox(
                    width: wide ? 320 : double.infinity,
                    child: TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(hintText: 'Enter title...'),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _countController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Count'),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedPriority,
                      isExpanded: true,
                      decoration: const InputDecoration(),
                      items: const [
                        DropdownMenuItem(value: 'high', child: Text('🔴 High')),
                        DropdownMenuItem(value: 'medium', child: Text('🟡 Medium')),
                        DropdownMenuItem(value: 'low', child: Text('🟢 Low')),
                      ],
                      onChanged: (val) => setState(() => _selectedPriority = val ?? 'medium'),
                    ),
                  ),
                  if (appState.categories.isNotEmpty)
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategoryId,
                        isExpanded: true,
                        decoration: const InputDecoration(hintText: 'Category'),
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('None')),
                          ...appState.categories.map((c) {
                            return DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(c.name),
                            );
                          }),
                        ],
                        onChanged: (val) => setState(() => _selectedCategoryId = val),
                      ),
                    ),


                  SizedBox(
                    width: wide ? 150 : double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _dueDate == null ? AppTheme.text : AppTheme.accent,
                        side: BorderSide(color: AppTheme.border.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _pickDueDate,
                      child: Text(_dueDate == null ? 'Set Due Date' : _formatDate(_dueDate!)),
                    ),
                  ),
                  if (_dueDate != null)
                    SizedBox(
                      width: 100,
                      child: TextButton(
                        onPressed: () => setState(() => _dueDate = null),
                        child: Text('Remove', style: TextStyle(color: AppTheme.danger)),
                      ),
                    ),
                  const SizedBox(height: 8),
                  
                  // Expandable tags & notes in quick add
                  TextField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                      hintText: 'Tags (comma separated, e.g. Flutter, AI)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Enter notes/links info...',
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          foregroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _addTarget,
                        child: const Text('Create Target'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.text,
                          side: BorderSide(color: AppTheme.border.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => appState.resetAllTargets(),
                        child: const Text('Reset All'),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTargetsCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Targets', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              Consumer<AppState>(
                builder: (context, appState, _) {
                  return DropdownButton<SortOption>(
                    value: appState.sortOption,
                    underline: const SizedBox.shrink(),
                    dropdownColor: AppTheme.surface,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    icon: Icon(Icons.sort, color: AppTheme.textMuted, size: 18),
                    items: const [
                      DropdownMenuItem(value: SortOption.newest, child: Text('Newest')),
                      DropdownMenuItem(value: SortOption.oldest, child: Text('Oldest')),
                      DropdownMenuItem(value: SortOption.alphabetical, child: Text('A → Z')),
                      DropdownMenuItem(value: SortOption.deadline, child: Text('Deadline')),
                      DropdownMenuItem(value: SortOption.progress, child: Text('Progress')),
                      DropdownMenuItem(value: SortOption.priority, child: Text('Priority')),
                    ],
                    onChanged: (v) {
                      if (v != null) appState.setSortOption(v);
                    },
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Right-click any target to edit, duplicate, archive, delete, or inspect properties.', style: TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 18),
          Consumer<AppState>(
            builder: (context, appState, _) {
              final today = DateTime.now();
              final todayDate = DateTime(today.year, today.month, today.day);
              
              var items = appState.sortedTargets;

              // 1. Filter by categories
              if (_filterCategoryId != null) {
                items = items.where((t) => t.categoryId == _filterCategoryId).toList();
              }

              // 2. Filter by status filter
              switch (_selectedFilter) {
                case TargetFilter.active:
                  items = items.where((t) => t.solvedCount < t.targetCount).toList();
                  break;
                case TargetFilter.completed:
                  items = items.where((t) => t.targetCount > 0 && t.solvedCount >= t.targetCount).toList();
                  break;
                case TargetFilter.overdue:
                  items = items.where((t) {
                    if (t.dueDate == null) return false;
                    final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
                    return due.isBefore(todayDate) && t.solvedCount < t.targetCount;
                  }).toList();
                  break;
                case TargetFilter.all:
                case TargetFilter.archived:
                  break;
              }

              // 3. Search query (matches title, tags, or notes)
              if (_searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                items = items.where((t) {
                  final titleMatch = t.title.toLowerCase().contains(query);
                  final notesMatch = t.notes.toLowerCase().contains(query);
                  final tagsMatch = t.tags.any((tag) => tag.toLowerCase().contains(query));
                  return titleMatch || notesMatch || tagsMatch;
                }).toList();
              }

              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text('No matching targets found.', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                );
              }

              return Column(
                children: items.map((item) => TargetCard(item: item, searchQuery: _searchQuery)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildArchivedCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Archived Targets', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Targets archived for later reference.', style: TextStyle(color: AppTheme.textMuted)),
          const SizedBox(height: 18),
          Consumer<AppState>(
            builder: (context, appState, _) {
              var items = appState.archivedTargets.toList();

              // Filter by categories
              if (_filterCategoryId != null) {
                items = items.where((t) => t.categoryId == _filterCategoryId).toList();
              }

              // Apply Search
              if (_searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                items = items.where((t) {
                  final titleMatch = t.title.toLowerCase().contains(query);
                  final notesMatch = t.notes.toLowerCase().contains(query);
                  final tagsMatch = t.tags.any((tag) => tag.toLowerCase().contains(query));
                  return titleMatch || notesMatch || tagsMatch;
                }).toList();
              }

              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text('No archived targets found.', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                );
              }

              return Column(
                children: items.map((item) => ArchivedTargetCard(item: item, searchQuery: _searchQuery)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────────
  Future<void> _addChecklistItem() async {
    final text = _checkTextController.text.trim();
    if (text.isEmpty) return;
    await Provider.of<AppState>(context, listen: false).addChecklistItem(text, _checkType);
    _checkTextController.clear();
    if (!mounted) return;
    FocusScope.of(context).unfocus();
  }


  Future<void> _editChecklistItem(dynamic item) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final controller = TextEditingController(text: item.text);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Edit checklist item'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await appState.updateChecklistItem(item.id, result);
    }
  }

  Future<void> _addTarget() async {
    final title = _titleController.text.trim();
    final count = int.tryParse(_countController.text) ?? 5;
    if (title.isEmpty) return;

    final tags = _tagsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    await Provider.of<AppState>(context, listen: false).addTarget(
      title,
      count,
      dueDate: _dueDate,
      priority: _selectedPriority,
      notes: _notesController.text.trim(),
      tags: tags,
      categoryId: _selectedCategoryId,
    );

    _titleController.clear();
    _countController.text = '5';
    _notesController.clear();
    _tagsController.clear();
    setState(() {
      _dueDate = null;
    });
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
