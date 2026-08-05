import 'dart:convert';

import 'package:exsurgat/exsurgat.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GABC code editor',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const EditorPage(title: 'GABC code editor'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class EditorPage extends StatefulWidget {
  const EditorPage({super.key, required this.title});
  final String title;

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final _gabcCtrl = TextEditingController(text: '(c3) ');

  bool dropCap = true;
  bool fancy = false;

  final fancyTheme = ChantTheme(
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
      font: GoogleFonts.uncialAntiqua().fontFamily,
      relativeSize: (size) => size * 4,
      color: Colors.deepOrange,
    ),
    aboveLine: TextStyleDefinition(relativeSize: (size) => size),
    choralSign: TextStyleDefinition(size: (ctxt) => ctxt.staffInterval * 1.5),
    lyric: TextStyleDefinition(relativeSize: (size) => size * 0.9),
    translation: TextStyleDefinition(relativeSize: (size) => size * 0.75),
  );
  final normalTheme = ChantTheme(
    baseTextStyle: BaseTextStyle(
      font: GoogleFonts.crimsonPro().fontFamily!,
      size: 16,
    ),
  );
  @override
  Widget build(BuildContext context) {
    final chantTheme = fancy ? fancyTheme : normalTheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: saveSvg,
            icon: Icon(Icons.save),
            tooltip: 'Save as SVG',
          ),
        ],
      ),
      body: Column(
        children: [
          TextField(
            style: TextStyle(fontFamily: 'Consolas'),
            autofocus: true,
            minLines: 1,
            maxLines: 10,
            controller: _gabcCtrl,
          ),
          Row(
            children: [
              Switch.adaptive(
                value: dropCap,
                onChanged: (v) => setState(() => dropCap = v),
              ),
              Text('Drop Cap'),
              VerticalDivider(),
              Switch.adaptive(
                value: fancy,
                onChanged: (v) => setState(() => fancy = v),
              ),
              Text('Fancy Theme'),
            ],
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8.0),
              color: Colors.amber.withAlpha(40),
              child: ListenableBuilder(
                listenable: _gabcCtrl,
                builder: (_, _) => ChantScoreView(
                  gabc: _gabcCtrl.text,
                  useDropCap: dropCap,
                  theme: chantTheme,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: loadSampleScore,
        tooltip: 'Load Sample Score',
        child: const Icon(Icons.abc_sharp),
      ),
    );
  }

  Future<void> saveSvg() async {
    final renderingContext = ChantContext(
      textMeasuringStrategy: .svg,
      stylingMode: .attributes,
      theme: fancy ? fancyTheme : ChantTheme.kDefaultTheme,
    );
    final score =
        ChantScore(
            ctxt: renderingContext,
            mappings: Gabc.createMappingsFromSource(
              renderingContext,
              _gabcCtrl.text,
            ),
            header: GabcHeader.fromSource(_gabcCtrl.text),
            useDropCap: true,
          )
          ..performLayout(renderingContext)
          ..layoutChantLines(renderingContext, 800);
    final xml = score.createSvgNode(renderingContext).toXmlString();
    await FilePicker.saveFile(
      allowedExtensions: ['.svg'],
      dialogTitle: 'Save chant to SVG',
      fileName: 'chant.svg',
      bytes: Utf8Codec().encode(xml),
    );
  }

  Future<void> loadSampleScore() async {
    _gabcCtrl.text = '''
annotation: Ant
mode: 7 a
title: Exsurgat Deus
text-right: <b>Ps 68 (67)</b>
%%
(c3)Ex(e)súr(g)gat(h) De(ihji)us,(i) *(,) et(i) dis(j)si(i)pén(hg)tur(ef) in(g)i(h)mí(f)ci(f) e(e)ius.(e) (::)
E(i) u(i) o(j) u(i) a(h) e.(gf) (::)
''';
  }
}
