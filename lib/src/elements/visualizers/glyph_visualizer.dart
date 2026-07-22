import 'dart:ui';

import 'package:xml/xml.dart';

import '../../core.dart' as core;
import '../../drawing.dart';
import '../../glyphs.dart';
import '../../quick_svg.dart';
import '../chant_layout_element.dart';
import '../notation/chant_notation_element.dart';
import '../notation/clefs/clef.dart';
import '../notation/neumes/note.dart';

class GlyphVisualizer extends ChantLayoutElement {
  GlyphVisualizer(ChantContext ctxt, GlyphCode glyphCode) {
    setGlyph(ctxt, glyphCode);
  }

  GlyphCode? glyphCode;
  Glyph? glyph;
  String? align;

  void setGlyph(ChantContext ctxt, GlyphCode glyphCode) {
    if (this.glyphCode != glyphCode) {
      this.glyphCode = glyphCode;
      glyph = glyphs[glyphCode];

      registerGlyph(ctxt);
    }

    glyph ??= glyphs[GlyphCode.none];

    origin = core.Point(
      glyph!.origin.x * ctxt.glyphScaling,
      glyph!.origin.y * ctxt.glyphScaling,
    );
    bounds = core.Rect.fromXYWH(
      0,
      -origin.y,
      glyph!.bounds.width * ctxt.glyphScaling,
      glyph!.bounds.height * ctxt.glyphScaling,
    );

    align = glyph!.align;
  }

  void registerGlyph(ChantContext ctxt) {
    if (ctxt.defs.containsKey(glyphCode!.code)) return;

    ctxt.defs[glyphCode!.code] = QuickSvg.createFragment(
      'g',
      getDefProps(ctxt),
      QuickSvg.svgFragmentForGlyph(glyph!),
    );
    ctxt.defsNode.children.add(
      QuickSvg.createNode(
        'g',
        getDefProps(ctxt),
        QuickSvg.nodesForGlyph(glyph!, QuickSvg.createNode),
      ),
    );
    ctxt.makeDefs.add(
      () => QuickSvg.createSvgTree(
        'g',
        getDefProps(ctxt),
        QuickSvg.nodesForGlyph(glyph!, QuickSvg.createSvgTree),
      ),
    );
  }

  Map<String, String> getDefProps(ChantContext ctxt) {
    return {
      'id': glyphCode!.code,
      'class': 'glyph',
      if (ctxt.scaleDefs) 'transform': 'scale(${ctxt.glyphScaling})',
    };
  }

  void setStaffPosition(ChantContext ctxt, int staffPosition) {
    bounds = core.Rect.fromXYWH(
      bounds.x,
      ctxt.calculateHeightFromStaffPosition(staffPosition) - origin.y,
      bounds.width,
      bounds.height,
    );
  }

  @override
  void draw(ChantContext ctxt) {
    if (glyph == null) return;
    final x = bounds.x + origin.x;
    final y = bounds.y + origin.y;
    ctxt.canvasCtxt.save();
    ctxt.canvasCtxt.translate(x, y);
    ctxt.canvasCtxt.scale(ctxt.glyphScaling, ctxt.glyphScaling);

    for (final path in glyph!.paths) {
      final paint = Paint()
        ..color = path.type == 'negative'
            ? const Color(0xFFFFFFFF)
            : ctxt.neumeLineColor;
      ctxt.canvasCtxt.drawPath(_parseSvgPath(path.data), paint);
    }

    ctxt.canvasCtxt.scale(1.0 / ctxt.glyphScaling, 1.0 / ctxt.glyphScaling);
    ctxt.canvasCtxt.translate(-x, -y);
    ctxt.canvasCtxt.restore();
  }

  @override
  XmlElement createSvgNode(ChantContext ctxt, [ChantLayoutElement? source]) {
    return QuickSvg.createNode('use', getSvgAttributes(ctxt, source));
  }

  XmlElement createSvgNodeWithAttributes(
    ChantContext ctxt, [
    ChantLayoutElement? source,
  ]) {
    return QuickSvg.createNode('use', getSvgAttributes(ctxt, source));
  }

  @override
  SvgTreeNode createSvgTree(ChantContext ctxt, [ChantLayoutElement? source]) {
    var attributes = getSvgAttributes(ctxt, source);
    if (source != null) attributes['source'] = source;
    return QuickSvg.createSvgTree("use", attributes);
  }

  @override
  String createSvgFragment(ChantContext ctxt, [ChantLayoutElement? source]) =>
      QuickSvg.createFragment('use', getSvgAttributes(ctxt, source), null);

  String createSvgFragmentWithAttributes(
    ChantContext ctxt, [
    ChantLayoutElement? source,
  ]) {
    return QuickSvg.createFragment('use', getSvgAttributes(ctxt, source), null);
  }

