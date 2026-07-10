import 'package:xml/xml.dart';

import 'glyphs.dart';

class SvgTreeNode {
  SvgTreeNode(this.name, {this.props = const {}, this.children = const []});

  final String name;
  final Map<String, dynamic> props;
  final List<dynamic> children;
}

typedef NodeMaker<T> =
    T Function(String name, Map<String, dynamic> attrs, [Object? children]);

class QuickSvg {
  static const String ns = 'http://www.w3.org/2000/svg';
  static const String xmlns = 'https://www.w3.org/2000/xmlns/';
  static const String xlink = 'http://www.w3.org/1999/xlink';

  static bool hasDOMAccess() => true;

  static XmlElement svg(String width, String height) {
    final node = XmlElement(XmlName.parts('svg', namespaceUri: ns))
      ..setAttribute('xmlns', ns)
      ..setAttribute('xmlns:xlink', xlink, namespaceUri: xmlns)
      ..setAttribute('version', '1.1')
      ..setAttribute('width', width)
      ..setAttribute('height', height);

    final defs = XmlElement(XmlName.parts('defs', namespaceUri: ns));
    node.children.add(defs);
    return node;
  }

  static XmlElement rect(String width, String height) =>
      XmlElement(XmlName.parts('rect', namespaceUri: ns))
        ..setAttribute('width', width)
        ..setAttribute('height', height);

  static XmlElement line(String x1, String y1, String x2, String y2) =>
      XmlElement(XmlName.parts('line', namespaceUri: ns))
        ..setAttribute('x1', x1)
        ..setAttribute('y1', y1)
        ..setAttribute('x2', x2)
        ..setAttribute('y2', y2);

  static XmlElement g() => XmlElement(XmlName.parts('g', namespaceUri: ns));

  static XmlElement text() =>
      XmlElement(XmlName.parts('text', namespaceUri: ns));

  static XmlElement tspan(String? str) {
    final node = XmlElement(XmlName.parts('tspan', namespaceUri: ns));
    if (str != null) {
      node.children.add(XmlText(str));
    }
    return node;
  }

  static XmlElement use(String nodeRef) =>
      XmlElement(XmlName.parts('use', namespaceUri: ns))
        ..setAttribute('xlink:href', '#$nodeRef');

  static String svgFragmentForGlyph(Glyph glyph) {
    final buffer = StringBuffer();
    for (final path in glyph.paths) {
      final name = path.data.isNotEmpty ? 'path' : 'g';
      final attrs = <String, dynamic>{};
      if (path.data.isNotEmpty) {
        attrs['d'] = path.data;
      }
      if (path.type == 'negative') {
        attrs['fill'] = '#fff';
      }
      buffer.write(createNode(name, attrs).toXmlString());
    }
    return buffer.toString();
  }

  static List<T> nodesForGlyph<T>(Glyph glyph, NodeMaker<T> make) {
    final nodes = <T>[];
    for (final path in glyph.paths) {
      final props = <String, dynamic>{};
      props['d'] = path.data;
      if (path.type == 'negative') {
        props['fill'] = '#fff';
      }
      final name = path.data.isNotEmpty ? 'path' : 'g';
      nodes.add(make(name, props));
    }
    return nodes;
  }

  static XmlElement createNode(
    String name, [
    Map<String, dynamic> attributes = const {},
    Object? children,
  ]) {
    final node = XmlElement(XmlName.parts(name));

    for (final entry in attributes.entries) {
      if (entry.value == null) continue;
      node.setAttribute(entry.key, entry.value.toString());
    }

    switch (children) {
      case String _:
        node.children.add(XmlText(children));
      case Iterable _:
        for (final child in children) {
          node.children.add(switch (child) {
            XmlNode _ => child,
            String _ => XmlText(child),
            SvgTreeNode _ => createNode(
              child.name,
              child.props,
              child.children,
            ),
            _ => throw ArgumentError.value(child, 'child'),
          });
        }
      case XmlNode _:
        node.children.add(children);
      case SvgTreeNode _:
        node.children.add(
          createNode(children.name, children.props, children.children),
        );
    }

    return node;
  }

  static SvgTreeNode createSvgTree(
    String name,
    Map<String, dynamic> props, [
    Object? children,
  ]) {
    final normalizedProps = props.map((k, v) => MapEntry(k.toCamelCase(), v));
    if (props['style'] != null) {
      props['style'] = (props['style'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k.toCamelCase(), v),
      );
    }
    final normalizedChildren = <dynamic>[];

    if (children is Iterable && children is! String) {
      normalizedChildren.addAll(children);
    } else if (children != null) {
      normalizedChildren.add(children);
    }

    return SvgTreeNode(
      name,
      props: normalizedProps,
      children: normalizedChildren,
    );
  }

  static String createFragment(
    String name,
    Map<String, dynamic> attributes, [
    String? child,
  ]) {
    final attrs = attributes.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${entry.key}="${entry.value}"')
        .join(' ');
    if (child == null || child.isEmpty) {
      return '<$name${attrs.isNotEmpty ? ' $attrs' : ''}/>';
    }
    return '<$name${attrs.isNotEmpty ? ' $attrs' : ''}>$child</$name>';
  }

  static XmlElement? parseFragment(String? fragment) {
    if (fragment == null || fragment.isEmpty) {
      return null;
    }

    final normalized = fragment.replaceAllMapped(
      RegExp(r'<(\w+)([^<]+?)\/>'),
      (match) => '<${match.group(1)}${match.group(2)}></${match.group(1)}>',
    );

    final document = XmlDocument.parse('<svg>$normalized</svg>');
    final container = XmlElement(XmlName.parts('g'));
    final children = List<XmlNode>.from(
      document.rootElement.children.whereType<XmlNode>(),
    );

    for (final child in children) {
      container.children.add(child);
    }

    return container;
  }

  static XmlElement translate(XmlElement node, String x, String y) {
    node.setAttribute('transform', 'translate($x,$y)');
    return node;
  }

  static XmlElement scale(XmlElement node, String sx, String sy) {
    node.setAttribute('transform', 'scale($sx,$sy)');
    return node;
  }

  static void clearNotations(XmlElement node) {
    final children = List<XmlNode>.from(node.children);
    for (final child in children) {
      node.children.remove(child);
    }
  }
}

extension on String {
  String toCamelCase() {
    final parts = split('-');
    final buffer = StringBuffer();
    bool firstFound = false;
    for (final part in parts) {
      if (part.isEmpty) continue;
      if (!firstFound) {
        buffer.write(part);
        firstFound = true;
      } else {
        buffer.write(part[0].toUpperCase());
        buffer.write(part.substring(1));
      }
    }
    return buffer.toString();
  }
}
