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

套路四步：`getInstance()`（异步拿实例）→ 读 `getInt(key) ?? 默认` → 写 `setXxx` → await 后 mounted 检查再 setState。它是异步 API 但背后是小文件/注册表（Windows 下由插件托管），秒级完成。

### 支持类型与 API 面

shared_preferences（pub.dev 当前 2.5.x）支持五种类型：

| 写入 | 读取 | 场景 |
|---|---|---|
| `setInt(key, int)` | `getInt(key)` | 计数、版本号 |
| `setDouble(key, double)` | `getDouble(key)` | 浮点设置 |
| `setBool(key, bool)` | `getBool(key)` | 开关 |
| `setString(key, String)` | `getString(key)` | 单字符串 |
| `setStringList(key, List<String>)` | `getStringList(key)` | 简单列表 |

管理操作：`remove(key)` 删一个、`clear()` 全清、`getKeys()` 列全部键、`containsKey(key)` 判存在。读一个不存在的键返回 null（不是抛错）——所以 `prefs.getInt(_prefsKey) ?? 0` 的兜底写法是标准姿势。

**测试金钥匙**：`SharedPreferences.setMockInitialValues({...})` 注入预置值，widget 测试不用碰真实存储——示例测试就是"预置 7 → 界面显示 7 → +1 → 实例里真是 8"全链路。

### 什么时候不用 prefs

prefs 适合"几十个键值对"。出现以下信号就该换文件/数据库：要存**嵌套结构**（Map 里套 List）、要**按条件查询**（"找出所有未完成的"）、单条数据**超过几十 KB**（prefs 底层是整文件读写，大 value 拖慢全部键的存取）。

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

把文件操作**封装成类**（构造收 path，方法读/写），UI 只调方法——第 20 章的 FileNotesStorage 是同款思路的完整版（还多一层抽象接口供测试注入）。

### 路径策略：path_provider 四目录

示例用 `Directory.systemTemp` 演示（重启即丢，纯教学）；**真实应用**用 path_provider（pub.dev 当前 2.1.x）取平台正确的目录：

| 方法 | 语义 | 该放什么 |
|---|---|---|
| `getApplicationDocumentsDirectory()` | 用户可见的应用文档目录 | 用户数据（记事、导出文件） |
| `getApplicationSupportDirectory()` | 应用内部支持目录 | 配置文件、应用私有数据 |
| `getApplicationCacheDirectory()` | 应用缓存目录 | 可重新下载的缓存（图片、临时 JSON） |
| `getTemporaryDirectory()` | 系统临时目录 | 随时可丢的 scratch 数据 |

桌面端对应关系（Windows）：documents → `C:\Users\<user>\Documents`（或应用子目录）、support → `%APPDATA%\<包名>`、cache/temp → `%LOCALAPPDATA%\<包名>\Cache` 和 `%TEMP%`。选错目录的后果：放 temp 用户重启就没了；放 documents 卸载时可能残留——**用户数据 documents，应用私有 support，可再得 cache**。

### 读写纪律

- **写**：`writeAsString` 默认覆盖整个文件——JSON 落盘是"全量重写"，没有增量更新。数据量大了（每次保存重写 10MB）就该上数据库。
- **读**：先 `exists()` 再读（首次启动文件不存在），或 try-catch `FileSystemException`——示例用前者，更显式。
- **并发**：没有内置文件锁——两个写操作并发会互相截断。应用内保证"同一文件同一时刻只有一个写者"（串行化或单例封装）。

## 17.4 测试两层法：IO 不进假时钟

widget 测试跑在 FakeAsync 环境里，真实文件 IO 的事件不一定推进——所以示例的测试文件分两层：**普通 `test()`** 做文件往返（真实 IO，测封装类），**testWidgets** 做 prefs 流（mock 值）。判断口诀：测"存储对不对"用纯 test，测"界面吃数据"用注入/mock 的 widget 测试——这正是第 13 章依赖注入思想的存储版。

```dart
// 纯 test：真实文件 IO，测 FileCounter 封装
test('FileCounter 读写往返', () async {
  final tmp = File('${Directory.systemTemp.path}/test_${DateTime.now().microsecondsSinceEpoch}.json');
  final counter = FileCounter(tmp.path);
  await counter.write(42);
  expect(await counter.read(), 42);
  await tmp.delete();
});

// testWidgets：prefs 走 mock，不碰真实存储
testWidgets('prefs 计数显示与 +1', (tester) async {
  SharedPreferences.setMockInitialValues({'prefs_count': 7});
  await tester.pumpWidget(const PersistApp());
  await tester.pump();  // 等 initState 里的异步加载完成
  expect(find.text('prefs 计数：7'), findsOneWidget);
  await tester.tap(find.text('prefs +1 并保存'));
  await tester.pump();
  expect(find.text('prefs 计数：8'), findsOneWidget);
});
```

