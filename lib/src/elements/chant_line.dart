import 'dart:math' as math;

import 'package:xml/xml.dart';

import '../chant_score.dart';
import '../drawing.dart';
import '../glyphs.dart';
import '../quick_svg.dart';
import 'brace_point.dart';
import 'chant_layout_element.dart';
import 'horizontal_episema.dart';
import 'notation/accidental.dart';
import 'notation/chant_line_break.dart';
import 'notation/chant_notation_element.dart';
import 'notation/clefs.dart';
import 'notation/custos.dart';
import 'notation/dividers.dart';
import 'notation/neumes.dart';
import 'notation/text_only.dart';
import 'text/annotation.dart';
import 'text/drop_cap.dart';
import 'text/lyric.dart';
import 'text/text_element.dart';
import 'visualizers.dart';

class _CondensableSpace {
  _CondensableSpace({required this.notation});

  dynamic notation;
  double total = 0;
  double condensable = 0;
}

final Expando<double> _condensableSpaceSums = Expando<double>();

extension CondensableSpaceListExtension on List<dynamic> {
  double get sum => _condensableSpaceSums[this] ?? 0;
  set sum(double value) => _condensableSpaceSums[this] = value;
}

class ChantLine extends ChantLayoutElement {
  final ChantScore score;

  int elementIndex = 0;

  int notationsStartIndex = 0;
  int numNotationsOnLine = 0;
  late Rect notationBounds;

  double staffLeft = 0;
  double staffRight = 0;

  double paddingLeft = 0;

  Clef? startingClef;
  Custos? custos;

  bool justify = true;

  List<LedgerLinePos> ledgerLines = [];
  List<dynamic> braces = [];

  dynamic nextLine;
  dynamic previousLine;

  double lyricLineHeight = 0;
  double lyricLineBaseline = 0;
  int numLyricLines = 0;

  double spaceAfterNotations = 0;
  double spaceBetweenTextTracks = 0;

  List<Lyric> lastLyrics = [];

  int? extraTextOnlyIndex;
  int extraTextOnlyLyricIndex = 0;

  double altLineHeight = 0;
  double altLineBaseline = 0;
  int numAltLines = 0;

  double translationLineHeight = 0;
  double translationLineBaseline = 0;
  int numTranslationLines = 0;

  double extraTextOnlyHeight = 0;

  List<dynamic> toJustify = [];
  dynamic condensableSpaces;

  List<dynamic>? lastLyricsBeforeTextOnly;
  int? maxNumNotationsOnLine;

  InsertionCursor? insertionCursor;

  ChantLine(this.score);

  int get staffSpaces {
    return score.staffLineCount - 1;
  }

  void performLayout(ChantContext ctxt) {
    final staffSpaces = this.staffSpaces;
    final staffLineCount = score.staffLineCount;
    notationBounds = Rect.fromXYWH(
      staffLeft,
      -(ctxt.staffLineWeight / 2 +
              staffLineCount * 2 -
              1 +
              ctxt.minSpaceAboveStaff) *
          ctxt.staffInterval,
      staffRight - staffLeft,
      (ctxt.staffLineWeight + (staffSpaces * 2) + ctxt.minSpaceAboveStaff) *
          ctxt.staffInterval,
    );

    var notations = score.notations;
    int lastNeumeIndex = extraTextOnlyIndex == null
        ? notationsStartIndex + numNotationsOnLine
        : extraTextOnlyIndex!;
    int lastIndex = notationsStartIndex + numNotationsOnLine;
    ChantNotationElement notation;

    notationBounds += startingClef!.bounds;

    lyricLineHeight =
        ctxt.textStyles['lyric']['size'] *
        (ctxt.textStyles['lyric']['lineHeight'] ?? 1.1);
    lyricLineBaseline = 0;
    numLyricLines = 0;

    altLineHeight = 0;
    altLineBaseline = 0;
    numAltLines = 0;

    translationLineHeight =
        ctxt.textStyles['translation']['size'] *
        (ctxt.textStyles['translation']['lineHeight'] ?? 1.1);
    translationLineBaseline = 0;
    numTranslationLines = 0;

    final aboveLinesLineHeight =
        ctxt.textStyles['al']['size'] *
        (ctxt.textStyles['al']['lineHeight'] ?? 1.1);

    for (int i = notationsStartIndex; i < lastNeumeIndex; i++) {
      notation = notations[i];

      if (notation.bounds.height != 0 || notation.bounds.width != 0) {
        notationBounds += notation.bounds;
      }

      if (notation.lyrics.isNotEmpty && notation.lyrics[0].text.isNotEmpty) {
        if (notation.lyrics[0].origin.y > lyricLineBaseline) {
          lyricLineBaseline = notation.lyrics[0].origin.y;
        }
        if (notation.lyrics.length > numLyricLines) {
          numLyricLines = notation.lyrics.length;
        }
      }

      if (notation.alText.isNotEmpty && numAltLines < notation.alText.length) {
        if (notation.alText[0].bounds.height > altLineHeight) {
          altLineHeight = notation.alText[0].bounds.height;
        }
        if (notation.alText[0].origin.y > altLineBaseline) {
          altLineBaseline = notation.alText[0].origin.y;
        }
        if (notation.alText.length > numAltLines) {
          numAltLines = notation.alText.length;
        }
      }

      if (notation.translationText.isNotEmpty &&
          notation.translationText[0].text.isEmpty) {
        if (notation.translationText[0].origin.y > translationLineBaseline) {
          translationLineBaseline = notation.translationText[0].origin.y;
        }
        if (notation.translationText.length > numTranslationLines) {
          numTranslationLines = notation.translationText.length;
        }
      }
    }

    if (custos != null) notationBounds += custos!.bounds;

    for (var brace in braces) {
      notationBounds += brace.bounds;
    }

    final notationBoundsOffset =
        notationBounds.bottom + ctxt.minSpaceBelowStaff * ctxt.staffInterval;
    lyricLineBaseline += notationBoundsOffset;
    translationLineBaseline += notationBoundsOffset;
    altLineBaseline +=
        notationBounds.y - altLineHeight - ctxt.staffInterval * 0.5;

    for (int i = notationsStartIndex; i < lastNeumeIndex; i++) {
      notation = notations[i];
      double offset = 0;
      for (int j = 0; j < notation.lyrics.length; j++) {
        notation.lyrics[j].bounds = notation.lyrics[j].bounds.copyWith(
          y: offset + lyricLineBaseline,
        );
        offset += lyricLineHeight;
      }

      for (int j = 0; j < notation.translationText.length; j++) {
        notation.translationText[j].bounds = notation.translationText[j].bounds
            .copyWith(y: offset + translationLineBaseline);
        offset += translationLineHeight;
      }

      offset = 0;
      for (int j = 0; j < notation.alText.length; j++) {
        notation.alText[j].bounds = notation.alText[j].bounds.copyWith(
          y: offset + altLineBaseline,
        );
        offset -= aboveLinesLineHeight;
      }
    }

    extraTextOnlyHeight = 0;
    if (ctxt.useExtraTextOnly) {
      int extraTextOnlyLyricIndex = this.extraTextOnlyLyricIndex;
      if (extraTextOnlyIndex == null) {
        dynamic lastNotation = (lastNeumeIndex > 0)
            ? notations[lastNeumeIndex - 1]
            : null;
        if (lastNotation is ChantLineBreak) {
          lastNotation = (lastNeumeIndex > 1)
              ? notations[lastNeumeIndex - 2]
              : null;
        }
        if (lastNotation is TextOnly &&
            lastNotation.lyrics.length == 1 &&
            lastNotation.lyrics[0].bounds.height > lyricLineHeight) {
          extraTextOnlyHeight = lyricLineHeight;
        }
      } else {
        dynamic lastLyrics;
        double xOffset = 0;
        double offset = (numLyricLines - 1) * lyricLineHeight;
        offset += numTranslationLines * translationLineHeight;
        int extraLines = 0;
        for (int i = extraTextOnlyIndex!; i < lastIndex; i++) {
          notation = notations[i];
          if (notation.lyrics.length <= extraTextOnlyLyricIndex) continue;
          lastLyrics = notation.lyrics[extraTextOnlyLyricIndex];
          if (lastLyrics.lineWidth != null) {
            xOffset = staffRight - lastLyrics.lineWidth!;
            offset += lyricLineHeight;
            extraLines++;
          }
          extraLines += lastLyrics.numLines - 1 as int;
          lastLyrics.bounds.y = offset + lyricLineBaseline;
          notation.bounds = notation.bounds.copyWith(
            x: notation.bounds.x + xOffset,
          );
        }
        extraTextOnlyHeight = lyricLineHeight * extraLines;
      }
    }

    if (startingClef!.hasLyrics) {
      double offset = 0;
      for (int j = 0; j < startingClef!.lyrics.length; j++) {
        startingClef!.lyrics[j].bounds = startingClef!.lyrics[j].bounds
            .copyWith(y: offset + lyricLineBaseline);
        offset += lyricLineHeight;
      }
    }

    if (notationsStartIndex == 0) {
      if (score.annotation case Annotation a) {
        a.bounds = a.bounds.copyWith(
          x: staffLeft / 2,
          y: -ctxt.staffInterval * (staffLineCount * 2 - 1),
        );
        if (score.dropCap case DropCap dc) {
          double lowestPossibleAnnotationY =
              lyricLineBaseline -
              a.bounds.height -
              ctxt.staffInterval * ctxt.textStyles['annotation']['padding'] -
              dc.origin.y;
          a.bounds = a.bounds.copyWith(
            y: lowestPossibleAnnotationY < a.bounds.y
                ? lowestPossibleAnnotationY
                : (a.bounds.y + lowestPossibleAnnotationY) / 2,
          );
          if (a.bounds.y < notationBounds.y) {
            notationBounds = notationBounds.copyWith(
              y: score.annotation!.bounds.y,
              height: notationBounds.height + notationBounds.y - a.bounds.y,
            );
          }
        }
        a.bounds = a.bounds.copyWith(y: a.bounds.y + a.origin.y);
      }

      if (score.dropCap case DropCap dc) {
        dc.bounds = dc.bounds.copyWith(
          x: staffLeft / 2,
          y: lyricLineBaseline - score.dropCap!.origin.y,
        );
        notationBounds += score.dropCap!.bounds;
        dc.bounds = dc.bounds.copyWith(y: lyricLineBaseline);
      }
    }

    if (numLyricLines > 0) {
      final lyricAndTextRect = Rect.fromXYWH(
        0,
        notationBoundsOffset,
        0,
        lyricLineHeight * numLyricLines +
            extraTextOnlyHeight +
            translationLineHeight * numTranslationLines,
      );
      notationBounds += lyricAndTextRect;
    }
    if (numAltLines > 0) {
      final altLineTextRect = Rect.fromXYWH(
        0,
        notationBounds.y -
            altLineHeight -
            0.5 * ctxt.staffInterval -
            aboveLinesLineHeight * (numAltLines - 1),
        0,
        aboveLinesLineHeight * numAltLines,
      );
      notationBounds += altLineTextRect;
    }
    notationBounds += Rect.fromXYWH(
      0,
      -ctxt.staffInterval,
      0,
      (ctxt.staffLineWeight / 2 + ctxt.minSpaceBelowStaff) * ctxt.staffInterval,
    );
    double totalHeight = notationBounds.height;

    bounds = bounds.copyWith(
      x: 0,
      y: notationBounds.y,
      width: notationBounds.right,
      height: totalHeight,
    );

    origin = Point(staffLeft, -notationBounds.y);
  }

