import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/note_page_model.dart';

enum PaperStyle { blank, ruled, grid, dots, dark }

class A4PageCanvas extends StatefulWidget {
  final NotePageModel pageModel;
  final TextEditingController textController;
  final double fontSize;
  final bool isBold;
  final bool isItalic;
  final TextAlign textAlign;
  final PaperStyle paperStyle;
  final Function(String) onChanged;
  final VoidCallback? onPageModified;

  const A4PageCanvas({
    super.key,
    required this.pageModel,
    required this.textController,
    required this.fontSize,
    required this.isBold,
    required this.isItalic,
    required this.textAlign,
    this.paperStyle = PaperStyle.ruled,
    required this.onChanged,
    this.onPageModified,
  });

  @override
  State<A4PageCanvas> createState() => _A4PageCanvasState();
}

class _A4PageCanvasState extends State<A4PageCanvas> {
  final FocusNode _sheetFocusNode = FocusNode();

  @override
  void dispose() {
    _sheetFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final isDarkPaper = widget.paperStyle == PaperStyle.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        // El ancho de la hoja se calcula en base al ancho horizontal disponible,
        // el cual NUNCA se reduce al desplegarse el teclado en pantalla.
        final double availableWidth = constraints.maxWidth;
        final double sheetWidth = (availableWidth - 32).clamp(280.0, 680.0);
        // Proporción estándar A4 internacional (1 : 1.4142)
        final double sheetHeight = sheetWidth * 1.4142;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            top: 14,
            bottom: isKeyboardOpen ? 140 : 28,
          ),
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (!_sheetFocusNode.hasFocus) {
                  _sheetFocusNode.requestFocus();
                }
              },
              child: Container(
                width: sheetWidth,
                constraints: BoxConstraints(minHeight: sheetHeight),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDarkPaper ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkPaper
                          ? Colors.black.withValues(alpha: 0.5)
                          : Colors.black.withValues(alpha: 0.12),
                      blurRadius: 14,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CustomPaint(
                    painter: PaperPatternPainter(
                      style: widget.paperStyle,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Texto principal de la hoja A4
                        Padding(
                          padding: EdgeInsets.only(
                            left: widget.paperStyle == PaperStyle.ruled ? 52.0 : 28.0,
                            right: 28.0,
                            top: 28.0,
                            bottom: 40.0,
                          ),
                          child: TextField(
                            controller: widget.textController,
                            focusNode: _sheetFocusNode,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            textAlign: widget.textAlign,
                            style: TextStyle(
                              fontSize: widget.fontSize,
                              fontWeight: widget.isBold ? FontWeight.bold : FontWeight.normal,
                              fontStyle: widget.isItalic ? FontStyle.italic : FontStyle.normal,
                              height: 1.55,
                              color: isDarkPaper ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B),
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Comienza a escribir tus apuntes aquí...',
                              hintStyle: TextStyle(
                                color: isDarkPaper
                                    ? Colors.white.withValues(alpha: 0.35)
                                    : Colors.black.withValues(alpha: 0.35),
                              ),
                            ),
                            onChanged: (val) {
                              widget.pageModel.textContent = val;
                              widget.onChanged(val);
                            },
                          ),
                        ),

                        // Elementos flotantes redimensionables (Notas adhesivas y Fotos)
                        ...widget.pageModel.floatingElements
                            .where((e) => e.elementType != FloatingElementType.examAlert)
                            .map((elem) {
                          return _ResizableFloatingWidget(
                            key: ValueKey(elem.id),
                            elem: elem,
                            sheetWidth: sheetWidth,
                            sheetHeight: sheetHeight,
                            onChanged: () {
                              widget.onChanged(widget.textController.text);
                              widget.onPageModified?.call();
                            },
                            onDelete: () {
                              setState(() {
                                widget.pageModel.floatingElements.removeWhere((e) => e.id == elem.id);
                              });
                              widget.onChanged(widget.textController.text);
                              widget.onPageModified?.call();
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Dibuja texturas realistas de papel universitario (rayado, cuadriculado, puntos o modo noche)
class PaperPatternPainter extends CustomPainter {
  final PaperStyle style;

  PaperPatternPainter({required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    if (style == PaperStyle.blank) return;

    if (style == PaperStyle.ruled) {
      _paintRuled(canvas, size);
    } else if (style == PaperStyle.grid) {
      _paintGrid(canvas, size);
    } else if (style == PaperStyle.dots) {
      _paintDots(canvas, size);
    } else if (style == PaperStyle.dark) {
      _paintDarkRuled(canvas, size);
    }
  }

  void _paintRuled(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;

    // Líneas horizontales espaciadas
    const double stepY = 28.0;
    for (double y = 48.0; y < size.height - 20; y += stepY) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Margen vertical izquierdo clásico de cuaderno universitario (rojo suave)
    final marginPaint = Paint()
      ..color = const Color(0xFFEF9A9A).withValues(alpha: 0.8)
      ..strokeWidth = 1.2;
    canvas.drawLine(const Offset(44, 0), Offset(44, size.height), marginPaint);
  }

  void _paintGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 0.8;

    const double step = 24.0;
    // Líneas verticales
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    // Líneas horizontales
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _paintDots(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;

    const double step = 24.0;
    for (double x = step; x < size.width; x += step) {
      for (double y = step; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }
  }

  void _paintDarkRuled(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 0.9;

    const double stepY = 28.0;
    for (double y = 48.0; y < size.height - 20; y += stepY) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant PaperPatternPainter oldDelegate) {
    return oldDelegate.style != style;
  }
}

/// Widget redimensionable y deslizable para Notas Adhesivas y Fotografías
class _ResizableFloatingWidget extends StatefulWidget {
  final FloatingElement elem;
  final double sheetWidth;
  final double sheetHeight;
  final VoidCallback onChanged;
  final VoidCallback onDelete;

  const _ResizableFloatingWidget({
    super.key,
    required this.elem,
    required this.sheetWidth,
    required this.sheetHeight,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_ResizableFloatingWidget> createState() => _ResizableFloatingWidgetState();
}

class _ResizableFloatingWidgetState extends State<_ResizableFloatingWidget> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  int _colorIndex = 0;

  static const List<Color> _noteColors = [
    Color(0xFFFFF9C4), // Amarillo clásico
    Color(0xFFC8E6C9), // Verde menta
    Color(0xFFF8BBD0), // Rosa suave
    Color(0xFFE1F5FE), // Celeste
    Color(0xFFEDE7F6), // Lavanda
  ];

  static const List<Color> _noteBorders = [
    Color(0xFFFBC02D),
    Color(0xFF81C784),
    Color(0xFFF06292),
    Color(0xFF4FC3F7),
    Color(0xFFBA68C8),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.elem.text);
  }

  @override
  void didUpdateWidget(covariant _ResizableFloatingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.elem.text != _controller.text) {
      _controller.text = widget.elem.text;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _cycleColor() {
    setState(() {
      _colorIndex = (_colorIndex + 1) % _noteColors.length;
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final elemType = widget.elem.elementType;

    if (elemType == FloatingElementType.codeSnippet) {
      return _buildCodeSnippetWidget();
    } else {
      return _buildStandardNoteWidget();
    }
  }

  // ===========================================================================
  // 1. TERMINAL INTERACTIVO DE CÓDIGO / ALGORITMOS (ING. DE SISTEMAS)
  // ===========================================================================
  Widget _buildCodeSnippetWidget() {
    final currentLang = widget.elem.language ?? 'Java';
    const languages = ['Java', 'Python', 'C++', 'SQL', 'Dart', 'JavaScript', 'Pseudocódigo', 'C#', 'Bash'];

    return Positioned(
      left: widget.elem.position.dx,
      top: widget.elem.position.dy,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: widget.elem.width,
            height: widget.elem.height,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A), // Dark Slate Terminal
              border: Border.all(color: const Color(0xFF334155), width: 1.5),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(2, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Cabecera estilo macOS con botones y selector de lenguaje
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
                  ),
                  child: Row(
                    children: [
                      // Botones ventana Mac
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFF59E0B), shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
                      const SizedBox(width: 8),

                      // Selector de Lenguaje
                      PopupMenuButton<String>(
                        initialValue: currentLang,
                        tooltip: 'Cambiar lenguaje',
                        padding: EdgeInsets.zero,
                        onSelected: (val) {
                          setState(() {
                            widget.elem.language = val;
                          });
                          widget.onChanged();
                        },
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        itemBuilder: (ctx) => languages.map((lang) => PopupMenuItem(
                          value: lang,
                          height: 32,
                          child: Text(lang, style: const TextStyle(fontSize: 12)),
                        )).toList(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Text(
                                currentLang,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8)),
                              ),
                              const Icon(Icons.arrow_drop_down, size: 14, color: Color(0xFF38BDF8)),
                            ],
                          ),
                        ),
                      ),

                      // Drag handle en el centro
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanUpdate: _handleDrag,
                          child: Container(
                            color: Colors.transparent,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: const Icon(Icons.drag_indicator_rounded, size: 14, color: Colors.white30),
                          ),
                        ),
                      ),

                      // Botón Copiar Código (fuera de onPanUpdate)
                      Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          onTap: () {
                            if (_controller.text.isNotEmpty) {
                              Clipboard.setData(ClipboardData(text: _controller.text));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✓ Código copiado al portapapeles'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Tooltip(
                              message: 'Copiar código',
                              child: Icon(Icons.copy_rounded, size: 14, color: Colors.white70),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Botón Eliminar (fuera de onPanUpdate)
                      Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          onTap: widget.onDelete,
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Tooltip(
                              message: 'Cerrar bloque',
                              child: Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Editor de Código Monoespaciado
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (!_focusNode.hasFocus) {
                        _focusNode.requestFocus();
                      }
                    },
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          hintText: '// Escribe o pega tu código aquí...',
                          hintStyle: TextStyle(fontSize: 11, color: Colors.white30, fontFamily: 'monospace'),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 12.5,
                          color: Color(0xFF38BDF8), // Cian eléctrico
                          height: 1.35,
                        ),
                        onChanged: (val) {
                          widget.elem.text = val;
                          widget.onChanged();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Control de Redimensionado
          _buildResizeHandle(const Color(0xFF38BDF8)),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. NOTA ADHESIVA ESTÁNDAR / FOTOGRAFÍA
  // ===========================================================================
  Widget _buildStandardNoteWidget() {
    final bgColor = _noteColors[_colorIndex];
    final borderColor = _noteBorders[_colorIndex];

    return Positioned(
      left: widget.elem.position.dx,
      top: widget.elem.position.dy,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: widget.elem.width,
            height: widget.elem.height,
            decoration: BoxDecoration(
              color: widget.elem.isImage ? Colors.white : bgColor,
              border: Border.all(
                color: widget.elem.isImage ? Colors.blueGrey.shade300 : borderColor,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 6,
                  offset: const Offset(2, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Barra superior de la nota adhesiva (Drag handle, Color y Borrar)
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: widget.elem.isImage
                        ? Colors.grey.shade100
                        : borderColor.withValues(alpha: 0.25),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                  child: Row(
                    children: [
                      // Drag handle
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanUpdate: _handleDrag,
                          child: Container(
                            color: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            alignment: Alignment.centerLeft,
                            child: const Icon(Icons.drag_indicator_rounded, size: 14, color: Colors.black45),
                          ),
                        ),
                      ),
                      if (!widget.elem.isImage)
                        Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            onTap: _cycleColor,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white70,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.palette_outlined, size: 13, color: Colors.black54),
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                      Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          onTap: widget.onDelete,
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.close_rounded, size: 16, color: Colors.black54),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenido (Imagen o Texto)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: widget.elem.isImage && widget.elem.imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: widget.elem.imagePath!.startsWith('http')
                                ? Image.network(
                                    widget.elem.imagePath!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.grey,
                                    ),
                                  )
                                : (kIsWeb
                                    ? const Icon(Icons.image_outlined, color: Colors.grey)
                                    : Image.file(
                                        File(widget.elem.imagePath!),
                                        fit: BoxFit.contain,
                                      )),
                          )
                        : TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: const InputDecoration(
                              hintText: 'Nota adhesiva...',
                              hintStyle: TextStyle(fontSize: 12, color: Colors.black38),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                              height: 1.3,
                            ),
                            onChanged: (val) {
                              widget.elem.text = val;
                              widget.onChanged();
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),

          // Control para redimensionar (esquina inferior derecha)
          _buildResizeHandle(borderColor),
        ],
      ),
    );
  }

  void _handleDrag(DragUpdateDetails details) {
    setState(() {
      final double maxX = (widget.sheetWidth - 50.0).clamp(0.0, double.infinity);
      final double maxY = (widget.sheetHeight - 50.0).clamp(0.0, double.infinity);
      final double newX = (widget.elem.position.dx + details.delta.dx).clamp(0.0, maxX);
      final double newY = (widget.elem.position.dy + details.delta.dy).clamp(0.0, maxY);
      widget.elem.position = Offset(newX, newY);
    });
    widget.onChanged();
  }

  Widget _buildResizeHandle(Color color) {
    return Positioned(
      right: -2,
      bottom: -2,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            widget.elem.width = (widget.elem.width + details.delta.dx).clamp(120.0, widget.sheetWidth);
            widget.elem.height = (widget.elem.height + details.delta.dy).clamp(80.0, widget.sheetHeight);
          });
          widget.onChanged();
        },
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 3),
            ],
          ),
          child: const Icon(
            Icons.open_in_full_rounded,
            size: 11,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
