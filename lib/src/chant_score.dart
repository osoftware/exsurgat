import 'dart:async';
import 'dart:ui' as ui;

import 'package:xml/xml.dart';

import 'chant_context.dart';
import 'chant_mapping.dart';
import 'core.dart' as core;
import 'elements/annotations.dart';
import 'elements/chant_layout_element.dart';
import 'elements/chant_line.dart';
import 'elements/notation/chant_notation_element.dart';
import 'elements/notation/clefs/clef.dart';
import 'elements/notation/dividers/insertion_cursor.dart';
import 'elements/notation/neumes/neume.dart';
import 'elements/notation/neumes/note.dart';
import 'elements/notation/text_only.dart';
import 'elements/text/drop_cap.dart';
import 'elements/text/titles.dart';
import 'gabc.dart';
import 'quick_svg.dart';

/// A selection state for a [ChantScore], tracking which elements are selected
/// and where an insertion cursor should be displayed.
class Selection {
  Selection({
    this.element = const ElementSelection(),
    this.line = const LineSelection(),
  });

  /// The element-level selection, containing the indices of elements in [ChantScore.notes].
  final ElementSelection element;

  /// The line-level selection, containing indices of lines in [ChantScore.lines]
  final LineSelection line;

  dynamic get insertion => element.insertion;
}

/// The element-level portion of a [Selection].
class ElementSelection {
  const ElementSelection({this.indices = const {}, this.insertion});

  /// The indices of the selected elements within the score's `notes` array.
  final Set<int> indices;

  /// The insertion cursor location, if any.
  final dynamic insertion;
}

class LineSelection {
  const LineSelection({this.indices = const {}});

  final Set<int> indices;
}

/// A chant score, the main document type produced by parsing gabc source.
class ChantScore {
  /// Creates a new [ChantScore] from the given [mappings].
  ///
  /// If [useDropCap] is `true`, then a drop cap is created for the first
  /// syllable of the score.
  ChantScore({
    ChantContext? ctxt,
    List<ChantMapping> mappings = const [],
    this.useDropCap = false,
    GabcHeader? header,
  }) : mappings = List.of(mappings) {
    if (ctxt != null) updateHeader(ctxt, header);
    if (ctxt != null) updateNotations(ctxt);
  }

  /// The mappings that describe how the gabc source maps to exsurge notations.
  List<ChantMapping> mappings;

  /// The chant lines (systems) that make up the score, created during layout.
  List<ChantLine> lines = [];

  /// A flattened array of all notes and notation elements in the score, for
  /// O(1) access by index.
  List<ChantLayoutElement> notes = [];

  /// A flattened array of all notations in the score.
  late List<ChantNotationElement> notations;

  /// The number of staff lines (typically 4 for Gregorian chant).
  int staffLineCount = 4;

  /// The titles (supertitle, title, subtitle, etc.) for the score.
  Titles? titles;

  /// The starting clef for the score.
  Clef? startingClef;

  /// Whether to use a drop cap for the first syllable.
  bool useDropCap = false;

  /// The drop cap element, if any.
  DropCap? dropCap;

  /// The annotation element, if any.
  Annotations? annotation;

  /// Whether the score has been compiled (laid out).
  bool compiled = false;

  /// Whether automatic coloring (e.g., for rubrics) is enabled.
  bool autoColoring = true;

  /// Whether the score needs to be laid out again.
  bool needsLayout = true;

  /// Whether to extend the staff lines of the last system to the right edge.
  bool extendLastSystemStaffLines = true;

  /// The bounding box of the score, valid after chant lines are created.
  core.Rect bounds = core.Rect();

  /// Whether the score has lyrics.
  bool hasLyrics = false;

  /// Whether the score has above-lines text.
  bool hasAboveLinesText = false;

  /// Whether the score has translations.
  bool hasTranslations = false;

  /// The current selection state, if any.
  Selection? selection;

  /// The element that the insertion cursor should be drawn after, if any.
  ChantLayoutElement? insertionElement;

  /// When [mergeAnnotationWithTextLeft] is active and there is no drop cap,
  /// this holds the merged text-left element that overrides the title's
  /// text-left.
  TextLeftRight? overrideTextLeft;