  InsertionCursor? layoutInsertionCursor(ChantContext ctxt) {
    if (insertionCursor != null) {
      insertionCursor!.performLayout(ctxt);
      final ie = score.insertionElement;
      final trailingSpace = ie is ChantNotationElement
          ? ie.trailingSpace(ctxt)
          : 0;
      insertionCursor!.bounds = insertionCursor!.bounds.copyWith(
        x: (ie!.bounds.right + trailingSpace) / 2 - insertionCursor!.origin.x,
      );
    }
    return insertionCursor;
  }

  @override
  void draw(ChantContext ctxt) {
    final canvasCtxt = ctxt.canvasCtxt;

    canvasCtxt.translate(bounds.x, bounds.y);

    final x1 = staffLeft;
    final x2 = staffRight;
    double y;
    for (int i = score.staffLineCount * -2 + 1; i < 0; i += 2) {
      y = ctxt.staffInterval * i;

      canvasCtxt.beginPath(
          strokeWidth: ctxt.staffLineWeight,
          color: ctxt.staffLineColor,
        )
        ..moveTo(x1, y)
        ..lineTo(x2, y)
        ..stroke();
    }

    if (layoutInsertionCursor(ctxt) != null) {
      layoutInsertionCursor(ctxt)!.draw(ctxt);
    }

    for (int i = 0; i < ledgerLines.length; i++) {
      final ledgerLine = ledgerLines[i];
      y = ctxt.calculateHeightFromStaffPosition(ledgerLine.staffPosition);

      canvasCtxt.beginPath(
          strokeWidth: ctxt.staffLineWeight,
          color: ctxt.staffLineColor,
        )
        ..moveTo(ledgerLine.x1, y)
        ..lineTo(ledgerLine.x2, y)
        ..stroke();
    }

    if (notationsStartIndex == 0) {
      if (score.dropCap != null) score.dropCap!.draw(ctxt);

      if (score.annotation != null &&
          (ctxt.mergeAnnotationWithTextLeft == null || score.dropCap != null)) {
        score.annotation!.draw(ctxt);
      }
    }

    final notations = score.notations;
    final lastIndex = notationsStartIndex + numNotationsOnLine;

    for (int i = notationsStartIndex; i < lastIndex; i++) {
      notations[i].draw(ctxt);
    }

    startingClef!.draw(ctxt);

    if (custos != null) custos!.draw(ctxt);

    canvasCtxt.translate(-bounds.x, -bounds.y);
  }

  List<T> getInnerNodes<T>(
    ChantContext ctxt, {
    double top = 0,
    // TODO: implement generic version
    // Map<String, String> functionNames = const {
    //   'quickSvg': 'createNode',
    //   'elements': 'createSvgNode',
    // },
    required NodeMaker<T> quickSvg,
    required ElementNodeMaker<T> element,
  }) {
    List<T> inner = [];

    final x1 = staffLeft;
    final x2 = staffRight;
    final staffSpaces = this.staffSpaces;
    if (ctxt.editable) {
      inner.add(
        quickSvg('rect', {
          'key': 'insertion',
          'x': x1,
          'y': ctxt.staffInterval * score.staffLineCount * -2 + 1,
          'width': x2 - x1,
          'height': ctxt.staffInterval * 2 * staffSpaces,
          'fill': 'none',
        }),
      );
    }

    for (int i = score.staffLineCount * -2 + 1; i < 0; i += 2) {
      inner.add(
        quickSvg('line', {
          'key': i,
          'x1': x1,
          'y1': ctxt.staffInterval * i,
          'x2': x2,
          'y2': ctxt.staffInterval * i,
          'stroke': ctxt.staffLineColor.toSvgString(),
          'stroke-width': ctxt.staffLineWeight,
          'class': 'staffLine',
        }),
      );
    }

    inner = [
      quickSvg('g', {'class': 'staffLines'}, inner),
    ];

    if (layoutInsertionCursor(ctxt) != null) {
      inner.add(element(layoutInsertionCursor(ctxt)!, ctxt));
    }

    for (int i = 0; i < ledgerLines.length; i++) {
      final ledgerLine = ledgerLines[i];
      final y = ctxt.calculateHeightFromStaffPosition(ledgerLine.staffPosition);

      inner.add(
        quickSvg('line', {
          'x1': ledgerLine.x1,
          'y1': y,
          'x2': ledgerLine.x2,
          'y2': y,
          'stroke': ctxt.staffLineColor,
          'stroke-width': ctxt.staffLineWeight,
          'class': 'ledgerLine',
        }),
      );
    }

    for (int i = 0; i < braces.length; i++) {
      inner.add(braces[i].createSvgNode(ctxt));
    }

    if (notationsStartIndex == 0) {
      if (score.dropCap != null) {
        inner.add(element(score.dropCap!, ctxt));
      }

      if (score.annotation != null &&
          (ctxt.mergeAnnotationWithTextLeft == null || score.dropCap != null)) {
        inner.add(element(score.annotation!, ctxt));
      }
    }

    inner.add(element(startingClef!, ctxt));

    final notations = score.notations;
    final lastIndex = notationsStartIndex + numNotationsOnLine;

    for (int i = notationsStartIndex; i < lastIndex; i++) {
      inner.add(element(notations[i], ctxt));
    }

    if (custos != null) {
      inner.add(element(custos!, ctxt));
    }
    return inner;
  }

  @override
  XmlElement createSvgNode(
    ChantContext ctxt, [
    ChantLayoutElement? source,
    double top = 0,
  ]) {
    final inner = getInnerNodes(
      ctxt,
      top: top,
      quickSvg: QuickSvg.createNode,
      element: (e, c) => e.createSvgNode(c, source),
    );

    return QuickSvg.createNode('g', {
      'class': 'chantLine',
      'transform': 'translate(${bounds.x},${bounds.y - top})',
      'element-index': elementIndex,
      'source': this,
    }, inner);
  }

  @override
  SvgTreeNode createSvgTree(
    ChantContext ctxt, [
    ChantLayoutElement? source,
    double top = 0,
  ]) {
    final inner = getInnerNodes(
      ctxt,
      top: top,
      quickSvg: QuickSvg.createSvgTree,
      element: (e, c) => e.createSvgTree(c, source),
    );

    return QuickSvg.createSvgTree('g', {
      'class': 'chantLine',
      'transform': 'translate(${bounds.x},${bounds.y - top})',
      'element-index': elementIndex,
    }, inner);
  }

