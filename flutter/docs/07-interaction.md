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

### GestureDetector 的完整手势清单

| 类别 | 回调 | 说明 |
|---|---|---|
| 点击 | `onTap` / `onTapDown` / `onTapUp` | 轻点 |
| | `onDoubleTap` | 双击 |
| | `onLongPress` | 长按 |
| 拖动 | `onPanUpdate` | 任意方向拖动（`details.localPosition` 当前位置） |
| | `onHorizontalDragUpdate` / `onVerticalDragUpdate` | 单方向拖动（带方向锁） |
| 缩放 | `onScaleUpdate` | 双指捏合（`details.scale` 缩放比） |
| 次级 | `onSecondaryTapUp` | 鼠标右键 |

`onPanUpdate` 与 `onVerticalDragUpdate` 的区别：前者无方向锁（横竖斜都行），后者**锁定垂直方向**——垂直列表内的拖动卡片用后者，避免与列表滚动抢方向。

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

### AlertDialog 的完整参数面

| 参数 | 用途 |
|---|---|
| `icon` | 标题上方的图标（`Icon(Icons.warning)`） |
| `title` | 标题（`Text('确认删除？')`） |
| `content` | 正文（`Text('删除后不可恢复')`，可放任意 Widget） |
| `actions` | 底部按钮列表 |
| `actionsAlignment` | 按钮对齐（默认右对齐；`MainAxisAlignment.spaceBetween` 拉开两端） |
| `scrollable` | 内容超长时允许整体滚动（默认 false，内容超高会溢出） |

### SimpleDialog：选项列表

`SimpleDialog` 是"无 actions 的 AlertDialog"——正文区直接放选项列表：

```dart
final color = await showDialog<String>(
  context: context,
  builder: (context) => SimpleDialog(
    title: const Text('选择颜色'),
    children: [
      SimpleDialogOption(
        onPressed: () => Navigator.pop(context, '红'),
        child: const Text('红色'),
      ),
      SimpleDialogOption(
        onPressed: () => Navigator.pop(context, '蓝'),
        child: const Text('蓝色'),
      ),
    ],
  ),
);
```

选型：**确认/警告用 AlertDialog（actions 按钮），多选一用 SimpleDialog（选项即内容）**。

### showDialog 的 barrier 参数

```dart
showDialog<bool>(
  context: context,
  barrierDismissible: false,  // 点外部不关闭（强制用户选择）
  barrierColor: Colors.black54, // 遮罩颜色
  builder: /* ... */,
)
```

`barrierDismissible` 默认 true（点遮罩关闭，Future 得 null）；`false` 用于"必须明确选择"的场景（退出确认、条款同意）。

## 7.3 SnackBar：不打断的轻提示

```dart
  void _showSnackBar() {
    // ═══ 7.4 SnackBar：轻提示（挂在 ScaffoldMessenger 上） ═══
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('已保存')));
  }
```

SnackBar 是底部滑入、几秒自动消失的轻提示，适合"已保存/已复制"这类无需确认的反馈。注意它是挂在 **ScaffoldMessenger** 上而不是某个 Scaffold——`of(context)` 沿树向上找到最近的信使，由它管理显示（哪怕页面已切换也不会悬空）。常用参数：`duration`（时长）、`action`（SnackBarAction 附带撤销按钮）。

### SnackBar 的常用配置

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text('已删除'),
    duration: const Duration(seconds: 3),      // 默认 4 秒
    action: SnackBarAction(
      label: '撤销',
      onPressed: _undo,
    ),
    behavior: SnackBarBehavior.floating,        // 悬浮卡片样式（默认贴底通栏）
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
);
```

新的 `showSnackBar` 会顶掉未消失的旧的（同屏最多一条）——连续操作只显示最新反馈，这是正确行为。

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

`showModalBottomSheet` 与 Dialog 同为模态（挡住背后、点外关闭），只是从底部升起——适合"一组相关选项"（分享渠道、更多操作）。选型：**二选一确认用 Dialog，选项菜单用 Sheet，告知用 SnackBar**。

### BottomSheet 的常用参数

| 参数 | 用途 |
|---|---|
| `isScrollControlled: true` | 内容高度不受 50% 屏高限制（全屏表单必备） |
| `shape` | 顶部圆角（`RoundedRectangleBorder(borderRadius: 顶部 16)`） |
| `isDismissible` | false = 禁止点外关闭（必须显式选择） |
| `enableDrag` | false = 禁止拖动关闭 |

`isScrollControlled: true` 的典型场景：底部弹出的评论输入框——默认 BottomSheet 最高半屏，全屏输入必须开它。

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
- **InkWell 没有水波纹**：父级背景色直接画在 Container 上（水波纹被盖住）——背景交给 Ink（`Ink(decoration: ..., child: InkWell(...))`）或让 InkWell 的 Material 祖先处理背景。
- **BottomSheet 内容超高溢出**：默认限高半屏——内容包 ListView 或 `isScrollControlled: true`。
---

上一章：[06 · Material 组件库：搭积木的说明书](06-material.md) ｜ 下一章：[08 · 有状态 Widget：setState 与生命周期](08-stateful.md) ｜ 返回：[README](../README.md)
