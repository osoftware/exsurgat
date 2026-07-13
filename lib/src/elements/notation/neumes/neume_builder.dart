import '../../../drawing.dart';
import '../../../glyphs.dart';
import '../../visualizers/linea_visualizer.dart';
import '../../visualizers/neume_beam_visualizer.dart';
import '../../visualizers/neume_line_visualizer.dart';
import '../../visualizers/virga_line_visualizer.dart';
import 'neume.dart';
import 'note.dart';

class NeumeBuilder {
  final ChantContext ctxt;
  final Neume neume;
  double x;
  Note? lastNote;
  bool lineIsHanging = false;
  double minX = 0;

  NeumeBuilder(this.ctxt, this.neume, {this.x = 0});

  /// Used to start a hanging line on the left of the next note
  NeumeBuilder lineFrom(Note note) {
    final previousNotation = ctxt.currNotationIndex - 1 >= 0
        ? ctxt.notations[ctxt.currNotationIndex - 1]
        : null;
    if (x == 0 &&
        previousNotation != null &&
        previousNotation.notes != null &&
        previousNotation.trailingSpace == 0) {
      lastNote = previousNotation.notes!.last;
      minX = -ctxt.neumeLineWeight;
    } else {
      lastNote = note;
      lineIsHanging = true;
    }
    return this;
  }

  /// Add a note, with a connecting line on the left if we have one
  NeumeBuilder noteAt(Note note, GlyphCode glyph, {bool withLineTo = true}) {
    note.setGlyph(ctxt, glyph);
    final noteAlignsRight = note.glyphVisualizer!.align == 'right';

    final needsLine =
        withLineTo &&
        lastNote != null &&
        (lineIsHanging ||
            (lastNote!.glyphVisualizer != null &&
                lastNote!.glyphVisualizer!.align == 'right') ||
            (lastNote!.staffPosition - note.staffPosition).abs() > 1);

    if (needsLine) {
      final line = NeumeLineVisualizer(ctxt, lastNote!, note, lineIsHanging);
      neume.addVisualizer(line);
      line.bounds = line.bounds.copyWith(
        x: (minX > x - line.bounds.width) ? minX : x - line.bounds.width,
      );

      if (!noteAlignsRight) x = line.bounds.x;
    }

    double xOffset = 0;
    if (hasFlag(note.shapeModifiers, NoteShapeModifiers.linea)) {
      final linea = LineaVisualizer(ctxt, note);
      neume.addVisualizer(linea);
      note.origin = note.origin.copyWith(x: note.origin.x + linea.origin.x);
      xOffset = linea.origin.x;
    }

    if (noteAlignsRight && lastNote != null) {
      note.bounds = note.bounds.copyWith(x: x - note.bounds.width);
    } else {
      note.bounds = note.bounds.copyWith(x: x + xOffset);
      x += note.bounds.width + xOffset;
    }

    neume.addVisualizer(note);

    lastNote = note;
    lineIsHanging = false;

    return this;
  }

  /// A special form of noteAt that creates a virga
  /// Uses a punctum cuadratum and a line rather than the virga glyphs
  NeumeBuilder virgaAt(Note note, {bool withLineTo = true}) {
    // Add the punctum for the virga
    noteAt(note, GlyphCode.punctumQuadratum);

    // Add a line for the virga
    final line = VirgaLineVisualizer(ctxt, note);
    x -= line.bounds.width;
    if (hasFlag(note.shapeModifiers, NoteShapeModifiers.reverse)) {
      line.bounds = line.bounds.copyWith(x: 0);
    } else {
      line.bounds = line.bounds.copyWith(x: x);
    }
    neume.addVisualizer(line);

    lastNote = note;
    lineIsHanging = false;

    return this;
  }

  NeumeBuilder advanceBy(double xValue) {
    lastNote = null;
    lineIsHanging = false;
    x += xValue;
    return this;
  }

  /// For terminating hanging lines with no lower notes
  NeumeBuilder withLineEndingAt(Note note) {
    if (lastNote == null) return this;

    final line = NeumeLineVisualizer(ctxt, lastNote!, note, true);
    neume.addVisualizer(line);
    x -= line.bounds.width;
    line.bounds = line.bounds.copyWith(x: x);

    neume.addVisualizer(line);

    lastNote = note;

    return this;
  }