  @override
  String createSvgFragment(
    ChantContext ctxt, [
    ChantLayoutElement? source,
    double top = 0,
  ]) {
    String inner = '';

    final x1 = staffLeft;
    final x2 = staffRight;

    for (int i = score.staffLineCount * -2 + 1; i < 0; i += 2) {
      inner += QuickSvg.createFragment('line', {
        'x1': x1,
        'y1': ctxt.staffInterval * i,
        'x2': x2,
        'y2': ctxt.staffInterval * i,
        'stroke': ctxt.staffLineColor.toSvgString(),
        'stroke-width': ctxt.staffLineWeight,
        'class': 'staffLine',
      });
    }

    inner = QuickSvg.createFragment('g', {'class': 'staffLines'}, inner);

    if (layoutInsertionCursor(ctxt) != null) {
      inner += layoutInsertionCursor(ctxt)!.createSvgFragment(ctxt, source);
    }

    for (int i = 0; i < ledgerLines.length; i++) {
      final ledgerLine = ledgerLines[i];
      final y = ctxt.calculateHeightFromStaffPosition(ledgerLine.staffPosition);

      inner += QuickSvg.createFragment('line', {
        'x1': ledgerLine.x1,
        'y1': y,
        'x2': ledgerLine.x2,
        'y2': y,
        'stroke': ctxt.staffLineColor.toSvgString(),
        'stroke-width': ctxt.staffLineWeight,
        'class': 'ledgerLine',
      });
    }

    for (int i = 0; i < braces.length; i++) {
      inner += braces[i].createSvgFragment(ctxt);
    }

    if (notationsStartIndex == 0) {
      if (score.dropCap != null) {
        inner += score.dropCap!.createSvgFragment(ctxt, source);
      }

      if (score.annotation != null &&
          (ctxt.mergeAnnotationWithTextLeft == null || score.dropCap != null)) {
        inner += score.annotation!.createSvgFragment(ctxt, source);
      }
    }

    inner += startingClef!.createSvgFragment(ctxt, source);

    final notations = score.notations;
    final lastIndex = notationsStartIndex + numNotationsOnLine;

    for (int i = notationsStartIndex; i < lastIndex; i++) {
      inner += notations[i].createSvgFragment(ctxt, source);
    }

    if (custos != null) {
      inner += custos!.createSvgFragment(ctxt, source);
    }

    return QuickSvg.createFragment('g', {
      'class': 'chantLine',
      'transform': 'translate(${bounds.x},${bounds.y - top})',
      'element-index': elementIndex,
    }, inner);
  }

  String generateCurlyBraceDrawable(
    ChantContext ctxt,
    double x1,
    double x2,
    double y,
    bool isAbove,
  ) {
    double h;

    if (isAbove) {
      h = -ctxt.staffInterval / 2;
    } else {
      h = ctxt.staffInterval / 2;
    }

    final q = 0.6;
    final len = x2 - x1;

    final qx1 = x1;
    final qy1 = y + q * h;
    final qx2 = x1 + 0.25 * len;
    final qy2 = y + (1 - q) * h;
    final tx1 = x1 + 0.5 * len;
    final ty1 = y + h;
    final qx3 = x2;
    final qy3 = y + q * h;
    final qx4 = x1 + 0.75 * len;
    final qy4 = y + (1 - q) * h;
    final d =
        'M $x1 $y Q $qx1 $qy1 $qx2 $qy2 T $tx1 $ty1 M $x2 $y Q $qx3 $qy3 $qx4 $qy4 T $tx1 $ty1';

    return QuickSvg.createFragment('path', {
      'd': d,
      'stroke': ctxt.neumeLineColor,
      'stroke-width': '${ctxt.neumeLineWeight}px',
      'fill': 'none',
    });
  }

