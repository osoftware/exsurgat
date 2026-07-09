import '../../../drawing.dart';
import '../chant_notation_element.dart';
import 'neume_builder.dart';
import 'note.dart';

class LedgerLine {
  final Note element;
  final Note endElem;
  final int staffPosition;

  LedgerLine({
    required this.element,
    required this.endElem,
    required this.staffPosition,
  });
}

/// Neumes base class
class Neume extends ChantNotationElement {
  final List<Note> notes = [];
  List<LedgerLine> ledgerLines = [];

  Neume([List<Note> notes = const []]) {
    for (var note in notes) {
      addNote(note);
    }
  }

  void addNote(Note note) {
    note.neume = this;
    notes.add(note);
  }

  @override
  void finishLayout(ChantContext ctxt) {
    ledgerLines = requiresLedgerLine(ctxt);

    // allow subclasses an opportunity to position their own markings...
    positionMarkings();

    // layout the markings of the notes
    for (var note in notes) {
      for (var episema in note.episemata) {
        episema.performLayout(ctxt);
        addVisualizer(episema);
      }

      for (var mora in note.morae) {
        mora.performLayout(ctxt);
        addVisualizer(mora);
      }

      // if the note has an ictus, then add it here
      if (note.ictus != null) {
        note.ictus!.performLayout(ctxt);
        addVisualizer(note.ictus!);
      }

      if (note.accent != null) {
        note.accent!.performLayout(ctxt);
        addVisualizer(note.accent!);
      }

      if (note.choralSign != null) {
        note.choralSign!.performLayout(ctxt);
        addVisualizer(note.choralSign!);
      }

      // braces are handled by the chant line, so we don't mess with them here
      // this is because brace size depends on chant line logic (neume spacing,
      // justification, etc.) so they are considered chant line level
      // markings rather than note level markings
    }

    origin = notes[0].origin.clone();

    super.finishLayout(ctxt);
  }

  List<LedgerLine> requiresLedgerLine(ChantContext ctxt) {
    dynamic firstAbove = false;
    bool needsAbove = false;
    dynamic firstBelow = false;
    bool needsBelow = false;
    List<LedgerLine> result = [];
    int ledgerLinePositionAbove = ctxt.staffLineCount * 2 + 1;

    if (notes.isEmpty) return result;

    for (var i = 0; i < notes.length; ++i) {
      var note = notes[i];
      var staffPosition = note.staffPosition;
      if (staffPosition >= ledgerLinePositionAbove - 1) {
        needsAbove =
            needsAbove || staffPosition >= ledgerLinePositionAbove - 0.9;
        if (firstAbove == false) {
          firstAbove = (i - 1).clamp(0, double.infinity).toInt();
        }
        if (staffPosition >= ledgerLinePositionAbove) continue;
      } else if (staffPosition <= 0) {
        needsBelow = needsBelow || staffPosition < -0.1;
        if (firstBelow == false) {
          firstBelow = (i - 1).clamp(0, double.infinity).toInt();
        }
        if (staffPosition <= -1) continue;
      }
      if (needsAbove || needsBelow) {
        var endI = i; // Math.abs(staffPosition) >= 4? i : i - 1;
        result.add(
          LedgerLine(
            element:
                notes[(firstAbove != false && firstAbove != 0)
                    ? firstAbove
                    : (firstBelow != false && firstBelow != 0)
                    ? firstBelow
                    : 0],
            endElem: notes[endI],
            staffPosition: needsAbove ? ledgerLinePositionAbove : -1,
          ),
        );
        firstAbove = firstBelow = needsAbove = needsBelow = false;
      }
    }
    if (needsAbove || needsBelow) {
      result.add(
        LedgerLine(
          element:
              notes[(firstAbove != false && firstAbove != 0)
                  ? firstAbove
                  : (firstBelow != false && firstBelow != 0)
                  ? firstBelow
                  : 0],
          endElem: notes[notes.length - 1],
          staffPosition: needsAbove ? ledgerLinePositionAbove : -1,
        ),
      );
    }
    return result;
  }

  void resetDependencies() {}

  NeumeBuilder build(ChantContext ctxt) => NeumeBuilder(ctxt, this);

  int positionEpisemata(Note note, MarkingPositionHint position) {
    for (var episema in note.episemata) {
      if (episema.positionHint == MarkingPositionHint.defaultHint) {
        episema.positionHint = position;
      }
    }
    if (note.choralSign != null) {
      note.choralSign!.positionHint = position;
    }
    return note.episemata.length;
  }

  int positionEpisemataAbove(Note note) {
    return positionEpisemata(note, MarkingPositionHint.above);
  }

  int positionEpisemataBelow(Note note) {
    return positionEpisemata(note, MarkingPositionHint.below);
  }