  Map<String, dynamic> getSvgAttributes(
    ChantContext ctxt, [
    ChantLayoutElement? source,
  ]) {
    String className = '';
    String? id;
    bool porrectus = <GlyphCode>[
      .porrectus1,
      .porrectus2,
      .porrectus3,
      .porrectus4,
    ].contains(glyphCode);
    if (porrectus) {
      var notes = (source as Note).neume!.notes;
      var noteIndex = notes.indexOf(source);
      var nextNote = noteIndex < notes.length - 1 ? notes[noteIndex + 1] : null;
      className = switch ((source.selected, nextNote?.selected ?? false)) {
        (true, true) => "selected",
        (true, false) => "selectedA",
        (false, true) => "selectedB",
        (false, false) => "",
      };
    } else {
      bool selected = switch (source) {
        Clef c => c.model?.selected ?? false,
        ChantLayoutElement e => e.selected,
        _ => false,
      };
      className = selected ? "selected" : "";
    }

    if (source is Note) {
      className += ' note';
      id = '${ctxt.noteIdPrefix}${source.noteIndex ?? 0 + 1}';
      if (porrectus) {
        className += ' porrectus porrectus-start';
      } else if (source.glyphVisualizer?.glyphCode == .none) {
        className += ' porrectus prrectus-end';
      }
    }

    return <String, dynamic>{
      'xlink:href': '#$glyphCode',
      'class': className,
      'id': ?id,
      if (source is ChantNotationElement) 'source-index': source.sourceIndex,
      if (source is ChantNotationElement) 'element-index': source.elementIndex,
      'x': ctxt.scaleDefs
          ? bounds.x + origin.x
          : (bounds.x + origin.x) / ctxt.glyphScaling,
      'y': ctxt.scaleDefs
          ? bounds.y + origin.y
          : (bounds.y + origin.y) / ctxt.glyphScaling,
      if (!ctxt.scaleDefs) 'transform': 'scale(${ctxt.glyphScaling})',
    };
  }
}

Path _parseSvgPath(String data) {
  final path = Path();
  if (data.trim().isEmpty) {
    return path;
  }

  final tokenPattern = RegExp(
    r'[MmLlCcQqZzAaHhVv-]?\d*\.?\d+(?:[eE][+-]?\d+)?',
  );
  final tokens = tokenPattern
      .allMatches(data)
      .map((match) => match.group(0)!)
      .toList();
  if (tokens.isEmpty) {
    return path;
  }

  var index = 0;
  String? command;
  double currentX = 0;
  double currentY = 0;
  double subpathX = 0;
  double subpathY = 0;

  void nextCommand() {
    if (index >= tokens.length) {
      return;
    }
    final token = tokens[index++];
    if (token.length == 1 && RegExp(r'[MmLlCcQqZzAaHhVv]').hasMatch(token)) {
      command = token;
      return;
    }
    if (token.startsWith(RegExp(r'[MmLlCcQqZzAaHhVv]'))) {
      command = token.substring(0, 1);
      final value = token.substring(1);
      if (value.isNotEmpty) {
        tokens.insert(index, value);
      }
      return;
    }
    command = null;
  }

  while (index < tokens.length) {
    if (command == null) {
      nextCommand();
      if (command == null) {
        break;
      }
    }
    switch (command) {
      case 'M':
      case 'm':
        final x = double.parse(tokens[index++]);
        final y = double.parse(tokens[index++]);
        final absolute = command == 'M';
        final dx = absolute ? x : x;
        final dy = absolute ? y : y;
        currentX = absolute ? dx : currentX + dx;
        currentY = absolute ? dy : currentY + dy;
        subpathX = currentX;
        subpathY = currentY;
        path.moveTo(currentX, currentY);
        command = null;
        break;
      case 'L':
      case 'l':
        final x = double.parse(tokens[index++]);
        final y = double.parse(tokens[index++]);
        final absolute = command == 'L';
        final nextX = absolute ? x : currentX + x;
        final nextY = absolute ? y : currentY + y;
        path.lineTo(nextX, nextY);
        currentX = nextX;
        currentY = nextY;
        command = null;
        break;
      case 'C':
      case 'c':
        final c1x = double.parse(tokens[index++]);
        final c1y = double.parse(tokens[index++]);
        final c2x = double.parse(tokens[index++]);
        final c2y = double.parse(tokens[index++]);
        final endX = double.parse(tokens[index++]);
        final endY = double.parse(tokens[index++]);
        final absolute = command == 'C';
        final x1 = absolute ? c1x : currentX + c1x;
        final y1 = absolute ? c1y : currentY + c1y;
        final x2 = absolute ? c2x : currentX + c2x;
        final y2 = absolute ? c2y : currentY + c2y;
        final nextX = absolute ? endX : currentX + endX;
        final nextY = absolute ? endY : currentY + endY;
        path.cubicTo(x1, y1, x2, y2, nextX, nextY);
        currentX = nextX;
        currentY = nextY;
        command = null;
        break;
      case 'Q':
      case 'q':
        final qx = double.parse(tokens[index++]);
        final qy = double.parse(tokens[index++]);
        final endX = double.parse(tokens[index++]);
        final endY = double.parse(tokens[index++]);
        final absolute = command == 'Q';
        final controlX = absolute ? qx : currentX + qx;
        final controlY = absolute ? qy : currentY + qy;
        final nextX = absolute ? endX : currentX + endX;
        final nextY = absolute ? endY : currentY + endY;
        path.quadraticBezierTo(controlX, controlY, nextX, nextY);
        currentX = nextX;
        currentY = nextY;
        command = null;
        break;
      case 'Z':
      case 'z':
        path.close();
        currentX = subpathX;
        currentY = subpathY;
        command = null;
        break;
      default:
        command = null;
        break;
    }
  }

  return path;
}