  void buildFromChantNotationIndex(
    ChantContext ctxt,
    int newElementStart,
    double width,
  ) {
    final notations = score.notations;
    List<dynamic> beginningLyrics = [];
    ChantNotationElement? prev;
    ChantNotationElement? prevNeume;
    List<Lyric> prevLyrics = [];
    List<dynamic> condensableSpaces = [];
    notationsStartIndex = newElementStart;
    numNotationsOnLine = 0;

    staffLeft = 0;
    paddingLeft = 0;

    extraTextOnlyIndex = null;
    extraTextOnlyLyricIndex = 0;

    if (width > 0) {
      staffRight = width;
    } else {
      staffRight = double.infinity;
    }

    if (notationsStartIndex == 0) {
      double padding = 0;

      if (score.dropCap != null) {
        padding = score.dropCap!.bounds.width + score.dropCap!.padding * 2;
      }

      if (score.annotation != null &&
          (ctxt.mergeAnnotationWithTextLeft == null || score.dropCap != null)) {
        padding =
            (padding >
                (score.annotation!.bounds.width +
                    score.annotation!.padding * 2))
            ? padding
            : (score.annotation!.bounds.width + score.annotation!.padding * 2);
      }

      staffLeft += padding;
      if (score.dropCap != null) {
        paddingLeft = (padding - score.dropCap!.bounds.width) / 2;
      }
    } else {
      prev = notations[newElementStart - 1];
      if (prev is DoubleBar &&
          prev.hasLyrics &&
          (prev.lyrics.length > 1 ||
              !prev.lyrics[0].text.startsWith(RegExp(r'^(i\.?)+j\.?')))) {
        beginningLyrics = prev.lyrics.map((lyric) {
          final newLyric = Lyric(
            ctxt,
            lyric.originalText,
            lyric.lyricType,
            lyric.notation,
            lyric.notations,
            lyric.sourceIndex,
          );
          newLyric.elidesToNext = lyric.elidesToNext;
          // Hide the original lyric by setting its bounds.y to an extremely high number.
          // If the chant is re-laid out, this value will be recalculated so that it won't stay hidden.
          lyric.bounds = lyric.bounds.copyWith(
            y: double.infinity,
          ); // Number.MAX_SAFE_INTEGER
          return newLyric;
        }).toList();
        double minX = beginningLyrics
            .map((l) => l.bounds.x)
            .reduce((a, b) => a < b ? a : b);
        for (var l in beginningLyrics) {
          l.bounds.x -= minX;
        }
      }
    }

    if (notations.isNotEmpty && notations[newElementStart] is Clef) {
      ctxt.activeClef = notations[newElementStart] as Clef;
      newElementStart++;
      notationsStartIndex++;
    }

    startingClef = ctxt.activeClef!.clone();
    startingClef!.performLayout(ctxt);
    startingClef!.bounds = startingClef!.bounds.copyWith(x: staffLeft);

    ChantNotationElement curr = startingClef!;

    if (beginningLyrics.isNotEmpty) {
      LyricArray.setNotation(beginningLyrics, curr);
    }

    double rightNotationBoundary =
        staffRight -
        glyphs[GlyphCode.custosLong]!.bounds.width * ctxt.glyphScaling;
    dynamic lastTranslationTextWithEndNeume;

    int i;
    int j;
    int lastNotationIndex = notations.length - 1;

    if (curr.hasLyrics) {
      LyricArray.mergeIn(lastLyrics, curr.lyrics);
    }

    if (ctxt.lastStartBrace != null && ctxt.lastStartBrace!.note == null) {
      ctxt.lastStartBrace!.note = startingClef!;
    }
    dynamic lastLyricsBeforeTextOnly;
    int? textOnlyStartIndex;

    for (i = newElementStart; i <= lastNotationIndex; i++) {
      prev = curr;
      if (curr is! TextOnly) prevNeume = curr;

      curr = notations[i];

      double actualRightBoundary;
      if (i == lastNotationIndex ||
          curr is Custos ||
          (prev is Custos && curr is Divider) ||
          (curr is ChantLineBreak && prevNeume is Custos)) {
        actualRightBoundary = staffRight;
      } else if (i == lastNotationIndex - 1) {
        actualRightBoundary =
            (rightNotationBoundary >
                (staffRight - notations[lastNotationIndex].bounds.width))
            ? rightNotationBoundary
            : (staffRight - notations[lastNotationIndex].bounds.width);
      } else {
        actualRightBoundary = rightNotationBoundary;
      }

      bool forceBreak =
          curr is! Divider &&
          curr is! ChantLineBreak &&
          curr is! Custos &&
          !(curr is TextOnly &&
              curr.hasLyrics &&
              RegExp(r'^(?:[*†]|i+j\.?)$').hasMatch(curr.lyrics[0].text)) &&
          lastNotationIndex - i > 1 &&
          !prevNeume!.keepWithNext &&
          prevNeume.bounds.right >= rightNotationBoundary;

      forceBreak =
          forceBreak ||
          (extraTextOnlyIndex != null &&
              curr is! TextOnly &&
              curr is! ChantLineBreak &&
              curr is! Custos &&
              curr.hasLyrics);

      if (curr is TextOnly && prev == prevNeume) {
        lastLyricsBeforeTextOnly = lastLyrics.toList();
        textOnlyStartIndex = i;
      }
      if (curr is TextOnly &&
          textOnlyStartIndex != null &&
          !notations[textOnlyStartIndex].hasLyrics) {
        textOnlyStartIndex = i;
      }

      if (curr.hasLyrics && curr.lyrics[0].needsLayout) {
        curr.lyrics[0].recalculateMetrics(ctxt);
      }

      bool fitsOnLine =
          !forceBreak &&
          positionNotationElement(
            ctxt,
            lastLyrics,
            prevNeume!,
            curr,
            actualRightBoundary,
            condensableSpaces,
          );
      bool candidateForExtraTextOnlyLine =
          ctxt.useExtraTextOnly &&
          curr is TextOnly &&
          LyricArray.hasOnlyOneLyric(curr.lyrics) &&
          (fitsOnLine == false || extraTextOnlyIndex != null);
      late int extraTextOnlyLyricIndex;
      if (candidateForExtraTextOnlyLine && extraTextOnlyIndex == null) {
        extraTextOnlyLyricIndex = LyricArray.indexOfLyric(curr.lyrics);
        if (textOnlyStartIndex == i) {
          String currentLyric = curr.lyrics[extraTextOnlyLyricIndex].text;
          if (currentLyric.length <= 1) {
            dynamic nextNotation = (i + 1 < notations.length)
                ? notations[i + 1]
                : null;
            candidateForExtraTextOnlyLine =
                nextNotation != null &&
                nextNotation is TextOnly &&
                nextNotation.lyrics.length > extraTextOnlyLyricIndex &&
                nextNotation.lyrics[extraTextOnlyLyricIndex].text.isNotEmpty;
          }
        }
      }
      if (candidateForExtraTextOnlyLine) {
        dynamic firstOnLine;
        extraTextOnlyLyricIndex = this.extraTextOnlyLyricIndex;
        if (extraTextOnlyIndex == null &&
            notations[textOnlyStartIndex!].lyrics.isNotEmpty) {
          if (textOnlyStartIndex == notationsStartIndex ||
              !ctxt.startExtraTextOnlyFromFirst) {
            textOnlyStartIndex = i;
            var lastNotationWithLyrics = notations
                .sublist(notationsStartIndex, i)
                .reversed
                .where((notation) => notation.hasLyrics)
                .firstOrNull;
            lastLyricsBeforeTextOnly =
                lastNotationWithLyrics?.lyrics.toList() ?? [];
          }
          extraTextOnlyIndex = textOnlyStartIndex;
          extraTextOnlyLyricIndex = this.extraTextOnlyLyricIndex =
              LyricArray.indexOfLyric(curr.lyrics);
          this.lastLyricsBeforeTextOnly = lastLyricsBeforeTextOnly;
          lastLyrics = [];
          i = textOnlyStartIndex - 1;
          numNotationsOnLine = textOnlyStartIndex - notationsStartIndex;
          continue;
        }
        curr.lyrics[extraTextOnlyLyricIndex].lineWidth = null;
        if (!fitsOnLine || i == extraTextOnlyIndex) {
          curr.bounds = curr.bounds.copyWith(
            x: curr.lyrics[extraTextOnlyLyricIndex].origin.x,
          );
          double lastLyricRight = (ctxt.startExtraTextOnlyFromFirst)
              ? LyricArray.getRight(lastLyrics) + ctxt.minLyricWordSpacing
              : 0;
          curr.lyrics[extraTextOnlyLyricIndex].setMaxWidth(
            ctxt,
            staffRight,
            staffRight - lastLyricRight,
          );
          firstOnLine = curr;
        }
        if (firstOnLine != null) {
          firstOnLine.lyrics[extraTextOnlyLyricIndex].lineWidth = curr
              .lyrics[extraTextOnlyLyricIndex]
              .getRight();
        }
      } else if (fitsOnLine == false) {
        bool isTextOnlyBeforeDivider(int idx) {
          final currNotation = notations[idx];
          if (currNotation is! TextOnly) return false;
          final firstDivider = notations
              .sublist(idx + 1)
              .indexWhere((notation) => notation is Divider);
          if (firstDivider < 0) return false;
          return notations
              .sublist(idx + 1, idx + 1 + firstDivider)
              .every((notation) => notation is TextOnly);
        }

        while (numNotationsOnLine > 1 &&
            (curr is Divider || curr is Custos || isTextOnlyBeforeDivider(i))) {
          curr = notations[--i];
          numNotationsOnLine--;
          if (lastLyricsBeforeTextOnly != null && isTextOnlyBeforeDivider(i)) {
            lastLyricsBeforeTextOnly = null;
          }
        }

        if (lastTranslationTextWithEndNeume != null) {
          // TODO: need to go back to before the last translation text start
        }

        final notationsAfterBreak = notations.sublist(i + 1);
        int countSyllables = 0;
        int countNotes = 0;
        if (ctxt.minSyllablesLastLine > 0 && ctxt.minNotesLastLine > 0) {
          countSyllables = notationsAfterBreak
              .where((notation) => notation.hasLyrics)
              .length;
          countNotes = notationsAfterBreak
              .whereType<Neume>()
              .expand((notation) => notation.notes)
              .length;
        }

        for (j = i - 1; j > notationsStartIndex; j--) {
          final cne = notations[j];
          curr = notations[j + 1];

          if (ctxt.minSyllablesLastLine > 0 && ctxt.minNotesLastLine > 0) {
            countSyllables += curr.hasLyrics ? 1 : 0;
            countNotes += switch (curr) {
              Neume(:final notes) => notes.length,
              _ => 0,
            };
          }

          if (cne.firstWithNoWidth != null) {
            numNotationsOnLine--;
            continue;
          }

          if (lastTranslationTextWithEndNeume != null) {
            numNotationsOnLine--;
            if (cne == lastTranslationTextWithEndNeume) {
              lastTranslationTextWithEndNeume = null;
            }
            continue;
          }

          if (curr case Neume(:final notes)
              when (notes.first.shape == NoteShape.quilisma ||
                  curr.notes.first.shape == NoteShape.inclinatum)) {
            numNotationsOnLine--;
            continue;
          }

          if (countSyllables < ctxt.minSyllablesLastLine &&
              countNotes < ctxt.minNotesLastLine) {
            numNotationsOnLine--;
            continue;
          }

          if ((cne as dynamic).keepWithNext == true) {
            if ((cne as dynamic).allowLineBreakBeforeNext &&
                maxNumNotationsOnLine == null) {
              maxNumNotationsOnLine = numNotationsOnLine;
            }
            numNotationsOnLine--;
          } else {
            break;
          }
        }
        if (extraTextOnlyIndex != null &&
            (notationsStartIndex + numNotationsOnLine) <= extraTextOnlyIndex!) {
          extraTextOnlyIndex = null;
        }

        if (numNotationsOnLine == 0) numNotationsOnLine = 1;

        curr = findNeumesToJustify(prevLyrics)!;
        lastLyrics = prevLyrics;
        if (maxNumNotationsOnLine != null) {
          double extraSpace = getWhitespaceOnRight(ctxt);
          if (extraSpace / (toJustify.length) >
              ctxt.staffInterval * ctxt.maxExtraSpaceInStaffIntervals) {
            LyricArray.mergeInArray(
              prevLyrics,
              notations.sublist(
                notationsStartIndex + numNotationsOnLine,
                notationsStartIndex + maxNumNotationsOnLine!,
              ),
            );
            numNotationsOnLine = maxNumNotationsOnLine!;
            maxNumNotationsOnLine = null;
          }
        }

        final next = (extraTextOnlyIndex == null)
            ? notations[notationsStartIndex + numNotationsOnLine]
            : notations[extraTextOnlyIndex!];
        if (next.hasLyrics &&
            (next.lyrics[0].lyricType == LyricType.beginningSyllable ||
                next.lyrics[0].lyricType == LyricType.singleSyllable)) {
          toJustify.add(next);
        }

        if (j >= 1 && notations[j] is Divider && notations[j - 1] is Custos) {
          prevLyrics = [];
          for (int k = j - 2; k >= notationsStartIndex; k--) {
            if (notations[k].hasLyrics) {
              LyricArray.mergeIn(prevLyrics, notations[k].lyrics);
              break;
            }
          }
          condensableSpaces.removeLast();
          condensableSpaces.removeLast();
          positionNotationElement(
            ctxt,
            prevLyrics,
            notations[j - 2],
            notations[j],
            staffRight,
            condensableSpaces,
          );
          custos = notations[j - 1] as Custos;
          custos!.bounds = custos!.bounds.copyWith(
            x: staffRight - custos!.bounds.width - custos!.leadingSpace,
          );
        }

        break;
      }

      if (curr.hasLyrics) LyricArray.mergeIn(lastLyrics, curr.lyrics);

      if (lastTranslationTextWithEndNeume != null &&
          curr ==
              (lastTranslationTextWithEndNeume as dynamic)
                  .translationText[0]
                  .endNeume) {
        lastTranslationTextWithEndNeume = null;
      } else if (curr.translationText.isNotEmpty &&
          curr.translationText.first.endNeume != null) {
        lastTranslationTextWithEndNeume = curr;
      }

      curr.line = this;
      numNotationsOnLine++;

      if (curr is Clef) ctxt.activeClef = curr;

      if (curr is ChantLineBreak && width > 0) {
        justify =
            curr.justify ||
            extraTextOnlyIndex != null ||
            getWhitespaceOnRight(ctxt) < 0;
        if (justify) findNeumesToJustify(prevLyrics);
        break;
      }

      if (curr is Custos) {
        custos = curr;
      } else if (curr is Neume) {
        custos = null;
      }
    }

    int lastIndexFinal = notationsStartIndex + numNotationsOnLine - 1;
    dynamic last = (lastIndexFinal >= 0 && lastIndexFinal < notations.length)
        ? notations[lastIndexFinal]
        : null;
    while (lastIndexFinal > 0 &&
        (last is ChantLineBreak || last is Custos || last is TextOnly)) {
      last = notations[--lastIndexFinal];
    }
    bool isLastLine =
        notationsStartIndex + numNotationsOnLine == notations.length;
    if ((justify && extraTextOnlyIndex != null) || (width > 0 && isLastLine)) {
      if (toJustify.isEmpty) findNeumesToJustify(prevLyrics);
      justify =
          (!isLastLine || last is Divider) &&
          getWhitespaceOnRight(ctxt) /
                  (toJustify.isNotEmpty ? toJustify.length : 1) <=
              ctxt.staffInterval * ctxt.maxExtraSpaceInStaffIntervals;
    }

    if (custos == null) {
      for (
        int i = notationsStartIndex + numNotationsOnLine;
        i < notations.length;
        i++
      ) {
        final notation = notations[i];

        if (notation is Neume) {
          custos = Custos(auto: true);
          ctxt.currNotationIndex = i - 1;
          custos!.performLayout(ctxt);

          if (justify) {
            custos!.bounds = custos!.bounds.copyWith(
              x: staffRight - custos!.bounds.width - custos!.leadingSpace,
            );
          } else {
            custos!.bounds = custos!.bounds.copyWith(
              x: prevNeume!.bounds.right + prevNeume.calculatedTrailingSpace,
            );
          }
          break;
        }
      }
    }

    if (lastLyricsBeforeTextOnly != null) {
      lastLyrics = lastLyricsBeforeTextOnly!.toList();
      lastLyricsBeforeTextOnly = null;
    }

    if (width > 0) {
      double whitespace = getWhitespaceOnRight(ctxt);
      double rightEdge = staffRight;
      if (whitespace < 0) {
        rightEdge -= whitespace;
      }
      int iLyric = 0;
      while (lastLyrics.isNotEmpty && iLyric < lastLyrics.length) {
        final lyrics = lastLyrics[iLyric];
        if (lyrics.allowsConnector()) {
          lyrics.setNeedsConnector(true, 0);
          if (width > 0 && ctxt.minLyricWordSpacing < ctxt.hyphenWidth) {
            double whitespaceLyric = rightEdge - lyrics.getRight();
            if (whitespaceLyric < 0) {
              double minHyphenWidth = (lastLyrics.length > 1)
                  ? ctxt.intraNeumeSpacing
                  : ctxt.minLyricWordSpacing;
              lyrics.setConnectorWidth(minHyphenWidth);
            }
          }
        }
        iLyric++;
      }
    }

    if (width <= 0) {
      final lastNotation =
          (notationsStartIndex + numNotationsOnLine - 1 >= 0 &&
              notationsStartIndex + numNotationsOnLine - 1 < notations.length)
          ? notations[notationsStartIndex + numNotationsOnLine - 1]
          : null;
      if (lastNotation != null) {
        staffRight = lastNotation.bounds.right;
      }
      justify = false;
    }

    justifyElements(ctxt, justify, condensableSpaces);
    centerDividers();

    if (width > 0 && isLastLine && score.extendLastSystemStaffLines != true) {
      final lastNotation =
          (notationsStartIndex + numNotationsOnLine - 1 >= 0 &&
              notationsStartIndex + numNotationsOnLine - 1 < notations.length)
          ? notations[notationsStartIndex + numNotationsOnLine - 1]
          : null;
      if (lastNotation != null) {
        staffRight = lastNotation.bounds.right;
      }
    }

    finishLayout(ctxt);
  }

