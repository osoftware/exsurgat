import 'package:xml/xml.dart';

import '../drawing.dart';
import '../quick_svg.dart';
import 'chant_layout_element.dart';
import 'notation/neumes/note.dart';

enum BraceShape { roundBrace, curlyBrace, accentedCurlyBrace }

enum BraceAttachment { left, right }

class BracePoint extends ChantLayoutElement {
  ChantLayoutElement? note;
  final bool isAbove;
  final BraceShape shape;
  final BraceAttachment attachment;

  int notationIndex = 0;
  bool automatic = false;

  BracePoint(this.note, this.isAbove, this.shape, this.attachment) : super();

  double getAttachmentX(ChantLayoutElement? noteArg) {
    final n = noteArg ?? note;
    final x = switch (n) {
      Note(:final neume) => neume!.bounds.x,
      _ => 0, // Custos
    };
    // TODO: verify null assumptions
    return attachment == BraceAttachment.left
        ? x + n!.bounds.x
        : x + n!.bounds.right;
  }

  @override
  String createSvgFragment(ChantContext ctxt, [ChantLayoutElement? source]) {
    // TODO: implement createSvgFragment
    throw UnimplementedError();
  }

  @override
  XmlElement createSvgNode(ChantContext ctxt, [ChantLayoutElement? source]) {
    // TODO: implement createSvgNode
    throw UnimplementedError();
  }

  @override
  SvgTreeNode createSvgTree(ChantContext ctxt, [ChantLayoutElement? source]) {
    // TODO: implement createSvgTree
    throw UnimplementedError();
  }

  @override
  void draw(ChantContext ctxt) {
    // TODO: implement draw
  }
}