  /// The pages of the score, created by [paginate]. Initially contains just
  /// this score.
  late List<ChantScore> pages;

  /// Make a copy of the score, only including the specified lines.
  ///
  /// [startLine] is the starting index (inclusive) and [endLine] is the
  /// ending index (exclusive).
  ChantScore copyLines(int startLine, int endLine) {
    final result = ChantScore()
      ..lines = lines.sublist(startLine, endLine)
      ..bounds = bounds.clone();
    final lastLine = result.lines.isEmpty ? null : result.lines.last;
    if (lastLine != null) {
      result.bounds = result.bounds.copyWith(
        height: lastLine.bounds.bottom - lastLine.origin.y,
      );
    }
    if (startLine == 0) {
      result.titles = titles;
      result.dropCap = dropCap;
      result.annotation = annotation;
    }
    return result;
  }

  void updateHeader(ChantContext ctxt, GabcHeader? header) {
    if (header != null) {
      titles = Titles(
        ctxt,
        this,
        title: header['title'],
        subtitle: header['subtitle'],
        supertitle: header['supertitle'],
        textLeft: header['textLeft'],
        textRight: header['textRight'],
      );
      if (header['annotation'] != null || header['mode'] != null) {
        annotation = Annotations(ctxt, [
          ...header['annotationArray'] ?? [?header['annotation']],
          ?header['mode'],
        ]);
      }
    }
  }

  /// Updates the selection state of the score.
  void updateSelection(Selection? selection) {
    this.selection = selection;
    final elementSelection = selection?.element ?? ElementSelection();
    final selectedIndices = elementSelection.indices;
    var insertion = elementSelection.insertion;
    if (insertion == null &&
        selectedIndices.length == 1 &&
        notes[selectedIndices.first] is TextOnly) {
      // if there is only one selection, and its a text only, it should display
      // as an insertion cursor:
      insertion = {'afterElementIndex': selectedIndices.first};
    }

    // update the selected elements so that they can be given a .selected class
    // when rendered
    for (var i = 0; i < notes.length; ++i) {
      final element = notes[i];
      element.selected = selectedIndices.contains(i);
    }

    final clef = startingClef?.model ?? startingClef;
    if (clef != null) {
      clef.selected = selectedIndices.contains(-1);
    }

    for (var i = 0; i < lines.length; ++i) {
      lines[i].insertionCursor = null;
      lines[i].selected = selection?.line.indices.contains(i) ?? false;
    }

    // update the insertion cursor, so it can be drawn on the correct system
    insertionElement = null;
    ChantLine? insertionLine;
    if (insertion != null) {
      if (insertion['chantLine'] is int) {
        insertionLine = lines[insertion['chantLine'] as int];
        insertionElement = insertionLine.startingClef;
        insertionLine.insertionCursor = InsertionCursor();
      } else if (insertion['afterElementIndex'] is int) {
        insertionElement = notes[insertion['afterElementIndex'] as int];
        if (insertionElement == null) {
          insertionLine = lines[0];
          insertionElement = insertionLine.startingClef;
        } else if (insertionElement case Note(:final neume)) {
          insertionElement = neume;
        }
        insertionLine ??=
            (insertionElement as dynamic).line ?? lines[lines.length - 1];
        insertionLine!.insertionCursor = InsertionCursor();
      }
    }
  }

