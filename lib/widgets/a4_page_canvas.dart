import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/note_page_model.dart';

class A4PageCanvas extends StatefulWidget {
  final NotePageModel pageModel;
  final TextEditingController textController;
  final double fontSize;
  final bool isBold;
  final bool isItalic;
  final TextAlign textAlign;
  final Function(String) onChanged;

  const A4PageCanvas({
    super.key,
    required this.pageModel,
    required this.textController,
    required this.fontSize,
    required this.isBold,
    required this.isItalic,
    required this.textAlign,
    required this.onChanged,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        // El ancho de la hoja se calcula en base al ancho horizontal disponible,
        // el cual NUNCA se reduce al desplegarse el teclado.
        // Restamos 32px para márgenes laterales y aplicamos un clamp para pantallas grandes/tablets.
        final double availableWidth = constraints.maxWidth;
        final double sheetWidth = (availableWidth - 32).clamp(280.0, 650.0);
        // Proporción estándar A4 internacional (1 : 1.4142)
        final double sheetHeight = sheetWidth * 1.4142;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            top: 16,
            bottom: isKeyboardOpen ? 120 : 24, // Espacio extra inferior para escribir cómodamente sobre el teclado
          ),
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                // Si el usuario toca cualquier área vacía de la hoja, enfocamos el editor principal
                if (!_sheetFocusNode.hasFocus) {
                  _sheetFocusNode.requestFocus();
                }
              },
              child: Container(
                width: sheetWidth,
                constraints: BoxConstraints(minHeight: sheetHeight),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Texto principal
                    Padding(
                      padding: const EdgeInsets.all(28.0),
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
                          height: 1.5,
                          color: Colors.black87,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Comienza a escribir tus apuntes aquí...',
                          hintStyle: TextStyle(color: Colors.black38),
                        ),
                        onChanged: (val) {
                          widget.pageModel.textContent = val;
                          widget.onChanged(val);
                        },
                      ),
                    ),
                    // Elementos flotantes redimensionables
                    ...widget.pageModel.floatingElements.map((elem) {
                      return _ResizableFloatingWidget(
                        key: ValueKey(elem.id),
                        elem: elem,
                        sheetWidth: sheetWidth,
                        sheetHeight: sheetHeight,
                        onChanged: () => widget.onChanged(widget.textController.text),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ResizableFloatingWidget extends StatefulWidget {
  final FloatingElement elem;
  final double sheetWidth;
  final double sheetHeight;
  final VoidCallback onChanged;

  const _ResizableFloatingWidget({
    super.key,
    required this.elem,
    required this.sheetWidth,
    required this.sheetHeight,
    required this.onChanged,
  });

  @override
  State<_ResizableFloatingWidget> createState() => _ResizableFloatingWidgetState();
}

class _ResizableFloatingWidgetState extends State<_ResizableFloatingWidget> {
  late TextEditingController _controller;

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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.elem.position.dx,
      top: widget.elem.position.dy,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                final double maxX = (widget.sheetWidth - 40.0).clamp(0.0, double.infinity);
                final double maxY = (widget.sheetHeight - 40.0).clamp(0.0, double.infinity);
                final double newX = (widget.elem.position.dx + details.delta.dx).clamp(0.0, maxX);
                final double newY = (widget.elem.position.dy + details.delta.dy).clamp(0.0, maxY);
                widget.elem.position = Offset(newX, newY);
              });
              widget.onChanged();
            },
            child: Container(
              width: widget.elem.width,
              height: widget.elem.height,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.85),
                border: Border.all(color: Colors.blue.shade400, width: 1.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: widget.elem.isImage && widget.elem.imagePath != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                // Si la ruta empieza con 'http', es una URL ya subida al
                // backend (Vercel Blob) y se muestra con Image.network,
                // tanto en web como en celular. Solo se usa Image.file
                // como respaldo para imágenes locales viejas que aún
                // no se hayan subido (o mientras se está subiendo).
                child: widget.elem.imagePath!.startsWith('http')
                    ? Image.network(
                  widget.elem.imagePath!,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Icon(
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
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Escribe aquí...',
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                onChanged: (val) {
                  widget.elem.text = val;
                  widget.onChanged();
                },
              ),
            ),
          ),
          // Botón / Control para redimensionar (esquina inferior derecha)
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  widget.elem.width = (widget.elem.width + details.delta.dx).clamp(80.0, widget.sheetWidth);
                  widget.elem.height = (widget.elem.height + details.delta.dy).clamp(50.0, widget.sheetHeight);
                });
                widget.onChanged();
              },
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.open_in_full,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
