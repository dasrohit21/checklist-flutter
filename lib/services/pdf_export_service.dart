import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/target_item.dart';
import '../models/checklist_item.dart';

class PdfExportService {
  static Future<void> exportReport({
    required List<TargetItem> targets,
    required List<TargetItem> archivedTargets,
    required List<ChecklistItem> checklistItems,
    required int streak,
  }) async {
    final pdf = pw.Document();

    final activeCount = targets.length;
    final archivedCount = archivedTargets.length;
    final solvedCount = [...targets, ...archivedTargets].fold(0, (sum, t) => sum + t.solvedCount);
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Title Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Problem Target Checklist Report',
                    style: const pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Text(
                    DateTime.now().toIso8601String().substring(0, 10),
                    style: const pw.TextStyle(color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Statistics Summary
            pw.Text('Summary Statistics', style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Metric', 'Value'],
              data: [
                ['Active Targets', '$activeCount'],
                ['Archived Targets', '$archivedCount'],
                ['Total Problems Solved', '$solvedCount'],
                ['Current Daily Streak', '$streak days'],
              ],
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 20),

            // Active Targets Section
            pw.Text('Active Targets', style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
            pw.SizedBox(height: 8),
            if (targets.isEmpty)
              pw.Text('No active targets.', style: const pw.TextStyle(fontStyle: pw.FontStyle.italic))
            else
              ...targets.map((target) {
                final pct = target.targetCount == 0 ? 0.0 : (target.solvedCount / target.targetCount) * 100;
                final status = target.solvedCount >= target.targetCount ? 'Completed' : 'In Progress';
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            target.title,
                            style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            '$status (${pct.toStringAsFixed(1)}%)',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: target.solvedCount >= target.targetCount ? PdfColors.green900 : PdfColors.amber900,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Solved: ${target.solvedCount} / ${target.targetCount} problems',
                        style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
                      ),
                      if (target.dueDate != null)
                        pw.Text(
                          'Due Date: ${target.dueDate!.toIso8601String().substring(0, 10)}',
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.red900),
                        ),
                      if (target.notes.isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text('Notes:', style: const pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text(target.notes, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ],
                  ),
                );
              }),
            pw.SizedBox(height: 20),

            // Checklist Items Section
            pw.Text('Checklist Items', style: const pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
            pw.SizedBox(height: 8),
            if (checklistItems.isEmpty)
              pw.Text('No checklist items.', style: const pw.TextStyle(fontStyle: pw.FontStyle.italic))
            else
              ...checklistItems.map((item) {
                final check = item.completed ? '[x]' : '[ ]';
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Text(
                    '$check (${item.type.toUpperCase()}) ${item.text}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: item.completed ? PdfColors.green800 : PdfColors.black,
                      decoration: item.completed ? pw.TextDecoration.lineThrough : null,
                    ),
                  ),
                );
              }),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'problem_target_checklist_report.pdf',
    );
  }
}