  /// Updates the internal notations arrays from the current [mappings].
  void updateNotations(ChantContext ctxt) {
    // flatten all mappings into one array for O(1) access to notations
    notations = [];
    notes = [];
    hasLyrics = false;
    hasAboveLinesText = false;
    hasTranslations = false;
    final elementSelection = selection?.element ?? ElementSelection();
    final selectedIndices = elementSelection.indices;
    var nonNoteElementCount = 0;

    // find the starting clef...
    // start with a default clef in case the notations don't provide one.
    startingClef = null;

    for (var i = 0; i < mappings.length; i++) {
      final mapping = mappings[i];
      for (var j = 0; j < mapping.notations.length; j++) {
        final notation = mapping.notations[j];
        notation.score = this;
        notation.mapping = mapping;

        if (startingClef == null) {
          if (notation is Neume) {
            startingClef = Clef.defaultClef();
          } else if (notation is Clef) {
            startingClef = notation;
            continue;
          }
        }

        notation.notationIndex = notations.length;
        notations.add(notation);
        if (!hasLyrics && notation.hasLyrics) hasLyrics = true;
        if (!hasAboveLinesText && notation.alText.isNotEmpty) {
          hasAboveLinesText = true;
        }
        if (!hasTranslations && notation.translationText.isNotEmpty) {
          hasTranslations = true;
        }

        // Update this.notes and find element indices:
        final elements = notation is Neume ? notation.notes : [notation];
        for (final element in elements) {
          final elementIndex = notes.length;
          notes.add(element);
          if (element case ChantNotationElement e) {
            e.elementIndex = elementIndex;
          }
          if (element is Note) {
            element.elementIndex = elementIndex;
            element.noteIndex = elementIndex - nonNoteElementCount;
          } else {
            ++nonNoteElementCount;
          }
          element.selected = selectedIndices.contains(elementIndex);
        }
      }
    }

    // if we've reached this far and we *still* don't have a clef, then there
    // aren't even any neumes in the score. still, set the default clef just
    // for good measure
    startingClef ??= Clef.defaultClef();
    startingClef!.elementIndex = -1;

    // update drop cap
    if (useDropCap) {
      recreateDropCap(ctxt);
    } else {
      dropCap = null;
    }

    needsLayout = true;
  }

  /// Recreates the drop cap from the first notation with lyrics.
  void recreateDropCap(ChantContext ctxt) {
    dropCap = null;

    // find the first notation with lyrics to use
    for (var i = 0; i < notations.length; i++) {
      final notation = notations[i];
      if (notation.hasLyrics && notation.lyrics[0].spans.isNotEmpty) {
        final lyrics = notation.lyrics[0];
        if (useDropCap) {
          dropCap = lyrics.generateDropCap(ctxt);
        } else {
          lyrics.dropCap = null;
          lyrics.generateSpansFromText(ctxt, lyrics.originalText);
        }
        notation.needsLayout = true;
        return;
      }
    }
  }

  /// Shared layout initialization method for [performLayout] and
  /// [performLayoutAsync].
  void initializeLayout(ChantContext ctxt) {
    // setup the context
    ctxt.activeClef = startingClef;
    ctxt.notations = notations;
    ctxt.currNotationIndex = 0;
    ctxt.staffLineCount = staffLineCount;

    if (dropCap != null) dropCap?.recalculateMetrics(ctxt);

    if (annotation != null) annotation!.recalculateMetrics(ctxt);
  }

  /// The synchronous version of layout that processes everything without
  /// yielding to any other workers/threads.
  ///
  /// Good for server side processing or very small chant pieces.
  void performLayout(ChantContext ctxt, [bool force = false]) {
    if (!force && needsLayout == false) return; // nothing to do here!

    ctxt.updateHyphenWidth();

    initializeLayout(ctxt);

    for (var i = 0; i < notations.length; i++) {
      final notation = notations[i];
      if (force || notation.needsLayout) {
        ctxt.currNotationIndex = i;
        notation.performLayout(ctxt);
      }
    }

    needsLayout = false;
  }

  /// For web applications, [performLayoutAsync] is more appropriate than
  /// [performLayout], since it will process the notations without locking up
  /// the UI thread.
  Future<void> performLayoutAsync(ChantContext ctxt) async {
    if (needsLayout == false) {
      return; // nothing to do here!
    }

    // check for sane value of hyphen width:
    ctxt.updateHyphenWidth();
    if (ctxt.hyphenWidth == 0 ||
        ctxt.hyphenWidth / ctxt.textStyles['lyric']['size'] > 0.6) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return;
    }

    initializeLayout(ctxt);

