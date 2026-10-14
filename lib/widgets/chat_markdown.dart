import 'package:flutter/material.dart';

/// Muestra texto con un subconjunto sencillo de Markdown, sin paquetes extra:
///   **negrita**, *cursiva*, `código`, listas con "- " / "* " / "1. " y títulos con "#".
/// Vive en lib/widgets/chat_markdown.dart
class ChatMarkdown extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Color codeBackground;

  const ChatMarkdown({
    super.key,
    required this.text,
    required this.style,
    required this.codeBackground,
  });

  static final RegExp _bulletRe = RegExp(r'^\s*[-*•]\s+(.*)$');
  static final RegExp _numberedRe = RegExp(r'^\s*(\d+)[.)]\s+(.*)$');
  static final RegExp _headingRe = RegExp(r'^\s*#{1,3}\s+(.*)$');
  static final RegExp _inlineRe =
      RegExp(r'(\*\*[^*]+\*\*|\*[^*\s][^*]*\*|`[^`]+`)');

  @override
  Widget build(BuildContext context) {
    final lines = text.replaceAll('\r\n', '\n').split('\n');
    final children = <Widget>[];

    for (final raw in lines) {
      final line = raw.trimRight();

      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 6));
        continue;
      }

      final heading = _headingRe.firstMatch(line);
      final bullet = _bulletRe.firstMatch(line);
      final numbered = _numberedRe.firstMatch(line);

      if (heading != null) {
        final headStyle = style.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: (style.fontSize ?? 14) + 1,
        );
        children.add(
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Text.rich(
              TextSpan(children: _inline(heading.group(1)!, headStyle)),
            ),
          ),
        );
      } else if (bullet != null) {
        children.add(_listRow('•', bullet.group(1)!, 14));
      } else if (numbered != null) {
        children.add(
            _listRow('${numbered.group(1)}.', numbered.group(2)!, 22));
      } else {
        children.add(Text.rich(TextSpan(children: _inline(line, style))));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _listRow(String marker, String content, double markerWidth) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2, left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: markerWidth, child: Text(marker, style: style)),
          Expanded(
            child: Text.rich(TextSpan(children: _inline(content, style))),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _inline(String input, TextStyle base) {
    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final m in _inlineRe.allMatches(input)) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: input.substring(cursor, m.start), style: base));
      }

      final token = m.group(0)!;
      if (token.startsWith('**')) {
        spans.add(TextSpan(
          text: token.substring(2, token.length - 2),
          style: base.copyWith(fontWeight: FontWeight.w700),
        ));
      } else if (token.startsWith('`')) {
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: base.copyWith(
            fontFamily: 'monospace',
            backgroundColor: codeBackground,
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: token.substring(1, token.length - 1),
          style: base.copyWith(fontStyle: FontStyle.italic),
        ));
      }
      cursor = m.end;
    }

    if (cursor < input.length) {
      spans.add(TextSpan(text: input.substring(cursor), style: base));
    }
    return spans;
  }
}
