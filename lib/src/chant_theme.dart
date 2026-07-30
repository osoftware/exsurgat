import 'dart:ui';

import 'chant_context.dart';

class TextStyleDefinition {
  const TextStyleDefinition({
    this.display = '',
    this.cssClass = '',
    this.defaultSize,
    this.size,
  });
  final String display;
  final String cssClass;
  final double Function(double size)? defaultSize;
  final double Function(ChantContext ctxt)? size;
}

class ChantColors {
  static const Color nigric = Color(0xFF000000);
  static const Color rubric = Color(0xFFDD0000);
}

final Map<String, TextStyleDefinition> defaultChantTheme = {
  'supertitle': TextStyleDefinition(
    display: 'Supertitle',
    cssClass: 'supertitle',
    defaultSize: (size) => (size * 7) / 6, // 14pt
  ),
  'title': TextStyleDefinition(
    display: 'Title',
    cssClass: 'title',
    defaultSize: (size) => (size * 3) / 2, // 18pt
  ),
  'subtitle': TextStyleDefinition(
    display: 'Subtitle',
    cssClass: 'subtitle',
    defaultSize: (size) => size, // 12pt
  ),
  'leftRight': TextStyleDefinition(
    display: 'Left / Right Text',
    cssClass: 'textLeftRight',
    defaultSize: (size) => size * 0.9,
  ),
  'annotation': TextStyleDefinition(
    display: 'Annotation',
    cssClass: 'annotation',
    defaultSize: (size) => (size * 2) / 3,
  ),
  'dropCap': TextStyleDefinition(
    display: 'Drop Cap',
    cssClass: 'dropCap',
    defaultSize: (size) => size * 4,
  ),
  'al': TextStyleDefinition(
    display: 'Above Staff',
    cssClass: 'aboveLinesText',
    defaultSize: (size) => size,
  ),
  'choralSign': TextStyleDefinition(
    display: 'Choral Sign',
    cssClass: 'choralSign',
    size: (ctxt) => ctxt.staffInterval * 1.5,
  ),
  'lyric': TextStyleDefinition(
    display: 'Lyric',
    cssClass: 'lyric',
    defaultSize: (size) => size * 0.9,
  ),
  'translation': TextStyleDefinition(
    display: 'Translation',
    cssClass: 'translation',
    defaultSize: (size) => size * 0.75,
  ),
};
