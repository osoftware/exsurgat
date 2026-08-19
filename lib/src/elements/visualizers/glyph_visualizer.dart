import 'dart:ui';

import 'package:xml/xml.dart';

import '../../chant_context.dart';
import '../../core.dart' as core;
import '../../drawing.dart';
import '../../glyphs.dart';
import '../../quick_svg.dart';
import '../chant_layout_element.dart';
import '../notation/chant_notation_element.dart';
import '../notation/clefs/clef.dart';
import '../notation/neumes/note.dart';

class GlyphVisualizer extends ChantLayoutElement {
  GlyphVisualizer(ChantContext ctxt, GlyphCode glyphCode, this.parent) {
    setGlyph(ctxt, glyphCode);
  }

  ChantLayoutElement parent;
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
    ctxt.canvas.save();
    ctxt.canvas.translate(x, y);
    ctxt.canvas.scale(ctxt.glyphScaling, ctxt.glyphScaling);

    for (final path in glyph!.paths) {
      ctxt.canvas.drawPath(_parseSvgPath(path.data), _getPathPaint(path, ctxt));
    }

    ctxt.canvas.restore();
  }

  Paint _getPathPaint(GlyphPath path, ChantContext ctxt) {
    final paint = Paint();
    if (path.type == 'negative') {
      return paint..color = const Color(0xFFFFFFFF);
    }
    late final selectedColor = ctxt.theme.selectionColor;
    late final unselectedColor = ctxt.theme.neumeColor;
    bool porrectus = <GlyphCode>[
      .porrectus1,
      .porrectus2,
      .porrectus3,
      .porrectus4,
    ].contains(glyphCode);
    if (porrectus) {
      var notes = (parent as Note).neume!.notes;
      var noteIndex = notes.indexOf(parent as Note);
      var nextNote = noteIndex < notes.length - 1 ? notes[noteIndex + 1] : null;
      switch ((parent.selected, nextNote?.selected ?? false)) {
        case (true, true):
          return paint..color = selectedColor;
        case (false, false):
          return paint..color = unselectedColor;
        case (final left, final right):
          return paint
            ..shader = Gradient.linear(
              Offset((bounds.x - origin.x) / ctxt.glyphScaling, 0),
              Offset((bounds.right - origin.x) / ctxt.glyphScaling, 0),
              [
                left ? selectedColor : unselectedColor,
                right ? selectedColor : unselectedColor,
              ],
              [0.5, 0.5],
            );
      }
    } else {
      bool selected = switch (parent) {
        Clef c => c.model?.selected ?? false,
        ChantLayoutElement e => e.selected,
      };
      return paint..color = selected ? selectedColor : unselectedColor;
    }
  }

  @override
  XmlElement createSvgNode(ChantContext ctxt, [ChantLayoutElement? source]) {
    return QuickSvg.createNode('use', getSvgAttributes(ctxt, source));
  }

  @override
  SvgTreeNode createSvgTree(ChantContext ctxt, [ChantLayoutElement? source]) {
    var attributes = getSvgAttributes(ctxt, source);
    if (source != null) attributes['data-source'] = source;
    return QuickSvg.createSvgTree("use", attributes);
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
        className += ' porrectus porrectus-end';
      }
    } else if (source is Clef) {
      className += ' clef';
    }

    return <String, dynamic>{
      'xlink:href': '#$glyphCode',
      'class': className,
      if (ctxt.stylingMode == .attributes)
        'fill': ctxt.theme.neumeColor.toSvgString(),
      'id': ?id,
      if (source is ChantNotationElement)
        'data-source-index': source.sourceIndex,
      if (source is ChantNotationElement)
        'data-element-index': source.elementIndex,
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

  // Match either a single command letter or a number (incl. scientific
  // notation, leading sign, and leading dot like ".5").
  final tokenPattern = RegExp(
    r'[MmLlCcQqSsTtAaHhVvZz]|-?\d*\.?\d+(?:[eE][+-]?\d+)?',
  );
  final tokens = tokenPattern
      .allMatches(data)
      .map((match) => match.group(0)!)
      .toList();
  if (tokens.isEmpty) {
    return path;
  }

  var index = 0;
  // Current command. Empty means none seen yet.
  var command = '';
  double currentX = 0;
  double currentY = 0;
  double subpathX = 0;
  double subpathY = 0;
  // Last control point of a C/S/Q/T command, for smooth-curve reflection.
  double prevCtrlX = 0;
  double prevCtrlY = 0;

  bool isCommand(String t) =>
      t.length == 1 && RegExp(r'[MmLlCcQqSsTtAaHhVvZz]').hasMatch(t);

  double nextNum() => double.parse(tokens[index++]);

  void resetControl() {
    prevCtrlX = currentX;
    prevCtrlY = currentY;
  }

  while (index < tokens.length) {
    final t = tokens[index];
    if (isCommand(t)) {
      command = t;
      index++;
    }
    // Otherwise: implicit repeat of the previous command.

    final upper = command.toUpperCase();
    final absolute = upper == command;

    switch (upper) {
      case 'M':
        {
          final x = nextNum();
          final y = nextNum();
          currentX = absolute ? x : currentX + x;
          currentY = absolute ? y : currentY + y;
          subpathX = currentX;
          subpathY = currentY;
          path.moveTo(currentX, currentY);
          resetControl();
          // Subsequent coordinate pairs after M are implicit lineto.
          command = absolute ? 'L' : 'l';
          break;
        }
      case 'L':
        {
          final x = nextNum();
          final y = nextNum();
          final nx = absolute ? x : currentX + x;
          final ny = absolute ? y : currentY + y;
          path.lineTo(nx, ny);
          currentX = nx;
          currentY = ny;
          resetControl();
          break;
        }
      case 'H':
        {
          final x = nextNum();
          final nx = absolute ? x : currentX + x;
          path.lineTo(nx, currentY);
          currentX = nx;
          resetControl();
          break;
        }
      case 'V':
        {
          final y = nextNum();
          final ny = absolute ? y : currentY + y;
          path.lineTo(currentX, ny);
          currentY = ny;
          resetControl();
          break;
        }
      case 'C':
        {
          final c1x = nextNum();
          final c1y = nextNum();
          final c2x = nextNum();
          final c2y = nextNum();
          final ex = nextNum();
          final ey = nextNum();
          final x1 = absolute ? c1x : currentX + c1x;
          final y1 = absolute ? c1y : currentY + c1y;
          final x2 = absolute ? c2x : currentX + c2x;
          final y2 = absolute ? c2y : currentY + c2y;
          final nx = absolute ? ex : currentX + ex;
          final ny = absolute ? ey : currentY + ey;
          path.cubicTo(x1, y1, x2, y2, nx, ny);
          prevCtrlX = x2;
          prevCtrlY = y2;
          currentX = nx;
          currentY = ny;
          break;
        }
      case 'S':
        {
          final c2x = nextNum();
          final c2y = nextNum();
          final ex = nextNum();
          final ey = nextNum();
          // Reflected control point (equals current point if prev was not
          // a C/S command, since resetControl set prevCtrl = current).
          final x1 = 2 * currentX - prevCtrlX;
          final y1 = 2 * currentY - prevCtrlY;
          final x2 = absolute ? c2x : currentX + c2x;
          final y2 = absolute ? c2y : currentY + c2y;
          final nx = absolute ? ex : currentX + ex;
          final ny = absolute ? ey : currentY + ey;
          path.cubicTo(x1, y1, x2, y2, nx, ny);
          prevCtrlX = x2;
          prevCtrlY = y2;
          currentX = nx;
          currentY = ny;
          break;
        }
      case 'Q':
        {
          final cx = nextNum();
          final cy = nextNum();
          final ex = nextNum();
          final ey = nextNum();
          final controlX = absolute ? cx : currentX + cx;
          final controlY = absolute ? cy : currentY + cy;
          final nx = absolute ? ex : currentX + ex;
          final ny = absolute ? ey : currentY + ey;
          path.quadraticBezierTo(controlX, controlY, nx, ny);
          prevCtrlX = controlX;
          prevCtrlY = controlY;
          currentX = nx;
          currentY = ny;
          break;
        }
      case 'T':
        {
          final ex = nextNum();
          final ey = nextNum();
          final controlX = 2 * currentX - prevCtrlX;
          final controlY = 2 * currentY - prevCtrlY;
          final nx = absolute ? ex : currentX + ex;
          final ny = absolute ? ey : currentY + ey;
          path.quadraticBezierTo(controlX, controlY, nx, ny);
          prevCtrlX = controlX;
          prevCtrlY = controlY;
          currentX = nx;
          currentY = ny;
          break;
        }
      case 'A':
        {
          final rx = nextNum();
          final ry = nextNum();
          final xAxisRotation = nextNum();
          final largeArcFlag = nextNum();
          final sweepFlag = nextNum();
          final ex = nextNum();
          final ey = nextNum();
          final nx = absolute ? ex : currentX + ex;
          final ny = absolute ? ey : currentY + ey;
          path.arcToPoint(
            Offset(nx, ny),
            radius: Radius.elliptical(rx, ry),
            rotation: xAxisRotation,
            largeArc: largeArcFlag != 0,
            clockwise: sweepFlag != 0,
          );
          currentX = nx;
          currentY = ny;
          resetControl();
          break;
        }
      case 'Z':
        path.close();
        currentX = subpathX;
        currentY = subpathY;
        resetControl();
        break;
      default:
        // Unknown command: bail out to avoid desync.
        return path;
    }
  }

  return path;
}
