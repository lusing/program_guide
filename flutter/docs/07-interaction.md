# 07 · 交互与对话框：点击、轻提示、确认

> 对应示例：examples/07_interaction/

## 7.1 解决什么问题

静态界面会展示了，接下来让它"活"：**用户的点击进来，界面的反馈出去**。Flutter 把交互拆成两层：手势识别（怎么点）与反馈呈现（对话框/轻提示/面板）。回调是一切的粘合剂——`onPressed` 传函数，正是 [Dart 教程·第 05 章](../dart/docs/05-functions.md) 的匿名函数与箭头语法。

两层点击组件，按需选：

```dart
          // ═══ 7.1 InkWell：水波纹点击（Material 风格首选） ═══
          Card(
            child: InkWell(
              onTap: () => setState(() => _taps++),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('点我（InkWell）：$_taps 次'),
              ),
            ),
          ),
          // ═══ 7.2 GestureDetector：更底层的原始手势 ═══
          Card(
            child: GestureDetector(
              onDoubleTap: () => setState(() => _taps += 10),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('双击（GestureDetector）+10'),
              ),
            ),
          ),
```

| | InkWell | GestureDetector |
|---|---|---|
| 定位 | Material 行为 | 原始手势识别 |
| 反馈 | 水波纹、hover 态 | 无 |
| 手势 | onTap/onDoubleTap… | 全套：拖动/长按/缩放/二级点击… |

**默认 InkWell**（要 Material 观感），要 GestureDetector 的独门手势（如 `onSecondaryTap` 右键、`onPanUpdate` 拖动）才换它。常用手势速查：`onTap / onDoubleTap / onLongPress / onSecondaryTap(右键，桌面)`。

## 7.2 AlertDialog：模态确认

```dart
  void _showDialog() {
    // ═══ 7.3 AlertDialog：确认对话框与返回值 ═══
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('删除')),
        ],
      ),
    );
  }
```

`showDialog` 不是构造 Widget 而是**推一条新路由**（第 10 章的伏笔）：对话框是"覆盖在页面上的临时页"。`builder` 提供内容，`actions` 放按钮（惯例：取消在左用 TextButton、确认在右用高一级按钮）。关闭即 `Navigator.pop(context)`；要带回结果就 `pop(context, true)`，调用方 `final ok = await showDialog<bool>(...)` 接住——第 20 章删除确认就是这么写的。

## 7.3 SnackBar：不打断的轻提示

```dart
  void _showSnackBar() {
    // ═══ 7.4 SnackBar：轻提示（挂在 ScaffoldMessenger 上） ═══
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('已保存')));
  }
```

SnackBar 是底部滑入、几秒自动消失的轻提示，适合"已保存/已复制"这类无需确认的反馈。注意它是挂在 **ScaffoldMessenger** 上而不是某个 Scaffold——`of(context)` 沿树向上找到最近的信使，由它管理显示（哪怕页面已切换也不会悬空）。常用参数：`duration`（时长）、`action`（SnackBarAction 附带撤销按钮）。

## 7.4 模态 BottomSheet：从底部升起的选项

```dart
  void _showSheet() {
    // ═══ 7.5 模态 BottomSheet ═══
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => const ListTile(title: Text('底部面板内容')),
    );
  }
```

`showModalBottomSheet` 与 Dialog 同为模态（挡住背后、点外关闭），只是从底部升起——适合"一组相关选项"（分享渠道、更多操作）。内容多时记得给固定高度或包 ListView。选型：**二选一确认用 Dialog，选项菜单用 Sheet，告知用 SnackBar**。

## 7.5 手势竞技场与原始指针

GestureDetector 的回调清单（点击/双击/长按/横竖拖动/缩放/次级点击）在 7.1 已见。往深一层：**同一根手指落下时，所有感兴趣的识别器进入"竞技场"，只有一个能赢**。三条裁决规则够用：

1. **同节点共存**：`onTap` 与 `onLongPress` 可以共存（语义不冲突，看谁先成立）；但 `onHorizontalDrag` 与 `onVerticalDrag` 同节点**互相排斥**（框架只能判一个方向，都不触发或抖动）；
2. **父子竞争，深的赢**：ListView 里一个可拖动卡片——内层识别器先赢，列表不滚；这是"嵌套滚动/拖拽"一切行为的根源；
3. **兄弟层叠，命中测试说了算**：Stack 上层组件命中（`HitTestBehavior.opaque` 连空隙都算）后，下层根本收不到指针——32 章索引条盖在列表上不抢手势就是靠这个。

比 GestureDetector 更底的一层是 **Listener**——**原始指针事件**（无语义、无竞技场）：

```dart
// ═══ 7.5 ═══
Listener(
  onPointerDown: (e) => print('按下 at ${e.localPosition}'),
  onPointerMove: (e) => ...,
  onPointerUp: (e) => ...,
  child: ...,
)
```

用途：自制手势（竞技场语义不够用，比如"画板"要每一根指针的原始轨迹）、指针级统计（多指触控）。日常点击长按永远先用 GestureDetector/InkWell；Listener 是"框架不给力时自己上"的后门——32 章的 A–Z 索引条就是"竖向拖动 + 位置换算"这类**位置敏感**交互，用 onVerticalDragUpdate 的 localPosition 正好够，再刁钻的需求才轮到 Listener。

## 坑位清单

- **async 回调里直接用 context**：`await showDialog(...)` 之后 context 可能已失效——用前必查 `if (!context.mounted) return;`（lint 会强制）。
- **SnackBar 报 "ScaffoldMessenger not found"**：widget 树上没有 MaterialApp/Scaffold 祖先——测试里要 pumpWidget 完整 App 而不是光秃秃的页面。
- **Dialog 没关就跳页面**：路由栈叠乱（Dialog 还在上面）——先 pop 对话框再 push。
- **onPressed: null 与 () {} 混淆**：null 是禁用（灰），`() {}` 是可点但无事发生；测试断言"点击有反应"时写错会安静地失败。
---

上一章：[06 · Material 组件库：搭积木的说明书](06-material.md) ｜ 下一章：[08 · 有状态 Widget：setState 与生命周期](08-stateful.md) ｜ 返回：[README](../README.md)
