# 04 · 布局 I：容器与装饰

> 对应示例：examples/04_layout_single/

## 4.1 解决什么问题

内容有了，怎么摆？Flutter 布局的心脏是一条**约束传递协议**：父级给子级下发约束（"你的宽度必须在 0..768 之间"），子级在约束内选定自己的尺寸回报，父级再决定摆放位置。记住一句口诀：**约束向下，尺寸向上，位置由父定**。本章讲只有一个孩子的容器——它们是这条协议最简单的参与者。

先看最常用的留白三件套：

```dart
            // ═══ 4.1 Padding 与 SizedBox：留白三件套 ═══
            Padding(
              padding: EdgeInsets.all(12),
              child: Text('Padding 四周留白 12'),
            ),
            SizedBox(height: 8, child: ColoredBox(color: Colors.amber)),
```

注意一个哲学选择：Flutter 没有 `widget.padding` 属性——**留白本身也是 Widget**（Padding）。一切皆 Widget 的代价是嵌套，收益是组合自由（Padding 包任何东西）与 const 优化。`EdgeInsets` 的四种姿势：`all(12)` / `symmetric(horizontal: 8, vertical: 4)` / `only(left: 16)` / `fromLTRB(8,4,8,4)`；`SizedBox` 管两种事：撑间隙（`height: 8`）和定尺寸（`width×height`）。

## 4.2 Container 与装饰：盒子模型的门面

```dart
    return Container(
      key: const Key('box-demo'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      // ═══ 4.2（续）BoxDecoration：颜色/圆角/边框/阴影 ═══
      decoration: BoxDecoration(
        color: Colors.deepOrange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepOrange, width: 2),
        boxShadow: const [
          BoxShadow(blurRadius: 8, offset: Offset(2, 4), color: Colors.black26),
        ],
      ),
      child: const Text('圆角 + 边框 + 阴影的 Container'),
    );
```

Container 是最常用的盒子，聚合了尺寸（width/height）、内边距（padding）、外边距（margin）、装饰（decoration）、变换（transform）和 `alignment`。装饰交给 `BoxDecoration`：

| 属性 | 效果 |
|---|---|
| `color` | 背景色（直接写 `Container(color:)` 也行） |
| `borderRadius` | 圆角 |
| `border` | 边框（`Border.all(color, width)`） |
| `boxShadow` | 阴影列表（blurRadius 模糊、offset 偏移） |
| `gradient` | 渐变（LinearGradient 等） |

性能小知识：**无参数的 Container 直接退化为 child**；只要纯色背景用 `ColoredBox`、只要约束用 `SizedBox` 更轻——框架内部也会做这种替换，但写代码时选对组件是好习惯。

## 4.3 Align 与 Center：摆放唯一的孩子

```dart
      child: const Align(
        alignment: Alignment(0.9, 0),
        child: Icon(Icons.arrow_circle_right),
      ),
```

Align 把唯一的孩子放到盒子里的指定位置。`Alignment(x, y)` 用 -1..1 的坐标：`(0,0)` 正中、`(-1,-1)` 左上、`(0.9, 0)` 靠右居中——不是像素值，是相对盒子的比例位置（九宫格加刻度）。`Center` 就是 `Align(alignment: Alignment.center)` 的别名，也是你写得最多的居中手段（第 02 章已经用过）。

Align 还有一个隐藏用途：**放松约束**。父级给的紧约束（"宽度必须是 768"）会让孩子的 `width` 设置失效——套一层 Align/Center，约束变松（"0..768 都行"），孩子的自有尺寸才能生效。第 15 章的动画示例就踩过这个坑（ListView 里 AnimatedContainer 宽度被顶满，Center 一包就好）。

## 4.4 布局选型小结

| 需求 | 用 |
|---|---|
| 内边距 | `Padding` |
| 间隙/固定尺寸 | `SizedBox` |
| 圆角边框阴影渐变 | `Container + BoxDecoration` |
| 摆放/居中/放松约束 | `Align` / `Center` |
| 摆多个孩子 | Row/Column/Stack（下一章） |
| 内容超出屏幕 | ListView（第 12 章） |

## 坑位清单

- **width 不生效**：先查父级约束是不是紧的（ListView 子项、Expanded 内）——套 Align/Center 放松，或改用 Expanded 瓜分（05 章）。
- **阴影被裁剪**：父级带裁剪（ClipRect）或贴边时阴影被切——留出 margin 余量。
- **Container 同时写 color 和 decoration 会编译错**：把 color 挪进 BoxDecoration。
- **`double.infinity` 的条件**：无界父级（如横向 Row 里写 `width: infinity`）直接崩（unbounded 约束）——用 Expanded/Flexible（05 章）表达"占满"。
