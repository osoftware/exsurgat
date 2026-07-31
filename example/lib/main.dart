import 'package:exsurgat/exsurgat.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
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
            ],
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8.0),
              color: Colors.amber.withAlpha(40),
              child: ListenableBuilder(
                listenable: _gabcCtrl,
                builder: (_, _) =>
                    ChantScoreView(gabc: _gabcCtrl.text, useDropCap: dropCap),
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

  void loadSampleScore() {
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
