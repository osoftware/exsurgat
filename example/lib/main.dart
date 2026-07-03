import 'package:flutter/material.dart';
import 'package:exsurgat/exsurgat.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _incrementCounter() {
    setState(() {
      gabc = '''
(c3) IN(h) tho(h)se(h) days(h) a(h) de(h)cre(h)e(h) went(h) o(h)ut(h) from(h) Ca(h)e(h)sar(h) Au(h)gus(h)tus(h)
that(h) the(h) who(h)le(h) world(h) sho(h)uld(h) be(h) en(h)rol(f)led.(g.) (:) This(h) was(h) the(h) first(h) en(h)roll(h)ment,(g.) (;) when(h) Qui(h)ri(h)ni(h)us(h) was(h) go(h)ver(h)nor(h) of(h) Sy(h)ri(d)a.(d.) (:) So(h) all(h) went(h) to(h) be(h) en(h)rol(h)led,(h.) (;) e(h)ach(h) to(h) his(h) own(f) town.(g.) (:) And(h) Jo(h)seph(h) to(h)o(h) went(h) up(h) from(h) Ga(h)li(h)le(h)e(h) from(h) the(h) town(h) of(h) Na(h)za(h)reth(h)
to(h) Ju(h)de(h)a,(g.) (;) to(h) the(h) ci(h)ty(h) of(h) Da(h)vid(h) that(h) is(h) cal(h)led(h) Beth(h)le(h)hem,(g.) (;) be(h)cau(h)se(h) he(h) was(h) of(h) the(h) ho(h)u(h)se(h) and(h) fa(h)mi(h)ly(h) of(h) Da(h)vid,(g.) (;) to(h) be(h) en(h)rol(h)led(h) with(h) Ma(h)ry,(h) his(h) be(h)tro(h)thed,(h) who(h) was(h) with(f) child.(g.) (:) Whi(h)le(h) the(h)y(h) we(h)re(h) the(h)re,(h.) (,) the(h) ti(h)me(h) ca(h)me(h) for(h) her(h) to(h) ha(h)ve(h) her(h) child,(h.) (;) and(h) she(h) ga(h)ve(h) birth(h) to(h) her(h) first(h)born(f) son.(g.) (:) She(h) wrap(h)ped(h) him(h) in(h) swadd(h)ling(h) clo(h)thes(h) and(h) la(h)id(h) him(h) in(h) a(h) man(h)ger,(g.) (;) be(h)cau(h)se(h) the(h)re(h) was(h) no(h) ro(h)om(h) for(h) them(h) in(h) the(f) inn.(g.) (:) Now(h) the(h)re(h) we(h)re(h) she(h)pherds(h) in(h) that(h) re(h)gi(h)on(h) li(h)ving(h) in(h) the(h) fi(h)elds(h.) (,) and(h) ke(h)e(h)ping(h) the(h) night(h) watch(h) o(h)ver(h) the(h)ir(h) f(f)lock.(g.) (:) The(h) an(h)gel(h) of(h) the(h) Lord(h) ap(h)pe(h)a(h)red(h) to(h) them(h.) (,) and(h) the(h) glo(h)ry(h) of(h) the(h) Lord(h) sho(h)ne(h) a(h)ro(g)und(f) them,(hg..) (;) and(h) the(h)y(h) we(h)re(h) s(h)truck(h) with(h) gre(h)at(h) fe(h.)ar.(d.) (:) The(h) an(h)gel(h) sa(h)id(h) to(f) them,(hg..) (;) "Do(h) not(h) be(h) a(h)fra(h)id;(h.) (;) for(h) be(h)hold,(h) I(h) pro(h)cla(h)im(h) to(h) y(h)o(h)u(h) go(h)od(h) news(h) of(h) gre(h)at(h) jo(h)y(h)
that(h) will(h) be(h) for(h) all(h) the(h) pe(h)o(h.)ple.(d.) (:) For(h) to(h)day(h) in(h) the(h) ci(h)ty(h) of(h) Da(h)vid(h)
a(h) sa(h)vi(h)or(h) has(h) be(h)en(h) born(h) for(h) y(h)o(h)u(h) who(h) is(h) Christ(h) and(f) Lord.(g.) (:) And(h) this(h) will(h) be(h) a(h) sign(h) for(h) y(h)o(h)u:(g.) (;) y(h)o(h)u(h) will(h) find(h) an(h) in(h)fant(h) wrap(h)ped(h) in(h) swadd(h)ling(h) clo(h)thes(h)
and(h) ly(h)ing(h) in(h) a(h) man(h.)ger."(d.) (:) And(h) sud(h)den(h)ly(h) the(h)re(h) was(h) a(h) mul(h)ti(h)tu(h)de(h) of(h) the(h) he(h)a(h)ven(h)ly(h) host(h) with(h) the(h) an(h)gel,(h.) (,) pra(h)i(h)sing(h) God(h) and(h) say(h)ing:(g.) (;) "Glo(h)ry(h) to(h) God(h) in(h) the(h) h(h)ighest,(g.) (;) and(h) on(h) e(h)arth(h) pe(h)a(h)ce(h) to(h) tho(h)se(h) on(h) whom(h) his(h) fa(i)vor(h) rests."(gxg..) (::)
''';
    });
  }

  String gabc = "(c4)";
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Neumes(gabc: gabc),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
