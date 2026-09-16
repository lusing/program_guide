# 18 · 文件、JSON 与 HTTP：dart:io 三件套

> 对应示例：examples/18_files_json_http.dart

## 18.1 解决什么问题

程序落地的三件事：**配置与缓存**（文件）、**与外界交换数据**（JSON）、**提供服务/调服务**（HTTP）。Dart 全部装进标准库——`dart:io` 管文件与网络，`dart:convert` 管编解码。零第三方依赖把这三件事做完，是本章的目标。

```dart
  // ═══ 18.1 File：读写文本与追加 ═══
  final dir = await Directory.systemTemp.createTemp('dart_guide_');
  final file = File('${dir.path}/note.txt');
  await file.writeAsString('第一行\n', mode: FileMode.write);
  await file.writeAsString('第二行\n', mode: FileMode.append);
  final text = await file.readAsString();
  print('文件内容：${text.trim().split('\n')}');
  print('存在=${await file.exists()} 大小=${await file.length()} 字节');
```

File 的现代 API 都是 **Future 风格**（await 即用）；`mode` 控制 write/append。每个方法几乎都有同步兄弟（`readAsStringSync`）——只该在纯 CLI 的"启动即读"场景用，server/Flutter 里同步 IO 会卡事件循环（第 15 章的教训）。

## 18.2 Directory：目录的创建与列举

```dart
  // ═══ 18.2 Directory：创建与列出 ═══
  await File('${dir.path}/extra.txt').writeAsString('x');
  final entries = await dir.list().toList();
  print('临时目录有 ${entries.length} 个条目');
  await dir.delete(recursive: true); // 清理临时目录
```

`Directory.systemTemp.createTemp('前缀_')` 造一次性目录（测试夹具标配，第 19/20 章都用它）；`list()` 返回 Stream（第 16 章）——大目录可以逐个处理而不必一次装满；`delete(recursive: true)` 连锅端。

## 18.3 JSON：编码与解码

```dart
  // ═══ 18.3 JSON：编码/解码 ═══
  final jsonText = jsonEncode({'name': 'Dart', 'scores': [90, 85]});
  print('编码：$jsonText');
  final decoded = jsonDecode(jsonText); // 静态类型是"动态的" Map/List
  print('解码：${decoded['name']} / ${decoded['scores'][1]}');
  print('解码类型：${decoded.runtimeType}');
```

`jsonEncode/jsonDecode` 一对函数完成往返，但要看清解码产物的真实类型：JSON 对象 → `Map<String, dynamic>`，数组 → `List<dynamic>`（runtimeType 打印为 `_Map<String, dynamic>` 即证）。**动态意味着从这里开始编译器不再帮你**——字段名拼错、类型取错都运行时才炸。所以：

## 18.4 类型安全 JSON：fromJson/toJson 模板

```dart
// ═══ 18.4 类型安全的 JSON：手写 fromJson/toJson ═══
class Book {
  final String title;
  final int year;
  const Book(this.title, this.year);

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        json['title'] as String,
        json['year'] as int,
      );

  Map<String, dynamic> toJson() => {'title': title, 'year': year};

  @override
  String toString() => '《$title》($year)';
}
```

```dart
  final books = [const Book('Dart 实战', 2026), const Book('深入浅出', 2025)];
  final bookJson = jsonEncode(books.map((b) => b.toJson()).toList());
  final restored = (jsonDecode(bookJson) as List)
      .map((e) => Book.fromJson(e as Map<String, dynamic>))
      .toList();
  print('还原：$restored');
```

模式四步：**工厂构造** `fromJson` 做"dynamic 世界 → 类型世界"的海关（逐字段 `as`，错了当场 TypeError 而不是拖到千里之外）；**toJson** 反向（注意 jsonEncode 收 `Map` 不是收对象，要先 `.map(toJson).toList()`）；`Map<String, dynamic>` 是字段值的标准类型；嵌套结构递归同构。生态里 json_serializable 等代码生成器免写这套样板——理解手写版之后，生成器只是省力工具。

## 18.5 HttpServer：起一个本地服务

dart:io 自带 HTTP 服务器与客户端，一个"自测型"示例收尾——**起服务 → 自己请求自己 → 关闭退出**，不依赖外网也不挂起：

```dart
  // ═══ 18.5 HttpServer：随机端口起服务，自请求一次后关闭 ═══
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final url = 'http://127.0.0.1:${server.port}';
  server.listen((request) async {
    final response = request.response;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode({'ok': true, 'path': request.uri.path}));
    await response.close();
  });

  final client = HttpClient();
  final req = await client.getUrl(Uri.parse('$url/hello'));
  final res = await req.close();
  final body = await utf8.decodeStream(res);
  print('HTTP ${res.statusCode} 响应：$body');

  await server.close(force: true);
  client.close();
```

四个要点：`bind(回环地址, 0)` 的 **0 = 随机端口**（测试不撞口，server.port 拿实际值）；服务端在 `listen` 里拿 request 写 response（一个 await + close 一气呵成）；客户端 HttpClient 三步 `getUrl → close → 读流`（`utf8.decodeStream` 把字节流拼成字符串，因为 HTTP body 是字节不是文本）；**用完 close**——server.close(force: true) 与 client.close()，少了它们进程不退出（第 16 章的同款纪律）。这套"自测型服务"骨架在第 19 章测试、真实 API 开发里都能直接套用。

## 坑位清单

- **裸用 jsonDecode 结果**：`decoded['a']['b']` 全程 dynamic，拼错字段名运行时才炸——尽快 `as` 进具体类型（18.4 模板）。
- **相对路径依赖 cwd**：`File('data.json')` 的相对基准是**运行目录**不是源码目录；跨机器用绝对路径或启动参数传（第 20 章的 `-f` 设计）。
- **HttpServer 不 close**：进程挂着不退出；本教程 build 脚本跑示例时就会当场暴露。
- **忘设 Content-Type**：客户端拿到的就是纯文本；JSON 接口必设 `ContentType.json`。
- **Windows 路径**：拼接用 `/` 在 Windows 的 dart:io 也能工作，但展示给用户时留意 `Platform.pathSeparator`。
