# 22 · 集中状态管理：从传参链到 ScopedModel

> 对应示例：examples/22_scoped_model/

## 22.1 解决什么问题

第 09 章解决了"两个组件共享一份数据"（提升 + InheritedNotifier）。但应用一大，新问题浮出水面：**状态散落在各处、靠构造参数长链下传**。2020 年《Flutter实战指南》用一个资讯 App 演示了这个痛点的完整解法——实体建模 + 集中式 ScopedModel，这套思路就是今天 provider/Riverpod 的直系祖先。本章手写一个 ~70 行的 scoped_model（零依赖）把它彻底讲透，顺路收编书里第 10 章的两个列表优化件（Dismissible 滑动删除、ListTile 打磨）。

## 22.2 传参链之痛

```dart
// ═══ 22.2 书 11.1：中间组件被迫当"传菜员" ═══
class ManageNews extends StatelessWidget {
  final Function addNews;       // 自己不用，转给 Tab
  final Function deleteNews;    // 自己不用，转给 Tab
  final Function updateNews;    // 自己不用，转给 Tab
  final List<Map<String, dynamic>> news;  // 还是用 Map 存的裸数据
  ManageNews(this.addNews, this.deleteNews, this.news, this.updateNews);
}
```

状态放根组件，每次加功能就多一根"数据 + 方法引用"的穿层管道；`main.dart` 越长越肿。两个坏味道同时出现：**穿层传参**与**裸 Map 当模型**。

## 22.3 实体类：先让数据有类型

```dart
// ═══ 22.3 书 11.2：final 字段 + required + 默认值，取代 Map ═══
class NewsItem {
  const NewsItem({required this.title, required this.score, this.isFavorite = false});

  final String title;
  final double score;
  final bool isFavorite;

  NewsItem copyWith({String? title, double? score, bool? isFavorite}) => NewsItem(
        title: title ?? this.title,
        score: score ?? this.score,
        isFavorite: isFavorite ?? this.isFavorite,
      );
}
```

裸 `Map<String, dynamic>` 的字段名拼错要到运行时才炸；实体类让 analyzer 管住拼写与类型。`final` 字段表达"不改对象、换新对象"——换的时候用 `copyWith`（书年代手抄全部字段重建，如今一行搞定，这是"当年如此/现在这样"的第一个点）。

## 22.4 手写 ScopedModel：三个零件

书用的 `scoped_model` 包（2018 年出品，2022 年停更）核心只有三个零件，全部能用手学过的原语拼出来：

```dart
// ═══ 22.4 lib/scoped_model.dart：手写核心 ≈ 60 行 ═══
// 零件一：Model —— 历史事实：包里的 Model 就是 ChangeNotifier 的子类
abstract class Model extends ChangeNotifier {}

// 零件二：ScopedModel —— 把一份中央状态挂到树上（包住 MaterialApp）
class ScopedModel<T extends Model> extends StatelessWidget {
  const ScopedModel({super.key, required this.model, required this.child});
  final T model;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      _InheritedScope<T>(model: model, child: child);
}

class _InheritedScope<T extends Model> extends InheritedNotifier<T> {
  const _InheritedScope({required T super.notifier, required super.child});
}

// 零件三：ScopedModelDescendant —— 订阅 + 取用，notifyListeners 时 builder 重跑
class ScopedModelDescendant<T extends Model> extends StatelessWidget {
  const ScopedModelDescendant({super.key, required this.builder, this.child});
  final Widget? child;  // 不随通知重建的"静态子树"（书里 builder 的第二个参数）
  final Widget Function(BuildContext, Widget?, T) builder;

  @override
  Widget build(BuildContext context) => builder(
        context,
        child,
        context.dependOnInheritedWidgetOfExactType<_InheritedScope<T>>>()!.notifier!,
      );
}
```

对照第 09 章：`_InheritedScope` 就是你的 `CartScope`，`Model` 就是 `Cart extends ChangeNotifier`——**scoped_model 不是新魔法，是把 09 章的手法产品化**。用起来：

```dart
// ═══ 22.4（续）三步：建模型 → 挂树上 → 后代订阅 ═══
ScopedModel<MainScopeModel>(
  model: MainScopeModel()..seed(),          // ① 中央状态只在根创建一次
  child: MaterialApp(home: NewsListPage()),
)
// 任意后代（含 showDialog 弹出的对话框）：
ScopedModelDescendant<MainScopeModel>(
  builder: (context, child, model) => IconButton(
    icon: Icon(model.showFavorites ? Icons.favorite : Icons.favorite_border),
    onPressed: model.toggleDisplayMode,     // ③ 改模型，依赖处自动重建
  ),
)
```

## 22.5 模型层的规矩

书 11.3–11.8 节沉淀出集中式模型的四条军规，全部进了示例：

