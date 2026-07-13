import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

import '../drawing.dart';
import '../glyphs.dart';
import '../quick_svg.dart';
import 'chant_layout_element.dart';
import 'notation/chant_notation_element.dart';
import 'notation/neumes/note.dart';

enum HorizontalEpisemaAlignment { defaultValue, left, center, right }

class HorizontalEpisema extends ChantLayoutElement {
  final Note note;
  bool terminating =
      false; // indicates if this episema should terminate itself or not
  HorizontalEpisemaAlignment alignment =
      HorizontalEpisemaAlignment.defaultValue;
  MarkingPositionHint positionHint = MarkingPositionHint.defaultHint;

  HorizontalEpisema(this.note) : super();

  void performLayout(ChantContext ctxt) {
    // following logic helps to keep the episemata away from staff lines if they get too close

    double y = 0;
    double step;
    double minDistanceAway =
        ctxt.staffInterval * 0.25; // min distance from neume
    GlyphCode glyphCode = note.glyphVisualizer!.glyphCode!;
    var ledgerLine = note.neume!.ledgerLines.isNotEmpty
        ? note.neume!.ledgerLines[0]
        : null;
    bool punctumInclinatumShorten = false;

    if (glyphCode == GlyphCode.punctumInclinatum) {
      var notes = note.neume!.notes;
      int index = notes.indexOf(note);
      var prevNote = index > 0 ? notes[index - 1] : null;
      if (prevNote != null &&
          prevNote.glyphVisualizer!.glyphCode == GlyphCode.punctumInclinatum &&
          prevNote.staffPosition - note.staffPosition == 1) {
        punctumInclinatumShorten = true;
      }
    }

    final int staffLineCountParity = (ctxt.staffLineCount % 2);
    final int staffLineCountNonParity = (staffLineCountParity + 1) % 2;

    if (positionHint == MarkingPositionHint.below) {
      y =
          note.bounds.bottom +
          minDistanceAway; // the highest the line could be at
      // convert y to be based around center Y between top and bottom staff lines so that it is symmetric:
      y += ctxt.staffLineCount * ctxt.staffInterval;

      if (glyphCode == GlyphCode.none) {
        // correction for episema under the second note of a porrectus
        y += ctxt.staffInterval / 2;
      }
      step = (y / ctxt.staffInterval).ceilToDouble();
      // if there's enough space, center the episema between the punctum and the next staff line
      if ((step.abs() % 2).toInt() == staffLineCountParity) {
        step = (step + 0.75 + (y - minDistanceAway) / ctxt.staffInterval) / 2;
      } else {
        // otherwise, find nearest acceptable third between staff lines (or staff line)
        step =
            ((1.5 * y / ctxt.staffInterval - 0.5).ceilToDouble() * 2 +
                staffLineCountNonParity) /
            3;

        // if it's an odd step, that means we're on a staff line,
        // so we shift to between the staff line
        if ((step.abs() % 2).toInt() == staffLineCountNonParity) {
          if (step.abs() < ctxt.staffLineCount ||
              (ledgerLine != null &&
                  ctxt.convertStaffPositionToSymmetric(
                        ledgerLine.staffPosition,
                      ) ==
                      -step)) {
            step += 2 / 3;
          } else {
            // no ledger line, but we don't want the episema to be at exactly the same height the ledger line would occupy:
            step += 1 / 3;
          }
        }
      }
    } else {
      y = note.bounds.y - minDistanceAway; // the lowest the line could be at
      // convert y to be based around center Y between top and bottom staff lines so that it is symmetric:
      y += ctxt.staffLineCount * ctxt.staffInterval;

      step = (y / ctxt.staffInterval).floorToDouble();
      // if there's enough space, center the episema between the punctum and the next staff line
      if ((step.abs() % 2).toInt() == staffLineCountParity) {
        step = (step - 0.75 + (y + minDistanceAway) / ctxt.staffInterval) / 2;
      } else {
        // otherwise, find nearest acceptable third between staff lines (or staff line)
        step =
            ((1.5 * y / ctxt.staffInterval - 0.5).floorToDouble() * 2 +
                staffLineCountNonParity) /
            3;

        // find nearest acceptable third between staff lines (or staff line)
        if ((step.abs() % 2).toInt() == staffLineCountNonParity) {
          // if it was a staff line, we need to adjust
          if (step.abs() < ctxt.staffLineCount ||
              (ledgerLine != null &&
                  ctxt.convertStaffPositionToSymmetric(
                        ledgerLine.staffPosition,
                      ) ==
                      -step)) {
            step -= 2 / 3;
          } else {
            // no ledger line, but we don't want the episema to be at exactly the same height the ledger line would occupy:
            step -= 1 / 3;
          }
        }
      }
    }

    y = (step - ctxt.staffLineCount) * ctxt.staffInterval;

    double width = note.bounds.width;
    double x = note.bounds.x;

    // The porrectus requires special handling of the note width,
    // otherwise the width is just that of the note itself
    if (glyphCode == GlyphCode.porrectus1 ||
        glyphCode == GlyphCode.porrectus2 ||
        glyphCode == GlyphCode.porrectus3 ||
        glyphCode == GlyphCode.porrectus4) {
      width = ctxt.staffInterval;
    } else if (glyphCode == GlyphCode.none) {
      width = ctxt.staffInterval;
      x -= width;
    } else if (punctumInclinatumShorten) {
      width *= 2 / 3;
      x += 0.5 * width;
    } else if (glyphCode == GlyphCode.punctumInclinatumLiquescent) {
      width *= 2 / 3;
      x += 0.25 * width;
    }

    // also, the position hint can affect the x/width of the episema
    if (alignment == HorizontalEpisemaAlignment.left) {
      width *= 0.8;
    } else if (alignment == HorizontalEpisemaAlignment.center) {
      x += width * 0.1;
      width *= 0.8;
    } else if (alignment == HorizontalEpisemaAlignment.right) {
      x += width * 0.2;
      width *= 0.8;
    }

    bounds = Rect.fromXYWH(
      x,
      y - ctxt.episemaLineWeight / 2,
      width,
      ctxt.episemaLineWeight,
    );

    origin = Point(0, 0);
  }

  @override
  void draw(ChantContext ctxt) {
    var canvasCtxt = ctxt.canvasCtxt;

    canvasCtxt.drawRect(
      ui.Rect.fromLTWH(bounds.x, bounds.y, bounds.width, bounds.height),
      ui.Paint()
        ..color = ctxt.neumeLineColor
        ..style = PaintingStyle.fill,
    );
  }

  Map<String, dynamic> getSvgProps(ChantContext ctxt) {
    return {
      'x': bounds.x,
      'y': bounds.y,
      'width': bounds.width,
      'height': bounds.height,
      'fill': ctxt.neumeLineColor,
      'class': 'horizontalEpisema',
    };
  }

  @override
  XmlElement createSvgNode(ChantContext ctxt, [ChantLayoutElement? source]) {
    return QuickSvg.createNode('rect', getSvgProps(ctxt));
  }

  SvgTreeNode createSvgTree(ChantContext ctxt, [ChantLayoutElement? source]) {
    return QuickSvg.createSvgTree('rect', getSvgProps(ctxt));
  }

  @override
  String createSvgFragment(ChantContext ctxt, [ChantLayoutElement? source]) {
    return QuickSvg.createFragment('rect', getSvgProps(ctxt));
  }
}