  void centerDividers() {
    int lastIndex = extraTextOnlyIndex == null
        ? notationsStartIndex + numNotationsOnLine
        : extraTextOnlyIndex!;
    ChantNotationElement curr;
    for (int i = notationsStartIndex; i < lastIndex; i++) {
      curr = score.notations[i];

      if (curr is Divider) {
        var prev = score.notations[i - 1];
        final next = (i + 1 == lastIndex) ? custos : score.notations[i + 1];
        if (prev == next && next == custos) {
          prev = score.notations[i - 2];
          next!.bounds = next.bounds.copyWith(
            x: staffRight - next.bounds.width,
          );
        }
        if (next != null) {
          final oldBoundsX = curr.bounds.x;
          final barWidth = curr.bounds.width;
          double leftPoint = (prev is TextOnly && prev.hasLyrics)
              ? prev.lyrics[0].getRight()
              : prev.bounds.right;
          double rightPoint = (next is TextOnly && next.hasLyrics)
              ? next.lyrics[0].getLeft()
              : next.bounds.x;
          if (prev is TextOnly) {
            final prevNonText = score.notations
                .sublist(notationsStartIndex, i)
                .reversed
                .where((notation) => notation is! TextOnly)
                .firstOrNull;
            leftPoint = prevNonText != null ? prevNonText.bounds.right : 0;
          }
          if (leftPoint != 0) {
            curr.bounds = curr.bounds.copyWith(
              x: (leftPoint + rightPoint - barWidth) / 2,
            );
          }
          if (curr.hasLyrics) {
            final offset = oldBoundsX - curr.bounds.x;
            for (int j = curr.lyrics.length - 1; j >= 0; j--) {
              curr.lyrics[j].bounds = curr.lyrics[j].bounds.copyWith(
                x: curr.lyrics[j].bounds.x + offset,
              );
              curr.lyrics[j].needsLayout = true;
            }
          }
        } else if (i == lastIndex - 1 &&
            justify &&
            (curr is DoubleBar || curr is FullBar)) {
          curr.bounds = curr.bounds.copyWith(x: staffRight - curr.bounds.width);
        }
      }
    }
  }

  ChantNotationElement? findNeumesToJustify(List<Lyric> prevLyrics) {
    toJustify = [];
    ChantNotationElement? prev;
    ChantNotationElement curr;
    ChantNotationElement? next;
    ChantNotationElement? nextOrCurr;
    int lastIndex = notationsStartIndex + numNotationsOnLine;
    for (int i = notationsStartIndex; i < lastIndex; i++) {
      prev = nextOrCurr;
      curr = score.notations[i];
      next = (curr is Accidental && i + 1 < score.notations.length)
          ? score.notations[i + 1]
          : null;
      if (next != null) i++;
      nextOrCurr = next ?? curr;
      final hasLyrics = nextOrCurr.hasLyrics;

      if (prev == null) continue;

      if (extraTextOnlyIndex != null &&
          i >= extraTextOnlyIndex! &&
          curr is TextOnly) {
        continue;
      }

      LyricArray.mergeIn(prevLyrics, prev.lyrics);
      if (prev.keepWithNext == true) continue;

      if (curr is! Divider &&
          prevLyrics.isNotEmpty &&
          prevLyrics[0].allowsConnector() &&
          hasLyrics) {
        continue;
      }

      if (nextOrCurr is ChantLineBreak) continue;

      if (nextOrCurr == custos && !hasLyrics) continue;

      if (i == 0 && score.useDropCap && hasLyrics) continue;

      toJustify.add(curr);
    }
    if (nextOrCurr != null) LyricArray.mergeIn(prevLyrics, nextOrCurr.lyrics);
    return nextOrCurr;
  }

  double getWhitespaceOnRight(ChantContext ctxt) {
    final notations = score.notations;
    int lastIndex = notationsStartIndex + numNotationsOnLine;
    ChantNotationElement? last =
        (lastIndex > 0 && lastIndex <= notations.length)
        ? notations[lastIndex - 1]
        : null;
    if (extraTextOnlyIndex != null && last is TextOnly) {
      lastIndex = extraTextOnlyIndex!;
      last = (lastIndex > 0 && lastIndex <= notations.length)
          ? notations[lastIndex - 1]
          : null;
    }
    double lastRightNeume = last != null
        ? last.bounds.right + last.calculatedTrailingSpace
        : 0;
    final lastLyrics = lastLyricsBeforeTextOnly ?? this.lastLyrics;
    double lastRightLyric = lastLyrics.isNotEmpty
        ? LyricArray.getRight(lastLyrics)
        : 0;

    if (custos != null) {
      lastRightNeume += custos!.bounds.width + (custos as dynamic).leadingSpace;
      if (custos!.hasLyrics) {
        lastRightLyric = LyricArray.getRight(custos!.lyrics);
      }
    } else if (lastIndex < notations.length) {
      lastRightNeume +=
          glyphs[GlyphCode.custosLong]!.bounds.width * ctxt.glyphScaling;
    }
    return staffRight -
        (lastRightLyric > lastRightNeume ? lastRightLyric : lastRightNeume);
  }

