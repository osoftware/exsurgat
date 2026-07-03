import 'package:xml/xml.dart';

import 'glyphs.dart';

class SvgTreeNode {
  SvgTreeNode(this.name, {this.props = const {}, this.children = const []});

  final String name;
  final Map<String, dynamic> props;
  final List<dynamic> children;
}

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

  static String svgFragmentForGlyph(dynamic glyph) {
    final buffer = StringBuffer();
    for (final path in glyph.paths ?? const <dynamic>[]) {
      final name = path.data != null ? 'path' : 'g';
      final attrs = <String, dynamic>{};
      if (path.data != null) {
        attrs['d'] = path.data;
      }
      if (path.type == 'negative') {
        attrs['fill'] = '#fff';
      }
      buffer.write(createNode(name, attrs).toXmlString());
    }
    return buffer.toString();
  }

  static List<dynamic> nodesForGlyph(
    Glyph glyph, {
    String functionName = 'createNode',
  }) {
    final nodes = <dynamic>[];
    for (final path in glyph.paths) {
      final props = <String, dynamic>{};
      props['d'] = path.data;
      if (path.type == 'negative') {
        props['fill'] = '#fff';
      }
      final name = path.data.isNotEmpty ? 'path' : 'g';
      if (functionName == 'createSvgTree') {
        nodes.add(createSvgTree(name, props));
      } else {
        nodes.add(createNode(name, props));
      }
    }
    return nodes;
  }

  static XmlElement createNode(
    String name, [
    Map<String, dynamic>? attributes,
    Object? children,
  ]) {
    final node = XmlElement(XmlName.parts(name));

    if (attributes != null) {
      for (final entry in attributes.entries) {
        if (entry.value == null) {
          continue;
        }
        node.setAttribute(entry.key, entry.value.toString());
      }
    }

    if (children != null) {
      if (children is String) {
        node.children.add(XmlText(children));
      } else if (children is Iterable) {
        for (final child in children) {
          if (child is XmlNode) {
            node.children.add(child);
          } else if (child is String) {
            node.children.add(XmlText(child));
          } else if (child is SvgTreeNode) {
            node.children.add(
              createNode(child.name, child.props, child.children),
            );
          }
        }
      } else if (children is XmlNode) {
        node.children.add(children);
      } else if (children is SvgTreeNode) {
        node.children.add(
          createNode(children.name, children.props, children.children),
        );
      }
    }

    return node;
  }

  static SvgTreeNode createSvgTree(
    String name,
    Map<String, dynamic> props, [
    Object? children,
  ]) {
    final normalizedProps = <String, dynamic>{...props};
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
    Map<String, dynamic> attributes,
    String? child,
  ) {
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
