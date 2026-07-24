import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_theme.dart';
import '../models/target_item.dart';
import '../providers/app_state.dart';
import '../models/category_item.dart';
import '../models/mission_behavior_analysis.dart';
import '../providers/behavior_provider.dart';
import 'highlight_text.dart';
import 'mission_setup_sheet.dart';


class TargetCard extends StatefulWidget {
  const TargetCard({super.key, required this.item, this.searchQuery = ''});

  final TargetItem item;
  final String searchQuery;

  @override
  State<TargetCard> createState() => _TargetCardState();
}

class _TargetCardState extends State<TargetCard> {
  bool _notesExpanded = false;

  Future<void> _launchUrl(String urlString) async {
    try {
      final uri = Uri.tryParse(urlString);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch $urlString: $e');
    }
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    showMenu(

      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx + 1, position.dy + 1),
      color: AppTheme.surface,
      items: [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: AppTheme.warning, size: 18),
              const SizedBox(width: 10),
              Text('Edit', style: TextStyle(color: AppTheme.text)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy, color: AppTheme.accent, size: 18),
              const SizedBox(width: 10),
              Text('Duplicate', style: TextStyle(color: AppTheme.text)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'archive',
          child: Row(
            children: [
              Icon(Icons.archive, color: AppTheme.feature, size: 18),
              const SizedBox(width: 10),
              Text('Archive', style: TextStyle(color: AppTheme.text)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: AppTheme.danger, size: 18),
              const SizedBox(width: 10),
              Text('Delete', style: TextStyle(color: AppTheme.text)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'properties',
          child: Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.textMuted, size: 18),
              const SizedBox(width: 10),
              Text('Properties', style: TextStyle(color: AppTheme.text)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      if (!context.mounted) return;
      switch (value) {
        case 'edit':

          _editTarget(context, appState);
          break;
        case 'duplicate':
          appState.duplicateTarget(widget.item.id);
          break;
        case 'archive':
          appState.archiveTarget(widget.item.id);
          break;
        case 'delete':
          appState.deleteTarget(widget.item.id);
          break;
        case 'properties':
          _showPropertiesDialog(context);
          break;
      }
    });
  }

  void _showPropertiesDialog(BuildContext context) {
    final cat = Provider.of<AppState>(context, listen: false)
        .categories
        .cast<CategoryItem?>()
        .firstWhere((c) => c?.id == widget.item.categoryId, orElse: () => null);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Row(
          children: [
            Icon(Icons.info, color: AppTheme.accent),
            const SizedBox(width: 10),
            const Text('Target Properties'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _propRow('Title', widget.item.title),
            _propRow('ID', widget.item.id),
            _propRow('Priority', widget.item.priority.toUpperCase()),
            _propRow('Category', cat?.name ?? 'Uncategorized'),
            _propRow('Problems', '${widget.item.solvedCount} / ${widget.item.targetCount}'),
            _propRow('Tags', widget.item.tags.isEmpty ? 'None' : widget.item.tags.join(', ')),
            _propRow('Links Attached', '${widget.item.links.length}'),
            _propRow('Has Notes', widget.item.notes.isEmpty ? 'No' : 'Yes (${widget.item.notes.length} chars)'),
            _propRow('Focused', widget.item.isFocused ? 'Yes' : 'No'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _propRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: AppTheme.text, fontSize: 14),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value, style: TextStyle(color: AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final animsOn = appState.animationsOn;
    
    // Find category
    final category = appState.categories
        .cast<CategoryItem?>()
        .firstWhere((c) => c?.id == widget.item.categoryId, orElse: () => null);

    final boxes = List<Widget>.generate(
      widget.item.targetCount,
      (index) {
        final isSolved = index + 1 <= widget.item.solvedCount;
        return GestureDetector(
          onTap: () async {
            final nextSolved = widget.item.solvedCount == index + 1 ? index : index + 1;
            await appState.setSolved(widget.item.id, nextSolved);
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: animsOn ? 180 : 0),
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 10, bottom: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSolved ? null : AppTheme.surfaceStrong.withValues(alpha: 0.4),
              gradient: isSolved ? const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF22D3EE)]) : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
            ),
            child: Text('${index + 1}', style: TextStyle(color: isSolved ? const Color(0xFF030712) : AppTheme.text, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );

    // Priority color mapping
    Color priorityColor = AppTheme.textMuted;
    if (widget.item.priority == 'high') priorityColor = AppTheme.danger;
    if (widget.item.priority == 'medium') priorityColor = AppTheme.warning;
    if (widget.item.priority == 'low') priorityColor = AppTheme.success;

    return GestureDetector(
      onSecondaryTapUp: (details) {
        if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          _showContextMenu(context, details.globalPosition);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: widget.item.isFocused ? AppTheme.accent : AppTheme.border.withValues(alpha: 0.2), width: widget.item.isFocused ? 2 : 1),
          boxShadow: [
            if (widget.item.isFocused)
              BoxShadow(color: AppTheme.accent.withValues(alpha: 0.15), blurRadius: 15, spreadRadius: 1)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badges row
                      Row(
                        children: [
                          // Priority badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              widget.item.priority.toUpperCase(),
                              style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Category badge
                          if (category != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(category.colorValue).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Color(category.colorValue).withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                category.name,
                                style: TextStyle(color: Color(category.colorValue), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          // Mission Health badge
                          Consumer<BehaviorProvider>(
                            builder: (context, behavior, _) {
                              final analysis = behavior.getHealthForTarget(widget.item.id);
                              if (analysis == null) return const SizedBox.shrink();
                              final status = analysis.healthStatus;
                              return Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: status.color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: status.color.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(status.icon, size: 10, color: status.color),
                                      const SizedBox(width: 4),
                                      Text(
                                        status.displayName,
                                        style: TextStyle(
                                          color: status.color,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
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
                      const SizedBox(height: 8),
                      buildHighlightedText(
                        widget.item.title,
                        widget.searchQuery,
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.text),
                      ),
                      const SizedBox(height: 4),
                      Text('Target: ${widget.item.targetCount} problems', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(_dueDateText(widget.item.dueDate), style: TextStyle(color: _dueDateColor(widget.item.dueDate), fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceStrong.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border.withValues(alpha: 0.2)),
                  ),
                  child: Text('${widget.item.solvedCount}/${widget.item.targetCount}', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
            
            // Tags view
            if (widget.item.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.item.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceStrong.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border.withValues(alpha: 0.1)),
                    ),
                    child: buildHighlightedText(
                      '#$tag',
                      widget.searchQuery,
                      TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16),
            Wrap(children: boxes),
            const SizedBox(height: 16),

            // Animated progress bar
            TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: animsOn ? 450 : 0),
              curve: Curves.easeInOut,
              tween: Tween<double>(
                begin: 0,
                end: widget.item.targetCount == 0
                    ? 0
                    : widget.item.solvedCount / widget.item.targetCount,
              ),
              builder: (context, progress, _) {
                final pct = (progress * 100).toStringAsFixed(1);
                final barColor = progress >= 1.0 ? AppTheme.success : AppTheme.accent;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${widget.item.solvedCount} / ${widget.item.targetCount} solved',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '$pct%',
                          style: TextStyle(
                            color: barColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 7,
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppTheme.surfaceStrong.withValues(alpha: 0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Notes Section
            if (widget.item.notes.isNotEmpty) ...[
              const SizedBox(height: 14),
              InkWell(
                onTap: () => setState(() => _notesExpanded = !_notesExpanded),
                child: Row(
                  children: [
                    Icon(_notesExpanded ? Icons.expand_less : Icons.expand_more, size: 16, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text('Notes', style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceStrong.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    widget.item.notes,
                    style: TextStyle(color: AppTheme.text, fontSize: 13, height: 1.4),
                  ),
                ),
                crossFadeState: _notesExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: Duration(milliseconds: animsOn ? 250 : 0),
              ),
            ],

            // Links Section
            if (widget.item.links.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.item.links.map((link) {
                  return ActionChip(
                    backgroundColor: AppTheme.surfaceStrong.withValues(alpha: 0.3),
                    side: BorderSide(color: AppTheme.border.withValues(alpha: 0.15)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    avatar: Icon(Icons.link, size: 14, color: AppTheme.accent),
                    label: Text(link.title, style: TextStyle(color: AppTheme.text, fontSize: 12)),
                    onPressed: () => _launchUrl(link.url),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16),
            Builder(
              builder: (ctx) {
                final isMissionActive = appState.activeMission != null;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _actionButton('Edit', AppTheme.warning, isMissionActive ? null : () async => _editTarget(context, appState)),
                    _actionButton('-', AppTheme.text, isMissionActive ? null : () async => appState.decrementTarget(widget.item.id)),
                    _actionButton('+', AppTheme.text, isMissionActive ? null : () async => appState.incrementTarget(widget.item.id)),
                    _actionButton('Reset', AppTheme.text, isMissionActive ? null : () async => appState.resetTarget(widget.item.id)),
                    _actionButton('Archive', AppTheme.feature, isMissionActive ? null : () async => appState.archiveTarget(widget.item.id)),
                    _actionButton('Delete', AppTheme.danger, isMissionActive ? null : () async => appState.deleteTarget(widget.item.id)),
                    _actionButton('Focus', AppTheme.accent, isMissionActive ? null : () async => appState.focusTarget(widget.item.id)),
                    _missionActionButton(
                      'Start Mission',
                      AppTheme.accent,
                      (isMissionActive || widget.item.solvedCount >= widget.item.targetCount)
                          ? null
                          : () => _startMissionSetup(context, appState),
                    ),
                  ],
                );
              }
            ),

          ],
        ),
      ),
    );
  }

  Future<void> _editTarget(BuildContext context, AppState appState) async {
    final titleController = TextEditingController(text: widget.item.title);
    final countController = TextEditingController(text: widget.item.targetCount.toString());
    final notesController = TextEditingController(text: widget.item.notes);
    final tagsController = TextEditingController(text: widget.item.tags.join(', '));
    
    DateTime? selectedDueDate = widget.item.dueDate;
    String selectedPriority = widget.item.priority;
    String? selectedCategoryId = widget.item.categoryId;
    
    // Manage links locally in state
    List<TargetLink> localLinks = List.from(widget.item.links);

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Edit Target'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                  const SizedBox(height: 12),
                  TextField(controller: countController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target count')),
                  const SizedBox(height: 12),
                   DropdownButtonFormField<String>(
                    initialValue: selectedPriority,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: const [
                      DropdownMenuItem(value: 'high', child: Text('🔴 High')),
                      DropdownMenuItem(value: 'medium', child: Text('🟡 Medium')),
                      DropdownMenuItem(value: 'low', child: Text('🟢 Low')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedPriority = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (appState.categories.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategoryId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        const DropdownMenuItem<String>(value: null, child: Text('None')),
                        ...appState.categories.map((c) => DropdownMenuItem<String>(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (val) {
                        setDialogState(() => selectedCategoryId = val);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],


                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: selectedDueDate == null ? AppTheme.text : AppTheme.accent,
                      side: BorderSide(color: AppTheme.border.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: selectedDueDate ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDueDate = picked);
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: selectedDueDate == null ? AppTheme.textMuted : AppTheme.accent),
                        const SizedBox(width: 8),
                        Text(selectedDueDate == null ? 'Set Due Date' : _formatDate(selectedDueDate!)),
                      ],
                    ),
                  ),
                  if (selectedDueDate != null)
                    TextButton(
                      onPressed: () => setDialogState(() => selectedDueDate = null),
                      child: Text('Remove due date', style: TextStyle(color: AppTheme.danger)),
                    ),

                  const SizedBox(height: 12),
                  TextField(
                    controller: tagsController,
                    decoration: const InputDecoration(
                      labelText: 'Tags (separated by commas)',
                      hintText: 'Flutter, AI, DSA',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Links Builder in Edit Dialog
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Attached Links', style: TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: Icon(Icons.add_link, color: AppTheme.accent),
                        onPressed: () async {
                          final linkTitleController = TextEditingController();
                          final linkUrlController = TextEditingController();
                          await showDialog(
                            context: ctx,
                            builder: (linkCtx) => AlertDialog(
                              backgroundColor: const Color(0xFF0F172A),
                              title: const Text('Add Link'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(controller: linkTitleController, decoration: const InputDecoration(labelText: 'Link Title')),
                                  const SizedBox(height: 12),
                                  TextField(controller: linkUrlController, decoration: const InputDecoration(labelText: 'URL')),
                                ],
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(linkCtx), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    final t = linkTitleController.text.trim();
                                    final u = linkUrlController.text.trim();
                                    if (t.isNotEmpty && u.isNotEmpty) {
                                      setDialogState(() {
                                        localLinks.add(TargetLink(title: t, url: u));
                                      });
                                    }
                                    Navigator.pop(linkCtx);
                                  },
                                  child: const Text('Add'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  ...localLinks.map((l) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(l.title, overflow: TextOverflow.ellipsis)),
                        IconButton(
                          icon: Icon(Icons.delete, color: AppTheme.danger, size: 16),
                          onPressed: () {
                            setDialogState(() {
                              localLinks.remove(l);
                            });
                          },
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final count = int.tryParse(countController.text) ?? widget.item.targetCount;
                if (title.isEmpty) return;
                
                // Parse tags
                final tags = tagsController.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                await appState.updateTarget(
                  widget.item.id,
                  title,
                  count,
                  dueDate: selectedDueDate,
                  priority: selectedPriority,
                  notes: notesController.text.trim(),
                  tags: tags,
                  categoryId: selectedCategoryId,
                  links: localLinks,
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
              },

              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _dueDateText(DateTime? dueDate) {
    if (dueDate == null) return 'Due: No due date';
    final days = _remainingDays(dueDate);
    final remainingText = days < 0
        ? 'overdue by ${days.abs()} ${days == -1 ? 'day' : 'days'}'
        : days == 0
            ? 'due today'
            : '$days ${days == 1 ? 'day' : 'days'} left';
    return 'Due: ${_formatDate(dueDate)} • $remainingText';
  }

  Color _dueDateColor(DateTime? dueDate) {
    if (dueDate == null) return AppTheme.textMuted;
    final days = _remainingDays(dueDate);
    if (days < 0) return AppTheme.danger;
    if (days > 7) return AppTheme.success;
    return AppTheme.warning;
  }

  int _remainingDays(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _actionButton(String text, Color color, VoidCallback? onPressed) {
    return SizedBox(
      width: 100,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.surfaceStrong.withValues(alpha: 0.4),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: AppTheme.border.withValues(alpha: 0.15)),
        ),
        child: Text(text),
      ),
    );
  }

  Widget _missionActionButton(String text, Color color, VoidCallback? onPressed) {
    return SizedBox(
      width: 140,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _startMissionSetup(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MissionSetupSheet(target: widget.item),
    );
  }
}


// ArchivedTargetCard
class ArchivedTargetCard extends StatelessWidget {
  const ArchivedTargetCard({super.key, required this.item, this.searchQuery = ''});

  final TargetItem item;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final progress = item.targetCount == 0 ? 0.0 : item.solvedCount / item.targetCount;
    final pct = (progress * 100).toStringAsFixed(1);
    final barColor = progress >= 1.0 ? AppTheme.success : AppTheme.textMuted;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: buildHighlightedText(
                            item.title,
                            searchQuery,
                            TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceStrong.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Archived',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Target: ${item.targetCount} problems', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceStrong.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border.withValues(alpha: 0.15)),
                ),
                child: Text('${item.solvedCount}/${item.targetCount}', style: TextStyle(color: barColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${item.solvedCount} / ${item.targetCount} solved', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
              Text('$pct%', style: TextStyle(color: barColor, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppTheme.surfaceStrong.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 100,
                child: ElevatedButton(
                  onPressed: () async => appState.restoreTarget(item.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceStrong.withValues(alpha: 0.4),
                    foregroundColor: AppTheme.accent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: AppTheme.border.withValues(alpha: 0.15)),
                  ),
                  child: const Text('Restore'),
                ),
              ),
              SizedBox(
                width: 100,
                child: ElevatedButton(
                  onPressed: () async => appState.deleteArchivedTarget(item.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceStrong.withValues(alpha: 0.4),
                    foregroundColor: AppTheme.danger,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: BorderSide(color: AppTheme.border.withValues(alpha: 0.15)),
                  ),
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
