import 'package:flutter/material.dart';

class RichTextToolbar extends StatelessWidget {
  final double fontSize;
  final ValueChanged<double> onFontSizeChanged;
  final VoidCallback onToggleBold;
  final VoidCallback onToggleItalic;
  final VoidCallback onToggleBullet;
  final ValueChanged<TextAlign> onAlignmentChanged;
  final VoidCallback onAddTextBox;
  final VoidCallback onAddImage;

  const RichTextToolbar({
    super.key,
    required this.fontSize,
    required this.onFontSizeChanged,
    required this.onToggleBold,
    required this.onToggleItalic,
    required this.onToggleBullet,
    required this.onAlignmentChanged,
    required this.onAddTextBox,
    required this.onAddImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.zoom_out, size: 20),
              tooltip: 'Reducir Fuente',
              onPressed: () => onFontSizeChanged((fontSize - 2).clamp(10, 36)),
            ),
            Text('${fontSize.toInt()} px', style: const TextStyle(fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.zoom_in, size: 20),
              tooltip: 'Aumentar Fuente',
              onPressed: () => onFontSizeChanged((fontSize + 2).clamp(10, 36)),
            ),
            const VerticalDivider(),
            IconButton(
              icon: const Icon(Icons.format_bold),
              tooltip: 'Negrita',
              onPressed: onToggleBold,
            ),
            IconButton(
              icon: const Icon(Icons.format_italic),
              tooltip: 'Cursiva',
              onPressed: onToggleItalic,
            ),
            IconButton(
              icon: const Icon(Icons.format_list_bulleted),
              tooltip: 'Viñetas',
              onPressed: onToggleBullet,
            ),
            const VerticalDivider(),
            IconButton(
              icon: const Icon(Icons.format_align_left),
              onPressed: () => onAlignmentChanged(TextAlign.left),
            ),
            IconButton(
              icon: const Icon(Icons.format_align_center),
              onPressed: () => onAlignmentChanged(TextAlign.center),
            ),
            IconButton(
              icon: const Icon(Icons.format_align_right),
              onPressed: () => onAlignmentChanged(TextAlign.right),
            ),
            const VerticalDivider(),
            ActionChip(
              avatar: const Icon(Icons.text_fields, size: 18),
              label: const Text('Cuadro Texto'),
              onPressed: onAddTextBox,
            ),
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.image, size: 18),
              label: const Text('Imagen'),
              onPressed: onAddImage,
            ),
          ],
        ),
      ),
    );
  }
}