  void justifyElements(
    ChantContext ctxt,
    bool doJustify,
    List<dynamic> condensableSpaces,
  ) {
    int i;
    var toJustify = this.toJustify;
    final notations = score.notations;
    final lastIndex = notationsStartIndex + numNotationsOnLine;

    final lastNotation =
        (notationsStartIndex + numNotationsOnLine - 1 >= 0 &&
            notationsStartIndex + numNotationsOnLine - 1 < notations.length)
        ? notations[notationsStartIndex + numNotationsOnLine - 1]
        : null;
    double extraSpaceBeforeCustos = 0;
    if (staffRight < double.infinity &&
        custos != null &&
        (lastNotation?.keepWithNext ?? false) &&
        custos!.bounds.x -
                lastNotation!.bounds.right -
                lastNotation.calculatedTrailingSpace >
            0) {
      extraSpaceBeforeCustos =
          custos!.bounds.x -
          lastNotation.bounds.right -
          lastNotation.calculatedTrailingSpace;
    }
    if (extraSpaceBeforeCustos > 0) {
      i = 0;
      while (lastLyrics.isNotEmpty && i < lastLyrics.length) {
        final lyrics = lastLyrics[i];
        if (lyrics.allowsConnector()) {
          final connectorWidth = lyrics.getConnectorWidth();
          if (ctxt.minLyricWordSpacing < connectorWidth) {
            double minHyphenWidth = (lastLyrics.length > 1)
                ? ctxt.intraNeumeSpacing
                : ctxt.minLyricWordSpacing;
            lyrics.setConnectorWidth(
              (connectorWidth - extraSpaceBeforeCustos > minHyphenWidth)
                  ? connectorWidth - extraSpaceBeforeCustos
                  : minHyphenWidth,
            );
          }
        }
        i++;
      }
      custos!.bounds = custos!.bounds.copyWith(
        x: lastNotation!.bounds.right + lastNotation.calculatedTrailingSpace,
      );
    }

    final extraSpace = getWhitespaceOnRight(ctxt);

    if (extraSpace.abs() < 0.5 ||
        (extraSpace > 0 && ((doJustify && toJustify.isEmpty) || !doJustify))) {
      return;
    }

    this.condensableSpaces = condensableSpaces;

    ChantNotationElement? curr;
    ChantNotationElement? prev;
    double offset = 0;
    double increment = extraSpace / toJustify.length;
    double multiplier = 0;
    int toJustifyIndex = 0;
    if (extraSpace < 0) {
      toJustify = condensableSpaces
          .where((s) => (s as dynamic).condensable > 0)
          .toList();
      multiplier =
          extraSpace /
          (condensableSpaces.fold(
            0.0,
            (sum, s) => sum + (s as dynamic).condensable,
          ));
      increment = 0;
    }
    dynamic nextToJustify = (toJustifyIndex < toJustify.length)
        ? toJustify[toJustifyIndex++]
        : null;
    bool incrementOffsetAtNextChance = false;
    for (i = notationsStartIndex; i < lastIndex; i++) {
      prev = curr;
      curr = notations[i];

      if (extraTextOnlyIndex != null &&
          i >= extraTextOnlyIndex! &&
          curr is TextOnly) {
        continue;
      }

      if (multiplier == 0 && curr == custos) {
        if (curr.hasLyrics) {
          curr.bounds = curr.bounds.copyWith(
            x:
                (curr.bounds.x +
                        (staffRight - LyricArray.getRight(curr.lyrics)) <
                    staffRight - curr.bounds.width)
                ? curr.bounds.x +
                      (staffRight - LyricArray.getRight(curr.lyrics))
                : staffRight - curr.bounds.width,
          );
          offset += increment;
        } else {
          curr.bounds = curr.bounds.copyWith(
            x: (curr.bounds.x + offset < staffRight - curr.bounds.width)
                ? curr.bounds.x + offset
                : staffRight - curr.bounds.width,
          );
        }
        continue;
      }

      if (multiplier != 0) {
        if (nextToJustify != null && nextToJustify.notation == curr) {
          offset += multiplier * nextToJustify.condensable;
          nextToJustify = (toJustifyIndex < toJustify.length)
              ? toJustify[toJustifyIndex++]
              : null;
        }
      } else if (nextToJustify == curr) {
        if (prev!.hasNoWidth) {
          incrementOffsetAtNextChance = true;
        } else {
          offset += increment;
        }
        nextToJustify = (toJustifyIndex < toJustify.length)
            ? toJustify[toJustifyIndex++]
            : null;
      } else if (incrementOffsetAtNextChance && !prev!.hasNoWidth) {
        incrementOffsetAtNextChance = false;
        offset += increment;
      }

      curr.bounds = curr.bounds.copyWith(x: curr.bounds.x + offset);
    }

    if (extraSpaceBeforeCustos > 0) {
      custos!.bounds = custos!.bounds.copyWith(
        x: lastNotation!.bounds.right + lastNotation.calculatedTrailingSpace,
      );
    }
  }

  void handleEndBrace(ChantContext ctxt, dynamic note, int i) {
    final startBrace = ctxt.lastStartBrace;
    if (startBrace == null) return;

    double y;
    final k = startBrace.notationIndex;
    final notations = score.notations;
    final dy = ctxt.intraNeumeSpacing / 2;
    final startNote = startBrace.note;

    if (startBrace.isAbove) {
      y =
          (ctxt.calculateHeightFromStaffPosition(score.staffLineCount * 2) <
              [
                startNote,
                note,
                ...notations.sublist(k, i + 1).map((n) => n.bounds.y - dy),
              ].reduce((a, b) => a < b ? a : b))
          ? ctxt.calculateHeightFromStaffPosition(score.staffLineCount * 2)
          : [
              startNote,
              note,
              ...notations.sublist(k, i + 1).map((n) => n.bounds.y - dy),
            ].reduce((a, b) => a < b ? a : b);
    } else {
      y =
          (ctxt.calculateHeightFromStaffPosition(0) >
              [
                startNote,
                note,
                ...notations.sublist(k, i + 1).map((n) => n.bounds.bottom + dy),
              ].reduce((a, b) => a > b ? a : b))
          ? ctxt.calculateHeightFromStaffPosition(0)
          : [
              startNote,
              note,
              ...notations.sublist(k, i + 1).map((n) => n.bounds.bottom + dy),
            ].reduce((a, b) => a > b ? a : b);
    }

    bool addAcuteAccent = false;

    if (startBrace.shape == BraceShape.roundBrace) {
      braces.add(
        RoundBraceVisualizer(
          ctxt,
          startBrace.getAttachmentX(startNote as Note),
          note.braceEnd.getAttachmentX(note),
          y,
          startBrace.isAbove,
        ),
      );
    } else {
      if (startBrace.shape == BraceShape.accentedCurlyBrace) {
        addAcuteAccent = true;
      }

      braces.add(
        CurlyBraceVisualizer(
          ctxt,
          startBrace.getAttachmentX(startNote as Note),
          note.braceEnd.getAttachmentX(note),
          y,
          startBrace.isAbove,
          addAcuteAccent,
        ),
      );
    }

    ctxt.lastStartBrace = null;
  }

