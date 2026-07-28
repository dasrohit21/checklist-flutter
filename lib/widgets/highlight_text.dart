import 'package:flutter/material.dart';

/// A [StatelessWidget] that renders [text] with every occurrence of [query]
/// (case-insensitive) highlighted in the accent colour.
///
/// Falls back to a plain [Text] when [query] is empty or not found.
class HighlightText extends StatelessWidget {
  const HighlightText({
    super.key,
    required this.text,
    required this.query,
    required this.style,
  });

  final String text;
  final String query;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return buildHighlightedText(text, query, style);
  }
}

/// Returns a [Widget] with every occurrence of [query] (case-insensitive)
/// visually highlighted in the accent colour.
///
/// Falls back to a plain [Text] when [query] is empty or not found.
Widget buildHighlightedText(String text, String query, TextStyle style) {
  if (query.isEmpty) return Text(text, style: style);

  final lowerText  = text.toLowerCase();
  final lowerQuery = query.toLowerCase();

  if (!lowerText.contains(lowerQuery)) return Text(text, style: style);

  final spans = <TextSpan>[];
  int start = 0;

  while (start <= text.length) {
    final idx = lowerText.indexOf(lowerQuery, start);
    if (idx == -1) {
      if (start < text.length) {
        spans.add(TextSpan(text: text.substring(start), style: style));
      }
      break;
    }
    if (idx > start) {
      spans.add(TextSpan(text: text.substring(start, idx), style: style));
    }
    spans.add(TextSpan(
      text: text.substring(idx, idx + query.length),
      style: style.copyWith(
        // accent #38BDF8 at ~20 % opacity
        backgroundColor: const Color(0x3338BDF8),
        color: const Color(0xFF38BDF8),
        fontWeight: FontWeight.w700,
      ),
    ));
    start = idx + query.length;
  }

  return RichText(text: TextSpan(children: spans));
}
