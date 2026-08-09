import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../models/note_page_model.dart';

class PptxExportService {
  static Future<String> exportNotesToPptx(List<NotePageModel> pages, String title) async {
    try {
      final archive = Archive();

      // 1. [Content_Types].xml
      final StringBuffer contentTypesXml = StringBuffer();
      contentTypesXml.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
      contentTypesXml.write('<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">');
      contentTypesXml.write('<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>');
      contentTypesXml.write('<Default Extension="xml" ContentType="application/xml"/>');
      contentTypesXml.write('<Default Extension="png" ContentType="image/png"/>');
      contentTypesXml.write('<Default Extension="jpg" ContentType="image/jpeg"/>');
      contentTypesXml.write('<Default Extension="jpeg" ContentType="image/jpeg"/>');
      contentTypesXml.write('<Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>');
      contentTypesXml.write('<Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>');
      contentTypesXml.write('<Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>');
      contentTypesXml.write('<Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>');

      for (int i = 0; i < pages.length; i++) {
        contentTypesXml.write('<Override PartName="/ppt/slides/slide${i + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>');
      }
      contentTypesXml.write('</Types>');
      _addFileToArchive(archive, '[Content_Types].xml', utf8.encode(contentTypesXml.toString()));

      // 2. _rels/.rels
      const String mainRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
          '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
          '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/>'
          '</Relationships>';
      _addFileToArchive(archive, '_rels/.rels', utf8.encode(mainRels));

      // 3. ppt/_rels/presentation.xml.rels
      final StringBuffer presRels = StringBuffer();
      presRels.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
      presRels.write('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">');
      presRels.write('<Relationship Id="rIdMaster1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>');

      for (int i = 0; i < pages.length; i++) {
        presRels.write('<Relationship Id="rId${i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide${i + 1}.xml"/>');
      }
      presRels.write('</Relationships>');
      _addFileToArchive(archive, 'ppt/_rels/presentation.xml.rels', utf8.encode(presRels.toString()));

      // 4. ppt/presentation.xml - CONFIGURACIÓN VERTICAL (6858000 x 9144000 EMUs)
      final StringBuffer presentationXml = StringBuffer();
      presentationXml.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
      presentationXml.write('<p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">');
      presentationXml.write('<p:sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rIdMaster1"/></p:sldMasterIdLst>');
      presentationXml.write('<p:sldIdLst>');
      for (int i = 0; i < pages.length; i++) {
        presentationXml.write('<p:sldId id="${256 + i}" r:id="rId${i + 1}"/>');
      }
      presentationXml.write('</p:sldIdLst>');
      // DIMENSIONES VERTICALES (Ancho: 6858000, Alto: 9144000)
      presentationXml.write('<p:sldSz cx="6858000" cy="9144000" type="A4"/>');
      presentationXml.write('</p:presentation>');
      _addFileToArchive(archive, 'ppt/presentation.xml', utf8.encode(presentationXml.toString()));

      // 5. ARCHIVOS DE PLANTILLA NECESARIOS PARA EVITAR "REPARACIÓN EN CELULARES"
      _addFileToArchive(archive, 'ppt/theme/theme1.xml', utf8.encode(_getThemeXml()));
      _addFileToArchive(archive, 'ppt/slideMasters/slideMaster1.xml', utf8.encode(_getSlideMasterXml()));
      _addFileToArchive(archive, 'ppt/slideMasters/_rels/slideMaster1.xml.rels', utf8.encode(_getSlideMasterRelsXml()));
      _addFileToArchive(archive, 'ppt/slideLayouts/slideLayout1.xml', utf8.encode(_getSlideLayoutXml()));
      _addFileToArchive(archive, 'ppt/slideLayouts/_rels/slideLayout1.xml.rels', utf8.encode(_getSlideLayoutRelsXml()));

      // 6. CREACIÓN DE DIAPOSITIVAS VERTICALES
      int globalImageCounter = 1;

      for (int i = 0; i < pages.length; i++) {
        final page = pages[i];
        final int slideNumber = i + 1;
        final StringBuffer slideXml = StringBuffer();
        final StringBuffer slideRelsXml = StringBuffer();

        slideRelsXml.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
        slideRelsXml.write('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">');
        slideRelsXml.write('<Relationship Id="rIdLayout" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>');

        slideXml.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
        slideXml.write('<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">');
        slideXml.write('<p:cSld><p:spTree>');
        slideXml.write('<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>');
        slideXml.write('<p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>');

        int shapeId = 2;
        int slideRelCounter = 1;

        // A) Texto Principal de la hoja A4 Vertical
        if (page.textContent.trim().isNotEmpty) {
          slideXml.write(_buildTextShape(
            id: shapeId++,
            name: 'Texto Principal',
            text: page.textContent,
            x: 381000,
            y: 381000,
            cx: 6096000,
            cy: 3500000,
            isFloating: false,
          ));
        }

        // B) Elementos Flotantes escalados al lienzo vertical
        for (var elem in page.floatingElements) {
          // Factor de conversión adaptado a lienzo vertical
          final int x = (elem.position.dx * 12000).toInt();
          final int y = ((elem.position.dy + 40) * 12000).toInt();
          final int cx = (elem.width * 12000).toInt();
          final int cy = (elem.height * 12000).toInt();

          if (elem.isImage && elem.imagePath != null) {
            final bytes = await _loadImageBytes(elem.imagePath!);
            if (bytes != null) {
              final String relId = 'rImgId$slideRelCounter';
              final String imageFileName = 'image_$globalImageCounter.png';

              _addFileToArchive(archive, 'ppt/media/$imageFileName', bytes);

              slideRelsXml.write('<Relationship Id="$relId" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="../media/$imageFileName"/>');

              slideXml.write(_buildImageShape(
                id: shapeId++,
                name: 'Imagen $globalImageCounter',
                relId: relId,
                x: x,
                y: y,
                cx: cx,
                cy: cy,
              ));

              slideRelCounter++;
              globalImageCounter++;
            }
          } else if (!elem.isImage && elem.text.trim().isNotEmpty) {
            slideXml.write(_buildTextShape(
              id: shapeId++,
              name: 'Cuadro Flotante',
              text: elem.text,
              x: x,
              y: y,
              cx: cx,
              cy: cy,
              isFloating: true,
            ));
          }
        }

        slideXml.write('</p:spTree></p:cSld></p:sld>');
        slideRelsXml.write('</Relationships>');

        _addFileToArchive(archive, 'ppt/slides/slide$slideNumber.xml', utf8.encode(slideXml.toString()));
        _addFileToArchive(archive, 'ppt/slides/_rels/slide$slideNumber.xml.rels', utf8.encode(slideRelsXml.toString()));
      }

      // 7. EMPAQUETADO FINAL ZIP/PPTX
      final ZipEncoder encoder = ZipEncoder();
      final List<int>? pptxBytes = encoder.encode(archive);

      if (pptxBytes == null) return 'Error al empaquetar la presentación';

      final String cleanTitle = title.replaceAll(RegExp(r'[^\w\s\-]'), '_');
      final String filename = '$cleanTitle.pptx';

      if (kIsWeb) {
        final blob = html.Blob([pptxBytes], 'application/vnd.openxmlformats-officedocument.presentationml.presentation');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', filename)
          ..click();
        html.Url.revokeObjectUrl(url);
        return 'Presentación descargada: $filename';
      } else {
        final outputDir = await getApplicationDocumentsDirectory();
        final filePath = '${outputDir.path}/$filename';
        final file = File(filePath);
        await file.writeAsBytes(pptxBytes);
        return filePath;
      }
    } catch (e) {
      return 'Error al exportar PowerPoint: $e';
    }
  }

