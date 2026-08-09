import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/note_page_model.dart';

class A4PageCanvas extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1 / 1.4142,
        child: Container(
          margin: const EdgeInsets.all(16),
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
            children: [
              // Texto principal
              Padding(
                padding: const EdgeInsets.all(28.0),
                child: TextField(
                  controller: textController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textAlign: textAlign,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                    fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                    height: 1.5,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Comienza a escribir tus apuntes aquí...',
                  ),
                  onChanged: (val) {
                    pageModel.textContent = val;
                    onChanged(val);
                  },
                ),
              ),
              // Elementos flotantes redimensionables
              ...pageModel.floatingElements.map((elem) {
                return _ResizableFloatingWidget(
                  key: ValueKey(elem.id),
                  elem: elem,
                  onChanged: () => onChanged(textController.text),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResizableFloatingWidget extends StatefulWidget {
  final FloatingElement elem;
  final VoidCallback onChanged;

  const _ResizableFloatingWidget({
    super.key,
    required this.elem,
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
        children: [
          GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                widget.elem.position += details.delta;
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
                child: kIsWeb
                    ? Image.network(
                  widget.elem.imagePath!,
                  fit: BoxFit.contain,
                )
                    : Image.file(
                  File(widget.elem.imagePath!),
                  fit: BoxFit.contain,
                ),
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
                  widget.elem.width = (widget.elem.width + details.delta.dx).clamp(80.0, 500.0);
                  widget.elem.height = (widget.elem.height + details.delta.dy).clamp(50.0, 500.0);
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