```dart
mixin NewsPart on Model {
  final List<NewsItem> _news = [];      // ① 私有状态：外界只能走方法
  bool _showFavorites = false;

  // ② getter 出口做防御性拷贝：外部改不动内部（List.of 复制的是列表不是元素）
  List<NewsItem> get displayNews => List.of(
      _showFavorites ? _news.where((n) => n.isFavorite).toList() : _news);

  // ④ 改完必 notifyListeners——忘了就"切页才刷新"（书 11.7 的原版坑）
  void addNews(NewsItem item) {
    _news.add(item);
    notifyListeners();
  }

  void deleteNews(NewsItem item) {          // 按实体不按索引（见下）
    _news.remove(item);
    notifyListeners();
  }

  void toggleFavorite(NewsItem item) {
    final i = _news.indexOf(item);
    if (i < 0) return;
    _news[i] = item.copyWith(isFavorite: !item.isFavorite);  // 换新对象
    notifyListeners();
  }

  void toggleDisplayMode() {
    _showFavorites = !_showFavorites;
    notifyListeners();
  }
}
```

- **忘了 notifyListeners**：收藏图标点了没反应，切走再切回来才变——数据变了没广播（书 11.7 用整整一节讲这个"啊哈时刻"）。重建是精确的：只有 `Descendant` 的 builder 重跑，宿主 widget 的 build 不动。
- **索引 vs 实体**：书用"选中索引"当光标（`selectNews(i)` → `deleteNews()`），每个方法收尾都要 `_selectedIndex = null`，而且**过滤模式下展示索引和内部索引错位**是经典 bug。按实体操作（`remove(item)` 走同一性匹配）从根上免掉这层心智负担——示例回归测试专门锁这个场景。
- **getter 出防御性拷贝**：外界拿到的列表改了也不影响内部（要更狠可以回 `List.unmodifiable`——改直接抛，19 章 fake 存储撞的就是它）。

## 22.6 多模型合并：mixin 登场

第二个领域状态（用户）进来时，`ScopedModel` 只有一个 `model:` 参数。书的解法是 Dart 的 mixin：

```dart
// ═══ 22.6 书 11.10：with 把多个领域模型合并成一个中央模型 ═══
mixin UserPart on Model {
  String? userName;
  void login(String name) { userName = name; notifyListeners(); }
  void logout() { userName = null; notifyListeners(); }
}

class MainScopeModel extends Model with NewsPart, UserPart {}
```

`with` 不是继承：把两个 mixin 的成员**拍平**进同一个类，一个 model 参数全带走。书 11.11 还演示了"连接两个模型"（建资讯时记下当前用户）——因为合并后 `_user` 与 `_news` 同类可见，`addNews` 直接读用户名即可。现代评注：provider 时代的答案是 `MultiProvider`（各模型独立挂树、不需要合并类），跨模型调用则靠构造注入——**合并是 scoped_model 时代的形状**。

## 22.7 从 ScopedModel 到今天

| 2020 书写法 | 是什么 | 现在的对应 |
|---|---|---|
| `Model` | ChangeNotifier 子类 | `ChangeNotifier`（09 章） |
| `ScopedModel(model:, child:)` | 挂树 | `ChangeNotifierProvider` / 09 章 InheritedNotifier |
| `ScopedModelDescendant(builder:)` | 订阅 | `context.watch` / `Consumer` |
| `MainScopeModel with A, B` | 合并模型 | `MultiProvider` |

scoped_model 停更于 2022，provider 是同批作者写的直系继任（把 `Descendant` 换成 `context.watch/read`、支持多模型组合），Riverpod 再往下一代（编译期安全、脱离 BuildContext）。**理解了本章这 60 行，所有这些工具你都等于提前看懂了源码**——选型时回到 09 章的表。

## 坑位清单

- **改了数据忘 notifyListeners**：界面"切页才刷新"——模型方法里改完必通知。
- **getter 裸返回内部列表**：外部一改，状态被旁路——出口做拷贝或 unmodifiable。
- **过滤列表的 index 传给模型**：展示索引 ≠ 内部索引——按实体操作，或传过滤前算好的引用。
- **在 build 里调模型方法**：`builder: (c, w, m) => m.addNews(...)` 每次重建都执行——改模型的调用放回调/生命周期里。
- **对话框里找不到模型**：`showDialog` 的路由挂在 Navigator 下、仍在 `ScopedModel` 子树内——能找到；但如果你把模型挂在了某个页面下面，全屏对话框就够不着了（挂根上）。
---

上一章：[21 · 调试与 DevTools：让代码开口说话](21-debugging.md) ｜ 下一章：[23 · 认证与凭据：token 的完整一生](23-auth.md) ｜ 返回：[README](../README.md)