  NeumeBuilder withPodatus({required Note lower, required Note upper}) {
    GlyphCode upperGlyph;
    GlyphCode lowerGlyph;

    if (lower.liquescent == LiquescentType.initioDebilis.value) {
      if (upper.liquescent == LiquescentType.none.value) {
        upperGlyph = GlyphCode.punctumQuadratum;
      } else {
        upperGlyph = GlyphCode.punctumQuadratumDesLiquescent;
      }
      lowerGlyph = GlyphCode.terminatingDesLiquescent;
    } else if (hasFlag(upper.liquescent, LiquescentType.small)) {
      lowerGlyph = GlyphCode.beginningAscLiquescent;
      upperGlyph = GlyphCode.terminatingAscLiquescent;
    } else if (hasFlag(upper.liquescent, LiquescentType.ascending)) {
      lowerGlyph = GlyphCode.punctumQuadratum;
      upperGlyph = GlyphCode.punctumQuadratumAscLiquescent;
    } else if (hasFlag(upper.liquescent, LiquescentType.descending)) {
      lowerGlyph = GlyphCode.punctumQuadratum;
      upperGlyph = GlyphCode.punctumQuadratumDesLiquescent;
    } else {
      final diff = upper.staffPosition - lower.staffPosition;
      lowerGlyph = diff > 1
          ? GlyphCode.podatusLower
          : GlyphCode.podatusLowerShort;
      upperGlyph = diff > 1
          ? GlyphCode.podatusUpper
          : GlyphCode.podatusUpperShort;
    }

    if (lower.shape == NoteShape.quilisma) {
      lowerGlyph = GlyphCode.quilisma;
    }

    noteAt(lower, lowerGlyph).noteAt(upper, upperGlyph);

    lastNote = null;

    return this;
  }

  NeumeBuilder withClivisUpper({
    required Note upper,
    Note? lower,
    GlyphCode glyph = GlyphCode.punctumQuadratum,
  }) {
    if (upper.shape == NoteShape.oriscus) {
      noteAt(upper, GlyphCode.oriscusDes, withLineTo: false);
    } else {
      if (lower != null) {
        lineFrom(lower);
        lineIsHanging = lower.staffPosition < upper.staffPosition;
        if (hasFlag(lower.liquescent, LiquescentType.small)) {
          glyph = GlyphCode.beginningDesLiquescent;
        }
      }
      noteAt(upper, glyph);
    }
    return this;
  }

  NeumeBuilder withClivisLower(Note lower) {
    GlyphCode lowerGlyph;
    if (hasFlag(lower.liquescent, LiquescentType.small)) {
      lowerGlyph = GlyphCode.terminatingDesLiquescent;
    } else if (lower.liquescent == LiquescentType.ascending.value) {
      lowerGlyph = GlyphCode.punctumQuadratumAscLiquescent;
    } else if (lower.liquescent == LiquescentType.descending.value) {
      lowerGlyph = GlyphCode.punctumQuadratumDesLiquescent;
    } else {
      lowerGlyph = GlyphCode.punctumQuadratum;
    }

    return noteAt(lower, lowerGlyph);
  }

  NeumeBuilder withClivis({required Note upper, required Note lower}) {
    withClivisUpper(upper: upper, lower: lower);
    withClivisLower(lower);

    lastNote = null;

    return this;
  }