    await _layoutElementsAsync(ctxt, 0);
  }

  Future<void> _layoutElementsAsync(ChantContext ctxt, int index) async {
    if (index >= notations.length) {
      needsLayout = false;
      return;
    }

    if (index == 0) ctxt.activeClef = startingClef;

    // process for up to 50 milliseconds
    final timeout = DateTime.now().millisecondsSinceEpoch + 50;
    do {
      final notation = notations[index];
      if (notation.needsLayout) {
        ctxt.currNotationIndex = index;
        notation.performLayout(ctxt);
      }
      index++;
    } while (index < notations.length &&
        DateTime.now().millisecondsSinceEpoch < timeout);

    // schedule the next block of processing
    await Future<void>.delayed(Duration.zero);
    await _layoutElementsAsync(ctxt, index);
  }

  /// Lays out the chant lines (systems) of the score to fit within [width].
  void layoutChantLines(
    ChantContext ctxt,
    double width, [
    void Function(ChantScore)? finishedCallback,
  ]) {
    lines = [];

    if (ctxt.mergeAnnotationWithTextLeft != null &&
        annotation != null &&
        dropCap == null) {
      overrideTextLeft = TextLeftRight(ctxt, '', 'textLeft');
      final mergedSpans = ctxt.mergeAnnotationWithTextLeft!([
        ...annotation!.annotations.map((a) => a.spans),
        ?titles?.textLeft?.spans,
      ]);
      overrideTextLeft!.spans = mergedSpans.cast();
    } else {
      overrideTextLeft = null;
    }

    var y = width > 0 ? titles?.layoutTitles(ctxt, width) ?? 0 : 0.0;
    var currIndex = 0;

    ctxt.activeClef = startingClef;

    final spaceBetweenSystems =
        ctxt.staffInterval * ctxt.theme.spaceBetweenSystems;

    do {
      final line = ChantLine(this);

      line.buildFromChantNotationIndex(ctxt, currIndex, width);
      currIndex = line.notationsStartIndex + line.numNotationsOnLine;
      line.performLayout(ctxt);
      line.elementIndex = lines.length;
      lines.add(line);

      line.bounds = line.bounds.copyWith(y: -line.bounds.y + y);
      y += line.bounds.height + spaceBetweenSystems;
    } while (currIndex < notations.length);

    final firstLine = lines[0];

    bounds = core.Rect.fromXYWH(0, 0, firstLine.bounds.width, 0);
    bounds = bounds.copyWith(height: y - spaceBetweenSystems);

    pages = [this];

    if (selection != null) {
      updateSelection(selection);
    }

    if (finishedCallback != null) finishedCallback(this);
  }

  /// Paginates the score into pages that fit within [height].
  void paginate(double height) {
    pages = [];
    var pageHeightOffset = 0.0;
    var startLineIndex = 0;
    for (var i = 1; i < lines.length; ++i) {
      final line = lines[i];
      final pageHeight = line.bounds.bottom - pageHeightOffset - line.origin.y;

      if (pageHeight > height) {
        // this line will be the first on the new page
        pages.add(copyLines(startLineIndex, i));
        startLineIndex = i;
        pageHeightOffset = line.bounds.y - line.origin.y;
        line.bounds = line.bounds.copyWith(y: line.origin.y);
      } else {
        // not a new page yet...update the bounds:
        line.bounds = line.bounds.copyWith(y: line.bounds.y - pageHeightOffset);
      }
    }
    pages.add(copyLines(startLineIndex, lines.length));
  }

  /// Draws the score to the canvas in [ctxt].
  void draw(ChantContext ctxt, {double scale = 1}) {
    final canvas = ctxt.canvas;

    canvas.save();
    canvas.scale(scale, scale);
    canvas.translate(bounds.x, bounds.y);

    titles?.draw(ctxt);

    for (var i = 0; i < lines.length; i++) {
      lines[i].draw(ctxt);
    }

    canvas.restore();
  }

  Future<ui.Image> createImage(ChantContext ctxt, {double scale = 1}) {
    final recorder = ui.PictureRecorder();
    ctxt.attachCanvas(ui.Canvas(recorder));
    draw(ctxt, scale: scale);
    return recorder.endRecording().toImage(
      (bounds.width * scale).toInt(),
      (bounds.height * scale).toInt(),
    );
  }

  /// Returns the SVG attributes for the root `<svg>` element.
  Map<String, dynamic> getSvgProps(ChantContext ctxt, [double? zoom]) {
    double? width;
    double? height;
    if (zoom != null) {
      width = zoom * bounds.width;
    } else {
      width = bounds.width;
      height = bounds.height;
    }
    // if zoom is truthy but not a num, width and height are undefined
    return {
      'xmlns': QuickSvg.ns,
      'xmlns:xlink': QuickSvg.xlink,
      'version': '1.1',
      'class': 'ChantScore${ctxt.editable ? ' EditableChantScore' : ''}',
      'width': width,
      'height': height,
      'viewBox': [0, 0, bounds.width, bounds.height].join(' '),
    };
  }

  /// Creates an [XmlElement] rendering of the score.
  XmlElement createSvgNode(ChantContext ctxt) {
    // create defs section
    final defs = ctxt.defsNode.copy();
    if (ctxt.stylingMode == .css) defs.children.add(ctxt.createStyleNode());

    final svgNode = QuickSvg.createNode('svg', getSvgProps(ctxt), [
      defs,
      ?titles?.createSvgNode(ctxt, titles!),
      for (final l in lines) l.createSvgNode(ctxt),
    ]);

    return svgNode;
  }

  /// Creates an [SvgTreeNode] representing the score.
  SvgTreeNode createSvgTree(ChantContext ctxt, [double? zoom]) {
    // create defs section
    final node = [
      QuickSvg.createSvgTree('defs', {}, [
        ...ctxt.makeDefs.map((makeDef) => makeDef()),
        ctxt.createStyleTree(),
      ]),
    ];

    if (titles != null) node.add(titles!.createSvgTree(ctxt));

    for (var i = 0; i < lines.length; i++) {
      // ChantLine.createSvgTree is currently commented out in the Dart port;
      // call it dynamically so the score compiles regardless.
      node.add(lines[i].createSvgTree(ctxt));
    }

    final g = QuickSvg.createSvgTree('g', {}, node);
    final svgProps = getSvgProps(ctxt, zoom);
    svgProps['data-source'] = this;
    return QuickSvg.createSvgTree('svg', svgProps, g);
  }

  /// Creates a separate [XmlElement] for each chant line (system).
  List<XmlElement> createSvgNodeForEachLine(ChantContext ctxt) {
    final node = <XmlElement>[];

    var top = 0.0;
    for (var i = 0; i < lines.length; i++) {
      final defsCopy = ctxt.defsNode.copy();
      defsCopy.children.add(ctxt.createStyleNode());
      final lineFragment = <XmlNode>[
        defsCopy,
        lines[i].createSvgNode(ctxt, null, top),
      ];
      final height = lines[i].bounds.height + ctxt.staffInterval * 1.5;
      var g = QuickSvg.createNode('g', {}, lineFragment);
      g = QuickSvg.createNode('svg', {
        'xmlns': QuickSvg.ns,
        'version': '1.1',
        'class': 'ChantScore',
        'width': bounds.width,
        'height': height,
        'viewBox': [0, 0, bounds.width, height].join(' '),
      }, g);
      node.add(g);
      top += height;
    }
    return node;
  }

  /// Unserializes the score from a JSON-compatible map.
  void unserializeFromJson(Map<String, dynamic> data, ChantContext ctxt) {
    autoColoring = data['auto-coloring'] as bool? ?? true;

    if (data['annotation'] != null && data['annotation'] != '') {
      // create the annotation
      annotation = Annotations(ctxt, data['annotation'] as List<String>);
    } else {
      annotation = null;
    }

    final createDropCap = data['drop-cap'] == 'auto';

    Gabc.parseChantNotations(data['notations'] as String, this, createDropCap);
  }

  /// Serializes the score to a JSON-compatible map.
  Map<String, dynamic> serializeToJson() {
    final data = <String, dynamic>{};

    data['type'] = 'score';
    data['auto-coloring'] = true;

    if (annotation != null) {
      data['annotation'] = annotation!.annotations
          .map((a) => a.unsanitizedText)
          .toList();
    } else {
      data['annotation'] = [];
    }

    return data;
  }
}
