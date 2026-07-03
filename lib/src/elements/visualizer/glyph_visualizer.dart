import 'dart:ui';

import 'package:xml/xml.dart';

import '../../core.dart' as core;
import '../../drawing.dart';
import '../../glyphs.dart';
import '../../quick_svg.dart';
import '../chant_layout_element.dart';

class GlyphVisualizer extends ChantLayoutElement {
  GlyphVisualizer(ChantContext ctxt, dynamic glyphCode) {
    glyph = null;
    setGlyph(ctxt, glyphCode);
  }

  GlyphCode? glyphCode;
  Glyph? glyph;
  late dynamic glyphRef;

  void setGlyph(ChantContext ctxt, dynamic glyphCode) {
    if (this.glyphCode != glyphCode) {
      final normalized = glyphCode == null || glyphCode == ''
          ? GlyphCode.none
          : glyphCode as GlyphCode;
      this.glyphCode = normalized;
      glyph = glyphs[normalized];
    }

    if (glyph == null) {
      glyph = glyphs[GlyphCode.none];
    }

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
  XmlElement createSvgNode(ChantContext ctxt) {
    return QuickSvg.createNode('use', getSvgAttributes(ctxt, null));
  }

  @override
  String createSvgFragment(ChantContext ctxt) {
    return QuickSvg.createFragment('use', getSvgAttributes(ctxt, null), null);
  }

  Map<String, dynamic> getSvgAttributes(ChantContext ctxt, dynamic source) {
    return <String, dynamic>{
      'xlink:href': '#${glyphCode.toString()}',
      'class': '',
      'x': (bounds.x + origin.x) / ctxt.glyphScaling,
      'y': (bounds.y + origin.y) / ctxt.glyphScaling,
      'transform': 'scale(${ctxt.glyphScaling})',
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