  /// Lays out a sequence of notes that are inclinata (e.g., climacus, pes subpunctis)
  NeumeBuilder withInclinata(List<Note> notes) {
    double staffPosition = notes[0].staffPosition.toDouble();
    double prevStaffPosition = notes[0].staffPosition.toDouble();

    final advanceWidth =
        glyphs[GlyphCode.punctumInclinatum]!.bounds.width * ctxt.glyphScaling;

    final stemNotes = <Note>[];
    int? beamCount;

    for (var i = 0; i < notes.length; i++) {
      final note = notes[i];

      Note? beamsNote;
      for (var j = i; j < notes.length; j++) {
        if (notes[j].inclinataFlags != null) {
          beamsNote = notes[j];
          break;
        }
      }

      if (beamsNote != null) {
        beamCount ??= beamsNote.inclinataFlags;
      }

      if (hasFlag(note.liquescent, LiquescentType.small)) {
        note.setGlyph(ctxt, GlyphCode.punctumInclinatumLiquescent);
      } else if (hasFlag(note.liquescent, LiquescentType.large)) {
        note.setGlyph(ctxt, GlyphCode.stropha);
      } else {
        note.setGlyph(ctxt, GlyphCode.punctumInclinatum);
      }

      staffPosition = note.staffPosition.toDouble();

      double multiple = (prevStaffPosition - staffPosition).abs();
      if (multiple == 0) {
        multiple = 1.1;
      } else {
        multiple *= (multiple >= 1 ? 2 : 4) / 3;
      }

      if (i > 0) x += advanceWidth * multiple;

      note.bounds = note.bounds.copyWith(x: x);

      neume.addVisualizer(note);
      if (beamsNote != null) {
        stemNotes.add(note);
      }
      prevStaffPosition = staffPosition;
    }

    if (stemNotes.isNotEmpty) {
      final firstNote = stemNotes.first;
      final lastNote = stemNotes.last;
      final startX = firstNote.bounds.x;
      final startY = firstNote.staffPosition + 4;
      final endX = lastNote.bounds.x;
      final endY = lastNote.staffPosition + 4;

      double getStaffPositionForX(double xVal) {
        if (xVal == startX) return startY.toDouble();
        return startY + ((xVal - startX) / (endX - startX)) * (endY - startY);
      }

      for (final note in stemNotes) {
        final stem = NeumeLineVisualizer(
          ctxt,
          note,
          getStaffPositionForX(note.bounds.x),
          false,
        );
        neume.addVisualizer(stem);
        stem.bounds = stem.bounds.copyWith(
          x: note.bounds.x + (note.bounds.width / 2) - (stem.bounds.width / 2),
        );
      }

      int currentBeamCount = beamCount ?? 0;
      while (currentBeamCount > 0) {
        final beams = NeumeBeamVisualizer(
          ctxt,
          startX + (firstNote.bounds.width / 2),
          endX + (lastNote.bounds.width / 2),
          startY.toDouble(),
          endY.toDouble(),
          (currentBeamCount--).toDouble(),
        );
        neume.addVisualizer(beams);
      }
    }

    return this;
  }

  NeumeBuilder withPorrectusSwash({required Note start, required Note end}) {
    final needsLine =
        lastNote != null &&
        (lineIsHanging ||
            (lastNote!.glyphVisualizer != null &&
                lastNote!.glyphVisualizer!.align == 'right') ||
            (lastNote!.staffPosition - start.staffPosition).abs() > 1);

    if (needsLine) {
      final line = NeumeLineVisualizer(ctxt, lastNote!, start, lineIsHanging);
      x = (minX > x - line.bounds.width) ? minX : x - line.bounds.width;
      line.bounds = line.bounds.copyWith(x: x);
      neume.addVisualizer(line);
    }

    GlyphCode glyph;
    final diff = start.staffPosition - end.staffPosition;
    switch (diff.toInt()) {
      case 1:
        glyph = GlyphCode.porrectus1;
        break;
      case 2:
        glyph = GlyphCode.porrectus2;
        break;
      case 3:
        glyph = GlyphCode.porrectus3;
        break;
      case 4:
        glyph = GlyphCode.porrectus4;
        break;
      default:
        glyph = GlyphCode.none;
        break;
    }

    start.setGlyph(ctxt, glyph);
    start.bounds = start.bounds.copyWith(x: x);

    end.setGlyph(ctxt, GlyphCode.none);

    x = start.bounds.right;
    end.bounds = end.bounds.copyWith(x: x - end.bounds.width);

    neume.addVisualizer(start);
    neume.addVisualizer(end);

    lastNote = end;
    lineIsHanging = false;

    return this;
  }
}
