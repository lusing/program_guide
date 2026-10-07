# 04 · 布局系统：坐标、Dock、Anchor、表格

> 对应示例：`examples/04_layout`（两列表单 + 流式按钮条 + Anchor 拉伸实验 + 窗口尺寸读数）

> **本章你将学会**：绝对坐标与 ClientSize、Dock 的抢占、Anchor 的钉边、TableLayoutPanel/FlowLayoutPanel、DPI 缩放。
> **前置章节**：[02](02-hello.md)、[03](03-forms.md)。

## 1. 两套世界观：坐标 vs 容器

```csharp
button.Location = new Point(120, 250);   // 绝对坐标：拖多大窗口它都钉死在那里
button.Dock = DockStyle.Fill;            // 容器关系：随父容器自动变化
```

绝对坐标直观但脆弱（窗口一拉就乱）；现代写法尽量用 **Dock + Anchor + 布局面板**三件套。

## 2. Dock：贴边的艺术

`DockStyle` 五个值：`Top/Bottom/Left/Right/Fill`。02 章已经用过 Top+Bottom。**关键规则：Dock 是抢占式的——同一条边被多个控件 Dock 时，按 z 序分配**：

```csharp
Controls.Add(_rich);      // Fill
Controls.Add(tools);      // Top
Controls.Add(login);      // Top
Controls.Add(_status);    // Bottom
```

**后 Add 的先占坑**。z 序表里靠前的控件优先选边，`Fill` 要第一个 Add 才能拿到"剩下的全部"，否则它会把别人挤没。本教程示例统一按"Fill 最先、其余按从下到上"的顺序 Add——你会在几乎每个示例的构造函数尾部看到。

## 3. Anchor：钉住哪条边就跟随哪条边

```csharp
_anchorBox.Anchor = AnchorStyles.Left | AnchorStyles.Top | AnchorStyles.Right;
// 左上钉死、右边跟随：拖宽窗口，文本框跟着变宽
```

默认值是 `Left | Top`（钉左上，所以控件平时不动）。四个方向任意组合：全钉 = 等比拉伸；只钉左右 = 水平伸缩垂直不动；钉对角 = 变形跟随。04 示例的 Anchor 实验区拖宽窗口能看到文本框宽度数字实时变化。

## 4. TableLayoutPanel：表格布局

```csharp
var table = new TableLayoutPanel { Dock = DockStyle.Top, ColumnCount = 2, RowCount = 4 };
table.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 28f));   // 列宽按比例
table.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 72f));
table.Controls.Add(label, 0, row);      // (控件, 列, 行) —— 指定格子
table.Controls.Add(input, 1, row);
```

表单类界面的标准答案："标签列 + 输入列"的两列表格。`ColumnStyle` 三种 `SizeType`：`Percent`（按比例分）、`AutoSize`（随内容）、`Absolute`（像素）。

## 5. FlowLayoutPanel：流式布局

```csharp
var flow = new FlowLayoutPanel { Dock = DockStyle.Bottom, FlowDirection = FlowDirection.LeftToRight };
foreach (var name in new[] { "重置", "保存", "导出", "打印", "分享", "更多…" })
    flow.Controls.Add(new Button { Text = name, AutoSize = true });   // 放不下自动换行
```

按钮条/工具区的答案。`FlowDirection` 四向；`WrapContents = false` 时溢出裁剪。

## 6. ClientSize vs Size、Padding/Margin

- `ClientSize` = 客户区（不含标题栏边框），**布局代码该关心的数字**；04 示例状态栏实时显示它。
- `Padding`（容器内边距）作用于**子控件**，`Margin`（控件外边距）作用于**自己与邻居**——两组值默认都是 3。
- `MinimumSize` 防止用户把窗口拖成一根线。

## 7. DPI 缩放：AutoScaleMode

```csharp
AutoScaleMode = AutoScaleMode.Font;     // 按字体尺寸整体缩放
```

高分屏上不糊不挤的官方答案。选项：`Font`（推荐，随系统字号）、`Dpi`（按像素密度）、`None`（自担风险）、`Inherit`。**窗体设了子控件自动跟随**。这是 .NET Core 3.0+ 重点修的领域（PerMonitorV2），老代码迁移时的高频问题源。

## 8. 三语言差异

F# 的枚举位或要留意**语法位置**：

```fsharp
// 位或表达式当命名实参的值：报 FS0691（解析断开）——先 let 绑定再赋值
let anchorBox = new TextBox(Location = Point(120, 250), Width = 300)
anchorBox.Anchor <- AnchorStyles.Left ||| AnchorStyles.Top ||| AnchorStyles.Right
```

C++/CLI：

```cpp
_anchorBox->Anchor = static_cast<AnchorStyles>(
    AnchorStyles::Left | AnchorStyles::Top | AnchorStyles::Right);   // 位或后要 cast 回枚举
table->Padding = System::Windows::Forms::Padding(12);               // Padding 在 Forms 命名空间（不在 Drawing）
```

**实测坑**：`System::Drawing::Padding` 报 C2039——现代 .NET 里 Padding 搬到了 `System.Windows.Forms`（本体在 `System.Windows.Forms.Primitives` 程序集，Cpp.Common.props 已引）。

## 坑位清单

1. Dock 的 Fill 最后 Add → 被先来的 Top/Bottom 挤没（或反过来挤没别人）——按"Fill 最先"的固定顺序写。
2. Anchor 写了却"没反应"：忘了它默认就是 `Left|Top`，要**组合**出你想要的跟随关系。
3. C++/CLI `table->Padding = System::Drawing::Padding(...)` 编不过——命名空间搬家了。
4. 老书示例用像素坐标摆满全屏、不设 `AutoScaleMode`——高分屏上要么小得看不清要么糊。
5. `Size` 当布局依据：标题栏高度随系统主题变，永远优先 `ClientSize`。

## 自测

1. 同为 `DockStyle.Top` 的两个控件，上下位置由什么决定？
2. `Anchor = Left | Right`（不钉上下）的控件拖高窗口时行为？
3. TableLayoutPanel 的 `ColumnStyle` 三种 SizeType 分别适用什么场景？
4. `Padding` 与 `Margin` 分别作用于谁？
5. 为什么推荐 `AutoScaleMode.Font` 而不是 `None`？

---

上一章：[03 窗体与生命周期](03-forms.md) · 下一章：[05 文本类控件](05-controls-text.md)
