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

spaceBetween 与 spaceEvenly 的区别一句话：**Between 把空隙只放中间，Evenly 连两端也均分**。

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

## 5.4 布局选型表

| 场景 | 组合 |
|---|---|
| 一行操作按钮 | `Row + spaceEvenly` |
| 表单竖排 | `Column`（装进可滚动 ListView） |
| 分栏布局 | `Row + Expanded(flex:)` |
| 图 + 角标 | `Stack + Positioned` |
| 底部信息条 | `Column + Expanded(主体) + 固定高条` |

## 坑位清单

- **RenderFlex overflow（黄黑条纹）**：内容总宽超过可用宽。三选一：`Expanded` 包裹可压缩的孩子、给文本 `Expanded + overflow: ellipsis`、整体改 `Wrap`（放不下就换行）/ListView。
- **mainAxisSize.min 的边界**：想让 Column 按内容收缩时用它；但父级若给无界高度（如 ListView 子项）会退化——不可滚动父级里再包 Flexible。
- **Stack 里的 Positioned 必须直接是 Stack 的孩子**：中间隔一层就报"incorrect use of ParentDataWidget"。
- **Row 嵌 Row 需要内层 Expanded**：内层 Row 在无界宽度里排孩子会崩，内层先 Expanded 拿到份额。
