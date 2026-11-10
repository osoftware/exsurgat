import 'package:exsurgat/exsurgat.dart';
import 'package:exsurgat/internals.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingTool extends Tool {
  final taps = <List<ChantHitTestTarget>>[];
  final hovers = <List<ChantHitTestTarget>>[];

  @override
  void handleTap(TapUpDetails details, List<ChantHitTestTarget> targets) {
    taps.add(targets);
  }

  @override
  void handleHover(PointerHoverEvent event, List<ChantHitTestTarget> targets) {
    hovers.add(targets);
  }
}

class _AdditionalGestureTool extends _RecordingTool {
  int longPresses = 0;

  @override
  Map<Type, GestureRecognizerFactory> buildGestures() => {
    ...super.buildGestures(),
    LongPressGestureRecognizer:
        GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(),
          (recognizer) => recognizer.onLongPress = () => longPresses++,
        ),
  };
}

class _ReplacementGestureTool extends _RecordingTool {
  int customTaps = 0;

  @override
  Map<Type, GestureRecognizerFactory> buildGestures() => {
    TapGestureRecognizer:
        GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(),
          (recognizer) => recognizer.onTap = () => customTaps++,
        ),
  };
}

void main() {
  Future<void> showScore(
    WidgetTester tester,
    ChantDocument document,
    Tool tool,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 600,
            height: 400,
            child: ChantScoreBody.editable(document: document, tool: tool),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Offset notePosition(Tool tool) {
    final neume = tool.score.notations.whereType<Neume>().first;
    final note = neume.notes.first;
    return tool.renderObject.localToGlobal(
      Offset(
        neume.line.bounds.x +
            neume.bounds.x +
            note.bounds.x +
            note.bounds.width / 2,
        neume.line.bounds.y + note.bounds.y + note.bounds.height / 2,
      ),
    );
  }

  testWidgets('base tool handles tap and hover with ordered targets', (
    tester,
  ) async {
    final document = ChantDocument.fromSource('mode:5\n%%\nA(c)');
    final tool = _RecordingTool();
    await showScore(tester, document, tool);
    final position = notePosition(tool);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: position);
    await mouse.moveTo(position);
    await tester.pump();
    expect(tool.hovers.last.first.element, isA<Note>());
    await tester.tapAt(position);
    await tester.pumpAndSettle();
    expect(tool.taps, hasLength(1));
    expect(tool.taps.single.first.element, isA<Note>());
    expect(tool.taps.single[1].element, isA<Neume>());
    await mouse.removePointer();
  });

  testWidgets('tool can add recognizers without losing default tap', (
    tester,
  ) async {
    final document = ChantDocument.fromSource('mode:5\n%%\nA(c)');
    final tool = _AdditionalGestureTool();
    await showScore(tester, document, tool);
    final position = notePosition(tool);
    await tester.tapAt(position);
    await tester.pumpAndSettle();
    expect(tool.taps, hasLength(1));
    await tester.longPressAt(position);
    await tester.pumpAndSettle();
    expect(tool.longPresses, 1);
    expect(tool.taps, hasLength(1));
  });

  testWidgets('tool can replace default tap recognizer', (tester) async {
    final document = ChantDocument.fromSource('mode:5\n%%\nA(c)');
    final tool = _ReplacementGestureTool();
    await showScore(tester, document, tool);
    await tester.tapAt(notePosition(tool));
    await tester.pumpAndSettle();
    expect(tool.customTaps, 1);
    expect(tool.taps, isEmpty);
  });

  testWidgets('switching away and back invalidates a pending tap', (
    tester,
  ) async {
    final document = ChantDocument.fromSource('mode:5\n%%\nA(c)');
    final first = _RecordingTool();
    final second = _RecordingTool();
    await showScore(tester, document, first);
    final position = notePosition(first);
    final gesture = await tester.startGesture(position);
    await showScore(tester, document, second);
    await showScore(tester, document, first);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(first.taps, isEmpty);
    expect(second.taps, isEmpty);
    await tester.tapAt(position);
    await tester.pumpAndSettle();
    expect(first.taps, hasLength(1));
  });
}
