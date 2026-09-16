import 'dart:async';

import 'package:flutter/material.dart';

// 14 异步 UI：FutureBuilder 与 StreamBuilder、加载/错误/数据三态
void main() => runApp(const AsyncUiApp());

class AsyncUiApp extends StatelessWidget {
  const AsyncUiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
      ),
      home: const AsyncUiPage(),
    );
  }
}

class AsyncUiPage extends StatefulWidget {
  const AsyncUiPage({super.key});

  @override
  State<AsyncUiPage> createState() => _AsyncUiPageState();
}

class _AsyncUiPageState extends State<AsyncUiPage> {
  // ═══ 14.2 状态里存 Future，而不是在 build 里现造 ═══
  Future<String>? _future;
  // ═══ 14.4 Stream.periodic + take：有限个 tick 的流 ═══
  final Stream<int> _ticks = Stream<int>.periodic(
    const Duration(milliseconds: 300),
    (i) => i + 1,
  ).take(5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('异步 UI')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: [
              // 注意：setState 的回调不能是"返回 Future 的箭头函数"（赋值表达式会返回值）
              FilledButton(
                onPressed: () => setState(() {
                  _future = Future.value('成功的数据');
                }),
                child: const Text('成功'),
              ),
              OutlinedButton(
                onPressed: () => setState(() {
                  // ..ignore()：future 在 FutureBuilder 订阅前就完成时，
                  // 不判为"未处理异步错误"（错误本身仍由 FutureBuilder 呈现）
                  _future = Future<String>.error('服务器 500')..ignore();
                }),
                child: const Text('失败'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ═══ 14.1 FutureBuilder：一次异步值的三态渲染 ═══
          FutureBuilder<String>(
            future: _future,
            builder: (context, snap) => switch (snap.connectionState) {
                  ConnectionState.none => const Text('还没发起请求'),
                  ConnectionState.done when snap.hasError => Text(
                      '加载失败：${snap.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ConnectionState.done => Text('拿到：${snap.data}'),
                  _ => const CircularProgressIndicator(),
                },
          ),
          const Divider(height: 32),
          // ═══ 14.3 StreamBuilder：序列数据逐个到达 ═══
          StreamBuilder<int>(
            stream: _ticks,
            builder: (context, snap) => Text(
              snap.hasData ? 'tick ${snap.data}/5' : '等待第一个事件…',
            ),
          ),
        ],
      ),
    );
  }
}
