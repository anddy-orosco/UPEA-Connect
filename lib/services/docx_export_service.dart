import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import '../models/note_page_model.dart';
import 'pptx_save_helper.dart';

class DocxExportService {
  /// Exporta los apuntes a un documento Microsoft Word (.docx) 100% compatible
  /// con Word, Google Docs, Office 365 y LibreOffice.
  static Future<String> exportNotesToDocx({
    required List<NotePageModel> pages,
    required String title,
    String? courseName,
  }) async {
    final archive = Archive();
    final cleanTitle = title.trim().isEmpty ? 'Apunte_Sin_Titulo' : title.trim();
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    // 1. [Content_Types].xml
    const String contentTypesXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">\n'
        '  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>\n'
        '  <Default Extension="xml" ContentType="application/xml"/>\n'
        '  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>\n'
        '  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>\n'
        '  <Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/>\n'
        '  <Override PartName="/word/fontTable.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.fontTable+xml"/>\n'
        '  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>\n'
        '  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>\n'
        '</Types>';
    _addFileToArchive(archive, '[Content_Types].xml', utf8.encode(contentTypesXml));

    // 2. _rels/.rels
    const String rootRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
        '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>\n'
        '  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>\n'
        '  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>\n'
        '</Relationships>';
    _addFileToArchive(archive, '_rels/.rels', utf8.encode(rootRels));

    // 3. word/_rels/document.xml.rels
    const String wordRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">\n'
        '  <Relationship Id="rIdStyles" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>\n'
        '  <Relationship Id="rIdSettings" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/>\n'
        '  <Relationship Id="rIdFontTable" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/fontTable" Target="fontTable.xml"/>\n'
        '</Relationships>';
    _addFileToArchive(archive, 'word/_rels/document.xml.rels', utf8.encode(wordRels));

    // 4. word/styles.xml
    _addFileToArchive(archive, 'word/styles.xml', utf8.encode(_getStylesXml()));

    // 5. word/settings.xml
    const String settingsXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">\n'
        '  <w:defaultTabStop w:val="720"/>\n'
        '</w:settings>';
    _addFileToArchive(archive, 'word/settings.xml', utf8.encode(settingsXml));

    // 6. word/fontTable.xml
    const String fontTableXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<w:fonts xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">\n'
        '  <w:font w:name="Calibri"><w:family w:val="swiss"/></w:font>\n'
        '  <w:font w:name="Calibri Light"><w:family w:val="swiss"/></w:font>\n'
        '</w:fonts>';
    _addFileToArchive(archive, 'word/fontTable.xml', utf8.encode(fontTableXml));

    // 7. docProps/core.xml & app.xml
    final String coreXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" '
        'xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/">\n'
        '  <dc:title>${_escapeXml(cleanTitle)}</dc:title>\n'
        '  <dc:creator>UPEA Connect</dc:creator>\n'
        '  <cp:lastModifiedBy>UPEA Connect</cp:lastModifiedBy>\n'
        '</cp:coreProperties>';
    _addFileToArchive(archive, 'docProps/core.xml', utf8.encode(coreXml));

    const String appXml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">\n'
        '  <Application>UPEA Connect</Application>\n'
        '</Properties>';
    _addFileToArchive(archive, 'docProps/app.xml', utf8.encode(appXml));

    // 8. word/document.xml - CUERPO PRINCIPAL
    final StringBuffer doc = StringBuffer();
    doc.write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n');
    doc.write('<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">\n');
    doc.write('  <w:body>\n');

    // Título institucional
    doc.write('    <w:p>\n');
    doc.write('      <w:pPr><w:pStyle w:val="SubtituloUpea"/></w:pPr>\n');
    doc.write('      <w:r><w:t>UNIVERSIDAD PÚBLICA DE EL ALTO - INGENIERÍA DE SISTEMAS</w:t></w:r>\n');
    doc.write('    </w:p>\n');

    // Título del apunte
    doc.write('    <w:p>\n');
    doc.write('      <w:pPr><w:pStyle w:val="TituloPrincipal"/><w:spacing w:after="100"/></w:pPr>\n');
    doc.write('      <w:r><w:t>${_escapeXml(cleanTitle)}</w:t></w:r>\n');
    doc.write('    </w:p>\n');

    // Metadatos (Materia y Fecha)
    doc.write('    <w:p>\n');
    doc.write('      <w:pPr><w:spacing w:after="240"/><w:pBdr><w:bottom w:val="single" w:sz="12" w:space="8" w:color="1A365D"/></w:pBdr></w:pPr>\n');
    if (courseName != null && courseName.trim().isNotEmpty) {
      doc.write('      <w:r><w:rPr><w:b/><w:color w:val="1A365D"/></w:rPr><w:t>Materia: ${_escapeXml(courseName.trim())}</w:t></w:r>\n');
      doc.write('      <w:r><w:t>   |   </w:t></w:r>\n');
    }
    doc.write('      <w:r><w:rPr><w:i/><w:color w:val="718096"/></w:rPr><w:t>Fecha: $formattedDate</w:t></w:r>\n');
    doc.write('    </w:p>\n');

    // Contenido por páginas
    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];
      final pageNum = i + 1;

