import 'package:flutter/material.dart';

/// Test Repaint area.
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Counter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  int innerIndex = 0;
  ValueNotifier<int> innerIndexNotifier = ValueNotifier(0);

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hello World Counter'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            StatefulBuilder(builder: (context, innerSetState) {
              return TextButton(
                  onPressed: () {
                    innerIndex++;
                    innerSetState(() {});
                  },
                  child: Text('Only refresh my self $innerIndex'));
            }),
            RepaintBoundary(
              child: StatefulBuilder(builder: (context, innerSetState) {
                return TextButton(
                    onPressed: () {
                      innerIndex++;
                      innerSetState(() {});
                    },
                    child: Text('RepaintBoundary $innerIndex'));
              }),
            ),
            ValueListenableBuilder(
                valueListenable: innerIndexNotifier,
                builder: (BuildContext context, value, Widget? child) {
                  return TextButton(
                      onPressed: () {
                        innerIndexNotifier.value++;
                      },
                      child: Text(
                          'ValueListenableBuilder ${innerIndexNotifier.value}'));
                }),
            const TestMiniRefresh(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TestMiniRefresh extends StatefulWidget {
  const TestMiniRefresh({super.key});

  @override
  State<TestMiniRefresh> createState() => _TestMiniRefreshState();
}

class _TestMiniRefreshState extends State<TestMiniRefresh> {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        setState(() {});
      },
      child: const Text('Hi there'),
    );
  }
}
