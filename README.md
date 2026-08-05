# exsurgat

Flutter package for rendering Gregorian chant from GABC notation.

`exsurgat` parses GABC source and draws chant staves, neumes, lyrics, titles, annotations directly in Flutter widgets and exports to SVG or PNG.

## Features

- Compile Gregorian chant from GABC source
- Display the sheet as a scrollable or non-scrollable Flutter widget
- Export to SVG or PNG
- Customize layout and colors

## Getting started

Add `exsurgat` to `dependencies` in `pubspec.yaml`. 

```yaml
dependencies:
  exsurgat:
```

For correct rendering of `{greextra}` codes you'll also need to add a font.

```yaml
flutter:
  fonts:
    - family: greextra
      fonts:
        - asset: packages/exsurgat/fonts/greextra.otf

```

Import package:

```dart
import 'package:exsurgat/exsurgat.dart';
```

## Basic usage

Use `ChantScoreView` to render a scrollable sheet from a GABC source string with a desired line width and padding:

```dart
String source = '''
annotation: Ant
mode: 7 a
title: Exsurgat Deus
text-right: <b>Ps 68 (67)</b>
%%
(c3)Ex(e)súr(g)gat(h) De(ihji)us,(i) *(,) et(i) dis(j)si(i)pén(hg)tur(ef) in(g)i(h)mí(f)ci(f) e(e)ius.(e) (::)
''';
return ChantScoreView(
  useDropCap: true,
  width: 800,
  padding: const EdgeInsets.all(12),
  gabc: source,
);
```

![Resulted rendering](https://cecile.orb.net.pl/img/exsurgat-deus.png)

For a non-scrollable widget that fills available space, use `ChantScoreBody` instead.

`ChantScoreView` uses `ChantScoreBody` internally.

## Customization

Use `ChantTheme` to customize fonts, sizes and colors of the sheet.

```dart
ChantScoreView(
  gabc: source,
  useDropCap: true,
  width: 800,
  padding: const EdgeInsets.all(12),
  theme: ChantTheme(
    textColor: Colors.brown,
    rubricColor: ChantColors.rubric,
    neumeColor: Colors.indigo,
    staffLineColor: ChantColors.nigric,
    dividerLineColor: Colors.blueGrey,
    baseTextStyle: BaseTextStyle(
      font: GoogleFonts.imFellDwPica().fontFamily!,
      size: 16,
    ),
    supertitle: TextStyleDefinition(relativeSize: (size) => (size * 7) / 6),
    title: TextStyleDefinition(relativeSize: (size) => (size * 3) / 2),
    subtitle: TextStyleDefinition(relativeSize: (size) => size),
    leftRight: TextStyleDefinition(relativeSize: (size) => size * 0.9),
    annotation: TextStyleDefinition(relativeSize: (size) => (size * 2) / 3),
    dropCap: TextStyleDefinition(
      font: 'Lombardic',
      relativeSize: (size) => size * 4,
      color: Colors.deepOrange,
    ),
    aboveLine: TextStyleDefinition(relativeSize: (size) => size),
    choralSign: TextStyleDefinition(size: (ctxt) => ctxt.staffInterval * 1.5),
    lyric: TextStyleDefinition(relativeSize: (size) => size * 0.9),
    translation: TextStyleDefinition(relativeSize: (size) => size * 0.75),
  ),
)
```
![Resulted rendering](https://cecile.orb.net.pl/img/exsurgat-deus-themed.png)

## SVG rendering

To export chant engraving to Scalable Vector Format - write code similar to the following snippet:

```dart
final renderingContext = ChantContext(textMeasuringStrategy: .svg);
final score =
    ChantScore(
        ctxt: renderingContext,
        mappings: Gabc.createMappingsFromSource(renderingContext, source),
        header: GabcHeader.fromSource(source),
        useDropCap: true,
      )
      ..performLayout(renderingContext)
      ..layoutChantLines(renderingContext, 800);
final xml = score.createSvgNode(renderingContext).toXmlString();
await File('output.svg').writeAsString(xml);
```
![output.svg](https://cecile.orb.net.pl/img/exsurgat-deus.svg)

## Bitmap rendering

To export chant engraving to Portable Network Graphics - write code similar to the following snippet:

```dart
final renderingContext = ChantContext(textMeasuringStrategy: .canvas);
final score =
    ChantScore(
        ctxt: renderingContext,
        mappings: Gabc.createMappingsFromSource(renderingContext, source),
        header: GabcHeader.fromSource(source),
        useDropCap: true,
      )
      ..performLayout(renderingContext)
      ..layoutChantLines(renderingContext, 800);
final image = await score.createImage(renderingContext, scale: 2);
final png = await image.toByteData(format: .png);
await File('output.png').writeAsBytes(png!.buffer.asInt8List());
```
![output.png](https://cecile.orb.net.pl/img/exsurgat-deus-transparent.png)


## Example app

The `example/` folder includes a live editor that updates chant rendering as you type GABC source.


## License

MIT license. See `LICENSE` for details.

## Credits

This project started as a Dart port of a JavaScript project [exsurge](https://github.com/bbloomf/exsurge) created by Fr. Matthew Spencer OSJ and maintained by Benjamin Bloomfield.

## Support

* [Buy me a coffee](https://buymeacoffee.com/ostudio)

* [Donate eCash (XEC)](https://pay.e.cash/?bip21=ecash:qrx0l5a2cjg679pghc7kalc8ff7uczf58qu7n49rwa)