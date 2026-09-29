# 12 · 列表与滚动：从十条到十万条

> 对应示例：examples/12_lists/

## 12.1 解决什么问题

Column 装十条八条没问题；装一千条会**全部实例化 + 高度溢出黄黑条**。答案是有 20 年工程经验的老概念——虚拟化列表：**只构建看得见的**。Flutter 的 ListView 家族把这件事做到开箱即用，本示例用 40 条数据演示"远处的条目根本没建"。

```dart
  // 40 条：足够长，懒构建的差异才看得见（可见区 + 缓存区之外的条目不构建）
  static final _items = List.generate(40, (i) => '条目 ${i + 1}');
```

四种形态按需选：

| 形态 | 场景 |
|---|---|
| `ListView(children: [...])` | 十几条以内的静态列表 |
| `ListView.builder` | **大量/动态数据（默认选它）** |
| `ListView.separated` | builder + 分隔线 |
| `ListView.custom` | 完全定制（高级） |

## 12.2 ListView.separated：builder 三件套

```dart
            // ═══ 12.1 ListView.separated：懒构建 + 分隔线 ═══
            ListView.separated(
              itemCount: _items.length,
              itemBuilder: (context, i) => ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(_items[i]),
                trailing: const Icon(Icons.chevron_right),
              ),
              separatorBuilder: (_, _) => const Divider(height: 1),
            ),
```

builder 模式的契约：你给 `itemCount` 和 `itemBuilder(context, index)`，ListView 只对**可见区 + cacheExtent（默认约 250 逻辑像素）**内的 index 调 builder——滚动到哪建到哪，滚出视口的销毁。示例测试验证了这一点：初始时"条目 30"不存在于元素树里，滚过去才被构建。**itemBuilder 每次都可能新建**——项内状态（展开/选中）要自己存到数据或父级，别指望 widget 记住。

## 12.3 GridView.count：网格

```dart
            // ═══ 12.2 GridView.count：固定列数网格 ═══
            GridView.count(
              crossAxisCount: 4,
              children: [for (final f in _items) Center(child: Text(f))],
            ),
```

网格与列表同源（都是 BoxScrollView 的滚动协议）：`crossAxisCount` 定列数，`childAspectRatio`（宽/高比）定格子形状，同样有 builder 版（`GridView.builder`）懒构建。

## 12.4 Sliver 一瞥：拼装滚动区

`ListView`/`GridView` 其实都是 `CustomScrollView` + Sliver（滚动切片）的预制组合。当你要**一屏多段异构滚动**——顶部折叠头图（SliverAppBar）、接着网格（SliverGrid）、再接列表（SliverList）——就上 CustomScrollView 手拼 Sliver。现阶段知道"它们是同一族"即可，用到再查。

## 12.5 控制滚动：ScrollController

```dart
final _ctrl = ScrollController();
// ListView(controller: _ctrl, ...)
_ctrl.animateTo(0, duration: ..., curve: Curves.easeOut); // 平滑回顶
```

controller 拿到位置（offset/maxScrollExtent）并能动它（jumpTo/animateTo）；桌面加 `Scrollbar(controller: _ctrl, ...)` 才有可见滚动条（第 18 章桌面习惯）。dispose 纪律同第 08 章。

## 12.6 Dismissible：滑动删除

通讯录、会话列表的招牌操作——手指一滑删一项。`Dismissible` 包住列表项即可：

```dart
// ═══ 12.6 ═══
Dismissible(
  key: ValueKey(item.id),               // 必须给：唯一且稳定
  direction: DismissDirection.endToStart,  // 只许从右往左滑
  background: Container(color: Colors.red, child: Icon(Icons.delete)),  // 滑出时露出的底
  onDismissed: (direction) {
    setState(() => items.remove(item)); // 删数据！组件只是跟着数据走
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} 已删除')));
  },
  child: ListTile(title: Text(item.name)),
)
```

三条纪律：

- **key 是命门**：必须每项唯一且**跨删除稳定**（业务 id，不是数组下标）。用 `ValueKey(index)` 时删除一项后框架认错人，动画错乱甚至红屏；
- **onDismissed 里必须删数据**：组件已经飞出去了，数据不删的话滚回来它又"复活"；
- **要拦截就上 confirmDismiss**：返回 `Future<bool>`——false 则弹回不删（"确认删除该会话？"对话框版删除的正规入口）。

> **当年如此 → 现在这样**：老教程（与旧书示例）在 StatelessWidget 里 `List items = new List.generate(30, ...)` 直接 `items.removeAt(index)`——可变字段 + 按下标删，刷新后错位。现代写法：状态进 State、数据用 `remove(item)` 按实体删（22 章军规"按实体不按索引"在列表上的投影）。

## 坑位清单

- **ListView 嵌 ListView**：内层要 `shrinkWrap: true` + 固定高（能不嵌就别嵌），正经方案是 CustomScrollView 拼 Sliver。
- **"没滚到的条目不存在"**：find/finders 与业务都受影响——断言远处条目时先滚过去（第 19 章测试就用了 dragUntilVisible）。
- **separator 不占 itemCount**：separated 版的 itemCount 只算数据项，别把分隔线也算进去。
- **忘了 itemCount**：builder 无限造下去——数据多少就写多少。
---

上一章：[11 · 表单：校验与提交](11-forms.md) ｜ 下一章：[13 · 网络与 JSON：数据从远方来](13-http-json.md) ｜ 返回：[README](../README.md)
