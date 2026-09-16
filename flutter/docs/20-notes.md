# 20 · 实战：记事本

> 对应示例：examples/20_notes/

## 20.1 成品走查

一个完整的桌面记事本：**列表 → 新建/编辑 → 保存 → 删除 → 换主题**，数据落在 JSON 文件。运行方式：

```bash
cd examples/20_notes && flutter run -d windows
```

功能与每步的出处：

| 功能 | 行为 | 用到的章 |
|---|---|---|
| 笔记列表 | 启动从文件加载，空态提示 | 12/17 |
| 新建/编辑 | FAB 新建；点条目进编辑页；✓ 保存返回 | 08/10 |
| 删除 | 长按条目 → 确认对话框 | 07 |
| 主题切换 | AppBar 图标一键深浅 | 16 |
| 持久化 | 每次变更写回 JSON 文件 | 17 |
| 测试 | 六个用例覆盖核心流程 | 19 |

## 20.2 工程结构：入口薄、模型纯、存储抽象

```text
20_notes/
├── lib/
│   ├── main.dart      入口 + 列表页（组装层）
│   ├── note.dart      Note 模型（纯数据）
│   ├── storage.dart   NotesStorage 抽象 + 文件实现
│   └── edit_page.dart 编辑页
└── test/notes_test.dart
```

四文件各司其职：**入口薄**（runApp 装配 + 根主题状态）、**模型纯**（Note 无任何 Flutter 依赖）、**存储抽象**（接口隔离实现）、**页面自治**（EditPage 不知道存储的存在，只管"编辑完 pop 带回结果"）。这是 13/17/19 章"可测设计"的落地形态——也是你能带走复用的工程骨架。

## 20.3 模型：Note 与时间戳

```dart
class Note {
  const Note({
    required this.id,
    required this.title,
    required this.body,
    this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as int,
        title: json['title'] as String,
        body: json['body'] as String,
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  Note copyWith({String? title, String? body, DateTime? updatedAt}) => Note(
        id: id,
        title: title ?? this.title,
        body: body ?? this.body,
        updatedAt: updatedAt ?? this.updatedAt,
      );
```

fromJson/toJson 是 [Dart 教程·第 20 章](../dart/docs/20-todo.md) 同款海关；**copyWith 是 Flutter 世界的高频惯用法**——Widget 不可变，"改一条笔记"永远是"复制一份新的"（07 章哲学的应用）。**DateTime 不会自动序列化**：存前 `toIso8601String()`、读时 `DateTime.tryParse`（tryParse 吃 null/垃圾返回 null——旧数据兼容就靠它）。

## 20.4 存储抽象：接口 + 文件实现

```dart
abstract class NotesStorage {
  Future<List<Note>> load();
  Future<void> save(List<Note> notes);
}

class FileNotesStorage implements NotesStorage {
  FileNotesStorage(this.path);
  // …readAsString / writeAsString + jsonDecode / JsonEncoder.withIndent
```

页面只认 `NotesStorage` 接口：main 装配 `FileNotesStorage(临时目录/notes.json)`，测试装配内存实现。换实现（换云端、换 DB）不动页面——第 09/13 章的依赖注入思想收口于此。

## 20.5 列表页：三态一职责

```dart
  Future<void> _openEditor({Note? note}) async {
    final saved = await Navigator.push<Note>(
      context,
      MaterialPageRoute(
        builder: (_) => EditPage(note: note, nextId: _nextId()),
      ),
    );
    if (saved == null || !mounted) return;
    setState(() {
      final i = _notes.indexWhere((n) => n.id == saved.id);
      if (i >= 0) {
        _notes[i] = saved;
      } else {
        _notes.insert(0, saved);
      }
    });
    await widget.storage.save(_notes);
  }
```

列表页管三态：**加载中**（CircularProgressIndicator）→ **空态**（提示文案）→ **数据**（ListView.builder，12 章）。`_openEditor` 是新建/编辑共用通道：push 后 await 编辑页 pop 回来的 Note（10 章），indexWhere 判断"更新还是插入"，**改完内存立刻落盘**。删除走长按 + 确认对话框（07 章），同样"改内存 → 落盘"两步。 mounted 检查在两处 await 之后——纪律回顾。

## 20.6 编辑页：controller 与保存即 pop

```dart
class _EditPageState extends State<EditPage> {
  late final _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
  late final _bodyCtrl = TextEditingController(text: widget.note?.body ?? '');

  void _save() {
    final note = (widget.note ?? Note(id: widget.nextId, title: '', body: ''))
        .copyWith(
      title: _titleCtrl.text,
      body: _bodyCtrl.text,
      updatedAt: DateTime.now(),
    );
    Navigator.pop(context, note);
  }
```

`late final x = TextEditingController(text: widget.note?.title ?? '')` 是**编辑页惯用形**：controller 初始化要用 widget 参数，late 延迟到首次访问（08 章）。保存逻辑极简：有旧笔记 copyWith、没旧笔记 new 一个，`pop(context, note)` 把结果交还列表页——编辑页不碰存储，职责干净。

## 20.7 测试：注入内存存储走全流程

```dart
class InMemoryStorage implements NotesStorage {
  InMemoryStorage([this.seed = const []]);
  final List<Note> seed;
  List<Note> saved = [];
  @override
  Future<List<Note>> load() async => [...seed]; // 返回拷贝：调用方要 insert/remove
  @override
  Future<void> save(List<Note> notes) async => saved = [...notes];
}
```

六个用例三层覆盖：模型 JSON 往返（纯 test）、文件存储往返（纯 test + 临时文件）、四个 widget 流程（初始渲染/新建保存/长按删除/主题切换，全部注入 InMemoryStorage）。注意测试夹具的教训：**load 返回拷贝**——页面拿到列表要 insert/remove，返回 const 原表会"unmodifiable list"炸掉。

## 20.8 扩展方向

每个方向都是一次独立练习：搜索过滤（TextField + where 过滤列表）、markdown 渲染（生态 flutter_markdown）、自动保存防抖（Timer 重置）、系统托盘（生态 tray_manager）、多窗口（等官方支持）、导出分享。做完这些，你已经在真实工程里了。

## 坑位清单

- **内存改了忘落盘**（或反之）：列表与文件不一致——固定"两步走"纪律：setState 改内存、紧接着 await save。
- **DateTime 直接 jsonEncode**：不报错但存的是字符串，读回时 `as DateTime` 崩——手转 ISO 字符串（20.3）。
- **编辑页拿旧 controller**：热重载后 State 复用而 widget.note 变了——didUpdateWidget 里同步，或页面不复用。
- **空标题笔记**：列表里显示兜底文案（`n.title.isEmpty ? '（无标题）' : n.title`），别让用户看到空白行。
