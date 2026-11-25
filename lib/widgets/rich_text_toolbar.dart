import 'package:flutter/material.dart';
import 'a4_page_canvas.dart';

class RichTextToolbar extends StatelessWidget {
  final double fontSize;
  final ValueChanged<double> onFontSizeChanged;
  final bool isBold;
  final bool isItalic;
  final VoidCallback onToggleBold;
  final VoidCallback onToggleItalic;
  final VoidCallback onToggleBullet;
  final VoidCallback onToggleNumbered;
  final VoidCallback onToggleChecklist;
  final VoidCallback onInsertExamCallout;
  final VoidCallback onInsertCodeBlock;
  final ValueChanged<TextAlign> onAlignmentChanged;
  final TextAlign currentAlign;
  final PaperStyle currentPaperStyle;
  final ValueChanged<PaperStyle> onPaperStyleChanged;
  final VoidCallback onAddTextBox;
  final VoidCallback onAddImage;

  const RichTextToolbar({
    super.key,
    required this.fontSize,
    required this.onFontSizeChanged,
    this.isBold = false,
    this.isItalic = false,
    required this.onToggleBold,
    required this.onToggleItalic,
    required this.onToggleBullet,
    required this.onToggleNumbered,
    required this.onToggleChecklist,
    required this.onInsertExamCallout,
    required this.onInsertCodeBlock,
    required this.onAlignmentChanged,
    this.currentAlign = TextAlign.left,
    this.currentPaperStyle = PaperStyle.ruled,
    required this.onPaperStyleChanged,
    required this.onAddTextBox,
    required this.onAddImage,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = Theme.of(context).cardColor;

    return Container(
      color: barBg,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            // =================================================================
            // SELECTOR DE TAMAÑO DE FUENTE
            // =================================================================
            _buildIconButton(
              icon: Icons.remove,
              tooltip: 'Reducir tamaño',
              onPressed: () => onFontSizeChanged((fontSize - 2).clamp(12.0, 36.0)),
              colorScheme: colorScheme,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${fontSize.toInt()}pt',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            _buildIconButton(
              icon: Icons.add,
              tooltip: 'Aumentar tamaño',
              onPressed: () => onFontSizeChanged((fontSize + 2).clamp(12.0, 36.0)),
              colorScheme: colorScheme,
            ),

            _buildVerticalDivider(),

            // =================================================================
            // FORMATO BOLD & ITALIC
            // =================================================================
            _buildToggleBtn(
              icon: Icons.format_bold_rounded,
              tooltip: 'Negrita',
              isActive: isBold,
              onPressed: onToggleBold,
              colorScheme: colorScheme,
            ),
            _buildToggleBtn(
              icon: Icons.format_italic_rounded,
              tooltip: 'Cursiva',
              isActive: isItalic,
              onPressed: onToggleItalic,
              colorScheme: colorScheme,
            ),

            _buildVerticalDivider(),

            // =================================================================
            // ALINEACIÓN DE TEXTO
            // =================================================================
            _buildToggleBtn(
              icon: Icons.format_align_left_rounded,
              tooltip: 'Alinear a la izquierda',
              isActive: currentAlign == TextAlign.left,
              onPressed: () => onAlignmentChanged(TextAlign.left),
              colorScheme: colorScheme,
            ),
            _buildToggleBtn(
              icon: Icons.format_align_center_rounded,
              tooltip: 'Centrar texto',
              isActive: currentAlign == TextAlign.center,
              onPressed: () => onAlignmentChanged(TextAlign.center),
              colorScheme: colorScheme,
            ),
            _buildToggleBtn(
              icon: Icons.format_align_right_rounded,
              tooltip: 'Alinear a la derecha',
              isActive: currentAlign == TextAlign.right,
              onPressed: () => onAlignmentChanged(TextAlign.right),
              colorScheme: colorScheme,
            ),

            _buildVerticalDivider(),

            // =================================================================
            // LISTAS Y ESTRUCTURAS DE ESTUDIO
            // =================================================================
            _buildActionChip(
              icon: Icons.format_list_bulleted_rounded,
              label: 'Viñeta',
              onPressed: onToggleBullet,
              colorScheme: colorScheme,
            ),
            const SizedBox(width: 6),
            _buildActionChip(
              icon: Icons.format_list_numbered_rounded,
              label: '1. Lista',
              onPressed: onToggleNumbered,
              colorScheme: colorScheme,
            ),
            const SizedBox(width: 6),
            _buildActionChip(
              icon: Icons.check_box_outlined,
              label: 'Checklist',
              onPressed: onToggleChecklist,
              colorScheme: colorScheme,
            ),
            const SizedBox(width: 6),
            _buildActionChip(
              icon: Icons.lightbulb_rounded,
              label: 'Ojo Examen',
              iconColor: Colors.amber.shade800,
              onPressed: onInsertExamCallout,
              colorScheme: colorScheme,
            ),
            const SizedBox(width: 6),
            _buildActionChip(
              icon: Icons.code_rounded,
              label: 'Código',
              onPressed: onInsertCodeBlock,
              colorScheme: colorScheme,
            ),

            _buildVerticalDivider(),

            // =================================================================
            // NOTAS ADHESIVAS Y MULTIMEDIA
            // =================================================================
            _buildActionChip(
              icon: Icons.note_alt_rounded,
              label: '+ Post-It',
              iconColor: Colors.amber.shade700,
              onPressed: onAddTextBox,
              colorScheme: colorScheme,
            ),
            const SizedBox(width: 6),
            _buildActionChip(
              icon: Icons.add_photo_alternate_rounded,
              label: '+ Foto',
              iconColor: Colors.teal,
              onPressed: onAddImage,
              colorScheme: colorScheme,
            ),

            _buildVerticalDivider(),

            // =================================================================
            // TIPO DE PAPEL (MENU POPUP)
            // =================================================================
            PopupMenuButton<PaperStyle>(
              initialValue: currentPaperStyle,
              tooltip: 'Estilo de hoja',
              onSelected: onPaperStyleChanged,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (context) => [
                _buildPaperMenuItem(PaperStyle.ruled, 'Hoja Rayada', Icons.density_small_rounded),
                _buildPaperMenuItem(PaperStyle.grid, 'Cuadriculada (Sistemas)', Icons.grid_4x4_rounded),
                _buildPaperMenuItem(PaperStyle.dots, 'Puntos (Bullet Journal)', Icons.more_horiz_rounded),
                _buildPaperMenuItem(PaperStyle.blank, 'Hoja Blanca Limpia', Icons.crop_portrait_rounded),
                _buildPaperMenuItem(PaperStyle.dark, 'Modo Noche (Pizarra)', Icons.nightlight_round),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.palette_rounded, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      _getPaperName(currentPaperStyle),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_drop_down, size: 16, color: colorScheme.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<PaperStyle> _buildPaperMenuItem(
    PaperStyle style,
    String title,
    IconData icon,
  ) {
    return PopupMenuItem(
      value: style,
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  String _getPaperName(PaperStyle style) {
    switch (style) {
      case PaperStyle.ruled:
        return 'Rayada';
      case PaperStyle.grid:
        return 'Cuadrícula';
      case PaperStyle.dots:
        return 'Puntos';
      case PaperStyle.blank:
        return 'Blanca';
      case PaperStyle.dark:
        return 'Pizarra';
    }
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18, color: colorScheme.onSurface),
      tooltip: tooltip,
      splashRadius: 18,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(),
      onPressed: onPressed,
    );
  }

  Widget _buildToggleBtn({
    required IconData icon,
    required String tooltip,
    required bool isActive,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isActive ? colorScheme.primary.withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 19,
          color: isActive ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        tooltip: tooltip,
        splashRadius: 18,
        padding: const EdgeInsets.all(6),
        constraints: const BoxConstraints(),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    Color? iconColor,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
  }) {
    return Material(
      color: colorScheme.onSurface.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: iconColor ?? colorScheme.primary),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 22,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey.withValues(alpha: 0.25),
    );
  }
}
