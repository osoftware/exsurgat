import 'package:exsurgat/src/quick_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

void main() {
  group('QuickSvg', () {
    test('creates svg and element nodes using xml nodes', () {
      final svg = QuickSvg.svg('100', '200');
      expect(svg.name.local, 'svg');
      expect(svg.getAttribute('width'), '100');
      expect(svg.getAttribute('height'), '200');
      expect(svg.getAttribute('xmlns'), QuickSvg.ns);

      final rect = QuickSvg.createNode('rect', {
        'x': '1',
        'y': '2',
        'fill': '#000',
      });
      expect(rect.name.local, 'rect');
      expect(rect.getAttribute('x'), '1');
      expect(rect.getAttribute('y'), '2');
      expect(rect.getAttribute('fill'), '#000');
    });

    test('creates a use node and parses a fragment into an xml element', () {
      final use = QuickSvg.use('glyph');
      expect(use.name.local, 'use');
      expect(use.toXmlString(), contains('glyph'));

      final container = QuickSvg.parseFragment('<rect x="1" y="2"/>');
      expect(container, isA<XmlElement>());
      expect(container!.name.local, 'g');
      expect(
        container.children.whereType<XmlElement>().first.name.local,
        'rect',
      );
    });

    test('builds a lightweight svg tree descriptor', () {
      final tree = QuickSvg.createSvgTree('g', {
        'class': 'note',
      }, QuickSvg.createNode('rect', {'x': '1'}));
      expect(tree.name, 'g');
      expect(tree.props['class'], 'note');
      expect(tree.children, hasLength(1));
    });
  });
}
