# 05 · 布局 II：线性、弹性与层叠

> 对应示例：examples/05_layout_multi/

## 5.1 解决什么问题

一个孩子怎么摆上一章讲完了；真实界面是"一排按钮、一列卡片、角标叠在图上"——多孩子布局的三位主角：Row/Column（线性）、Expanded/Flexible（弹性）、Stack（层叠）。理解它们的关键还是第 04 章那条协议：**约束向下、尺寸向上**——Row/Column 只是把它沿主轴重复了一遍。

```dart
        // ═══ 5.1（续）spaceEvenly：均分空隙；交叉轴默认居中拉伸 ═══
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            Chip(label: Text('左')),
            Chip(label: Text('中')),
            Chip(label: Text('右')),
          ],
        ),
```

Row 横排、Column 竖排，参数同构。两条轴先分清：**主轴**（Row 的水平/Column 的垂直）与**交叉轴**（另一个方向）。两个对齐参数各管一轴：

| 参数 | 管哪轴 | 常用值 |
|---|---|---|
| `mainAxisAlignment` | 主轴 | `start/end/center/spaceBetween/spaceEvenly/spaceAround` |
| `crossAxisAlignment` | 交叉轴 | `center`（默认）/`start/end`/`stretch`（撑满） |

spaceBetween 与 spaceEvenly 的区别一句话：**Between 把空隙只放中间，Evenly 连两端也均分**。spaceAround 是"两端半份、中间整份"——三个值的视觉差在示例里改一行就能看清。

### mainAxisSize：主轴方向的尺寸策略

Row/Column 默认占满主轴（`mainAxisSize: MainAxisSize.max`）——Row 默认和父级一样宽，哪怕内容只有一点。要"按内容收缩"（比如按钮组不撑满整行）：

```dart
Row(
  mainAxisSize: MainAxisSize.min,  // 按内容宽度收缩
  children: [/* 三个按钮 */],
)
```

注意边界：Column 在**可滚动父级**（ListView）里用 `mainAxisSize.min` 会退化——ListView 给子项的垂直约束是无界的，Column 不知道"多高算内容高"。不可滚动父级里没问题。

## 5.2 Expanded 与 Flexible：瓜分剩余空间

```dart
        child: Row(
          children: const [
            // ═══ 5.2（续）flex 比例瓜分；Flexible 先按需后让步 ═══
            Expanded(flex: 2, child: ColoredBox(color: Colors.green, child: Center(child: Text('2 份')))),
            Expanded(flex: 1, child: ColoredBox(color: Colors.teal, child: Center(child: Text('1 份')))),
            Flexible(child: ColoredBox(color: Colors.lime, child: Center(child: Text('让')))),
          ],
        ),
```

Row/Column 先让孩子按"想要多大"排，剩下的空隙怎么分？交给这两个：

| | 行为 | 典型用途 |
|---|---|---|
| `Expanded(flex: n)` | **必须**占满分到的份额 | 2:1 分栏、把列表撑满宽 |
| `Flexible(flex: n)` | 先按内容大小，**不超**份额 | 可长可短的标签区 |

`flex` 是比例：两个 Expanded flex 2:1 就是 2/3 与 1/3。它们还是"内容超宽"的第一解药——见坑位清单。

### Expanded = Flexible(tight)

api.flutter.dev 上的精确定义：`Expanded` 就是 `Flexible(fit: FlexFit.tight)` 的语法糖——强制孩子占满分配到的空间。`Flexible` 默认 `fit: FlexFit.loose`——孩子可以小于分配的空间。记住这个等价关系，两个 Widget 就只剩一个概念。

### Spacer：纯占位的 Expanded

`Spacer(flex: 1)` 是一个 Expanded 的空盒子——纯粹用来"推开"两侧的元素：

```dart
Row(
  children: [
    const Text('左侧'),
    const Spacer(),           // 把"右侧"推到最右
    const Text('右侧'),
  ],
)
```

比 `Expanded(child: SizedBox())` 更语义化——看到 Spacer 就知道"这里只是留白"。

## 5.3 Stack 与 Positioned：层叠

```dart
      child: Stack(
        children: const [
          // ═══ 5.3（续）alignment 对齐 + Positioned 精确定位 ═══
          ColoredBox(color: Colors.blueGrey, child: Center(child: Text('底层'))),
          Positioned(right: 8, top: 8, child: Icon(Icons.push_pin)),
        ],
      ),
```

Stack 按列表顺序**从底到顶**叠放孩子。两种摆法：非 Positioned 的孩子按 `alignment` 对齐（默认左上角）；`Positioned(left/top/right/bottom)` 精确锚定——角标、悬浮关闭按钮、进度遮罩都是这套。一个 Stack 尺寸规则：**按最大的非 Positioned 孩子定尺寸**。

