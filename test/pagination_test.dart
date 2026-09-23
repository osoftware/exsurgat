import 'package:exsurgat/exsurgat.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pagination', () {
    // Many short lines so the score paginates into multiple pages.
    final gabcSource = '''
page-width: 4in;
page-height: 3in;
margin-left: 0.5in;
margin-right: 0.25in;
margin-top: 0.25in;
margin-bottom: 0.25in;
%%
Ky(gh)ri(gf)e(e.) (,) e(gvFD)le(ghg)í(gfe)son(f.) (,)
Ky(gh)ri(gf)e(e.) (,) e(gvFD)le(ghg)í(gfe)son(f.) (,)
Ky(gh)ri(gf)e(e.) (,) e(gvFD)le(ghg)í(gfe)son(f.) (,)
Ky(gh)ri(gf)e(e.) (,) e(gvFD)le(ghg)í(gfe)son(f.) (,)
Ky(gh)ri(gf)e(e.) (,) e(gvFD)le(ghg)í(gfe)son(f.) (,)
Ky(gh)ri(gf)e(e.) (,) e(gvFD)le(ghg)í(gfe)son(f.) (,)
Ky(gh)ri(gf)e(e.) (,) e(gvFD)le(ghg)í(gfe)son(f.) (,)
Ky(gh)ri(gf)e(e.) (,) e(gvFD)le(ghg)í(gfe)son(f.) (,)
''';

    test('Document layout is read from header', () {
      final doc = ChantDocument.fromSource(gabcSource);
      expect(doc.layout.pageWidth, equals(Scalar(4, Unit.inches)));
      expect(doc.layout.pageHeight, equals(Scalar(3, Unit.inches)));
      expect(doc.layout.marginLeft, equals(Scalar(0.5, Unit.inches)));
      expect(doc.layout.marginRight, equals(Scalar(0.25, Unit.inches)));
      expect(doc.layout.marginTop, equals(Scalar(0.25, Unit.inches)));
      expect(doc.layout.marginBottom, equals(Scalar(0.25, Unit.inches)));
    });

    test('layoutChantLines uses content width from margins', () {
      final doc = ChantDocument.fromSource(gabcSource);
      final ctxt = doc.ctxt;
      final score = doc.score;
      score.performLayout(ctxt);
      score.layoutChantLines(ctxt, 4 * 96 - 0.5 * 96 - 0.25 * 96);
      // Staff lines should not exceed the content width.
      for (final line in score.lines) {
        expect(line.staffRight, lessThanOrEqualTo(4 * 96 - 0.75 * 96 + 0.001));
      }
    });

    test('paginate splits score into multiple pages', () {
      final doc = ChantDocument.fromSource(gabcSource);
      final ctxt = doc.ctxt;
      final score = doc.score;
      score.performLayout(ctxt);
      score.layoutChantLines(ctxt, 4 * 96 - 0.75 * 96);
      score.paginate(3 * 96 - 0.5 * 96);
      expect(score.pages.length, greaterThan(1));
      // All lines distributed across pages.
      var lineCount = 0;
      for (final page in score.pages) {
        lineCount += page.lines.length;
      }
      expect(lineCount, equals(score.lines.length));
    });

    test('RenderChantScore paginated layout sizes to page slots', () async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      final doc = ChantDocument.fromSource(gabcSource);
      final renderObject = RenderChantScore(
        gabc: '',
        document: doc,
        useDropCap: null,
        theme: null,
        tool: null,
        arrangement: PageArrangement.row,
        pageIndex: 0,
        pageGap: 24,
        pageDecoration: null,
      );
      // Simulate layout with generous constraints.
      renderObject.layout(
        BoxConstraints.loose(const Size(10000, 10000)),
        parentUsesSize: true,
      );
      final pageWidth = 4 * 96.0;
      final pageHeight = 3 * 96.0;
      final gap = 24.0;
      final pageCount = doc.score.pages.length;
      expect(pageCount, greaterThan(1));
      expect(
        renderObject.size.width,
        closeTo(pageCount * pageWidth + (pageCount - 1) * gap, 0.5),
      );
      expect(renderObject.size.height, closeTo(pageHeight, 0.5));
      binding; // silence unused warning
      renderObject.dispose();
    });

    test('RenderChantScore single arrangement shows one page', () {
      final doc = ChantDocument.fromSource(gabcSource);
      final renderObject = RenderChantScore(
        gabc: '',
        document: doc,
        useDropCap: null,
        theme: null,
        tool: null,
        arrangement: PageArrangement.single,
        pageIndex: 1,
        pageGap: 24,
        pageDecoration: null,
      );
      renderObject.layout(
        BoxConstraints.loose(const Size(10000, 10000)),
        parentUsesSize: true,
      );
      expect(doc.score.pages.length, greaterThan(1));
      expect(renderObject.size.width, closeTo(4 * 96.0, 0.5));
      expect(renderObject.size.height, closeTo(3 * 96.0, 0.5));
      renderObject.dispose();
    });

    test('RenderChantScore facingPairs puts first page alone', () {
      final doc = ChantDocument.fromSource(gabcSource);
      final renderObject = RenderChantScore(
        gabc: '',
        document: doc,
        useDropCap: null,
        theme: null,
        tool: null,
        arrangement: PageArrangement.facingPairs,
        pageIndex: 0,
        pageGap: 24,
        pageDecoration: null,
      );
      renderObject.layout(
        BoxConstraints.loose(const Size(10000, 10000)),
        parentUsesSize: true,
      );
      final pageCount = doc.score.pages.length;
      final pageWidth = 4 * 96.0;
      final pageHeight = 3 * 96.0;
      final gap = 24.0;
      // Rows: page 0 alone, then ceil((pageCount-1)/2) rows of pairs.
      final rows = 1 + ((pageCount - 1) + 1) ~/ 2;
      expect(
        renderObject.size.height,
        closeTo(rows * pageHeight + (rows - 1) * gap, 0.5),
      );
      expect(renderObject.size.width, closeTo(2 * pageWidth + 4.0, 0.5));
      renderObject.dispose();
    });

    test('RenderChantScore auto arrangement keeps legacy behavior', () {
      final doc = ChantDocument.fromSource(gabcSource);
      final renderObject = RenderChantScore(
        gabc: '',
        document: doc,
        useDropCap: null,
        theme: null,
        tool: null,
        arrangement: PageArrangement.auto,
        pageIndex: 0,
        pageGap: 24,
        pageDecoration: null,
      );
      renderObject.layout(
        BoxConstraints.loose(const Size(10000, 10000)),
        parentUsesSize: true,
      );
      // Legacy: single page, no pagination.
      expect(doc.score.pages.length, equals(1));
      renderObject.dispose();
    });
  });
}