  void finishLayout(ChantContext ctxt) {
    ledgerLines = [];

    final notations = score.notations;
    final lastIndex = notationsStartIndex + numNotationsOnLine;

    void processElementForLedgerLine(
      ChantLayoutElement element, {
      Note? endElem,
      int? staffPosition,
      double? offsetX,
    }) {
      final sp = staffPosition ?? (element as dynamic).staffPosition;
      final ox = offsetX ?? (element is Note ? element.neume!.bounds.x : 0);
      final ee = endElem ?? element;

      final ledgerLinePositionAbove = ctxt.staffLineCount * 2 + 1;
      if (sp >= ledgerLinePositionAbove || sp <= -1) {
        var x1 = ox + element.bounds.x - ctxt.intraNeumeSpacing;
        final x2 = ox + ee.bounds.x + ee.bounds.width + ctxt.intraNeumeSpacing;

        int roundedStaffPosition = sp;
        if (sp > 0) {
          roundedStaffPosition = sp - ((sp - 1) % 2);
        } else {
          roundedStaffPosition = sp - ((sp + 1) % 2);
        }

        final minLedgerSeparation =
            ctxt.staffInterval * ctxt.minLedgerSeparation;

        if (ledgerLines.isNotEmpty &&
            ledgerLines.last.x2 + minLedgerSeparation >= x1) {
          final half = (x1 - ledgerLines.last.x2) / 2;
          ledgerLines.last.x2 += half;
          x1 -= half;
        }

        double finalX2 = x2;
        if (finalX2 > staffRight) finalX2 = staffRight;

        ledgerLines.add(LedgerLinePos(x1, finalX2, roundedStaffPosition));
      }
    }

    List<HorizontalEpisema> episemata = [];
    BracePoint? startBrace;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    void positionNonLyricText(
      TextElement text,
      ChantNotationElement neume, {
      double? rightX,
    }) {
      text.setMaxWidth(ctxt, staffRight);
      text.bounds = text.bounds.copyWith(x: 0);
      if (rightX != null) {
        text.bounds = text.bounds.copyWith(
          x: (text.bounds.x + rightX - text.bounds.width) / 2,
        );
      }
      final beyondStaffRight = neume.bounds.x + text.bounds.right - staffRight;
      if (beyondStaffRight > 0) {
        text.bounds = text.bounds.copyWith(x: text.bounds.x - beyondStaffRight);
      }
      if (neume.bounds.x + text.bounds.x < 0) {
        text.bounds = text.bounds.copyWith(x: -neume.bounds.x);
      }
    }

    int i; // TODO: clean up if(startBrace...) section
    for (i = notationsStartIndex; i < lastIndex; i++) {
      final neume = notations[i];

      minY = (minY < neume.bounds.y) ? minY : neume.bounds.y;
      maxY = (maxY > neume.bounds.bottom) ? maxY : neume.bounds.bottom;

      if (neume is Custos) {
        processElementForLedgerLine(neume);
        continue;
      }

      if (neume.alText.isNotEmpty) {
        for (int j = 0; j < neume.alText.length; j++) {
          positionNonLyricText(neume.alText[j], neume);
        }
      }

      if (neume.translationText.isNotEmpty) {
        for (int j = 0; j < neume.translationText.length; j++) {
          final text = neume.translationText[j];
          if (text.endNeume != null) {
            double rightX = (text.endNeume!.hasLyrics)
                ? text.endNeume!.bounds.x +
                      text.endNeume!.lyrics
                          .map((l) => l.bounds.right)
                          .reduce(math.max)
                : text.endNeume!.bounds.right;
            rightX -= neume.bounds.x;
            positionNonLyricText(text, neume, rightX: rightX);
          } else {
            positionNonLyricText(text, neume);
          }
        }
      }

      if (neume is! Neume) continue;

      for (int j = 0; j < neume.ledgerLines.length; j++) {
        final ll = neume.ledgerLines[j];
        processElementForLedgerLine(
          ll.element,
          endElem: ll.endElem,
          staffPosition: ll.staffPosition,
        );
      }

      for (int j = 0; j < neume.notes.length; j++) {
        final note = neume.notes[j];

        if (note.episemata.isEmpty) episemata = [];
        for (int k = 0; k < note.episemata.length; k++) {
          final episema = note.episemata[k];

          double spaceBetweenEpisemata = 0;

          if (episemata.isNotEmpty) {
            spaceBetweenEpisemata =
                neume.bounds.x +
                episema.bounds.x -
                (episemata.last.note.neume!.bounds.x +
                    episemata.last.bounds.right);
          }

          if (episemata.isEmpty ||
              episemata.last.positionHint != episema.positionHint ||
              episemata.last.terminating == true ||
              episemata.last.alignment == HorizontalEpisemaAlignment.left ||
              episemata.last.alignment == HorizontalEpisemaAlignment.center ||
              episema.alignment == HorizontalEpisemaAlignment.right ||
              episema.alignment == HorizontalEpisemaAlignment.center ||
              (spaceBetweenEpisemata > ctxt.intraNeumeSpacing * 2 &&
                  note.glyphVisualizer!.glyphCode != GlyphCode.none)) {
            episemata = [episema];
          } else {
            double newY;

            if (episema.positionHint == MarkingPositionHint.below) {
              newY = (episema.bounds.y > episemata.last.bounds.y)
                  ? episema.bounds.y
                  : episemata.last.bounds.y;
            } else {
              newY = (episema.bounds.y < episemata.last.bounds.y)
                  ? episema.bounds.y
                  : episemata.last.bounds.y;
            }

            if (episema.bounds.y != newY) {
              episema.bounds = episema.bounds.copyWith(y: newY);
            } else {
              for (int l = 0; l < episemata.length; l++) {
                episemata[l].bounds = episemata[l].bounds.copyWith(y: newY);
              }
            }

            double newWidth =
                neume.bounds.x +
                episema.bounds.x -
                (episemata.last.note.neume!.bounds.x + episemata.last.bounds.x);
            if (newWidth < 0) {
              newWidth *= -1;
              episemata.last.bounds = episemata.last.bounds.copyWith(
                x: episemata.last.bounds.x - newWidth,
              );
            }
            episemata.last.bounds = episemata.last.bounds.copyWith(
              width: newWidth,
            );

            episemata.add(episema);
          }
        }

        if (note.braceEnd != null) handleEndBrace(ctxt, note, i);

        if (note.braceStart != null) {
          ctxt.lastStartBrace = startBrace = note.braceStart;
          startBrace!.notationIndex = i;
        }
      }
    }

    if (startBrace != null) {
      if (custos != null) {
        final nextNotation = notations[lastIndex];
        final nextNote = (nextNotation is Neume) ? nextNotation.notes[0] : null;
        final nextNotationButOne = (lastIndex + 1 < notations.length)
            ? notations[lastIndex + 1]
            : null;
        final nextNoteButOne = (nextNotationButOne is Neume)
            ? nextNotationButOne.notes[0]
            : null;
        final braceEnd =
            (nextNote?.braceEnd) ??
            (nextNotation is Accidental ? nextNoteButOne?.braceEnd : null);
        if (braceEnd != null) {
          custos!.braceEnd = braceEnd;
          handleEndBrace(ctxt, custos!, i);
        } else {
          custos!.braceEnd = BracePoint(
            custos!,
            startBrace.isAbove,
            startBrace.shape,
            BraceAttachment.right,
          );
          handleEndBrace(ctxt, custos!, i - 1);
          ctxt.lastStartBrace = BracePoint(
            null,
            startBrace.isAbove,
            startBrace.shape,
            BraceAttachment.left,
          );
          (ctxt.lastStartBrace as dynamic).notationIndex = i;
        }
      }
    }

    if (custos != null) processElementForLedgerLine(custos!);
  }

