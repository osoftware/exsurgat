import 'package:xml/xml.dart';

import '../../../drawing.dart';
import '../../../glyphs.dart';
import '../../../quick_svg.dart';
import '../../brace_point.dart';
import '../../chant_layout_element.dart';
import '../../horizontal_episema.dart';
import '../../mora.dart';
import '../../text/above_lines_text.dart';
import '../../visualizers/glyph_visualizer.dart';
import 'neume.dart';

enum LiquescentType with Flags {
  none(0),
  large(1 << 0),
  small(1 << 1),
  ascending(1 << 2),
  descending(1 << 3),
  initioDebilis(1 << 4);

  @override
  final int value;

  const LiquescentType(this.value);
}

enum NoteShape { defaultShape, virga, inclinatum, quilisma, stropha, oriscus }

enum NoteShapeModifiers with Flags {
  none(0),
  ascending(1 << 0),
  descending(1 << 1),
  cavum(1 << 2),
  stemmed(1 << 3),
  linea(1 << 4),
  reverse(1 << 5);

  @override
  final int value;

  const NoteShapeModifiers(this.value);
}

class Note extends ChantLayoutElement {
  Pitch? pitch;
  GlyphVisualizer? glyphVisualizer;

  // The staffPosition on a note is an integer that indicates the vertical position on the staff.
  // 0 is the space just below the lowest line on the staff (equivalent to gabc 'c'). Positive numbers go up
  // the staff, and negative numbers go down, i.e., 1 is gabc 'd', 2 is gabc 'e', -1 is gabc 'b', etc.
  int staffPosition = 4;
  double staffPositionOffset = 0;
  int? sourceIndex;
  String sourceGabc = '';
  int sourceLength = 0;
  int liquescent = 0;
  NoteShape shape = NoteShape.defaultShape;
  int shapeModifiers = 0;

  // notes keep track of the neume they belong to in order to facilitate layout
  // this.neume gets set when a note is added to a neume via Neume.addNote()
  Neume? neume;

  // indices used by ChantScore.updateNotations for selection tracking
  int? elementIndex;
  int? noteIndex;
  dynamic line;

  // various markings that can exist on a note, organized by type
  // for faster access and simpler code logic
  final List<HorizontalEpisema> episemata = [];
  final List<Mora> morae =
      []; // silly to have an array of these, but gabc allows multiple morae per note!

  // these are set on the note when they are needed, otherwise, they're undefined
  dynamic ictus;
  dynamic accuteAccent;
  dynamic braceStart;
  BracePoint? braceEnd;
  dynamic svgNode;
  dynamic accent;
  dynamic choralSign;
  dynamic inclinataFlags;
  AboveLinesText? alText;

  Note({this.pitch});

  void setGlyph(ChantContext ctxt, GlyphCode glyphCode) {
    if (glyphVisualizer != null) {
      glyphVisualizer!.setGlyph(ctxt, glyphCode);
    } else {
      glyphVisualizer = GlyphVisualizer(ctxt, glyphCode);
    }

    glyphVisualizer!.setStaffPosition(ctxt, staffPosition);

    // assign glyphvisualizer metrics to this note
    bounds = glyphVisualizer!.bounds.clone();
    origin = glyphVisualizer!.origin.clone();
  }

  @override
  void draw(ChantContext ctxt) {
    glyphVisualizer!.bounds = bounds.clone();

    glyphVisualizer!.draw(ctxt);
  }

  @override
  XmlElement createSvgNode(ChantContext ctxt) {
    // TODO: investigate if this is even needed
    glyphVisualizer!.bounds = bounds.clone();
    svgNode = glyphVisualizer!.createSvgNodeWithAttributes(ctxt, this);
    return svgNode;
  }

  @override
  SvgTreeNode createSvgTree(ChantContext ctxt) {
    glyphVisualizer!.bounds = bounds.clone();
    return glyphVisualizer!.createSvgTree(ctxt, this);
  }

  @override
  String createSvgFragment(ChantContext ctxt) {
    glyphVisualizer!.bounds = bounds.clone();
    return glyphVisualizer!.createSvgFragmentWithAttributes(ctxt, this);
  }
}
