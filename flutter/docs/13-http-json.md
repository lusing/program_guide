# 13 · 网络与 JSON：数据从远方来

> 对应示例：examples/13_http_json/

## 13.1 解决什么问题

本地写死的数据终究要换成真数据：请求 HTTP 接口、解析 JSON、变成类型安全的对象。异步底座（Future/await）在 [Dart 教程·第 15 章](../dart/docs/15-async.md)，JSON 建模模板在 [Dart 教程·第 18 章](../dart/docs/18-files-json-http.md)——本章只讲 Flutter 侧怎么把它们接进界面，以及一个重要工程习惯：**依赖注入让页面可测**。

请求侧用 Flutter 官方第一方包 `http`（pubspec 里 `http: ^1.2.0`）：

```dart
Future<List<NewsItem>> Function() fetchFrom(String url) => () async {
      // ═══ 13.1 http 包：一行 GET，未来 JSON 解码 ═══
      final resp = await http.get(Uri.parse(url));
      final list = jsonDecode(resp.body) as List<dynamic>;
      return list
          .map((e) => NewsItem.fromJson(e as Map<String, dynamic>))
          .toList();
    };
```

为什么不用裸 dart:io HttpClient（Dart 教程 18 章教过）？http 包 API 更顺手（`resp.body` 已解码、状态码直接读）且跨平台（Web 上自动换实现）；两者心智模型一致，学过的 await/JSON 全部适用。

## 13.2 数据建模：fromJson 一行海关

```dart
// ═══ 13.2 数据模型 + fromJson（模板见 Dart 教程·第 18 章） ═══
class NewsItem {
  const NewsItem({required this.id, required this.title, required this.done});

  factory NewsItem.fromJson(Map<String, dynamic> json) => NewsItem(
        id: json['id'] as int,
        title: json['title'] as String,
        done: json['done'] as bool,
      );
```

模型类 + factory fromJson + toJson：**dynamic 世界到类型世界的海关**，逐字段 as 强转，类型不对当场抛错而不是拖到千里之外。完整模板（嵌套/可空字段/列表）看 Dart 教程 18 章——Flutter 生态的 json_serializable 代码生成只是把这个样板自动化，手写先懂原理。

## 13.3 自测型后端：零外网的示例

```dart
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
```

学习网络章最烦的是"接口挂了示例就废了"——本示例**内置一个本地 HttpServer**（随机端口、固定返回两条 JSON），`flutter run` 即有真数据可看。这个"自测型"模式直接搬自 Dart 教程 18 章，写自己的练习 Demo 时同样好用。

## 13.4 消费数据：initState 发请求 + FutureBuilder

```dart
class _NewsPageState extends State<NewsPage> {
  late final Future<List<NewsItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.fetcher(); // 只在 initState 发一次请求（第 14 章坑位）
  }
```

请求发在 **initState**（一次性），结果存成 State 字段 `_future`，build 里交给 FutureBuilder 渲染（第 14 章专门讲三态渲染）。为什么不在 build 里现发？build 会被调用多次——每次重建都打一遍接口。这个坑 14 章展开。

## 13.5 依赖注入：让页面可测

```dart
class NewsApp extends StatelessWidget {
  // ═══ 13.5 依赖注入：main 传真实现，测试注入假 fetcher ═══
  const NewsApp({super.key, required this.fetcher});

  final Future<List<NewsItem>> Function() fetcher;
```

页面**不自己写死数据源**，而是接收一个 `fetcher` 函数：main 传"真 HTTP"，widget 测试传"假数据"：

```dart
    await tester.pumpWidget(NewsApp(
      fetcher: () async => const [NewsItem(id: 1, title: '本地假数据 A', done: true)],
    ));
```

这就是依赖注入在 Flutter 里最朴素的形态——构造参数传函数/对象。第 17 章的存储、第 20 章的 NotesStorage 都是同款思路：**边界（网络/文件）注入化，核心逻辑才可测**。

## 13.6 频道切换：参数化 URL + Drawer 联动

真实资讯类 App 的列表不是一张嘴等喂数据——用户在抽屉里换频道，列表得跟着换请求。《Flutter从0基础到App上线》13 章的头条新闻实战把这套联动浓缩成一个模式：**频道对象 = 显示名 + 请求参数**：

```dart
// ═══ 13.6 ═══
class Channel {
  const Channel(this.id, this.name);   // 书里的 ChannelList(type, name) 同构
  final String id;                     // 进 URL 的请求参数
  final String name;                   // Drawer 里显示的名字
}

const channels = [
  Channel('top', '头条'), Channel('shehui', '社会'), Channel('keji', '科技'),
];

Future<List<NewsItem>> fetchNews(Channel c) async {
  // 每次换频道都要重新生成 URL——参数变了旧地址就是废纸
  final uri = Uri.parse('https://api.example.com/news')
      .replace(queryParameters: {'channel': c.id});
  ...
}
```

当年如此 → 现在这样：书里 `new List()` + `channelList.add(...)` 逐个塞；现代是 `const` 列表字面量。联动链路两跳：Drawer 的 `ListTile.onTap` 换 `currentChannel` → 触发 `fetchNews(currentChannel)` 重拉。频道与页面的解耦升级版见第 29 章——用 Stream 广播替代直接持有，换频道的发起方甚至不需要认识列表页。

## 坑位清单

- **build 里发请求**：每次重建都发（帧率掉、接口被打爆）——initState 发一次存 State（14 章详述）。
- **jsonDecode 结果裸用**：全程 dynamic、拼错字段名运行时才炸——立刻 as + fromJson 进类型世界。
- **错误处理只考虑成功**：断网/500 时 FutureBuilder 给你 error 态（14 章），别让界面白屏。
- **API key 写进代码**：桌面应用也是要发出去的——配置/环境变量，别提交仓库。
---

上一章：[12 · 列表与滚动：从十条到十万条](12-lists.md) ｜ 下一章：[14 · 异步 UI：把 Future 画出来](14-async-ui.md) ｜ 返回：[README](../README.md)