### Positioned 的填充语义

`Positioned` 的四个边参数不是"偏移量"而是"锚定距离"：

```dart
// 距右 8、距上 8——位置由右和上两条边决定
Positioned(right: 8, top: 8, child: Icon(...))

// 只给 left 和 right——水平方向被拉伸（孩子获得紧约束）
Positioned(left: 0, right: 0, top: 0, child: Container(height: 4, color: Colors.red))  // 顶部通栏红条

// 四边都给——填满整个 Stack（遮罩层就是这么做的）
Positioned.fill(child: ModalBarrier(...))
```

`Positioned.fill` 是四边全 0 的语法糖——半透明遮罩、点击拦截层用它。

## 5.4 Wrap：自动换行的 Row

Row 放不下就溢出（黄黑条纹）；Wrap 放不下**自动换行**——标签云、筛选器、按钮组都该用它：

```dart
Wrap(
  spacing: 8,        // 主轴方向的间隙
  runSpacing: 4,     // 换行后的行间隙
  children: tags.map((t) => Chip(label: Text(t))).toList(),
)
```

`direction` 控制横排还是竖排；`alignment`/`runAlignment` 分别控制主轴和交叉轴的对齐。Wrap 是"Row 的容错版"——内容多少不确定时优先 Wrap，确定一行放得下才用 Row。

## 5.5 Table：行列表格

多子布局的第四位成员：**Table**——每行高度随内容、每列宽度单独控制的网格（员工表、对比表、棋盘）。它不是 GridView 的别名：GridView 是**滚动**布局（子项可懒构建），Table 是**紧凑**布局（全量布局，适合一屏内的小表）：

```dart
// ═══ 5.4 ═══
Table(
  columnWidths: const <int, TableColumnWidth>{
    0: FixedColumnWidth(90),            // 第 0 列定宽
    1: FlexColumnWidth(),               // 其余列瓜分剩余
  },
  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
  border: TableBorder.all(color: Colors.black38, width: 1),
  children: const <TableRow>[
    TableRow(children: [Text('姓名'), Text('部门')]),   // 每行孩子数必须等于列数
    TableRow(children: [Text('张三'), Text('研发')]),
  ],
)
```

三条纪律：**每行孩子数必须一致**（多一个少一个直接断言崩）；**列宽**用 `columnWidths` 按下标指定（`FixedColumnWidth(90)` 定宽 / `FlexColumnWidth()` 弹性 / `FractionColumnWidth(0.4)` 按比例）；跨行跨列没有 HTML 的 colspan——需要时用 `TableRow` 里嵌 Row/Column 自己拼。不确定要不要 Table 时默认 Row+Column 组合，规整网格数据才值得上它。

## 5.6 布局选型表

| 场景 | 组合 |
|---|---|
| 一行操作按钮 | `Row + spaceEvenly` |
| 表单竖排 | `Column`（装进可滚动 ListView） |
| 分栏布局 | `Row + Expanded(flex:)` |
| 图 + 角标 | `Stack + Positioned` |
| 底部信息条 | `Column + Expanded(主体) + 固定高条` |
| 标签云/筛选器 | `Wrap + spacing` |
| 规整数据表 | `Table`（列宽 columnWidths，行高随内容） |

## 坑位清单

- **RenderFlex overflow（黄黑条纹）**：内容总宽超过可用宽。三选一：`Expanded` 包裹可压缩的孩子、给文本 `Expanded + overflow: ellipsis`、整体改 `Wrap`（放不下就换行）/ListView。
- **mainAxisSize.min 的边界**：想让 Column 按内容收缩时用它；但父级若给无界高度（如 ListView 子项）会退化——不可滚动父级里再包 Flexible。
- **Stack 里的 Positioned 必须直接是 Stack 的孩子**：中间隔一层就报"incorrect use of ParentDataWidget"。
- **Row 嵌 Row 需要内层 Expanded**：内层 Row 在无界宽度里排孩子会崩，内层先 Expanded 拿到份额。
- **Expanded 用在不可滚动 Column 里**：Column 在 ListView 里垂直无界——Expanded 找不到"剩余空间"会崩。ListView 子项要撑满高度用 `SizedBox.expand` 或定高。
- **Wrap 当 Row 用**：Wrap 的行高不一致时（有的行一个 Chip、有的行三个）视觉参差——需要严格单行对齐时还是 Row + Expanded。
---

上一章：[04 · 布局 I：容器与装饰](04-layout-single.md) ｜ 下一章：[06 · Material 组件库：搭积木的说明书](06-material.md) ｜ 返回：[README](../README.md)