  bool positionNotationElement(
    ChantContext ctxt,
    List<dynamic> prevLyrics,
    ChantNotationElement prev,
    ChantNotationElement curr,
    double rightNotationBoundary, [
    List<dynamic>? condensableSpaces,
  ]) {
    final spaces = condensableSpaces ?? <dynamic>[];
    if (spaces.sum == 0 && spaces.isEmpty) {
      spaces.sum = 0;
    }

    int i;
    final space = _CondensableSpace(notation: curr);
    bool fixedX = false;

    if ((curr.hasNoWidth == false || curr.firstWithNoWidth == curr) &&
        prev.firstWithNoWidth != null) {
      curr.bounds = curr.bounds.copyWith(x: prev.firstWithNoWidth!.bounds.x);
      fixedX = true;
    } else {
      curr.bounds = curr.bounds.copyWith(x: prev.bounds.right);
    }

    if ((curr is TextOnly && extraTextOnlyIndex == null) ||
        (!curr.hasLyrics && prev.calculatedTrailingSpace < 0)) {
      curr.calculatedTrailingSpace = prev.calculatedTrailingSpace;
      if (curr.hasLyrics) {
        curr.calculatedTrailingSpace -= curr.lyrics[0].bounds.width;
      }
      if (curr is TextOnly && curr.lyrics.length == 1) {
        curr.lyrics[0].setMaxWidth(
          ctxt,
          staffRight,
          staffRight -
              LyricArray.getRight(prevLyrics) -
              ctxt.minLyricWordSpacing,
        );
      }
    } else if (!fixedX) {
      curr.bounds = curr.bounds.copyWith(
        x: curr.bounds.x + prev.calculatedTrailingSpace,
      );
    }

    if (curr.hasLyrics &&
        prev is! Divider &&
        prev is! Accidental &&
        numNotationsOnLine > 0 &&
        (curr.lyrics[0].lyricType == LyricType.singleSyllable ||
            curr.lyrics[0].lyricType == LyricType.beginningSyllable)) {
      curr.bounds = curr.bounds.copyWith(
        x: curr.bounds.x + ctxt.intraNeumeSpacing * ctxt.interVerbalMultiplier,
      );
    }

    if (curr.hasNoWidth || fixedX) {
      space.total = 0;
      space.condensable = 0;
    } else if (extraTextOnlyIndex != null && curr is TextOnly) {
      curr.bounds = curr.bounds.copyWith(x: 0);
      space.total = 0;
      space.condensable = 0;
    } else {
      space.total = curr.bounds.x - prev.bounds.right;
      space.condensable = space.total * ctxt.condensingTolerance;
    }

    if (prevLyrics.isEmpty) {
      double maxRight = curr.bounds.right + curr.calculatedTrailingSpace;
      for (i = 0; i < curr.lyrics.length; i++) {
        final currLyric = curr.lyrics[i];
        bool needsConnector =
            currLyric.allowsConnector() &&
            currLyric.dropCap != null &&
            currLyric.originalText.isNotEmpty &&
            currLyric.text.isEmpty;
        currLyric.setNeedsConnector(needsConnector);
        final minLeft = staffLeft - paddingLeft;
        if (currLyric.getLeft() < minLeft) {
          curr.bounds = curr.bounds.copyWith(
            x: curr.bounds.x - currLyric.getLeft() - minLeft,
          );
        }
        space.condensable = math.min(
          space.condensable,
          currLyric.getLeft() - minLeft,
        );
        maxRight = math.max(maxRight, currLyric.getRight());
      }

      if (maxRight > rightNotationBoundary + spaces.sum + space.condensable) {
        return false;
      }
      spaces.add(space);
      spaces.sum += space.condensable;
      return true;
    } else {
      if (curr.firstOfSyllable != null &&
          prevLyrics.isNotEmpty &&
          !curr.hasLyrics) {
        curr.bounds = curr.bounds.copyWith(
          x: math.max(curr.bounds.x, prevLyrics[0].getRight()),
        );
        space.total = curr.bounds.x - prev.bounds.right;
        space.condensable = space.total * ctxt.condensingTolerance;
      }
    }

    if (!curr.hasLyrics) {
      if (curr.bounds.right + curr.calculatedTrailingSpace >
          rightNotationBoundary + spaces.sum + space.condensable) {
        return false;
      }
      spaces.add(space);
      spaces.sum += space.condensable;
      return true;
    }

    bool hasShifted;
    bool atLeastOneWithoutConnector;
    do {
      hasShifted = false;
      atLeastOneWithoutConnector = false;
      for (i = 0; i < curr.lyrics.length; i++) {
        if (curr.lyrics[i].originalText.isEmpty) continue;
        double prevLyricRight = 0;
        List<dynamic> condensableSpacesSincePrevLyric = [];
        double condensableSpaceSincePrevLyric = 0;
        if (i < prevLyrics.length && prevLyrics[i] != null) {
          prevLyricRight = prevLyrics[i].getRight();
          final notationI = spaces
              .map((s) => s.notation)
              .toList()
              .lastIndexOf(prevLyrics[i].notation);
          if (notationI >= 0) {
            condensableSpacesSincePrevLyric = spaces
                .sublist(notationI + 1)
                .cast<dynamic>();
            condensableSpaceSincePrevLyric = condensableSpacesSincePrevLyric
                .fold(0.0, (sum, s) => sum + s.condensable);
          } else {
            condensableSpaceSincePrevLyric = 0;
          }
        }

        curr.lyrics[i].setNeedsConnector(false);
        final currLyricLeft = curr.lyrics[i].getLeft();
        if (prevLyrics[i] == null || prevLyrics[i].allowsConnector() == false) {
          final extraSpace =
              currLyricLeft - prevLyricRight - ctxt.minLyricWordSpacing;
          if (extraSpace < 0) {
            final shift =
                prevLyricRight + ctxt.minLyricWordSpacing - currLyricLeft;
            curr.bounds = curr.bounds.copyWith(x: curr.bounds.x + shift);
            condensableSpaceSincePrevLyric = 0;
            hasShifted = shift > 0.5;
          } else {
            condensableSpaceSincePrevLyric = extraSpace;
          }
        } else {
          if (prevLyricRight + 0.1 >
              currLyricLeft -
                  condensableSpaceSincePrevLyric -
                  space.condensable) {
            final shift = prevLyricRight - currLyricLeft;
            if (shift < -0.1) {
              final multiplier =
                  shift / (condensableSpaceSincePrevLyric + space.condensable);
              double offset = 0;
              for (final s in condensableSpacesSincePrevLyric) {
                offset += multiplier * s.condensable;
                s.notation.bounds.x += offset;
              }
            }
            curr.bounds = curr.bounds.copyWith(x: curr.bounds.x + shift);
            condensableSpaceSincePrevLyric = 0;
            atLeastOneWithoutConnector = true;
            hasShifted = shift > 0.5;
          } else {
            if (ctxt.minLyricWordSpacing < ctxt.hyphenWidth) {
              final spaceBetweenSyls = currLyricLeft - prevLyricRight;
              if (spaceBetweenSyls < ctxt.hyphenWidth) {
                final minHyphenWidth = prevLyrics.length > 1
                    ? ctxt.intraNeumeSpacing
                    : ctxt.minLyricWordSpacing;
                prevLyrics[i].setConnectorWidth(
                  math.max(minHyphenWidth, spaceBetweenSyls),
                );
              }
            }
            prevLyrics[i].setNeedsConnector(true);
            prevLyricRight = prevLyrics[i].getRight();
            if (prevLyricRight + 0.1 > currLyricLeft) {
              final shift = prevLyricRight - currLyricLeft;
              curr.bounds = curr.bounds.copyWith(x: curr.bounds.x + shift);
              condensableSpaceSincePrevLyric = 0;
              hasShifted = shift > 0.5;
            } else {
              condensableSpaceSincePrevLyric = currLyricLeft - prevLyricRight;
            }
          }
        }

        if (condensableSpaceSincePrevLyric != 0) {
          final previousCondensableSpaceSum = condensableSpacesSincePrevLyric
              .fold(0.0, (sum, s) => sum + s.condensable);
          if (condensableSpaceSincePrevLyric <
              previousCondensableSpaceSum + space.condensable) {
            final multiplier =
                condensableSpaceSincePrevLyric /
                (previousCondensableSpaceSum + space.condensable);
            space.condensable *= multiplier;
            if (condensableSpacesSincePrevLyric.isNotEmpty) {
              for (final s in condensableSpacesSincePrevLyric) {
                s.condensable *= multiplier;
              }
              spaces.sum = spaces
                  .map((s) => s.condensable)
                  .fold(0.0, (a, b) => a + b);
            }
          }
        }
      }
    } while (curr.lyrics.length > 1 &&
        hasShifted &&
        atLeastOneWithoutConnector);

    for (i = math.min(curr.lyrics.length, prevLyrics.length) - 1; i >= 0; i--) {
      final pLyrics = prevLyrics[i];
      if (pLyrics != null &&
          pLyrics.needsConnector &&
          pLyrics.connectorWidth != null) {
        final currLyricLeft = curr.lyrics[i].getLeft();
        final prevLyricRight = pLyrics.getRight() - pLyrics.connectorWidth!;
        double spaceBetweenSyls = currLyricLeft - prevLyricRight;
        if (spaceBetweenSyls >= ctxt.hyphenWidth) {
          spaceBetweenSyls = 0;
        }
        pLyrics.setConnectorWidth(spaceBetweenSyls);
      }
    }

    if (curr.bounds.right + curr.calculatedTrailingSpace <
            rightNotationBoundary + spaces.sum + space.condensable &&
        LyricArray.getRight(curr.lyrics, true) <=
            staffRight + spaces.sum + space.condensable) {
      if (prev is Accidental) {
        final shift =
            curr.bounds.x -
            prev.bounds.width -
            prev.calculatedTrailingSpace -
            prev.bounds.x;
        prev.bounds = prev.bounds.copyWith(x: prev.bounds.x + shift);
        if (shift.abs() > 0.1) {
          final lastCondensable = spaces[spaces.length - 1];
          spaces.sum -= lastCondensable.condensable;
          lastCondensable.condensable = 0;
        }
      }
      spaces.add(space);
      spaces.sum += space.condensable;
      return true;
    }

    return false;
  }

  dynamic bisectNotationAtX(double x, {bool useMidpoint = true}) {
    int minIndex = -1;
    int maxIndex = (numNotationsOnLine < double.infinity)
        ? numNotationsOnLine
        : 0;
    int curIndex = minIndex + ((maxIndex - minIndex) >> 1);
    final notations = score.notations.sublist(
      notationsStartIndex,
      notationsStartIndex + numNotationsOnLine,
    );

    while (minIndex < curIndex) {
      final notation = notations[curIndex];
      final notationX = notation.bounds.x;
      if (notationX > x) {
        maxIndex = curIndex;
      } else {
        minIndex = curIndex;
      }
      curIndex = minIndex + ((maxIndex - minIndex) >> 1);
    }
    final notation = notations[curIndex];
    if (useMidpoint &&
        notation.bounds.width == 0 &&
        curIndex + 1 < notations.length) {
      final nextNotation = notations[curIndex + 1];
      final closenessToLeft = x - notation.bounds.x;
      final closenessToRight = nextNotation.bounds.x - x;
      if (closenessToRight < closenessToLeft) {
        curIndex++;
      }
    }
    return notation;
  }
}

class LedgerLinePos {
  double x1;
  double x2;
  int staffPosition;

  LedgerLinePos(this.x1, this.x2, this.staffPosition);
}
