import 'dart:ui' as ui;
import 'dart:ui' show TextAlign;

import 'package:exsurgat/exsurgat.dart';
import 'package:exsurgat/internals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const gabcSource = '''
%%
Ky(gh)ri(gf)e(e.) e(gvFD)le(ghg)í(gfe)son(f.) (,)
Ky(gh)ri(gf)e(e.) e(gvFD)le(ghg)í(gfe)son(f.) (,)
''';

  // Attaches a throwaway canvas so line.draw can record pictures.
  (ChantContext, ui.PictureRecorder) recordingContext(ChantContext ctxt) {
    final recorder = ui.PictureRecorder();
    ctxt.attachCanvas(ui.Canvas(recorder));
    return (ctxt, recorder);
  }

  group('ChantLine picture cache', () {
    test('second draw with unchanged state reuses cached picture', () {
      final doc = ChantDocument.fromSource(gabcSource);
      final ctxt = doc.ctxt;
      final score = doc.score;
      score.performLayout(ctxt);
      score.layoutChantLines(ctxt, 800);
      expect(score.lines, isNotEmpty);

      final line = score.lines.first;
      expect(line.debugHasCachedPicture, isFalse);
      final (_, r1) = recordingContext(ctxt);
      line.draw(ctxt);
      r1.endRecording();
      expect(line.debugHasCachedPicture, isTrue);

      final signature = line.debugPictureSignature;
      final (_, r2) = recordingContext(ctxt);
      line.draw(ctxt);
      r2.endRecording();
      expect(line.debugPictureSignature, same(signature));
    });

    test('selection change invalidates cached picture', () {
      final doc = ChantDocument.fromSource(gabcSource);
      final ctxt = doc.ctxt;
      final score = doc.score;
      score.performLayout(ctxt);
      score.layoutChantLines(ctxt, 800);

      final line = score.lines.first;
      final (_, r1) = recordingContext(ctxt);
      line.draw(ctxt);
      r1.endRecording();
      final signature = line.debugPictureSignature;

      line.selected = true;
      final (_, r2) = recordingContext(ctxt);
      line.draw(ctxt);
      r2.endRecording();
      expect(line.debugPictureSignature, isNot(same(signature)));
    });

    test('relayout bumps epoch and disposes old line pictures', () {
      final doc = ChantDocument.fromSource(gabcSource);
      final ctxt = doc.ctxt;
      final score = doc.score;
      score.performLayout(ctxt);
      score.layoutChantLines(ctxt, 800);
      final epoch = ctxt.layoutEpoch;
      final (_, r1) = recordingContext(ctxt);
      score.lines.first.draw(ctxt);
      r1.endRecording();
      expect(score.lines.first.debugHasCachedPicture, isTrue);

      score.layoutChantLines(ctxt, 800);
      expect(ctxt.layoutEpoch, greaterThan(epoch));
      // New lines start without a cached picture.
      expect(score.lines.first.debugHasCachedPicture, isFalse);
    });

    test('insertion preview invalidates cached picture', () {
      final doc = ChantDocument.fromSource(gabcSource);
      final ctxt = doc.ctxt;
      final score = doc.score;
      score.performLayout(ctxt);
      score.layoutChantLines(ctxt, 800);

      final line = score.lines.first;
      final (_, r1) = recordingContext(ctxt);
      line.draw(ctxt);
      r1.endRecording();
      final signature = line.debugPictureSignature;

      line.insertionPreview = line.notations.first;
      final (_, r2) = recordingContext(ctxt);
      line.draw(ctxt);
      r2.endRecording();
      expect(line.debugPictureSignature, isNot(same(signature)));
    });
  });

  group('TextSpan paragraph cache', () {
    test('same style inputs return the same paragraph instance', () {
      final doc = ChantDocument.fromSource(gabcSource);
      final ctxt = doc.ctxt;
      final score = doc.score;
      score.performLayout(ctxt);
      score.layoutChantLines(ctxt, 800);

      final props = <String, dynamic>{
        'base-font-family': 'serif',
        'base-font-size': 16.0,
        'fill': ctxt.theme.textColor,
      };
      final span = TextSpan('Kyrie', [], []);
      final p1 = span.buildParagraph(ctxt, props, TextAlign.start);
      final p2 = span.buildParagraph(ctxt, props, TextAlign.start);
      expect(identical(p1, p2), isTrue);
    });

    test('changed style inputs rebuild the paragraph', () {
      final doc = ChantDocument.fromSource(gabcSource);
      final ctxt = doc.ctxt;
      final span = TextSpan('Kyrie', [], []);
      final props = <String, dynamic>{
        'base-font-family': 'serif',
        'base-font-size': 16.0,
        'fill': ctxt.theme.textColor,
      };
      final p1 = span.buildParagraph(ctxt, props, TextAlign.start);
      final p2 = span.buildParagraph(
        ctxt,
        {...props, 'fill': 0xFF000000},
        TextAlign.start,
      );
      expect(identical(p1, p2), isFalse);
    });

    test('text mutation invalidates the cached paragraph', () {
      final doc = ChantDocument.fromSource(gabcSource);
      final ctxt = doc.ctxt;
      final span = TextSpan('Kyrie', [], []);
      final props = <String, dynamic>{
        'base-font-family': 'serif',
        'base-font-size': 16.0,
        'fill': ctxt.theme.textColor,
      };
      final p1 = span.buildParagraph(ctxt, props, TextAlign.start);
      span.text = 'Gloria';
      final p2 = span.buildParagraph(ctxt, props, TextAlign.start);
      expect(identical(p1, p2), isFalse);
    });
  });
}
