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
    test('underline changes invalidate the cached paragraph', () {
      final ctxt = ChantContext();
      final span = TextSpan('Kyrie', [], []);
      final props = <String, dynamic>{
        'base-font-family': 'serif',
        'base-font-size': 16.0,
      };
      final plain = span.buildParagraph(ctxt, props, TextAlign.start);
      final underlined = span.buildParagraph(ctxt, {
        ...props,
        'text-decoration': 'underline',
      }, TextAlign.start);
      expect(underlined, isNot(same(plain)));
    });

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
      final p2 = span.buildParagraph(ctxt, {
        ...props,
        'fill': const ui.Color(0xFF123456),
      }, TextAlign.start);
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

  test('markup parsing can be reused without changing the score element', () {
    final doc = ChantDocument.fromSource('%%\nKyrie(c)');
    final lyric = doc.score.notations.expand((n) => n.lyrics).first;
    final originalText = lyric.text;
    final originalSpans = lyric.spans;
    final parsed = TextElement.parseSpansFromText(
      doc.ctxt,
      '<b>A<i>B</i></b><v>{greextra}{Cross}</v>',
    );

    expect(parsed.visibleText, 'AB${greextraGlyphs['Cross']}');
    expect(parsed.spans[0].activeTags, ['b']);
    expect(parsed.spans[1].activeTags, ['b', 'i']);
    expect(parsed.spans.last.properties['font-family'], 'greextra');
    expect(lyric.text, originalText);
    expect(lyric.spans, same(originalSpans));
  });

  test('visible text includes standalone symbols and explicit line breaks', () {
    final ctxt = ChantContext();
    expect(TextElement.parseSpansFromText(ctxt, '*').visibleText, '*');
    expect(TextElement.parseSpansFromText(ctxt, 'a<br>b').visibleText, 'a\nb');
  });

  test('source mappings cover normalized and transformed visible text', () {
    final ctxt = ChantContext();
    const source = '<b>A  B</b><v>{greextra}{Cross}</v><br>é';
    final parsed = TextElement.parseSpansFromText(ctxt, source);
    final mappings = parsed.sourceMappings;

    expect(parsed.visibleText, 'A B${greextraGlyphs['Cross']}\né');
    expect(
      mappings.map(
        (mapping) => source.substring(mapping.sourceStart, mapping.sourceEnd),
      ),
      ['A', '  ', 'B', '<v>{greextra}{Cross}</v>', '<br>', 'é'],
    );
    expect(
      mappings
          .map(
            (mapping) => parsed.visibleText.substring(
              mapping.visibleStart,
              mapping.visibleEnd,
            ),
          )
          .join(),
      parsed.visibleText,
    );
  });

  test('source mappings retain UTF-16 offsets and mixed verbatim content', () {
    final ctxt = ChantContext();
    const source = '😀<v>x{greextra}{Cross}y</v><sp>ae</sp>';
    final parsed = TextElement.parseSpansFromText(ctxt, source);
    final mappings = parsed.sourceMappings;

    expect(parsed.visibleText, '😀x${greextraGlyphs['Cross']}yæ');
    expect(mappings[0].visibleStart, 0);
    expect(mappings[0].visibleEnd, 2);
    expect(
      mappings
          .map(
            (mapping) =>
                source.substring(mapping.sourceStart, mapping.sourceEnd),
          )
          .skip(1),
      ['x', '{greextra}{Cross}', 'y', '<sp>ae</sp>'],
    );
    expect(mappings.last.visibleEnd, parsed.visibleText.length);
  });

  test('source mappings expose enclosing markup and verbatim frames', () {
    final parsed = TextElement.parseSpansFromText(
      ChantContext(),
      '<b>A<i><v>BC</v></i></b>',
    );
    expect(parsed.sourceMappings[1].frames.map((frame) => frame.opening), [
      '<b>',
      '<i>',
      '<v>',
    ]);
    expect(parsed.sourceMappings[1].frames.map((frame) => frame.closing), [
      '</b>',
      '</i>',
      '</v>',
    ]);
  });

  test('shorthand formatting closes at its matching delimiter', () {
    final parsed = TextElement.parseSpansFromText(ChantContext(), '_a_b');
    expect(parsed.visibleText, 'ab');
    expect(parsed.spans.first.activeTags, ['i']);
    expect(parsed.spans.last.activeTags, isEmpty);
    expect(parsed.sourceMappings.first.frames.single.closing, '_');
  });

  test('underline and relative elision size resolve in canvas text styles', () {
    final ctxt = ChantContext();
    final parsed = TextElement.parseSpansFromText(ctxt, '<ul><e>A</e></ul>');
    final style = TextSpan.getTextStyle(
      {
        'base-font-family': 'serif',
        'base-font-size': 20.0,
        ...parsed.spans.single.properties,
      },
      ctxt,
      null,
    );

    expect(
      style,
      ui.TextStyle(
        color: ctxt.theme.textColor,
        fontFamilyFallback: ['serif'],
        fontSize: 18.0,
        fontStyle: ui.FontStyle.italic,
        decoration: ui.TextDecoration.underline,
      ),
    );
  });

  test('font fill markup resolves to a canvas color', () {
    final ctxt = ChantContext();
    final parsed = TextElement.parseSpansFromText(
      ctxt,
      '<font fill="#123456">A</font>',
    );
    final props = {
      'base-font-family': 'serif',
      'base-font-size': 20.0,
      ...parsed.spans.single.properties,
    };
    expect(
      TextSpan.getTextStyle(props, ctxt, null),
      ui.TextStyle(
        color: const ui.Color(0xff123456),
        fontFamilyFallback: ['serif'],
        fontSize: 20,
      ),
    );
  });
}