注意 widget 测试里 `pump()` 的必要性：`_loadPrefs` 是异步的，首帧 build 时 `_prefsCount` 还是 0——`pump()` 让微任务队列跑完，setState 后的帧才出现"7"。漏掉这步会看到"0"然后断言失败。

## 17.5 选型：键值 / 文件 / 数据库

书 7.5 用 sqflite 做通讯录 CRUD（建库建表 + 增查）。三条路线怎么选：

| 路线 | 适合 | 不适合 | 依赖 |
|---|---|---|---|
| shared_preferences | 设置项、小标志位 | 结构化查询、大数据量 | 第一方 |
| 文件（JSON 落盘） | 中等结构、整体读写（第 20 章记事本） | 频繁局部更新 | 零依赖 |
| SQLite（sqflite） | 大量记录、条件查询、迁移 | 简单场景（杀鸡牛刀） | **社区包** |

sqflite（pub.dev 当前 2.4.x）是社区事实标准（非 flutter.dev 第一方，本教程的第一方主线不引入），但概念值得记住。基本形状：

```dart
final db = await openDatabase(
  '${(await getApplicationDocumentsDirectory()).path}/app.db',
  version: 1,
  onCreate: (db, version) => db.execute(
    'create table notes(id integer primary key, title text, body text)',
  ),
);

// 增（参数占位防注入）
await db.insert('notes', {'title': t, 'body': b});

// 查（? 占位 + 参数列表）
final rows = await db.rawQuery(
  'select * from notes where title like ?',
  ['%$keyword%'],
);
```

要点：数据库文件放应用私有目录（path_provider 的 `getApplicationDocumentsDirectory()` 拼库名）；`onCreate` 只在首次建库时跑，后续结构变更走 `onUpgrade`（按 version 号分支迁移）；**SQL 拼接用 `?` 占位**（`rawQuery('... where id = ?', [id])`）防注入——字符串插值拼 SQL 是安全红线。桌面端（Windows/macOS/Linux）sqflite 通过 `sqflite_common_ffi` 支持（`sqfliteFfiInit()` + `databaseFactory = databaseFactoryFfi`），移动端直接可用。数据量到"文件每次全量重写开始肉疼"时，就是上它的时机——在那之前，第 20 章的文件方案完全够。

## 17.6 写入时机：什么时候落盘

"什么时候写"和"怎么写"同样重要。三个常见时机：

- **即时写**：每次变更立刻落盘（示例的 prefs +1）。简单可靠，但高频操作（每敲一个字存一次）IO 浪费。
- **防抖写**：变更后 N 秒无新变更才落盘——`Timer` 重置式：

```dart
Timer? _saveTimer;

void _onChanged() {
  _saveTimer?.cancel();
  _saveTimer = Timer(const Duration(seconds: 2), _save);
}
```

- **生命周期写**：`didChangeAppLifecycleState` 监听退后台（`AppLifecycleState.paused`）时统一落盘——配合防抖，"退后台必存"双保险。第 20 章实战的记事本就是"编辑页即时写 + 列表页读盘"的最简组合。

## 坑位清单

- **忘 await 的读写**：写还没落盘就退出，数据丢了；读拿到旧值——prefs/文件 API 全是 Future。
- **initState 里同步读 prefs**：拿不到（异步）——initState 里启动加载，回调里 setState（示例 `_loadPrefs` 的形状）。
- **相对路径依赖 cwd**：`File('data.json')` 的基准是运行目录不是工程目录——绝对路径或注入。
- **大 JSON 塞 prefs**：它是键值不是数据库——结构化数据走文件/DB。
- **path_provider 目录选错**：用户数据放 temp 重启即丢；缓存放 documents 卸载残留——documents（用户数据）/ support（应用私有）/ cache（可再得）对号入座。
- **JSON 落盘没有事务**：写到一半进程被杀 = 文件截断损坏——重要数据写临时文件再 rename 原子替换（`writeAsString` 到 `x.json.tmp`，完成后 `rename` 成 `x.json`）。
- **sqflite 字符串拼 SQL**：`'where id = $id'` 是注入红线——`?` 占位 + 参数列表。
- **测试里忘 pump 等异步加载**：initState 里的异步读首帧还没回来——`pump()` 让微任务跑完再断言。
---

上一章：[16 · 主题与响应式：一处定义，处处生效](16-theme.md) ｜ 下一章：[18 · 桌面专题：Windows 的一等公民](18-desktop.md) ｜ 返回：[README](../README.md)
