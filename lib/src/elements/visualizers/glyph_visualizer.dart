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
      ctxt.canvas.drawSvgPath(path.data, _getPathPaint(path, ctxt));
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
