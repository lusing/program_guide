import 'package:flutter/material.dart';

import 'counter.dart';

// 19 Widget 测试：被测对象本身——纯逻辑 + 薄 UI
void main() => runApp(const TestingApp());

class TestingApp extends StatelessWidget {
  const TestingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const CounterPage(),
    );
  }
}

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  final _counter = Counter();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('测试分层')),
      body: Center(child: Text('value = ${_counter.value}')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(_counter.increment),
        child: const Icon(Icons.add),
      ),
    );
  }
}
