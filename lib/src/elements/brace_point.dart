import 'package:xml/xml.dart';

import '../chant_context.dart';
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
  XmlElement createSvgNode(ChantContext ctxt, [ChantLayoutElement? source]) {
    throw UnsupportedError('Braces are handled by the ChantLine');
  }

  @override
  SvgTreeNode createSvgTree(ChantContext ctxt, [ChantLayoutElement? source]) {
    throw UnsupportedError('Braces are handled by the ChantLine');
  }

  @override
  void draw(ChantContext ctxt) {
    // braces are handled by the chant line, so we don't mess with them here
    // this is because brace size depends on chant line logic (neume spacing,
    // justification, etc.) so they are considered chant line level
    // markings rather than note level markings
    throw UnsupportedError('Braces are handled by the ChantLine');
  }
}