  static Future<Uint8List?> _loadImageBytes(String path) async {
    try {
      if (kIsWeb) {
        final request = await html.HttpRequest.request(path, responseType: 'arraybuffer');
        return Uint8List.view(request.response as ByteBuffer);
      } else {
        final file = File(path);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
    } catch (e) {
      debugPrint('Error al leer imagen: $e');
    }
    return null;
  }

  static void _addFileToArchive(Archive archive, String path, List<int> bytes) {
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  static String _buildTextShape({
    required int id,
    required String name,
    required String text,
    required int x,
    required int y,
    required int cx,
    required int cy,
    required bool isFloating,
  }) {
    final StringBuffer sb = StringBuffer();
    sb.write('<p:sp>');
    sb.write('<p:nvSpPr><p:cNvPr id="$id" name="$name"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr>');
    sb.write('<p:spPr><a:xfrm><a:off x="$x" y="$y"/><a:ext cx="$cx" cy="$cy"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom>');

    if (isFloating) {
      sb.write('<a:solidFill><a:srgbClr val="E3F2FD"/></a:solidFill>');
      sb.write('<a:ln w="12700"><a:solidFill><a:srgbClr val="2196F3"/></a:solidFill></a:ln>');
    }

    sb.write('</p:spPr>');
    sb.write('<p:txBody><a:bodyPr wrap="square" lIns="91440" tIns="91440" rIns="91440" bIns="91440"/><a:lstStyle/>');

    final lines = text.split('\n');
    for (var line in lines) {
      sb.write('<a:p><a:r><a:rPr lang="es-ES" sz="1400"/><a:t>${_escapeXml(line)}</a:t></a:r></a:p>');
    }

    sb.write('</p:txBody></p:sp>');
    return sb.toString();
  }

  static String _buildImageShape({
    required int id,
    required String name,
    required String relId,
    required int x,
    required int y,
    required int cx,
    required int cy,
  }) {
    return '<p:pic>'
        '<p:nvPicPr>'
        '<p:cNvPr id="$id" name="$name"/>'
        '<p:cNvPicPr><a:picLocks noChangeAspect="1"/></p:cNvPicPr>'
        '<p:nvPr/>'
        '</p:nvPicPr>'
        '<p:blipFill>'
        '<a:blip r:embed="$relId"/>'
        '<a:stretch><a:fillRect/></a:stretch>'
        '</p:blipFill>'
        '<p:spPr>'
        '<a:xfrm>'
        '<a:off x="$x" y="$y"/>'
        '<a:ext cx="$cx" cy="$cy"/>'
        '</a:xfrm>'
        '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom>'
        '</p:spPr>'
        '</p:pic>';
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _getThemeXml() {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Office Theme">'
        '<a:themeElements><a:clrScheme name="Office"><a:dk1><a:srgbClr val="000000"/></a:dk1><a:lt1><a:srgbClr val="FFFFFF"/></a:lt1><a:dk2><a:srgbClr val="1F497D"/></a:dk2><a:lt2><a:srgbClr val="EEECE1"/></a:lt2><a:accent1><a:srgbClr val="4F81BD"/></a:accent1><a:accent2><a:srgbClr val="F05A28"/></a:accent2><a:accent3><a:srgbClr val="9BBB59"/></a:accent3><a:accent4><a:srgbClr val="8064A2"/></a:accent4><a:accent5><a:srgbClr val="4BACC6"/></a:accent5><a:accent6><a:srgbClr val="F79646"/></a:accent6><a:hlink><a:srgbClr val="0000FF"/></a:hlink><a:folHlink><a:srgbClr val="800080"/></a:folHlink></a:clrScheme>'
        '<a:fontScheme name="Office"><a:majorFont><a:latin typeface="Calibri"/></a:majorFont><a:minorFont><a:latin typeface="Calibri"/></a:minorFont></a:fontScheme>'
        '<a:fmtScheme name="Office"><a:fillStyleLst><a:solidFill><a:srgbClr val="FFFFFF"/></a:solidFill></a:fillStyleLst><a:lnStyleLst><a:ln w="9525"><a:solidFill><a:srgbClr val="000000"/></a:solidFill></a:ln></a:lnStyleLst><a:effectStyleLst><a:effectLst/></a:effectStyleLst><a:bgFillStyleLst><a:solidFill><a:srgbClr val="FFFFFF"/></a:solidFill></a:bgFillStyleLst></a:fmtScheme></a:themeElements></a:theme>';
  }

  static String _getSlideMasterXml() {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<p:sldMaster xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">'
        '<p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/></p:spTree></p:cSld>'
        '<p:sldLayoutIdLst><p:sldLayoutId id="2147483649" r:id="rIdLayout1"/></p:sldLayoutIdLst></p:sldMaster>';
  }

  static String _getSlideMasterRelsXml() {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rIdLayout1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/>'
        '<Relationship Id="rIdTheme" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="../theme/theme1.xml"/>'
        '</Relationships>';
  }

  static String _getSlideLayoutXml() {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<p:sldLayout xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" type="blank">'
        '<p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr/></p:spTree></p:cSld></p:sldLayout>';
  }

  static String _getSlideLayoutRelsXml() {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rIdMaster" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="../slideMasters/slideMaster1.xml"/>'
        '</Relationships>';
  }
}