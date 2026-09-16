import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// 13 网络与 JSON：http 包、fromJson、依赖注入让页面可测
Future<void> main() async {
  // ═══ 13.4 自测型后端：本地起一个 HttpServer，零外网依赖 ═══
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    final body = jsonEncode([
      {'id': 1, 'title': '第一条新闻', 'done': true},
      {'id': 2, 'title': '第二条新闻', 'done': false},
    ]);
    request.response.headers.contentType = ContentType.json;
    request.response.write(body);
    await request.response.close();
  });
  runApp(NewsApp(fetcher: fetchFrom('http://127.0.0.1:${server.port}/notes')));
}

// ═══ 13.2 数据模型 + fromJson（模板见 Dart 教程·第 18 章） ═══
class NewsItem {
  const NewsItem({required this.id, required this.title, required this.done});

  factory NewsItem.fromJson(Map<String, dynamic> json) => NewsItem(
        id: json['id'] as int,
        title: json['title'] as String,
        done: json['done'] as bool,
      );

  final int id;
  final String title;
  final bool done;
}

Future<List<NewsItem>> Function() fetchFrom(String url) => () async {
      // ═══ 13.1 http 包：一行 GET，未来 JSON 解码 ═══
      final resp = await http.get(Uri.parse(url));
      final list = jsonDecode(resp.body) as List<dynamic>;
      return list
          .map((e) => NewsItem.fromJson(e as Map<String, dynamic>))
          .toList();
    };

class NewsApp extends StatelessWidget {
  // ═══ 13.5 依赖注入：main 传真实现，测试注入假 fetcher ═══
  const NewsApp({super.key, required this.fetcher});

  final Future<List<NewsItem>> Function() fetcher;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      home: NewsPage(fetcher: fetcher),
    );
  }
}

class NewsPage extends StatefulWidget {
  const NewsPage({super.key, required this.fetcher});

  final Future<List<NewsItem>> Function() fetcher;

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  late final Future<List<NewsItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.fetcher(); // 只在 initState 发一次请求（第 14 章坑位）
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('网络与 JSON')),
      // ═══ 13.3 消费 Future：FutureBuilder（第 14 章展开） ═══
      body: FutureBuilder<List<NewsItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('加载失败：${snapshot.error}'));
          }
          final items = snapshot.data;
          if (items == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: [
              for (final n in items)
                ListTile(
                  leading: Icon(
                      n.done ? Icons.check_box : Icons.check_box_outline_blank),
                  title: Text(n.title),
                ),
            ],
          );
        },
      ),
    );
  }
}
