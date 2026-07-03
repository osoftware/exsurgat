import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

export 'src/quick_svg.dart';

class Neumes extends StatefulWidget {
  const Neumes({super.key, required this.gabc});

  final String gabc;

  @override
  State<Neumes> createState() => _NeumesState();
}

class _NeumesState extends State<Neumes> {
  final _ctrl = WebViewController();

  @override
  initState() {
    super.initState();
    initWebView();
  }

  Future<void> initWebView() async {
    await _ctrl.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _ctrl.addJavaScriptChannel(
      'Ready',
      onMessageReceived: (_) {
        _ctrl.runJavaScript(
          "setChant('${widget.gabc}'); renderChant(window.innerWidth);",
        );
      },
    );
    await _ctrl.addJavaScriptChannel('SvgResult', onMessageReceived: (msg) {});
    await _ctrl.loadFlutterAsset('packages/exsurgat/assets/exsurge.html');
  }

  @override
  void didUpdateWidget(covariant Neumes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gabc != widget.gabc) {
      _ctrl.runJavaScript(
        "setChant(`${widget.gabc}`); renderChant(window.innerWidth);",
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    MediaQuery.widthOf(context);
    _ctrl.runJavaScript("renderChant(window.innerWidth);");
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: WebViewWidget(controller: _ctrl),
    );
  }
}