  void positionPodatusEpisemata(Note bottomNote, Note topNote) {
    // 1. episema on lower note by default be below, upper note above
    positionEpisemataBelow(bottomNote);
    positionEpisemataAbove(topNote);
    if (topNote.ictus != null) {
      topNote.ictus!.positionHint = MarkingPositionHint.above;
    }
  }

  void positionInclinataMorae(List<Note> notes) {
    var subset = notes.length >= 2 ? notes.sublist(notes.length - 2) : notes;
    if (subset.length < 2 ||
        subset[1].staffPosition > subset[0].staffPosition) {
      return;
    }
    var bottomNote = subset[1];
    var topNote = subset[0];

    // The mora on the second (lower) note should be below the punctum,
    // if the punctum is on a line and the previous punctum is in the space above.
    if ((bottomNote.staffPosition.abs() % 2) == 1 &&
        topNote.staffPosition - bottomNote.staffPosition == 1 &&
        bottomNote.morae.isNotEmpty) {
      var mark = bottomNote.morae.last;
      if (mark.positionHint == MarkingPositionHint.defaultHint) {
        mark.positionHint = MarkingPositionHint.below;
      }
    }
  }

  void positionPodatusMorae(Note bottomNote, Note topNote) {
    dynamic mark;

    // The mora on the first (lower) note should be below it,
    // if it is on a line.
    if ((bottomNote.staffPosition.abs() % 2) == 1) {
      if (bottomNote.morae.length == 1) {
        mark = bottomNote.morae[0];
      } else if (topNote.morae.length > 1) {
        mark = topNote.morae[0];
      }
      if (mark != null &&
          mark.positionHint == MarkingPositionHint.defaultHint) {
        mark.positionHint = MarkingPositionHint.below;
      }
    }

    // if there is a mora on the first note but not on the second, and the neume
    // continues with a punctum higher than the second note, we need to adjust
    // the space after the neume so that it follows immediately with no gap
    if (bottomNote.morae.isNotEmpty && topNote.morae.isEmpty) {
      bottomNote.morae[0].ignoreBounds = true;
    }
  }

  // for any subclasses that begin with a podatus, they can call this from their own positionMarkings()
  void positionPodatusMarkings(Note bottomNote, Note topNote) {
    positionPodatusEpisemata(bottomNote, topNote);
    positionPodatusMorae(bottomNote, topNote);
  }

  // just like a clivis, but the first note of the three also works like the second note of the clivis:
  // episema below, unless the middle note also has an episema
  bool positionTorculusMarkings(
    Note firstNote,
    Note secondNote,
    Note thirdNote,
  ) {
    var hasTopEpisema = positionClivisMarkings(secondNote, thirdNote);
    var result =
        positionEpisemata(
              firstNote,
              hasTopEpisema
                  ? MarkingPositionHint.above
                  : MarkingPositionHint.below,
            ) >
            0 &&
        hasTopEpisema;
    return result;
  }

  void positionClivisMorae(Note firstNote, Note secondNote) {
    // 1. second note of a clivis that ends on a line and goes down one step has its mora below:
    if (secondNote.morae.isNotEmpty &&
        firstNote.staffPosition - secondNote.staffPosition == 1 &&
        (secondNote.staffPosition.abs() % 2) == 1) {
      secondNote.morae.last.positionHint = MarkingPositionHint.below;
    }
  }

  bool positionClivisEpisemata(Note firstNote, Note secondNote) {
    var hasTopEpisema = positionEpisemataAbove(firstNote) > 0;
    positionEpisemata(
      secondNote,
      hasTopEpisema ? MarkingPositionHint.above : MarkingPositionHint.below,
    );
    return hasTopEpisema;
  }

  bool positionClivisMarkings(Note firstNote, Note secondNote) {
    positionClivisMorae(firstNote, secondNote);
    return positionClivisEpisemata(firstNote, secondNote);
  }

  void positionPorrectusMarkings(
    Note firstNote,
    Note secondNote,
    Note thirdNote,
  ) {
    // episemata on first and second note work like a clivis,
    // the second note should have its episema below, unless the first note also has an episema.
    positionClivisEpisemata(firstNote, secondNote);
    positionPodatusMarkings(secondNote, thirdNote);
  }

  void positionPorrectusFlexusMarkings(
    Note first,
    Note second,
    Note third,
    Note fourth,
  ) {
    var hasTopEpisema = positionEpisemataAbove(first) > 0;
    hasTopEpisema = positionClivisMarkings(third, fourth) || hasTopEpisema;
    positionEpisemata(
      second,
      hasTopEpisema ? MarkingPositionHint.above : MarkingPositionHint.below,
    );
  }

  // subclasses can override this in order to correctly place markings in a neume specific way
  void positionMarkings() {}
}
