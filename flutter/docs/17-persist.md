# 17 · 数据持久化：记住用户的世界

> 对应示例：examples/17_persist/

## 17.1 解决什么问题

应用一关，State 全没——用户的数据要活在进程之外。三档选型先立好：

| 档 | 工具 | 适用 |
|---|---|---|
| 键值 | `shared_preferences`（第一方包） | 设置项、计数、上次状态 |
| 文件 | `dart:io` + JSON | 结构化数据（本示例与 20 章实战用） |
| 数据库 | sqflite（生态）/ drift | 大量数据、要查询 |

JSON 建模（toJson/fromJson 模板）在 [Dart 教程·第 18 章](../dart/docs/18-files-json-http.md)讲过，本章直接用；文件 API 也是同一批（readAsString/writeAsString）——Flutter 侧新增的只是**何时读写**（生命周期配合）与**怎么测**。

## 17.2 shared_preferences：键值对

```dart
          // ═══ 17.2 shared_preferences：键值对存取 ═══
          Text('prefs 计数：$_prefsCount',
              style: Theme.of(context).textTheme.titleLarge),
          FilledButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final next = (prefs.getInt(_prefsKey) ?? 0) + 1;
              await prefs.setInt(_prefsKey, next);
              if (!mounted) return;
              setState(() => _prefsCount = next);
            },
            child: const Text('prefs +1 并保存'),
          ),
```

套路四步：`getInstance()`（异步拿实例）→ 读 `getInt(key) ?? 默认` → 写 `setInt/setString/setStringList` → await 后 mounted 检查再 setState。它是异步 API 但背后是小文件/注册表（Windows 下由插件托管），秒级完成。**测试金钥匙**：`SharedPreferences.setMockInitialValues({...})` 注入预置值，widget 测试不用碰真实存储——示例测试就是"预置 7 → 界面显示 7 → +1 → 实例里真是 8"全链路。

## 17.3 文件：读盘写盘按钮化

```dart
// ═══ 17.1 文件存储：JSON 落盘（模板见 Dart 教程·第 18 章） ═══
class FileCounter {
  FileCounter(this.path);

  final String path;

  Future<int> read() async {
    final file = File(path);
    if (!await file.exists()) return 0;
    return jsonDecode(await file.readAsString()) as int;
  }

  Future<void> write(int value) async {
    await File(path).writeAsString(jsonEncode(value));
  }
}
```

把文件操作**封装成类**（构造收 path，方法读/写），UI 只调方法——第 20 章的 FileNotesStorage 是同款思路的完整版（还多一层抽象接口供测试注入）。路径策略：示例用 `Directory.systemTemp` 演示；**真实应用**该用 path_provider（生态包）取应用数据目录（`getApplicationDocumentsDirectory()`），用户清缓存时数据不丢。

## 17.4 测试两层法：IO 不进假时钟

widget 测试跑在 FakeAsync 环境里，真实文件 IO 的事件不一定推进——所以示例的测试文件分两层：**普通 `test()`** 做文件往返（真实 IO，测封装类），**testWidgets** 做 prefs 流（mock 值）。判断口诀：测"存储对不对"用纯 test，测"界面吃数据"用注入/mock 的 widget 测试——这正是第 13 章依赖注入思想的存储版。

## 坑位清单

- **忘 await 的读写**：写还没落盘就退出，数据丢了；读拿到旧值——prefs/文件 API 全是 Future。
- **initState 里同步读 prefs**：拿不到（异步）——initState 里启动加载，回调里 setState（示例 `_loadPrefs` 的形状）。
- **相对路径依赖 cwd**：`File('data.json')` 的基准是运行目录不是工程目录——绝对路径或注入。
- **大 JSON 塞 prefs**：它是键值不是数据库——结构化数据走文件/DB。