      // Encabezado de página
      if (pages.length > 1) {
        doc.write('    <w:p>\n');
        doc.write('      <w:pPr><w:pStyle w:val="EncabezadoPagina"/><w:spacing w:before="200" w:after="120"/></w:pPr>\n');
        doc.write('      <w:r><w:t>Página $pageNum de ${pages.length}</w:t></w:r>\n');
        doc.write('    </w:p>\n');
      }

      // Líneas de texto de la página
      final lines = page.textContent.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) {
          doc.write('    <w:p><w:pPr><w:spacing w:after="100"/></w:pPr></w:p>\n');
          continue;
        }

        if (trimmed.startsWith('# ')) {
          doc.write('    <w:p>\n');
          doc.write('      <w:pPr><w:pStyle w:val="Heading1"/><w:spacing w:before="240" w:after="80"/></w:pPr>\n');
          doc.write('      <w:r><w:t>${_escapeXml(trimmed.substring(2))}</w:t></w:r>\n');
          doc.write('    </w:p>\n');
        } else if (trimmed.startsWith('## ')) {
          doc.write('    <w:p>\n');
          doc.write('      <w:pPr><w:pStyle w:val="Heading2"/><w:spacing w:before="180" w:after="60"/></w:pPr>\n');
          doc.write('      <w:r><w:t>${_escapeXml(trimmed.substring(3))}</w:t></w:r>\n');
          doc.write('    </w:p>\n');
        } else if (trimmed.startsWith('• ') || trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
          final bulletText = trimmed.replaceFirst(RegExp(r'^[•\-\*]\s*'), '');
          doc.write('    <w:p>\n');
          doc.write('      <w:pPr><w:ind w:left="400"/><w:spacing w:after="60"/></w:pPr>\n');
          doc.write('      <w:r><w:rPr><w:b/><w:color w:val="1A365D"/></w:rPr><w:t>• </w:t></w:r>\n');
          doc.write('      <w:r><w:t>${_escapeXml(bulletText)}</w:t></w:r>\n');
          doc.write('    </w:p>\n');
        } else if (RegExp(r'^\d+\.\s').hasMatch(trimmed)) {
          doc.write('    <w:p>\n');
          doc.write('      <w:pPr><w:ind w:left="400"/><w:spacing w:after="60"/></w:pPr>\n');
          doc.write('      <w:r><w:t>${_escapeXml(trimmed)}</w:t></w:r>\n');
          doc.write('    </w:p>\n');
        } else if (trimmed.startsWith('[!]') || trimmed.toUpperCase().contains('OJO EXAMEN')) {
          // Bloque resaltado de examen
          doc.write('    <w:tbl>\n');
          doc.write('      <w:tblPr><w:tblW w:w="5000" w:type="pct"/><w:tblBorders><w:left w:val="single" w:sz="24" w:space="0" w:color="C53030"/><w:top w:val="none"/><w:right w:val="none"/><w:bottom w:val="none"/></w:tblBorders><w:shd w:val="clear" w:color="auto" w:fill="FFF5F5"/></w:tblPr>\n');
          doc.write('      <w:tr><w:tc><w:tcPr><w:tcMar><w:top w:w="120" w:type="dxa"/><w:left w:w="160" w:type="dxa"/><w:bottom w:w="120" w:type="dxa"/><w:right w:w="160" w:type="dxa"/></w:tcMar></w:tcPr>\n');
          doc.write('        <w:p><w:r><w:rPr><w:b/><w:color w:val="C53030"/></w:rPr><w:t>${_escapeXml(trimmed)}</w:t></w:r></w:p>\n');
          doc.write('      </w:tc></w:tr>\n');
          doc.write('    </w:tbl>\n');
        } else {
          doc.write('    <w:p>\n');
          doc.write('      <w:pPr><w:spacing w:after="100"/><w:jc w:val="both"/></w:pPr>\n');
          doc.write('      <w:r><w:t>${_escapeXml(trimmed)}</w:t></w:r>\n');
          doc.write('    </w:p>\n');
        }
      }

      // Notas adhesivas, Ojo Examen y Bloques de Código en la página
      final textElements = page.floatingElements.where((e) => !e.isImage && e.text.trim().isNotEmpty).toList();
      if (textElements.isNotEmpty) {
        doc.write('    <w:p><w:pPr><w:spacing w:before="140" w:after="80"/></w:pPr><w:r><w:rPr><w:b/><w:sz w:val="18"/><w:color w:val="718096"/></w:rPr><w:t>Elementos Destacados Adjuntos:</w:t></w:r></w:p>\n');
        for (final elem in textElements) {
          if (elem.elementType == FloatingElementType.examAlert) {
            // Tabla de Alerta Ojo Examen en Word
            doc.write('    <w:tbl>\n');
            doc.write('      <w:tblPr><w:tblW w:w="5000" w:type="pct"/><w:tblBorders><w:left w:val="single" w:sz="36" w:space="0" w:color="DC2626"/><w:top w:val="single" w:sz="4" w:space="0" w:color="FECACA"/><w:right w:val="single" w:sz="4" w:space="0" w:color="FECACA"/><w:bottom w:val="single" w:sz="4" w:space="0" w:color="FECACA"/></w:tblBorders><w:shd w:val="clear" w:color="auto" w:fill="FFF5F5"/></w:tblPr>\n');
            doc.write('      <w:tr><w:tc><w:tcPr><w:tcMar><w:top w:w="140" w:type="dxa"/><w:left w:w="180" w:type="dxa"/><w:bottom w:w="140" w:type="dxa"/><w:right w:w="180" w:type="dxa"/></w:tcMar></w:tcPr>\n');
            doc.write('        <w:p><w:r><w:rPr><w:b/><w:color w:val="DC2626"/><w:sz w:val="18"/></w:rPr><w:t>[!] OJO EXAMEN (TEMA CLAVE):</w:t></w:r></w:p>\n');
            doc.write('        <w:p><w:r><w:rPr><w:b/><w:color w:val="7F1D1D"/></w:rPr><w:t>${_escapeXml(elem.text.trim())}</w:t></w:r></w:p>\n');
            doc.write('      </w:tc></w:tr>\n');
            doc.write('    </w:tbl>\n');
          } else if (elem.elementType == FloatingElementType.codeSnippet) {
            // Tabla de Bloque de Código en Word
            final lang = elem.language ?? 'Código';
            doc.write('    <w:tbl>\n');
            doc.write('      <w:tblPr><w:tblW w:w="5000" w:type="pct"/><w:tblBorders><w:left w:val="single" w:sz="18" w:space="0" w:color="334155"/><w:top w:val="single" w:sz="18" w:space="0" w:color="334155"/><w:right w:val="single" w:sz="18" w:space="0" w:color="334155"/><w:bottom w:val="single" w:sz="18" w:space="0" w:color="334155"/></w:tblBorders><w:shd w:val="clear" w:color="auto" w:fill="0F172A"/></w:tblPr>\n');
            doc.write('      <w:tr><w:tc><w:tcPr><w:tcMar><w:top w:w="120" w:type="dxa"/><w:left w:w="160" w:type="dxa"/><w:bottom w:w="120" w:type="dxa"/><w:right w:w="160" w:type="dxa"/></w:tcMar></w:tcPr>\n');
            doc.write('        <w:p><w:r><w:rPr><w:b/><w:color w:val="38BDF8"/><w:sz w:val="16"/></w:rPr><w:t>// Lenguaje: $lang</w:t></w:r></w:p>\n');
            doc.write('        <w:p><w:r><w:rPr><w:rFonts w:ascii="Courier New" w:hAnsi="Courier New"/><w:color w:val="F8FAFC"/><w:sz w:val="18"/></w:rPr><w:t>${_escapeXml(elem.text.trim())}</w:t></w:r></w:p>\n');
            doc.write('      </w:tc></w:tr>\n');
            doc.write('    </w:tbl>\n');
          } else {
            // Nota adhesiva estándar
            doc.write('    <w:tbl>\n');
            doc.write('      <w:tblPr><w:tblW w:w="5000" w:type="pct"/><w:tblBorders><w:left w:val="single" w:sz="18" w:space="0" w:color="FFE082"/><w:top w:val="none"/><w:right w:val="none"/><w:bottom w:val="none"/></w:tblBorders><w:shd w:val="clear" w:color="auto" w:fill="FFFDE7"/></w:tblPr>\n');
            doc.write('      <w:tr><w:tc><w:tcPr><w:tcMar><w:top w:w="120" w:type="dxa"/><w:left w:w="160" w:type="dxa"/><w:bottom w:w="120" w:type="dxa"/><w:right w:w="160" w:type="dxa"/></w:tcMar></w:tcPr>\n');
            doc.write('        <w:p><w:r><w:rPr><w:i/><w:color w:val="2D3748"/></w:rPr><w:t>${_escapeXml(elem.text.trim())}</w:t></w:r></w:p>\n');
            doc.write('      </w:tc></w:tr>\n');
            doc.write('    </w:tbl>\n');
          }
        }
      }

      // Salto de página entre hojas (excepto la última)
      if (i < pages.length - 1) {
        doc.write('    <w:p><w:r><w:br w:type="page"/></w:r></w:p>\n');
      }
    }

    // Configuración de página A4 con márgenes
    doc.write('    <w:sectPr>\n');
    doc.write('      <w:pgSz w:w="11906" w:h="16838"/>\n'); // A4 estándar internacional
    doc.write('      <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="720" w:footer="720" w:gutter="0"/>\n');
    doc.write('    </w:sectPr>\n');
    doc.write('  </w:body>\n');
    doc.write('</w:document>\n');

    _addFileToArchive(archive, 'word/document.xml', utf8.encode(doc.toString()));

    // Empaquetar y guardar archivo .docx
    final zipEncoder = ZipEncoder();
    final List<int>? docxBytes = zipEncoder.encode(archive);
    if (docxBytes == null) {
      throw Exception('No se pudo generar el archivo Word (.docx)');
    }

    final sanitizedFileName = cleanTitle
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(' ', '_');
    final filename = '$sanitizedFileName.docx';

    return await PptxSaveHelper.saveAndDownload(docxBytes, filename);
  }

  static void _addFileToArchive(Archive archive, String name, List<int> content) {
    archive.addFile(ArchiveFile(name, content.length, content));
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _getStylesXml() {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">\n'
        '  <w:docDefaults>\n'
        '    <w:rPrDefault>\n'
        '      <w:rPr>\n'
        '        <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/>\n'
        '        <w:sz w:val="22"/>\n'
        '        <w:color w:val="2D3748"/>\n'
        '      </w:rPr>\n'
        '    </w:rPrDefault>\n'
        '  </w:docDefaults>\n'
        '  <w:style w:type="paragraph" w:styleId="Normal" w:default="1">\n'
        '    <w:name w:val="Normal"/>\n'
        '    <w:pPr><w:spacing w:line="276" w:lineRule="auto"/></w:pPr>\n'
        '  </w:style>\n'
        '  <w:style w:type="paragraph" w:styleId="SubtituloUpea">\n'
        '    <w:name w:val="SubtituloUpea"/>\n'
        '    <w:rPr>\n'
        '      <w:b/>\n'
        '      <w:sz w:val="18"/>\n'
        '      <w:color w:val="718096"/>\n'
        '    </w:rPr>\n'
        '  </w:style>\n'
        '  <w:style w:type="paragraph" w:styleId="TituloPrincipal">\n'
        '    <w:name w:val="TituloPrincipal"/>\n'
        '    <w:rPr>\n'
        '      <w:b/>\n'
        '      <w:sz w:val="44"/>\n'
        '      <w:color w:val="1A365D"/>\n'
        '    </w:rPr>\n'
        '  </w:style>\n'
        '  <w:style w:type="paragraph" w:styleId="Heading1">\n'
        '    <w:name w:val="Heading 1"/>\n'
        '    <w:rPr>\n'
        '      <w:b/>\n'
        '      <w:sz w:val="30"/>\n'
        '      <w:color w:val="1A365D"/>\n'
        '    </w:rPr>\n'
        '  </w:style>\n'
        '  <w:style w:type="paragraph" w:styleId="Heading2">\n'
        '    <w:name w:val="Heading 2"/>\n'
        '    <w:rPr>\n'
        '      <w:b/>\n'
        '      <w:sz w:val="26"/>\n'
        '      <w:color w:val="2B6CB0"/>\n'
        '    </w:rPr>\n'
        '  </w:style>\n'
        '  <w:style w:type="paragraph" w:styleId="EncabezadoPagina">\n'
        '    <w:name w:val="EncabezadoPagina"/>\n'
        '    <w:rPr>\n'
        '      <w:b/>\n'
        '      <w:sz w:val="18"/>\n'
        '      <w:color w:val="718096"/>\n'
        '    </w:rPr>\n'
        '  </w:style>\n'
        '</w:styles>';
  }
}
